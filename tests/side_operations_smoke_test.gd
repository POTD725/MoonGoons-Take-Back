extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	PrecinctState.reset_state()
	SideOperations.reset_state()
	PrecinctState.credits = 5000
	PrecinctState.evidence = 5

	var start_engine: Dictionary = SideOperations.start_operation("engine")
	_expect(bool(start_engine.get("ok", false)), "Engine repair operation starts")
	SideOperations.engine_action("isolate_power")
	var fault: String = String(SideOperations.active_operation.get("fault_part", "fuse"))
	SideOperations.engine_action("replace_%s" % fault)
	while int(SideOperations.active_operation.get("coolant", 0)) < 45:
		SideOperations.engine_action("coolant_up")
	while int(SideOperations.active_operation.get("coolant", 0)) > 55:
		SideOperations.engine_action("coolant_down")
	SideOperations.engine_action("lock_coolant")
	var engine_result: Dictionary = SideOperations.engine_action("restart")
	_expect(bool(engine_result.get("ok", false)) and SideOperations.engine_repairs == 1, "Engine puzzle completes through power, part, coolant, and restart stages")

	var start_weapon: Dictionary = SideOperations.start_operation("weapons")
	_expect(bool(start_weapon.get("ok", false)), "Weapons fitting operation starts")
	var sequence: Array = SideOperations.active_operation.get("sequence", []) as Array
	for part_value: Variant in sequence:
		SideOperations.weapon_action(String(part_value))
	var target: int = int(SideOperations.active_operation.get("target_alignment", 50))
	var guard: int = 0
	while absi(int(SideOperations.active_operation.get("alignment", 0)) - target) > 5 and guard < 30:
		if int(SideOperations.active_operation.get("alignment", 0)) < target:
			SideOperations.weapon_action("align_right")
		else:
			SideOperations.weapon_action("align_left")
		guard += 1
	var weapon_result: Dictionary = SideOperations.weapon_action("calibrate")
	_expect(bool(weapon_result.get("ok", false)) and SideOperations.weapon_upgrades == 1, "Weapon parts install in sequence and calibrate inside the target band")
	_expect(SideOperations.defense_bonus >= 8, "Successful weapons work increases station defense")

	var start_medical: Dictionary = SideOperations.start_operation("medical")
	_expect(bool(start_medical.get("ok", false)), "Medical side operation starts")
	var treatments: Array = SideOperations.active_operation.get("sequence", []) as Array
	var medical_result: Dictionary = {}
	for treatment_value: Variant in treatments:
		medical_result = SideOperations.medical_action(String(treatment_value))
	_expect(bool(medical_result.get("ok", false)) and SideOperations.medical_cases == 1, "Medical puzzle stabilizes the patient with the correct treatment order")

	var start_interrogation: Dictionary = SideOperations.start_operation("interrogation")
	_expect(bool(start_interrogation.get("ok", false)), "Interrogation side operation starts")
	SideOperations.active_operation["actual_guilt"] = 85
	SideOperations.interrogation_action("ask")
	SideOperations.interrogation_action("ask")
	SideOperations.interrogation_action("present_evidence")
	SideOperations.interrogation_action("present_evidence")
	SideOperations.interrogation_action("present_evidence")
	SideOperations.interrogation_action("verify_statement")
	var confession: Dictionary = SideOperations.interrogation_action("seek_confession")
	_expect(bool(confession.get("ok", false)) and SideOperations.confessions == 1, "Balanced guilt, cooperation, stress, and credibility meters produce a reliable confession")

	SideOperations.start_operation("interrogation")
	SideOperations.active_operation["actual_guilt"] = 90
	SideOperations.interrogation_action("confront")
	SideOperations.interrogation_action("confront")
	SideOperations.interrogation_action("confront")
	var unreliable: Dictionary = SideOperations.interrogation_action("seek_confession")
	_expect(not bool(unreliable.get("ok", false)) and SideOperations.unreliable_statements == 1, "High-pressure low-credibility interview is rejected as unreliable")

	var scene: PackedScene = load("res://scenes/LivingPrecinct.tscn") as PackedScene
	_expect(scene != null, "Living precinct scene loads with side operations")
	if scene != null:
		var instance: Node = scene.instantiate()
		root.add_child(instance)
		for _frame: int in range(24):
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
