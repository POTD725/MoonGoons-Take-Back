extends Node
## Consolidates runtime-created HUD controls after every precinct subsystem has loaded.
## Uses plain ASCII camera labels so browser exports do not display missing-glyph boxes.

var precinct: Node
var applied: bool = false

func _ready() -> void:
	precinct = get_parent()
	call_deferred("_apply_when_ready")

func _apply_when_ready() -> void:
	for _frame: int in range(24):
		await get_tree().process_frame
	_apply_layout()

func _process(_delta: float) -> void:
	if not applied:
		return
	# Reapply only when the viewport changes enough to require responsive placement.
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x < 900.0:
		_apply_compact_layout(viewport_size)

func _apply_layout() -> void:
	if precinct == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var top_y: float = 96.0
	var specs: Array[Dictionary] = [
		{"name":"EquipmentToggle", "x":180.0, "width":176.0, "text":"ROOM EQUIPMENT"},
		{"name":"ResourceMapButton", "x":364.0, "width":160.0, "text":"RESOURCE MAP"},
		{"name":"SpaceThreatButton", "x":532.0, "width":160.0, "text":"SPACE THREATS"},
		{"name":"StationCommandButton", "x":700.0, "width":184.0, "text":"STATION COMMAND"},
		{"name":"SideOperationsButton", "x":892.0, "width":130.0, "text":"SIDE OPS"}
	]
	for spec: Dictionary in specs:
		var button: Button = _find_named(precinct, String(spec.get("name", ""))) as Button
		if button == null:
			continue
		button.position = Vector2(float(spec.get("x", 0.0)), top_y)
		button.size = Vector2(float(spec.get("width", 150.0)), 38.0)
		button.text = String(spec.get("text", button.text))
		button.add_theme_font_size_override("font_size", 13)

	var details: Button = _find_named(precinct, "RoomDetailsToggle") as Button
	if details != null:
		details.position = Vector2(18.0, top_y)
		details.size = Vector2(154.0, 38.0)
		details.add_theme_font_size_override("font_size", 13)

	var camera_panel: PanelContainer = _find_named(precinct, "CameraControls") as PanelContainer
	if camera_panel != null:
		camera_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		camera_panel.offset_left = -184.0
		camera_panel.offset_top = 142.0
		camera_panel.offset_right = -14.0
		camera_panel.offset_bottom = 370.0
		_replace_camera_glyphs(camera_panel)

	if viewport_size.x < 1100.0:
		_apply_compact_layout(viewport_size)
	applied = true

func _apply_compact_layout(viewport_size: Vector2) -> void:
	var buttons: Array[Button] = []
	for node_name: String in ["RoomDetailsToggle", "EquipmentToggle", "ResourceMapButton", "SpaceThreatButton", "StationCommandButton", "SideOperationsButton"]:
		var button: Button = _find_named(precinct, node_name) as Button
		if button != null:
			buttons.append(button)
	if buttons.is_empty():
		return
	var margin: float = 12.0
	var gap: float = 6.0
	var available: float = maxf(600.0, viewport_size.x - margin * 2.0)
	var width: float = maxf(94.0, (available - gap * float(buttons.size() - 1)) / float(buttons.size()))
	for index: int in range(buttons.size()):
		var button: Button = buttons[index]
		button.position = Vector2(margin + float(index) * (width + gap), 96.0)
		button.size = Vector2(width, 38.0)
		button.add_theme_font_size_override("font_size", 10)

func _replace_camera_glyphs(camera_panel: Node) -> void:
	for child: Node in camera_panel.find_children("*", "Button", true, false):
		var button := child as Button
		match button.tooltip_text:
			"Rotate left": button.text = "CCW"
			"Reset camera": button.text = "HOME"
			"Rotate right": button.text = "CW"
			"Pan forward": button.text = "UP"
			"Pan left": button.text = "LEFT"
			"Center city": button.text = "CENTER"
			"Pan right": button.text = "RIGHT"
			"Pan backward": button.text = "DOWN"
			"Zoom out": button.text = "-"
			"Zoom in": button.text = "+"
		button.add_theme_font_size_override("font_size", 10)
		button.custom_minimum_size = Vector2(48.0, 32.0)

func _find_named(root: Node, wanted_name: String) -> Node:
	if root.name == wanted_name:
		return root
	for child: Node in root.get_children():
		var found: Node = _find_named(child, wanted_name)
		if found != null:
			return found
	return null
