extends Node
## Persistent command ribbon. Every command is a compact word button and every
## workspace opens as a side tray, never as a full-screen dropdown.

var precinct: Node
var layer: CanvasLayer
var ribbon: HBoxContainer
var hint: Label
var buttons: Dictionary = {}
var active_command: String = "city"
var refresh_clock: float = 0.0

const COMMANDS: Array[Dictionary] = [
	{"id":"city", "label":"CITY", "hint":"Station overview"},
	{"id":"missions", "label":"MISSIONS", "hint":"Chapter and daily objectives"},
	{"id":"dispatch", "label":"DISPATCH", "hint":"Select call, select officers, deploy"},
	{"id":"officers", "label":"OFFICERS", "hint":"Train, heal, and post personnel"},
	{"id":"equipment", "label":"EQUIPMENT", "hint":"Room items, levels, styles, and upgrades"},
	{"id":"station", "label":"STATION", "hint":"Construction and station defenses"},
	{"id":"resources", "label":"RESOURCES", "hint":"Moonsteel, Helium-3, and salvage"},
	{"id":"threats", "label":"THREATS", "hint":"Syndicate fleets and marauders"},
	{"id":"side_ops", "label":"SIDE OPS", "hint":"Repair, medical, weapons, interrogation"},
	{"id":"research", "label":"RESEARCH", "hint":"Alliance research tree"}
]

func _ready() -> void:
	precinct = get_parent()
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(22):
		await get_tree().process_frame
	if precinct == null:
		return
	_hide_legacy_buttons()
	_build_ribbon()
	_activate("city")

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock < 0.35:
		return
	refresh_clock = 0.0
	_reposition_active_tray()

