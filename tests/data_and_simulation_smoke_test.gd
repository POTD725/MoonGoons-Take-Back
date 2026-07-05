extends SceneTree
## Run with:
## godot --headless --path . --script res://tests/data_and_simulation_smoke_test.gd
## This is a local smoke suite, not full multiplayer certification.

var failures: Array[String] = []

func _init() -> void:
	_test_data_catalog()
	_test_fixed_point_movement()
	_test_lockstep_turn()
	_test_resource_bank()
	_test_combat_and_abilities()
	_test_mission_controller()
	_test_save_system()
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
	var issues: Array[String] = validator.validate(game_data)
	if not issues.is_empty():
		failures.append("Data validation issues: %s" % ", ".join(issues))
	var parser := MoonGoonsAbilityDataParser.new()
	if not parser.initialize_from_game_data(game_data):
		failures.append("Ability parser failed: %s" % ", ".join(parser.errors))
	if parser.get_profile("pk_patrol_deputy").is_empty():
		failures.append("Patrol Deputy profile was not resolved.")
	if parser.get_profile("pk_hero_magistrate").is_empty():
		failures.append("Tier 3 Magistrate profile was not resolved.")
	if game_data.get_translation("es", "ui_menu.start_game") != "Iniciar juego":
		failures.append("Spanish localization lookup did not resolve expected string.")

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
	var result: Dictionary = lockstep.update_network_turn_loop()
	if not bool(result.get("advanced", false)):
		failures.append("Lockstep turn did not advance after both packets arrived.")
	if lockstep.current_simulation_tick != 3:
		failures.append("Lockstep turn did not execute exactly three simulation ticks.")

func _test_resource_bank() -> void:
	var bank := MoonGoonsResourceBank.new()
	bank.initialize_player_account(1, 5, 200)
	for _tick: int in range(MoonGoonsFixedMath.TICKS_PER_SECOND):
		bank.process_passive_income_tick(1, 2 * MoonGoonsFixedMath.SCALE)
	var snapshot: Dictionary = bank.get_player_snapshot(1)
	if int(snapshot.get("credits_fp", 0)) != 202 * MoonGoonsFixedMath.SCALE:
		failures.append("Resource bank did not accumulate exactly two Credits per simulated second.")
	if not bank.try_spend(1, {"credits": 100, "command_capacity": 2}):
		failures.append("Resource bank rejected an affordable capacity-valid purchase.")
	if bank.try_spend(1, {"credits": 1000, "command_capacity": 1}):
		failures.append("Resource bank approved an unaffordable purchase.")

func _test_combat_and_abilities() -> void:
	var bank := MoonGoonsResourceBank.new()
	bank.initialize_player_account(1, 20)
	var damage := MoonGoonsCombatDamageProcessor.new(bank)
	var runner := MoonGoonsCombatDamageProcessor.CombatEntity.new(
		"syn_runner_test", 2, "the_syndicate", "light_infantry", 100 * MoonGoonsFixedMath.SCALE, true
	)
	damage.register_entity(runner)
	var impact: Dictionary = damage.apply_weapon_impact(
		"pk_deputy_test", "lunar_peacekeepers", 1, "syn_runner_test", "kinetic", 100 * MoonGoonsFixedMath.SCALE, MoonGoonsGameRand.new(7), true
	)
	if String(impact.get("result", "")) != "arrested" or not runner.is_arrested:
		failures.append("Peacekeeper lethal detain did not produce an arrest state.")
	if int(bank.get_player_snapshot(1).get("evidence_fp", 0)) != 25 * MoonGoonsFixedMath.SCALE:
		failures.append("Arrest did not award 25 Evidence.")
	var ability_bank := MoonGoonsResourceBank.new()
	ability_bank.initialize_player_account(2, 20)
	var abilities := MoonGoonsCombatAbilityController.new(ability_bank)
	abilities.register_unit_abilities("runner_ability_test", 2, [{"id": "siphon", "cooldown": 0.0, "effects": {}}])
	var activate: Dictionary = abilities.execute_ability("runner_ability_test", "siphon", {"valid_resource_node": true})
	if not bool(activate.get("ok", false)):
		failures.append("Siphon ability was not activated.")
	for _tick: int in range(MoonGoonsFixedMath.TICKS_PER_SECOND):
		abilities.process_simulation_tick()
	if int(ability_bank.get_player_snapshot(2).get("credits_fp", 0)) != 202 * MoonGoonsFixedMath.SCALE:
		failures.append("Active Siphon did not generate exactly two Credits per second.")

func _test_mission_controller() -> void:
	var bank := MoonGoonsResourceBank.new()
	bank.initialize_player_account(1, 20)
	var mission := MoonGoonsMissionController.new(bank)
	if not mission.load_catalog() or not mission.start_mission("m_1_02"):
		failures.append("Mission controller could not load Mission 1.02.")
		return
	mission.notify_event("on_buildings_changed", {"built_building_ids": ["pk_tactical_armory", "pk_drone_bay"]})
	if mission.get_objective_state("build_perimeter") != "completed":
		failures.append("Mission 1.02 build objective did not complete.")
	mission.notify_event("on_enter_area", {"area_id": "mining_terminal", "hostiles_cleared_in_area": "mining_yard"})
	if int(bank.get_player_snapshot(1).get("evidence_fp", 0)) != 50 * MoonGoonsFixedMath.SCALE:
		failures.append("Mission 1.02 terminal event did not award 50 Evidence.")

func _test_save_system() -> void:
	var saves := MoonGoonsSaveSystem.new()
	var payload := {"mission_id": "m_1_02", "credits_fp": 202000}
	if not saves.save_snapshot(9, 1, 42, payload):
		failures.append("Save system could not write smoke-test snapshot: %s" % ", ".join(saves.errors))
		return
	var loaded: Dictionary = saves.load_snapshot(9, 1)
	if not bool(loaded.get("ok", false)):
		failures.append("Save system could not load smoke-test snapshot.")
	elif (loaded.get("snapshot", {}) as Dictionary).get("mission_id") != "m_1_02":
		failures.append("Save system returned the wrong mission snapshot payload.")
	saves.delete_snapshot(9)
