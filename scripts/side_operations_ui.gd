extends Node
## Interactive side-operation panel for engine repair, weapons fitting,
## medical triage, and evidence-driven interrogation.

var precinct: Node3D
var layer: CanvasLayer
var open_button: Button
var panel: PanelContainer
var title_label: Label
var briefing_label: Label
var status_label: Label
var timer_label: Label
var meter_column: VBoxContainer
var action_grid: GridContainer
var refresh_clock: float = 0.0
var meter_bars: Dictionary = {}

func _ready() -> void:
	precinct = get_parent() as Node3D
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(14):
		await get_tree().process_frame
	if precinct == null:
		return
	_build_interface()
	if not SideOperations.operation_changed.is_connected(_refresh):
		SideOperations.operation_changed.connect(_refresh)
	_refresh()

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock < 0.25:
		return
	refresh_clock = 0.0
	if panel != null and panel.visible:
		_refresh_meters()

func _build_interface() -> void:
	layer = CanvasLayer.new()
	layer.name = "SideOperationsLayer"
	layer.layer = 28
	precinct.add_child(layer)
	open_button = Button.new()
	open_button.name = "SideOperationsButton"
	open_button.text = "SIDE OPS"
	open_button.position = Vector2(1030.0, 84.0)
	open_button.size = Vector2(130.0, 38.0)
	open_button.pressed.connect(_toggle_panel)
	layer.add_child(open_button)
	panel = PanelContainer.new()
	panel.name = "SideOperationsPanel"
	panel.position = Vector2(610.0, 92.0)
	panel.size = Vector2(640.0, 540.0)
	panel.visible = false
	layer.add_child(panel)
	var main_column := VBoxContainer.new()
	main_column.add_theme_constant_override("separation", 8)
	panel.add_child(main_column)
	var header_row := HBoxContainer.new()
	main_column.add_child(header_row)
	title_label = Label.new()
	title_label.text = "STATION SIDE OPERATIONS"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 19)
	header_row.add_child(title_label)
	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.pressed.connect(_toggle_panel)
	header_row.add_child(close_button)
	var launch_row := HBoxContainer.new()
	launch_row.alignment = BoxContainer.ALIGNMENT_CENTER
	main_column.add_child(launch_row)
	for operation_data: Dictionary in [
		{"id":"engine", "label":"ENGINE REPAIR"},
		{"id":"weapons", "label":"WEAPONS FITTING"},
		{"id":"medical", "label":"MEDICAL OPS"},
		{"id":"interrogation", "label":"INTERROGATION"}
	]:
		var launch_button := Button.new()
		launch_button.text = String(operation_data.get("label", "OPERATION"))
		launch_button.custom_minimum_size = Vector2(145.0, 38.0)
		launch_button.pressed.connect(_start_operation.bind(String(operation_data.get("id", ""))))
		launch_row.add_child(launch_button)
	briefing_label = Label.new()
	briefing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	briefing_label.custom_minimum_size = Vector2(600.0, 58.0)
	main_column.add_child(briefing_label)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size = Vector2(600.0, 48.0)
	main_column.add_child(status_label)
	timer_label = Label.new()
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	main_column.add_child(timer_label)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_column.add_child(body)
	meter_column = VBoxContainer.new()
	meter_column.custom_minimum_size = Vector2(235.0, 300.0)
	meter_column.add_theme_constant_override("separation", 8)
	body.add_child(meter_column)
	action_grid = GridContainer.new()
	action_grid.columns = 2
	action_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_grid.add_theme_constant_override("h_separation", 8)
	action_grid.add_theme_constant_override("v_separation", 8)
	body.add_child(action_grid)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	main_column.add_child(footer)
	var abandon := Button.new()
	abandon.text = "ABANDON OPERATION"
	abandon.pressed.connect(_abandon_operation)
	footer.add_child(abandon)

func _toggle_panel() -> void:
	panel.visible = not panel.visible
	MoonGoonsAudio.play("click")
	if panel.visible:
		_refresh()

func _start_operation(operation_id: String) -> void:
	var result: Dictionary = SideOperations.start_operation(operation_id)
	MoonGoonsAudio.play("confirm" if bool(result.get("ok", false)) else "error")
	_refresh()

