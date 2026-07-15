extends SceneTree
## Headless checks for the Syndicate Rising hideout and tactical-job campaign.

var failures: int = 0

func _init() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	print("[SYNDICATE] Loading criminal campaign state...")
	var state_script: Script = load("res://scripts/syndicate_state.gd") as Script
	_expect(state_script != null, "Syndicate state script loads")
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

	var rebuild_result: Dictionary = state_node.call("repair_room", "chop_shop") as Dictionary
	_expect(bool(rebuild_result.get("ok", false)), "Damaged hideout room enters rebuild queue")
	var chop_shop: Dictionary = state_node.call("get_room", "chop_shop") as Dictionary
	_expect(int(chop_shop.get("repair_end", 0)) > 0, "Rebuild queue stores an absolute completion timer")

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
	state_node.set("credits", 1000)
	state_node.set("intel", 100)
	var tech_result: Dictionary = state_node.call("begin_black_tech") as Dictionary
	_expect(bool(tech_result.get("ok", false)), "Black-tech research starts when the Signal Den is rebuilt")

	state_node.call("_generate_job")
	var jobs_value: Variant = state_node.get("jobs")
	_expect(jobs_value is Array and not (jobs_value as Array).is_empty(), "Job generation produces a criminal score")
	if jobs_value is Array and not (jobs_value as Array).is_empty():
		var first_job: Dictionary = (jobs_value as Array)[0] as Dictionary
		var job_id: String = String(first_job.get("id", ""))
		var crew_ids: Array[String] = ["crew_1"]
		var launch_result: Dictionary = state_node.call("begin_job", job_id, crew_ids) as Dictionary
		_expect(bool(launch_result.get("ok", false)), "An available crew member can launch a job")
		var active_job_value: Variant = state_node.get("active_job")
		_expect(active_job_value is Dictionary and not (active_job_value as Dictionary).is_empty(), "Launching moves the score into tactical battle state")
		var notoriety_before: int = int(state_node.get("notoriety"))
		var hp_results: Dictionary = {"crew_1": 80}
		state_node.call("finish_job", true, hp_results)
		_expect(int(state_node.get("notoriety")) > notoriety_before, "Winning a job increases Syndicate Notoriety")

	var router_scene: PackedScene = load("res://scenes/CampaignRouter.tscn") as PackedScene
	var hideout_scene: PackedScene = load("res://scenes/SyndicateHideout.tscn") as PackedScene
	var raid_scene: PackedScene = load("res://scenes/SyndicateRaid.tscn") as PackedScene
	var emblem: Texture2D = load("res://assets/syndicate/syndicate_emblem.svg") as Texture2D
	_expect(router_scene != null, "Campaign router scene parses")
	_expect(hideout_scene != null, "Syndicate hideout scene parses")
	_expect(raid_scene != null, "Syndicate tactical raid scene parses")
	_expect(emblem != null, "Original Syndicate emblem imports")

	state_node.queue_free()
	await process_frame
	if failures == 0:
		print("SUCCESS: Syndicate Rising smoke tests passed.")
	else:
		push_error("FAILED: %d Syndicate smoke test(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
