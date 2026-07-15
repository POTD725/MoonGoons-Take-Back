extends "res://scripts/take_back_syndicate_layout.gd"
## Godot 4.3 compatibility layer for the Syndicate-style station GUI.
## Keeps icons at authored dimensions because Button.icon_max_width is unavailable.

const PATROL_SPACECRAFT: Texture2D = preload("res://assets/ui/patrol_spacecraft.svg")
const NAV_DATA_COMPAT: Array[Dictionary] = [
	{"id":"station", "title":"STATION", "subtitle":"DECK", "icon":"station_deck"},
	{"id":"missions", "title":"MISSIONS", "subtitle":"DUTY", "icon":"missions"},
	{"id":"operations", "title":"OPERATIONS", "subtitle":"SPACE", "icon":"resources"},
	{"id":"officers", "title":"OFFICERS", "subtitle":"ROSTER", "icon":"officers"},
	{"id":"command", "title":"COMMAND", "subtitle":"SYSTEMS", "icon":"equipment"}
]

func _build_navigation() -> void:
	var rects: Array[Rect2] = [
		Rect2(8.0, 1170.0, 134.0, 96.0), Rect2(150.0, 1170.0, 134.0, 96.0),
		Rect2(292.0, 1170.0, 134.0, 96.0), Rect2(434.0, 1170.0, 134.0, 96.0),
		Rect2(576.0, 1170.0, 136.0, 96.0)
	]
	for index: int in range(NAV_DATA_COMPAT.size()):
		var data: Dictionary = NAV_DATA_COMPAT[index]
		var id: String = String(data.get("id", "station"))
		var label: String = "%s\n%s" % [String(data.get("title", "STATION")), String(data.get("subtitle", "DECK"))]
		var button := _make_button("nav_%s" % id, rects[index], label, _nav_tooltip(id), String(data.get("icon", "station_deck")), _on_nav_pressed.bind(id))
		button.add_theme_font_size_override("font_size", 11)
		nav_buttons[id] = button

func _build_command_drawer() -> void:
	command_drawer = PanelContainer.new()
	command_drawer.name = "CommandSystemsDrawer"
	command_drawer.position = Vector2(354.0, 598.0)
	command_drawer.size = Vector2(348.0, 352.0)
	command_drawer.visible = false
	command_drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	command_drawer.add_theme_stylebox_override("panel", _panel_style(Color("07131f", 0.99), Color("67e7ff"), 12))
	add_child(command_drawer)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	command_drawer.add_child(column)
	command_title = Label.new()
	command_title.text = "COMMAND SYSTEMS"
	command_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	command_title.add_theme_font_size_override("font_size", 16)
	column.add_child(command_title)
	var systems: Array[Dictionary] = [
		{"id":"equipment", "label":"ROOM EQUIPMENT", "icon":"equipment"},
		{"id":"station", "label":"STATION DEFENSE", "icon":"shield"},
		{"id":"threats", "label":"SPACE THREATS", "icon":"threats"},
		{"id":"side_ops", "label":"SIDE OPERATIONS", "icon":"side_ops"},
		{"id":"research", "label":"ALLIANCE RESEARCH", "icon":"research"}
	]
	for data: Dictionary in systems:
		var button := Button.new()
		button.text = String(data.get("label", "SYSTEM"))
		button.custom_minimum_size = Vector2(320.0, 48.0)
		button.icon = GameIconRegistry.icon_for(String(data.get("icon", "equipment")), 30)
		button.expand_icon = false
		button.tooltip_text = _system_tooltip(String(data.get("id", "equipment")))
		button.add_theme_stylebox_override("normal", _button_style(false))
		button.add_theme_stylebox_override("hover", _button_style(true))
		button.pressed.connect(_open_system.bind(String(data.get("id", "equipment"))))
		column.add_child(button)
	var close := Button.new()
	close.text = "CLOSE COMMAND SYSTEMS"
	close.custom_minimum_size = Vector2(320.0, 40.0)
	close.icon = GameIconRegistry.icon_for("close", 26)
	close.expand_icon = false
	close.add_theme_stylebox_override("normal", _button_style(false))
	close.add_theme_stylebox_override("hover", _button_style(true))
	close.pressed.connect(func() -> void: command_drawer.visible = false)
	column.add_child(close)

func _make_button(id: String, rect: Rect2, label: String, tooltip: String, icon_key: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = id
	button.position = rect.position
	button.size = rect.size
	button.text = label
	button.tooltip_text = tooltip
	button.icon = PATROL_SPACECRAFT if _is_patrol_control(id, label, icon_key) else GameIconRegistry.icon_for(icon_key, 26)
	button.expand_icon = false
	button.add_theme_font_size_override("font_size", 8)
	button.add_theme_stylebox_override("normal", _button_style(false))
	button.add_theme_stylebox_override("hover", _button_style(true))
	button.add_theme_stylebox_override("pressed", _button_style(true))
	button.pressed.connect(callback)
	add_child(button)
	buttons[id] = button
	return button

func _is_patrol_control(id: String, label: String, icon_key: String) -> bool:
	var combined: String = "%s %s %s" % [id, label, icon_key]
	return combined.to_lower().contains("patrol")