func _abandon_operation() -> void:
	var result: Dictionary = SideOperations.abandon_operation()
	MoonGoonsAudio.play("click" if bool(result.get("ok", false)) else "error")
	_refresh()

func _refresh() -> void:
	if panel == null:
		return
	var operation: Dictionary = SideOperations.active_operation
	_clear_children(meter_column)
	_clear_children(action_grid)
	meter_bars.clear()
	if operation.is_empty():
		title_label.text = "STATION SIDE OPERATIONS"
		briefing_label.text = "Select an operation. Successful work earns resources, evidence, equipment progress, and station-defense bonuses."
		status_label.text = "No side operation is active."
		timer_label.text = ""
		return
	var operation_type: String = String(operation.get("type", "operation"))
	title_label.text = operation_type.replace("_", " ").to_upper()
	briefing_label.text = String(operation.get("briefing", "Operation active."))
	status_label.text = String(operation.get("message", "Awaiting input."))
	if bool(operation.get("finished", false)):
		timer_label.text = "COMPLETE" if bool(operation.get("success", false)) else "FAILED"
	else:
		var seconds: int = SideOperations.operation_time_left()
		timer_label.text = "TIME %02d:%02d" % [seconds / 60, seconds % 60] if seconds > 0 else "UNTIMED OPERATION"
	match operation_type:
		"engine": _build_engine_controls(operation)
		"weapons": _build_weapon_controls(operation)
		"medical": _build_medical_controls(operation)
		"interrogation": _build_interrogation_controls(operation)
	_refresh_meters()

func _build_engine_controls(operation: Dictionary) -> void:
	_add_meter("integrity", "ENGINE INTEGRITY", int(operation.get("integrity", 100)), 100)
	_add_meter("coolant", "COOLANT FLOW", int(operation.get("coolant", 50)), 100)
	_add_meter("stage", "REPAIR SEQUENCE", int(operation.get("stage", 0)), 4)
	_add_action("ISOLATE POWER", SideOperations.engine_action.bind("isolate_power"))
	_add_action("REPLACE COUPLER", SideOperations.engine_action.bind("replace_coupler"))
	_add_action("REPLACE PUMP", SideOperations.engine_action.bind("replace_pump"))
	_add_action("REPLACE FUSE", SideOperations.engine_action.bind("replace_fuse"))
	_add_action("COOLANT -", SideOperations.engine_action.bind("coolant_down"))
	_add_action("COOLANT +", SideOperations.engine_action.bind("coolant_up"))
	_add_action("LOCK COOLANT", SideOperations.engine_action.bind("lock_coolant"))
	_add_action("RESTART ENGINE", SideOperations.engine_action.bind("restart"))

func _build_weapon_controls(operation: Dictionary) -> void:
	_add_meter("stability", "WEAPON STABILITY", int(operation.get("stability", 100)), 100)
	_add_meter("alignment", "EMITTER ALIGNMENT", int(operation.get("alignment", 50)), 100)
	var installed: Array = operation.get("installed", []) as Array
	var sequence: Array = operation.get("sequence", []) as Array
	_add_meter("parts", "PARTS INSTALLED", installed.size(), maxi(1, sequence.size()))
	_add_text("DIAGNOSTIC ORDER\n%s" % " → ".join(sequence.map(func(value: Variant) -> String: return String(value).replace("_", " ").capitalize())))
	for part_id: String in ["capacitor", "cooling_jacket", "targeting_chip", "ammo_feed"]:
		_add_action(part_id.replace("_", " ").to_upper(), SideOperations.weapon_action.bind(part_id))
	_add_action("ALIGN LEFT", SideOperations.weapon_action.bind("align_left"))
	_add_action("ALIGN RIGHT", SideOperations.weapon_action.bind("align_right"))
	_add_action("CALIBRATE", SideOperations.weapon_action.bind("calibrate"))

func _build_medical_controls(operation: Dictionary) -> void:
	_add_meter("vitals", "PATIENT VITALS", int(operation.get("vitals", 68)), 100)
	var completed: Array = operation.get("completed", []) as Array
	var sequence: Array = operation.get("sequence", []) as Array
	_add_meter("treatment", "TREATMENT PROGRESS", completed.size(), maxi(1, sequence.size()))
	for treatment: String in ["oxygen", "seal_wound", "pressure_stabilizer", "decon", "anti_rad", "fluids", "tourniquet", "medgel", "transfusion"]:
		_add_action(treatment.replace("_", " ").to_upper(), SideOperations.medical_action.bind(treatment))

