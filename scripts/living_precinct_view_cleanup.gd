extends Node
## Keeps the living precinct visible and interactive.
## Removes wall-sized schematic billboards, repairs 3D labels, and makes room details collapsible.

var precinct: Node
var toggle_button: Button
var city_panel: Control
var refresh_clock: float = 0.0

func _ready() -> void:
	precinct = get_parent()
	call_deferred("_apply_cleanup")

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock < 0.45:
		return
	refresh_clock = 0.0
	_cleanup_room_visuals()
	_update_toggle_text()

func _apply_cleanup() -> void:
	for _frame in range(5):
		await get_tree().process_frame
	if precinct == null:
		return
	var panel_value: Variant = precinct.get("city_panel")
	if panel_value is Control:
		city_panel = panel_value as Control
		city_panel.position = Vector2(14.0, 112.0)
		city_panel.size = Vector2(306.0, 500.0)
	_remove_generic_inspector_art()
	_cleanup_room_visuals()
	_build_toggle()
	# Open on the city itself. Details appear after selecting a room or pressing the toggle.
	if city_panel != null:
		city_panel.visible = false
	precinct.set("camera_target", Vector3.ZERO)
	precinct.set("camera_distance", 38.0)
	var camera_value: Variant = precinct.get("camera")
	if camera_value is Camera3D:
		(camera_value as Camera3D).fov = 48.0
	_update_toggle_text()

func _cleanup_room_visuals() -> void:
	if precinct == null:
		return
	var rooms_value: Variant = precinct.get("rooms_root")
	if not rooms_value is Node3D:
		return
	var rooms_root := rooms_value as Node3D
	for room_child: Node in rooms_root.get_children():
		if not room_child is Node3D:
			continue
		var room := room_child as Node3D
		for billboard_name: String in ["RoomArt", "EstablishedMoonGoonsArt"]:
			var billboard: Node = room.get_node_or_null(billboard_name)
			if billboard != null:
				billboard.queue_free()
		var label: Label3D = room.get_node_or_null("RoomLabel") as Label3D
		if label != null:
			label.fixed_size = false
			label.pixel_size = 0.006
			label.font_size = 42
			label.outline_size = 8
			label.no_depth_test = false
			label.position.y = 3.42

func _remove_generic_inspector_art() -> void:
	var interface: CanvasLayer = precinct.get_node_or_null("Interface") as CanvasLayer
	if interface == null or interface.get_child_count() == 0:
		return
	var root: Node = interface.get_child(0)
	var preview: Node = _find_named(root, "SelectedRoomArtwork")
	if preview != null:
		preview.queue_free()
	var caption: Label = _find_label(root, "ILLUSTRATED INTERIOR")
	if caption != null:
		caption.queue_free()
	var art_status: Label = _find_label(root, "ROOM ART")
	if art_status != null:
		art_status.text = "  MODELED ROOMS 8/8   •   LIVE PERSONNEL ACTIVE"
		art_status.modulate = Color("7ef5d0")
	var info_value: Variant = precinct.get("room_info")
	if info_value is Label:
		var info := info_value as Label
		info.custom_minimum_size = Vector2(278.0, 205.0)
		info.add_theme_font_size_override("font_size", 11)

func _build_toggle() -> void:
	if toggle_button != null:
		return
	var layer := CanvasLayer.new()
	layer.name = "RoomInspectorControls"
	layer.layer = 45
	add_child(layer)
	toggle_button = Button.new()
	toggle_button.name = "RoomDetailsToggle"
	toggle_button.position = Vector2(18.0, 108.0)
	toggle_button.size = Vector2(154.0, 34.0)
	toggle_button.tooltip_text = "Show or hide the selected room controls without covering the precinct."
	toggle_button.pressed.connect(_toggle_room_details)
	layer.add_child(toggle_button)

func _toggle_room_details() -> void:
	if city_panel == null:
		return
	if city_panel.visible:
		city_panel.visible = false
	else:
		precinct.call("_show_tab", "city")
		city_panel.visible = true
	MoonGoonsAudio.play("click")
	_update_toggle_text()

func _update_toggle_text() -> void:
	if toggle_button == null:
		return
	toggle_button.text = "HIDE DETAILS" if city_panel != null and city_panel.visible else "ROOM DETAILS"

func _find_named(root: Node, wanted_name: String) -> Node:
	if root.name == wanted_name:
		return root
	for child: Node in root.get_children():
		var found: Node = _find_named(child, wanted_name)
		if found != null:
			return found
	return null

func _find_label(root: Node, needle: String) -> Label:
	if root is Label and (root as Label).text.contains(needle):
		return root as Label
	for child: Node in root.get_children():
		var found: Label = _find_label(child, needle)
		if found != null:
			return found
	return null
