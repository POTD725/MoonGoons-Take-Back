extends SceneTree
## Run with:
## godot --headless --path . --script res://tests/data_and_simulation_smoke_test.gd
## This is a lightweight local smoke test, not a full multiplayer certification suite.

var failures: Array[String] = []

func _init() -> void:
	_test_data_catalog()
	_test_fixed_point_movement()
	_test_lockstep_turn()
	if failures.is_empty():
		print("MoonGoons smoke test passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _test_data_catalog() -> void:
	var game_data := MoonGoonsGameData.new()
	if not game_data.load_all():
		failures.append("Game data failed to load: %s" % ", ".join(game_data.errors))
		return
	var validator := MoonGoonsDataValidator.new()
	var issues := validator.validate(game_data)
	if not issues.is_empty():
		failures.append("Data validation issues: %s" % ", ".join(issues))
	var parser := MoonGoonsAbilityDataParser.new()
	if not parser.initialize_from_game_data(game_data):
		failures.append("Ability parser failed: %s" % ", ".join(parser.errors))
	if parser.get_profile("pk_patrol_deputy").is_empty():
		failures.append("Patrol Deputy profile was not resolved.")
	if parser.get_profile("pk_hero_magistrate").is_empty():
		failures.append("Tier 3 Magistrate profile was not resolved.")

func _test_fixed_point_movement() -> void:
	var controller := MoonGoonsFixedPointMovementController.new()
	var unit := MoonGoonsSimulationUnit.new(
		"test_unit_01",
		"lunar_peacekeepers",
		0,
		0,
		MoonGoonsFixedMath.from_float(4.5)
	)
	if not controller.register_unit(unit):
		failures.append("Simulation unit registration failed.")
		return
	controller.issue_move_command(["test_unit_01"], MoonGoonsFixedMath.from_float(3.0), 0)
	for _tick: int in range(30):
		controller.process_simulation_tick()
	if unit.current_position.x <= 0:
		failures.append("Fixed-point unit did not advance toward move target.")
	if unit.current_position.x > MoonGoonsFixedMath.from_float(3.0):
		failures.append("Fixed-point unit overshot move target.")

func _test_lockstep_turn() -> void:
	var controller := MoonGoonsFixedPointMovementController.new()
	var unit := MoonGoonsSimulationUnit.new("network_unit_01", "lunar_peacekeepers", 0, 0, MoonGoonsFixedMath.from_float(3.0))
	controller.register_unit(unit)
	var lockstep := MoonGoonsLockstepNetworkManager.new(controller, [1, 2])
	var player_one_packet := lockstep.make_input_packet(0, 1, [{
		"command_type": "move",
		"selected_unit_ids": ["network_unit_01"],
		"target_x_fp": MoonGoonsFixedMath.from_float(1.0),
		"target_z_fp": 0
	}])
	var player_two_packet := lockstep.make_input_packet(0, 2, [{"command_type": "no_op"}])
	if not lockstep.receive_input_packet(player_one_packet) or not lockstep.receive_input_packet(player_two_packet):
		failures.append("Lockstep packets were rejected unexpectedly.")
		return
	var result := lockstep.update_network_turn_loop()
	if not bool(result.get("advanced", false)):
		failures.append("Lockstep turn did not advance after both packets arrived.")
	if lockstep.current_simulation_tick != 3:
		failures.append("Lockstep turn did not execute exactly three simulation ticks.")