func _build_ribbon() -> void:
	layer = CanvasLayer.new()
	layer.name = "CompactCommandRibbonLayer"
	layer.layer = 72
	precinct.add_child(layer)
	var shell := PanelContainer.new()
	shell.name = "CompactCommandRibbon"
	shell.set_anchors_preset(Control.PRESET_TOP_WIDE)
	shell.offset_left = 12.0
	shell.offset_top = 96.0
	shell.offset_right = -12.0
	shell.offset_bottom = 142.0
	shell.add_theme_stylebox_override("panel", _panel_style())
	layer.add_child(shell)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	shell.add_child(row)
	ribbon = HBoxContainer.new()
	ribbon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ribbon.add_theme_constant_override("separation", 4)
	row.add_child(ribbon)
	for command: Dictionary in COMMANDS:
		var id: String = String(command.get("id", "city"))
		var button := Button.new()
		button.name = "Command_%s" % id
		button.text = String(command.get("label", id.to_upper()))
		button.tooltip_text = String(command.get("hint", ""))
		button.custom_minimum_size = Vector2(78.0, 34.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(_activate.bind(id))
		button.add_theme_stylebox_override("normal", _button_style(Color("091722"), Color("36586B")))
		button.add_theme_stylebox_override("hover", _button_style(Color("102B3A"), Color("6CEBFF")))
		button.add_theme_stylebox_override("pressed", _button_style(Color("174052"), Color("8EF5FF")))
		ribbon.add_child(button)
		buttons[id] = button
	hint = Label.new()
	hint.custom_minimum_size = Vector2(205.0, 34.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	row.add_child(hint)

func _activate(command_id: String) -> void:
	active_command = command_id
	_close_all_trays()
	match command_id:
		"city":
			precinct.call("_show_tab", "city")
			_set_core_panel_visible("city_panel", false)
		"missions":
			precinct.call("_show_tab", "tasks")
			_set_core_panel_visible("tasks_panel", true)
		"dispatch":
			precinct.call("_show_tab", "patrol")
			_set_core_panel_visible("patrol_panel", true)
		"officers":
			precinct.call("_show_tab", "officers")
			_set_core_panel_visible("officer_panel", true)
		"equipment":
			precinct.call("_show_tab", "city")
			_set_external_panel("PrecinctProgressionUI", "equipment_panel", true)
		"station":
			_set_external_panel("StationCommandUI", "panel", true)
		"resources":
			_set_external_panel("ResourceHarvestController", "panel", true)
		"threats":
			_set_external_panel("SpaceThreatOperations", "panel", true)
		"side_ops":
			_set_external_panel("SideOperationsUI", "panel", true)
		"research":
			var research_overlay: Node = get_node_or_null("/root/AllianceResearchOverlay")
			if research_overlay != null:
				var panel_value: Variant = research_overlay.get("panel")
				if panel_value is Control:
					(panel_value as Control).visible = true
	_update_button_states()
	_reposition_active_tray()
	MoonGoonsAudio.play("click")

func _close_all_trays() -> void:
	for property_name: String in ["city_panel", "officer_panel", "patrol_panel", "custody_panel", "tasks_panel"]:
		_set_core_panel_visible(property_name, false)
	_set_external_panel("PrecinctProgressionUI", "equipment_panel", false)
	_set_external_panel("StationCommandUI", "panel", false)
	_set_external_panel("ResourceHarvestController", "panel", false)
	_set_external_panel("SpaceThreatOperations", "panel", false)
	_set_external_panel("SideOperationsUI", "panel", false)
	var research_overlay: Node = get_node_or_null("/root/AllianceResearchOverlay")
	if research_overlay != null:
		var panel_value: Variant = research_overlay.get("panel")
		if panel_value is Control:
			(panel_value as Control).visible = false

func _set_core_panel_visible(property_name: String, show: bool) -> void:
	var value: Variant = precinct.get(property_name)
	if value is Control:
		(value as Control).visible = show

func _set_external_panel(node_name: String, property_name: String, show: bool) -> void:
	var controller: Node = precinct.get_node_or_null(node_name)
	if controller == null:
		return
	var value: Variant = controller.get(property_name)
	if value is Control:
		(value as Control).visible = show

func _reposition_active_tray() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var tray_width: float = clampf(viewport_size.x * 0.29, 330.0, 430.0)
	var tray_height: float = maxf(420.0, viewport_size.y - 218.0)
	var tray_position := Vector2(viewport_size.x - tray_width - 16.0, 150.0)
	var tray: Control = _active_tray()
	if tray == null:
		return
	tray.position = tray_position
	tray.size = Vector2(tray_width, tray_height)
	tray.move_to_front()
	# Research was authored as a wide browser. Force it into the same side-tray footprint.
	if active_command == "research":
		tray.custom_minimum_size = Vector2.ZERO

func _active_tray() -> Control:
	match active_command:
		"missions": return precinct.get("tasks_panel") as Control
		"dispatch": return precinct.get("patrol_panel") as Control
		"officers": return precinct.get("officer_panel") as Control
		"equipment": return _external_control("PrecinctProgressionUI", "equipment_panel")
		"station": return _external_control("StationCommandUI", "panel")
		"resources": return _external_control("ResourceHarvestController", "panel")
		"threats": return _external_control("SpaceThreatOperations", "panel")
		"side_ops": return _external_control("SideOperationsUI", "panel")
		"research":
			var overlay: Node = get_node_or_null("/root/AllianceResearchOverlay")
			if overlay != null:
				return overlay.get("panel") as Control
	return null

func _external_control(node_name: String, property_name: String) -> Control:
	var controller: Node = precinct.get_node_or_null(node_name)
	if controller == null:
		return null
	return controller.get(property_name) as Control

func _hide_legacy_buttons() -> void:
	var interface: CanvasLayer = precinct.get_node_or_null("Interface") as CanvasLayer
	if interface != null:
		for button: Button in _find_buttons(interface):
			if button.text in ["CITY", "OFFICERS", "PATROL", "CUSTODY", "TASKS", "MISSIONS", "CAMPAIGN ROUTER", "RTS FRONT"]:
				button.visible = false
	for controller_name: String in ["PrecinctProgressionUI", "StationCommandUI", "ResourceHarvestController", "SpaceThreatOperations", "SideOperationsUI"]:
		var controller: Node = precinct.get_node_or_null(controller_name)
		if controller == null:
			continue
		for property_name: String in ["equipment_toggle", "open_button", "toggle"]:
			var value: Variant = controller.get(property_name)
			if value is Control:
				(value as Control).visible = false
	var cleanup: Node = precinct.get_node_or_null("UnobstructedViewCleanup")
	if cleanup != null:
		var toggle_value: Variant = cleanup.get("toggle_button")
		if toggle_value is Control:
			(toggle_value as Control).visible = false

func _update_button_states() -> void:
	for key_value: Variant in buttons.keys():
		var id: String = String(key_value)
		var button: Button = buttons[id] as Button
		button.disabled = id == active_command
	for command: Dictionary in COMMANDS:
		if String(command.get("id", "")) == active_command and hint != null:
			hint.text = String(command.get("hint", ""))

func _find_buttons(root: Node) -> Array[Button]:
	var result: Array[Button] = []
	if root is Button:
		result.append(root as Button)
	for child: Node in root.get_children():
		result.append_array(_find_buttons(child))
	return result

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("07131D", 0.96)
	style.border_color = Color("47758A")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style
