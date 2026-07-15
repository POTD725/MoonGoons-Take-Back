extends Node
## Runtime layout and art presentation pass for the living precinct.
## Keeps the gameplay controller focused while repairing the responsive HUD.

const ROOM_PREVIEWS: Dictionary = {
	"ops": preload("res://assets/precinct/rooms/ops_center.svg"),
	"armory": preload("res://assets/precinct/rooms/armory.svg"),
	"cells": preload("res://assets/precinct/rooms/holding_cells.svg"),
	"quarters": preload("res://assets/precinct/rooms/crew_quarters.svg"),
	"medbay": preload("res://assets/precinct/rooms/medbay.svg"),
	"chief": preload("res://assets/precinct/rooms/chief_office.svg"),
	"interrogation": preload("res://assets/precinct/rooms/interrogation.svg"),
	"transfer": preload("res://assets/precinct/rooms/transfer_hall.svg")
}

var precinct: Node
var room_preview: TextureRect
var preview_caption: Label
var last_room_id: String = ""
var refresh_clock: float = 0.0

func _ready() -> void:
	precinct = get_parent()
	call_deferred("_apply_polish")

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock < 0.20:
		return
	refresh_clock = 0.0
	_refresh_preview()

func _apply_polish() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if precinct == null:
		return
	_polish_header()
	_polish_side_panels()
	_add_selected_room_preview()
	_correct_back_row_art_orientation()
	precinct.set("camera_target", Vector3(3.2, 0.0, 0.0))
	precinct.set("camera_distance", 31.5)
	var camera_value: Variant = precinct.get("camera")
	if camera_value is Camera3D:
		(camera_value as Camera3D).fov = 44.0
	_refresh_preview(true)

func _polish_header() -> void:
	var interface: CanvasLayer = precinct.get_node_or_null("Interface") as CanvasLayer
	if interface == null or interface.get_child_count() <= 0:
		return
	var root: Control = interface.get_child(0) as Control
	if root == null:
		return
	var title: Label = _find_label(root, "LIVING LUNAR PRECINCT")
	var resource: Label = precinct.get("resource_label") as Label
	var help: Label = _find_label(root, "RMB drag")
	if title == null or resource == null or help == null:
		return
	var top: PanelContainer = title.get_parent().get_parent() as PanelContainer
	var old_row: HBoxContainer = title.get_parent() as HBoxContainer
	if top == null or old_row == null:
		return
	old_row.remove_child(title)
	old_row.remove_child(resource)
	old_row.remove_child(help)
	top.remove_child(old_row)
	old_row.queue_free()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	top.add_child(column)
	var headline := HBoxContainer.new()
	headline.add_theme_constant_override("separation", 12)
	column.add_child(headline)
	title.text = "  MOONGOONS TAKE BACK // LIVING LUNAR PRECINCT"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	headline.add_child(title)
	help.text = "RMB rotate  •  wheel zoom  •  WASD pan   "
	help.add_theme_font_size_override("font_size", 11)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	headline.add_child(help)
	var telemetry := HBoxContainer.new()
	telemetry.add_theme_constant_override("separation", 10)
	column.add_child(telemetry)
	var art_status := Label.new()
	art_status.text = "  ROOM ART 8/8   •   %s" % MoonGoonsSkins.status_text()
	art_status.add_theme_font_size_override("font_size", 11)
	art_status.modulate = Color("7ef5d0")
	art_status.custom_minimum_size = Vector2(300.0, 0.0)
	telemetry.add_child(art_status)
	resource.custom_minimum_size = Vector2.ZERO
	resource.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	resource.add_theme_font_size_override("font_size", 12)
	telemetry.add_child(resource)
	top.offset_bottom = 92.0

func _polish_side_panels() -> void:
	var interface: CanvasLayer = precinct.get_node_or_null("Interface") as CanvasLayer
	if interface == null or interface.get_child_count() <= 0:
		return
	var root: Control = interface.get_child(0) as Control
	if root == null:
		return
	for child: Node in root.get_children():
		if child is PanelContainer:
			var panel := child as PanelContainer
			if panel.position.x >= 10.0 and panel.position.x <= 30.0 and panel.position.y > 60.0:
				panel.position = Vector2(14.0, 102.0)
				panel.size = Vector2(324.0, 536.0)

func _add_selected_room_preview() -> void:
	var city_panel_value: Variant = precinct.get("city_panel")
	if not city_panel_value is Control:
		return
	var city_panel: Control = city_panel_value as Control
	if city_panel.get_child_count() <= 0:
		return
	var column: VBoxContainer = city_panel.get_child(0) as VBoxContainer
	if column == null:
		return
	room_preview = TextureRect.new()
	room_preview.name = "SelectedRoomArtwork"
	room_preview.custom_minimum_size = Vector2(296.0, 124.0)
	room_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	room_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(room_preview)
	column.move_child(room_preview, 2)
	preview_caption = Label.new()
	preview_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_caption.add_theme_font_size_override("font_size", 10)
	preview_caption.modulate = Color("8edff4")
	column.add_child(preview_caption)
	column.move_child(preview_caption, 3)
	var room_info_value: Variant = precinct.get("room_info")
	if room_info_value is Label:
		var room_info := room_info_value as Label
		room_info.custom_minimum_size = Vector2(296.0, 112.0)
		room_info.add_theme_font_size_override("font_size", 11)
	for child: Node in column.get_children():
		if child is Button:
			(child as Button).custom_minimum_size = Vector2(140.0, 31.0)

func _correct_back_row_art_orientation() -> void:
	var rooms_value: Variant = precinct.get("rooms_root")
	if not rooms_value is Node3D:
		return
	var rooms_root := rooms_value as Node3D
	for room_child: Node in rooms_root.get_children():
		if not room_child is Node3D:
			continue
		var room := room_child as Node3D
		if room.position.z <= 0.0:
			continue
		for panel_name: String in ["RoomArt", "EstablishedMoonGoonsArt"]:
			var panel: Node3D = room.get_node_or_null(panel_name) as Node3D
			if panel != null:
				panel.rotation.y = PI

func _refresh_preview(force: bool = false) -> void:
	if room_preview == null:
		return
	var selected_value: Variant = precinct.get("selected_room_id")
	var room_id: String = str(selected_value)
	if not force and room_id == last_room_id:
		return
	last_room_id = room_id
	room_preview.texture = ROOM_PREVIEWS.get(room_id) as Texture2D
	var room: Dictionary = PrecinctState.get_room(room_id)
	var repaired: bool = bool(room.get("repaired", false))
	room_preview.modulate = Color.WHITE if repaired else Color(0.42, 0.45, 0.52, 1.0)
	if preview_caption != null:
		preview_caption.text = "ILLUSTRATED INTERIOR  •  %s  •  LEVEL %d" % ["ONLINE" if repaired else "DAMAGED", int(room.get("level", 1))]
		preview_caption.modulate = Color("7ef5d0") if repaired else Color("ff829b")

func _find_label(root: Node, needle: String) -> Label:
	if root is Label and (root as Label).text.contains(needle):
		return root as Label
	for child: Node in root.get_children():
		var found: Label = _find_label(child, needle)
		if found != null:
			return found
	return null
