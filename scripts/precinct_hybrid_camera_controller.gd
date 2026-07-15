extends Node
## Makes the precinct a 2D/3D hybrid instead of a straight-down strategy map.
## Three-quarter city is the default. Cutaway and tactical views remain optional.

var precinct: Node
var bridge: Node
var layer: CanvasLayer
var mode_label: Label
var current_mode: String = "three_quarter"

const THREE_QUARTER := {
	"target": Vector3(2.5, 0.8, 0.6),
	"distance": 40.0,
	"yaw": 0.52,
	"pitch": -0.43
}
const CUTAWAY := {
	"distance": 25.0,
	"yaw": 0.28,
	"pitch": -0.34
}
const TACTICAL := {
	"target": Vector3(2.5, 0.0, 0.0),
	"distance": 46.0,
	"yaw": 0.0,
	"pitch": -1.05
}

func _ready() -> void:
	precinct = get_parent()
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(20):
		await get_tree().process_frame
	if precinct == null:
		return
	bridge = precinct.get_node_or_null("CameraInputBridge")
	_hide_old_camera_box()
	_build_view_controls()
	set_three_quarter_view()

func set_three_quarter_view() -> void:
	current_mode = "three_quarter"
	_apply_view(THREE_QUARTER)
	_set_exterior_visible(true)
	_set_ribbon_mode("city")
	_update_label("3/4 CITY")

func set_cutaway_view() -> void:
	current_mode = "cutaway"
	var target: Vector3 = Vector3.ZERO
	var selected_id: String = String(precinct.get("selected_room_id"))
	var rooms_value: Variant = precinct.get("room_nodes")
	if rooms_value is Dictionary:
		var room: Node3D = (rooms_value as Dictionary).get(selected_id) as Node3D
		if room != null:
			target = room.position + Vector3(0.0, 0.8, 0.0)
	precinct.set("camera_target", target)
	precinct.set("camera_distance", float(CUTAWAY.distance))
	precinct.set("camera_yaw", float(CUTAWAY.yaw))
	precinct.set("camera_pitch", float(CUTAWAY.pitch))
	_set_exterior_visible(false)
	_set_ribbon_mode("equipment")
	_update_label("ROOM CUTAWAY")

func set_tactical_view() -> void:
	current_mode = "tactical"
	_apply_view(TACTICAL)
	_set_exterior_visible(true)
	_set_ribbon_mode("city")
	_update_label("TACTICAL MAP")

func rotate_left() -> void:
	precinct.set("camera_yaw", float(precinct.get("camera_yaw")) - 0.18)
	_update_label(_mode_name())

func rotate_right() -> void:
	precinct.set("camera_yaw", float(precinct.get("camera_yaw")) + 0.18)
	_update_label(_mode_name())

func zoom_in() -> void:
	precinct.set("camera_distance", clampf(float(precinct.get("camera_distance")) - 3.0, 16.0, 58.0))

func zoom_out() -> void:
	precinct.set("camera_distance", clampf(float(precinct.get("camera_distance")) + 3.0, 16.0, 58.0))

func _apply_view(data: Dictionary) -> void:
	precinct.set("camera_target", data.get("target", Vector3.ZERO))
	precinct.set("camera_distance", float(data.get("distance", 40.0)))
	precinct.set("camera_yaw", float(data.get("yaw", 0.52)))
	precinct.set("camera_pitch", float(data.get("pitch", -0.43)))

func _set_exterior_visible(show: bool) -> void:
	var exterior_controller: Node = precinct.get_node_or_null("ExteriorCityVisuals")
	if exterior_controller == null:
		return
	var exterior_value: Variant = exterior_controller.get("exterior_root")
	if exterior_value is Node3D:
		(exterior_value as Node3D).visible = show

func _set_ribbon_mode(mode: String) -> void:
	var ribbon: Node = precinct.get_node_or_null("CompactCommandRibbon")
	if ribbon != null and ribbon.has_method("_activate"):
		ribbon.call("_activate", mode)

func _hide_old_camera_box() -> void:
	if bridge == null:
		return
	var controls_value: Variant = bridge.get("controls_layer")
	if controls_value is CanvasLayer:
		(controls_value as CanvasLayer).visible = false

func _build_view_controls() -> void:
	layer = CanvasLayer.new()
	layer.name = "HybridViewControlsLayer"
	layer.layer = 74
	precinct.add_child(layer)
	var panel := PanelContainer.new()
	panel.name = "HybridViewControls"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -452.0
	panel.offset_top = 148.0
	panel.offset_right = -14.0
	panel.offset_bottom = 190.0
	panel.add_theme_stylebox_override("panel", _panel_style())
	layer.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	panel.add_child(row)
	row.add_child(_button("3/4 CITY", set_three_quarter_view, "Default 2D/3D city angle"))
	row.add_child(_button("CUTAWAY", set_cutaway_view, "Open the selected room interior"))
	row.add_child(_button("MAP", set_tactical_view, "Optional overhead tactical view"))
	row.add_child(_button("TURN L", rotate_left, "Rotate city left"))
	row.add_child(_button("TURN R", rotate_right, "Rotate city right"))
	row.add_child(_button("ZOOM +", zoom_in, "Move camera closer"))
	row.add_child(_button("ZOOM -", zoom_out, "Move camera farther away"))
	mode_label = Label.new()
	mode_label.custom_minimum_size = Vector2(88.0, 30.0)
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mode_label.add_theme_font_size_override("font_size", 9)
	row.add_child(mode_label)

func _button(text_value: String, callback: Callable, tooltip: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(52.0, 30.0)
	button.add_theme_font_size_override("font_size", 9)
	button.pressed.connect(callback)
	return button

func _update_label(value: String) -> void:
	if mode_label != null:
		mode_label.text = value

func _mode_name() -> String:
	match current_mode:
		"cutaway": return "ROOM CUTAWAY"
		"tactical": return "TACTICAL MAP"
	return "3/4 CITY"

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("07131D", 0.96)
	style.border_color = Color("47758A")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 5.0
	style.content_margin_right = 5.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style
