extends SceneTree
## Verifies that MoonGoons Take Back is the cops-side game using the uploaded
## APK's screen hierarchy without copying its protected assets or code.

var failures: int = 0

func _init() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var threat_script: Script = load("res://scripts/counter_syndicate_state.gd") as Script
	var map_script: Script = load("res://scripts/syndicate_threat_map.gd") as Script
	var campaign_script: Script = load("res://scripts/peacekeeper_campaign_mode.gd") as Script
	var battle_bridge_script: Script = load("res://scripts/peacekeeper_battle_bridge.gd") as Script
	_expect(threat_script != null, "Counter-Syndicate campaign state loads")
	_expect(map_script != null, "Clickable Syndicate threat map loads")
	_expect(campaign_script != null, "Peacekeeper campaign identity layer loads")
	_expect(battle_bridge_script != null, "Battle-to-district result bridge loads")
	if threat_script == null:
		quit(1)
		return

	var threat_state: Node = threat_script.new() as Node
	root.add_child(threat_state)
	await process_frame
	threat_state.call("reset_state")
	var districts_value: Variant = threat_state.get("districts")
	_expect(districts_value is Array and (districts_value as Array).size() == 6, "Six hostile lunar districts exist")
	var selected_result: Dictionary = threat_state.call("select_target", "dock_seven") as Dictionary
	_expect(bool(selected_result.get("ok", false)), "Peacekeepers can select a Syndicate-controlled district")
	_expect(String(threat_state.get("current_target_id")) == "dock_seven", "Selected district becomes the active target")

	var district: Dictionary = threat_state.call("get_district", "dock_seven") as Dictionary
	var threat_before: int = int(district.get("threat", 0))
	var control_before: int = int(district.get("control", 0))
	threat_state.call("record_patrol_result", "dock_seven", true, 2)
	_expect(int(district.get("threat", 0)) < threat_before, "Winning a patrol lowers Syndicate threat")
	_expect(int(district.get("control", 0)) > control_before, "Winning a patrol raises Peacekeeper control")
	var arrests_before: int = int(threat_state.get("major_arrests"))
	threat_state.call("record_major_arrest", "dock_seven")
	_expect(int(threat_state.get("major_arrests")) == arrests_before + 1, "Major arrests are recorded against the hostile district")
	_expect(String(threat_state.call("campaign_status")).contains("AUTHORITY"), "Campaign HUD reports Authority versus Syndicate control")

	var map_scene: PackedScene = load("res://scenes/SyndicateThreatMap.tscn") as PackedScene
	var living_scene: PackedScene = load("res://scenes/LivingPrecinct.tscn") as PackedScene
	var battle_scene: PackedScene = load("res://scenes/PrecinctBattle.tscn") as PackedScene
	_expect(map_scene != null, "Threat-map scene parses")
	_expect(living_scene != null, "Living precinct scene parses")
	_expect(battle_scene != null, "Peacekeeper patrol battle scene parses")

	var living_file: FileAccess = FileAccess.open("res://scenes/LivingPrecinct.tscn", FileAccess.READ)
	_expect(living_file != null, "Living precinct scene can be inspected")
	if living_file != null:
		var living_text: String = living_file.get_as_text()
		_expect(living_text.contains("peacekeeper_campaign_mode.gd"), "Precinct includes the counter-Syndicate campaign layer")
	var battle_file: FileAccess = FileAccess.open("res://scenes/PrecinctBattle.tscn", FileAccess.READ)
	_expect(battle_file != null, "Patrol battle scene can be inspected")
	if battle_file != null:
		_expect(battle_file.get_as_text().contains("peacekeeper_battle_bridge.gd"), "Battles feed results back into district control")

	var project_file: ConfigFile = ConfigFile.new()
	var config_error: Error = project_file.load("res://project.godot")
	_expect(config_error == OK, "Project configuration loads")
	_expect(String(project_file.get_value("application", "run/main_scene", "")) == "res://scenes/LivingPrecinct.tscn", "Take Back starts directly in the cops-side precinct")
	_expect(String(project_file.get_value("autoload", "CounterSyndicate", "")) == "*res://scripts/counter_syndicate_state.gd", "Counter-Syndicate state is globally registered")

	threat_state.queue_free()
	await process_frame
	if failures == 0:
		print("SUCCESS: Cops-side counter-Syndicate campaign structure passed.")
	else:
		push_error("FAILED: %d counter-Syndicate campaign check(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
