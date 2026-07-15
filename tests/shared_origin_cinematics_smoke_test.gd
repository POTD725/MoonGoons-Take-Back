extends SceneTree

var failures: int = 0
var battle_started_count: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var campaign: Node = root.get_node_or_null("TakeBackCampaign")
	var threats: Node = root.get_node_or_null("SpaceThreats")
	var station: Node = root.get_node_or_null("StationProgression")
	var precinct: Node = root.get_node_or_null("PrecinctState")
	_expect(campaign != null, "Take Back shared campaign autoload exists")
	_expect(threats != null and threats.has_signal("battle_started"), "Space battles expose a cinematic start signal")
	if campaign == null or threats == null or station == null or precinct == null:
		quit(1)
		return

	campaign.call("reset_campaign")
	campaign.set("cinematic_kind", "origin")
	campaign.set("cinematic_slide_index", 0)
	var origin_slides: Array = campaign.call("cinematic_slides") as Array
	var chapters: Array = campaign.call("chapter_catalog") as Array
	_expect(origin_slides.size() >= 5, "Origin story contains at least five illustrated beats")
	_expect(chapters.size() >= 6, "Shared campaign contains origin and five Take Back chapters")
	_expect(String((chapters[1] as Dictionary).get("target", "")) == "vox_courier_pack", "The first operation follows the Ghost Key courier route")

	var required_assets: Array[String] = [
		"res://assets/shared/syndicate_rising/lunar_surface_panorama.svg",
		"res://assets/shared/syndicate_rising/peacekeeper_orbital_station.svg",
		"res://assets/shared/syndicate_rising/take_back_response.svg",
		"res://assets/shared/syndicate_rising/harvest_sites.svg",
		"res://assets/shared/syndicate_rising/hideout_defenses.svg",
		"res://assets/shared/syndicate_rising/side_missions.svg"
	]
	for asset_path: String in required_assets:
		_expect(FileAccess.file_exists(asset_path), "Shared art checked into Take Back: %s" % asset_path.get_file())

	var cinematic_scene: PackedScene = load("res://scenes/TakeBackCinematic.tscn") as PackedScene
	_expect(cinematic_scene != null, "Origin and attack cinematic scene parses")
	if cinematic_scene != null:
		var cinematic: Node = cinematic_scene.instantiate()
		root.add_child(cinematic)
		await process_frame
		_expect(cinematic.name == "TakeBackCinematic", "Cinematic screen instantiates")
		cinematic.queue_free()
		await process_frame

	threats.call("reset_state")
	station.call("reset_state")
	precinct.call("reset_state")
	station.set("station_level", 10)
	if not threats.is_connected("battle_started", _on_battle_started):
		threats.connect("battle_started", _on_battle_started)
	var start_result: Dictionary = threats.call("begin_battle", "vox_courier_pack") as Dictionary
	_expect(bool(start_result.get("ok", false)), "Vox-13 engagement still starts through the tested combat state")
	_expect(battle_started_count == 1, "Starting a named fleet engagement requests one cinematic")

	campaign.set("current_chapter", 1)
	campaign.call("_on_target_defeated", "vox_courier_pack", "Vox-13")
	_expect(int(campaign.get("current_chapter")) == 2, "Defeating the chapter target advances the shared story")

	if failures == 0:
		print("SUCCESS: Shared origin, artwork, and attack cinematics passed.")
	else:
		push_error("FAILED: %d shared campaign or cinematic check(s) failed." % failures)
	quit(failures)

func _on_battle_started(_target_id: String) -> void:
	battle_started_count += 1

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
