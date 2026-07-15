extends SceneTree

var failures: int = 0
var precinct_state: Node
var side_operations: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	precinct_state = root.get_node_or_null("PrecinctState")
	side_operations = root.get_node_or_null("SideOperations")
	_expect(precinct_state != null and side_operations != null, "Precinct and side-operation autoloads are available")
	if failures > 0:
		quit(failures)
		return
	precinct_state.call("reset_state")
	side_operations.call("reset_state")
	precinct_state.set("credits", 5000)
	precinct_state.set("evidence", 5)

	var start_engine: Dictionary = side_operations.call("start_operation", "engine") as Dictionary
	_expect(bool(start_engine.get("ok", false)), "Engine repair operation starts")
	side_operations.call("engine_action", "isolate_power")
	var operation: Dictionary = side_operations.get("active_operation") as Dictionary
	var fault: String = String(operation.get("fault_part", "fuse"))
	side_operations.call("engine_action", "replace_%s" % fault)
	while int((side_operations.get("active_operation") as Dictionary).get("coolant", 0)) < 45:
		side_operations.call("engine_action", "coolant_up")
	while int((side_operations.get("active_operation") as Dictionary).get("coolant", 0)) > 55:
		side_operations.call("engine_action", "coolant_down")
	side_operations.call("engine_action", "lock_coolant")
	var engine_result: Dictionary = side_operations.call("engine_action", "restart") as Dictionary
	_expect(bool(engine_result.get("ok", false)) and int(side_operations.get("engine_repairs")) == 1, "Engine puzzle completes through power, part, coolant, and restart stages")

	var start_weapon: Dictionary = side_operations.call("start_operation", "weapons") as Dictionary
	_expect(bool(start_weapon.get("ok", false)), "Weapons fitting operation starts")
	operation = side_operations.get("active_operation") as Dictionary
	var sequence: Array = operation.get("sequence", []) as Array
	for part_value: Variant in sequence:
		side_operations.call("weapon_action", String(part_value))
	operation = side_operations.get("active_operation") as Dictionary
	var target: int = int(operation.get("target_alignment", 50))
	var guard: int = 0
	while absi(int((side_operations.get("active_operation") as Dictionary).get("alignment", 0)) - target) > 5 and guard < 30:
		if int((side_operations.get("active_operation") as Dictionary).get("alignment", 0)) < target:
			side_operations.call("weapon_action", "align_right")
		else:
			side_operations.call("weapon_action", "align_left")
		guard += 1
	var weapon_result: Dictionary = side_operations.call("weapon_action", "calibrate") as Dictionary
	_expect(bool(weapon_result.get("ok", false)) and int(side_operations.get("weapon_upgrades")) == 1, "Weapon parts install in sequence and calibrate inside the target band")
	_expect(int(side_operations.get("defense_bonus")) >= 8, "Successful weapons work increases station defense")

	var start_medical: Dictionary = side_operations.call("start_operation", "medical") as Dictionary
	_expect(bool(start_medical.get("ok", false)), "Medical side operation starts")
	operation = side_operations.get("active_operation") as Dictionary
	var treatments: Array = operation.get("sequence", []) as Array
	var medical_result: Dictionary = {}
	for treatment_value: Variant in treatments:
		medical_result = side_operations.call("medical_action", String(treatment_value)) as Dictionary
	_expect(bool(medical_result.get("ok", false)) and int(side_operations.get("medical_cases")) == 1, "Medical puzzle stabilizes the patient with the correct treatment order")

	var start_interrogation: Dictionary = side_operations.call("start_operation", "interrogation") as Dictionary
	_expect(bool(start_interrogation.get("ok", false)), "Interrogation side operation starts")
	operation = side_operations.get("active_operation") as Dictionary
	operation["actual_guilt"] = 85
	side_operations.call("interrogation_action", "ask")
	side_operations.call("interrogation_action", "ask")
	side_operations.call("interrogation_action", "present_evidence")
	side_operations.call("interrogation_action", "present_evidence")
	side_operations.call("interrogation_action", "present_evidence")
	side_operations.call("interrogation_action", "verify_statement")
	var confession: Dictionary = side_operations.call("interrogation_action", "seek_confession") as Dictionary
	_expect(bool(confession.get("ok", false)) and int(side_operations.get("confessions")) == 1, "Balanced guilt, cooperation, stress, and credibility meters produce a reliable confession")

	side_operations.call("start_operation", "interrogation")
	operation = side_operations.get("active_operation") as Dictionary
	operation["actual_guilt"] = 90
	side_operations.call("interrogation_action", "confront")
	side_operations.call("interrogation_action", "confront")
	side_operations.call("interrogation_action", "confront")
	var unreliable: Dictionary = side_operations.call("interrogation_action", "seek_confession") as Dictionary
	_expect(not bool(unreliable.get("ok", false)) and int(side_operations.get("unreliable_statements")) == 1, "High-pressure low-credibility interview is rejected as unreliable")

	var scene: PackedScene = load("res://scenes/LivingPrecinct.tscn") as PackedScene
	_expect(scene != null, "Living precinct scene loads with side operations")
	if scene != null:
		var instance: Node = scene.instantiate()
		root.add_child(instance)
		for _frame: int in range(28):
			await process_frame
		_expect(instance.has_node("SideOperationsUI"), "Side operations controller is attached to the living station")
		var side_button: Button = instance.get_node_or_null("SideOperationsLayer/SideOperationsButton") as Button
		var side_panel: PanelContainer = instance.get_node_or_null("SideOperationsLayer/SideOperationsPanel") as PanelContainer
		_expect(side_button != null and side_panel != null, "Side Ops button and interactive puzzle panel are created at runtime")
		instance.queue_free()
		await process_frame

	if failures == 0:
		print("SUCCESS: Station side-operation puzzles passed.")
	else:
		push_error("FAILED: %d side-operation puzzle check(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