func _build_interrogation_controls(operation: Dictionary) -> void:
	_add_meter("guilt", "GUILT ASSESSMENT", int(operation.get("guilt", 12)), 100)
	_add_meter("stress", "STRESS", int(operation.get("stress", 18)), 100)
	_add_meter("cooperation", "COOPERATION", int(operation.get("cooperation", 35)), 100)
	_add_meter("credibility", "CREDIBILITY", int(operation.get("credibility", 50)), 100)
	_add_action("CONTROLLED QUESTION", SideOperations.interrogation_action.bind("ask"))
	_add_action("PRESENT EVIDENCE", SideOperations.interrogation_action.bind("present_evidence"))
	_add_action("REASSURE", SideOperations.interrogation_action.bind("reassure"))
	_add_action("CONFRONT", SideOperations.interrogation_action.bind("confront"))
	_add_action("VERIFY STATEMENT", SideOperations.interrogation_action.bind("verify_statement"))
	_add_action("SEEK CONFESSION", SideOperations.interrogation_action.bind("seek_confession"))

func _add_meter(key: String, label_text: String, value: int, maximum: int) -> void:
	var label := Label.new()
	label.text = "%s  %d / %d" % [label_text, value, maximum]
	meter_column.add_child(label)
	var bar := ProgressBar.new()
	bar.name = "Meter_%s" % key
	bar.max_value = maximum
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(220.0, 22.0)
	meter_column.add_child(bar)
	meter_bars[key] = {"bar":bar, "label":label, "title":label_text, "max":maximum}

func _add_text(text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meter_column.add_child(label)

func _add_action(label_text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(170.0, 42.0)
	button.disabled = bool(SideOperations.active_operation.get("finished", false))
	button.pressed.connect(_perform_action.bind(callback))
	action_grid.add_child(button)

func _perform_action(callback: Callable) -> void:
	var result: Variant = callback.call()
	if result is Dictionary:
		MoonGoonsAudio.play("confirm" if bool((result as Dictionary).get("ok", false)) else "error")
	_refresh()

func _refresh_meters() -> void:
	if SideOperations.active_operation.is_empty():
		return
	var operation: Dictionary = SideOperations.active_operation
	var values: Dictionary = {
		"integrity":int(operation.get("integrity", 0)),
		"coolant":int(operation.get("coolant", 0)),
		"stage":int(operation.get("stage", 0)),
		"stability":int(operation.get("stability", 0)),
		"alignment":int(operation.get("alignment", 0)),
		"parts":(operation.get("installed", []) as Array).size(),
		"vitals":int(operation.get("vitals", 0)),
		"treatment":(operation.get("completed", []) as Array).size(),
		"guilt":int(operation.get("guilt", 0)),
		"stress":int(operation.get("stress", 0)),
		"cooperation":int(operation.get("cooperation", 0)),
		"credibility":int(operation.get("credibility", 0))
	}
	for key_value: Variant in meter_bars.keys():
		var key: String = String(key_value)
		var meter: Dictionary = meter_bars[key]
		var bar: ProgressBar = meter.get("bar") as ProgressBar
		var label: Label = meter.get("label") as Label
		var maximum: int = int(meter.get("max", 100))
		var value: int = int(values.get(key, 0))
		if bar != null:
			bar.value = value
		if label != null:
			label.text = "%s  %d / %d" % [String(meter.get("title", key.to_upper())), value, maximum]
	var seconds: int = SideOperations.operation_time_left()
	if seconds > 0 and not bool(operation.get("finished", false)):
		timer_label.text = "TIME %02d:%02d" % [seconds / 60, seconds % 60]
	if seconds <= 0 and int(operation.get("deadline", 0)) > 0 and not bool(operation.get("finished", false)):
		status_label.text = "Time expired. Choose an action to resolve the operation."

func _clear_children(node: Node) -> void:
	for child: Node in node.get_children():
		child.queue_free()
