extends SceneTree
## Headless checks for the illustrated Syndicate Rising campaign.

var failures: int = 0

func _init() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	print("[SYNDICATE] Loading criminal campaign state...")
	var state_script: Script = load("res://scripts/syndicate_state.gd") as Script
	var audio_script: Script = load("res://scripts/syndicate_audio.gd") as Script
	_expect(state_script != null, "Syndicate state script loads")
	_expect(audio_script != null, "Procedural audio script loads")
	if state_script == null:
		quit(1)
		return
	var state_node: Node = state_script.new() as Node
	root.add_child(state_node)
	await process_frame
	state_node.call("reset_state")
	var rooms_value: Variant = state_node.get("rooms")
	var crew_value: Variant = state_node.get("crew")
	_expect(rooms_value is Array and (rooms_value as Array).size() == 8, "Eight criminal hideout rooms exist")
	_expect(crew_value is Array and (crew_value as Array).size() == 4, "Four starter criminals exist")
	_expect(String(state_node.get("pending_cutscene")) == "prologue", "New campaign begins with an illustrated prologue")

	var rebuild_result: Dictionary = state_node.call("repair_room", "chop_shop") as Dictionary
	_expect(bool(rebuild_result.get("ok", false)), "Damaged hideout room enters rebuild queue")
	var chop_shop: Dictionary = state_node.call("get_room", "chop_shop") as Dictionary
	_expect(int(chop_shop.get("repair_end", 0)) > 0, "Rebuild queue stores an absolute completion timer")
	chop_shop["repaired"] = true
	chop_shop["repair_end"] = 0
	state_node.set("credits", 2000)
	var upgrade_result: Dictionary = state_node.call("upgrade_room", "chop_shop") as Dictionary
	_expect(bool(upgrade_result.get("ok", false)), "Rebuilt room can be upgraded")
	_expect(int(chop_shop.get("level", 1)) == 2, "Room upgrade raises its level")

	var tunnel: Dictionary = state_node.call("get_room", "tunnel") as Dictionary
	tunnel["repaired"] = true
	var credits_before_fence: int = int(state_node.get("credits"))
	var cargo_before_fence: int = int(state_node.get("contraband"))
	var fence_result: Dictionary = state_node.call("fence_contraband") as Dictionary
	_expect(bool(fence_result.get("ok", false)), "Contraband can be fenced through the rebuilt tunnel")
	_expect(int(state_node.get("credits")) > credits_before_fence, "Fencing contraband awards credits")
	_expect(int(state_node.get("contraband")) < cargo_before_fence, "Fencing contraband consumes cargo")

	var signal_den: Dictionary = state_node.call("get_room", "signal_den") as Dictionary
	signal_den["repaired"] = true
	state_node.set("credits", 2000)
	state_node.set("intel", 100)
	var tech_result: Dictionary = state_node.call("begin_black_tech") as Dictionary
	_expect(bool(tech_result.get("ok", false)), "Black-tech research starts when the Signal Den is rebuilt")

	state_node.call("_generate_job")
	var jobs_value: Variant = state_node.get("jobs")
	_expect(jobs_value is Array and not (jobs_value as Array).is_empty(), "Job generation produces a criminal score")
	if jobs_value is Array and not (jobs_value as Array).is_empty():
		var first_job: Dictionary = (jobs_value as Array)[0] as Dictionary
		_expect(bool(first_job.get("story", false)), "Opening score is the chapter story job")
		_expect(String(first_job.get("story_id", "")) == "ghost_key", "Chapter one begins with Steal the Ghost Key")
		var job_id: String = String(first_job.get("id", ""))
		var crew_ids: Array[String] = ["crew_1"]
		var launch_result: Dictionary = state_node.call("begin_job", job_id, crew_ids) as Dictionary
		_expect(bool(launch_result.get("ok", false)), "An available crew member can launch a job")
		var notoriety_before: int = int(state_node.get("notoriety"))
		var hp_results: Dictionary = {"crew_1": 80}
		state_node.call("finish_job", true, hp_results)
		_expect(int(state_node.get("notoriety")) > notoriety_before, "Winning a job increases Syndicate Notoriety")
		_expect(int(state_node.get("story_chapter")) == 2, "Winning chapter one advances the story")
		_expect(String(state_node.get("pending_cutscene")) == "ghost_key", "Chapter victory schedules the next cutscene")

	var router_scene: PackedScene = load("res://scenes/CampaignRouter.tscn") as PackedScene
	var hideout_scene: PackedScene = load("res://scenes/SyndicateHideout.tscn") as PackedScene
	var raid_scene: PackedScene = load("res://scenes/SyndicateRaid.tscn") as PackedScene
	var cutscene_scene: PackedScene = load("res://scenes/SyndicateCutscene.tscn") as PackedScene
	_expect(router_scene != null, "Campaign router scene parses")
	_expect(hideout_scene != null, "Syndicate hideout scene parses")
	_expect(raid_scene != null, "Syndicate tactical raid scene parses")
	_expect(cutscene_scene != null, "Illustrated cutscene scene parses")

	var art_paths: Array[String] = [
		"res://assets/syndicate/rooms/backroom_command.svg",
		"res://assets/syndicate/rooms/chop_shop.svg",
		"res://assets/syndicate/rooms/black_market.svg",
		"res://assets/syndicate/rooms/safehouse_bunks.svg",
		"res://assets/syndicate/rooms/street_clinic.svg",
		"res://assets/syndicate/rooms/boss_office.svg",
		"res://assets/syndicate/rooms/signal_den.svg",
		"res://assets/syndicate/rooms/smuggler_tunnel.svg",
		"res://assets/syndicate/portraits/nyx_raze.svg",
		"res://assets/syndicate/portraits/vox_13.svg",
		"res://assets/syndicate/portraits/cinder_quell.svg",
		"res://assets/syndicate/portraits/grit_mercer.svg",
		"res://assets/syndicate/enemies/peacekeeper_response.svg",
		"res://assets/syndicate/cutscenes/crater_market_falls.svg",
		"res://assets/syndicate/cutscenes/ghost_key_network.svg",
		"res://assets/syndicate/cutscenes/take_back_dark.svg"
	]
	for path: String in art_paths:
		var texture: Texture2D = load(path) as Texture2D
		_expect(texture != null, "Artwork imports: %s" % path.get_file())

	state_node.queue_free()
	await process_frame
	if failures == 0:
		print("SUCCESS: Syndicate Rising art, audio, story, and gameplay smoke tests passed.")
	else:
		push_error("FAILED: %d Syndicate smoke test(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
