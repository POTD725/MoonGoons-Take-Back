extends Control
## Interactive browser city renderer. Draws recognizable exterior station buildings
## above the WebGL clear pass and mirrors the real camera's pan, zoom, and orbit.

const ROOM_ORDER: Array[String] = [
	"ops", "armory", "cells", "quarters",
	"medbay", "chief", "interrogation", "transfer"
]
const ROOM_NAMES: Dictionary = {
	"ops":"OPERATIONS", "armory":"ARMORY", "cells":"DETENTION", "quarters":"HABITAT",
	"medbay":"MEDBAY", "chief":"CHIEF COMMAND", "interrogation":"INTERROGATION", "transfer":"TRANSFER HANGAR"
}
const ROOM_COLORS: Dictionary = {
	"ops":"#48D7FF", "armory":"#FFAB4A", "cells":"#6CA8FF", "quarters":"#FFD18A",
	"medbay":"#55F0C2", "chief":"#FFE36A", "interrogation":"#C17BFF", "transfer":"#62DFFF"
}
const ROOM_ART_PATHS: Dictionary = {
	"ops":"res://assets/precinct/rooms/ops_center.svg",
	"armory":"res://assets/precinct/rooms/armory.svg",
	"cells":"res://assets/precinct/rooms/holding_cells.svg",
	"quarters":"res://assets/precinct/rooms/crew_quarters.svg",
	"medbay":"res://assets/precinct/rooms/medbay.svg",
	"chief":"res://assets/precinct/rooms/chief_office.svg",
	"interrogation":"res://assets/precinct/rooms/interrogation.svg",
	"transfer":"res://assets/precinct/rooms/transfer_hall.svg"
}

var precinct: Node
var animation_clock: float = 0.0
var panorama: Texture2D
var room_art: Dictionary = {}
var room_rects: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = OS.has_feature("web")
	if not visible:
		set_process(false)
		return
	precinct = get_parent().get_parent()
	panorama = load("res://assets/shared/syndicate_rising/lunar_surface_panorama.svg") as Texture2D
	for room_id: String in ROOM_ORDER:
		room_art[room_id] = load(String(ROOM_ART_PATHS.get(room_id, ""))) as Texture2D
	if not PrecinctState.state_changed.is_connected(_on_state_changed):
		PrecinctState.state_changed.connect(_on_state_changed)
	queue_redraw()

func _process(delta: float) -> void:
	animation_clock += delta
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	for room_value: Variant in room_rects.keys():
		var room_id: String = String(room_value)
		var rect: Rect2 = room_rects[room_id] as Rect2
		if rect.has_point(mouse_event.position):
			_select_room(room_id)
			accept_event()
			return

func _select_room(room_id: String) -> void:
	if precinct == null:
		return
	precinct.set("selected_room_id", room_id)
	var room_nodes_value: Variant = precinct.get("room_nodes")
	if room_nodes_value is Dictionary:
		var room_node: Node3D = (room_nodes_value as Dictionary).get(room_id) as Node3D
		if room_node != null:
			precinct.set("camera_target", room_node.position)
	precinct.set("camera_distance", 27.0)
	precinct.call("_show_tab", "city")
	var city_value: Variant = precinct.get("city_panel")
	if city_value is Control:
		var city_panel := city_value as Control
		var viewport_size: Vector2 = get_viewport_rect().size
		city_panel.position = Vector2(viewport_size.x - 360.0, 150.0)
		city_panel.size = Vector2(344.0, minf(520.0, viewport_size.y - 220.0))
		city_panel.visible = true
	MoonGoonsAudio.play("door")
	queue_redraw()

func _on_state_changed() -> void:
	queue_redraw()

func _draw() -> void:
	var viewport_size: Vector2 = size
	if viewport_size.x < 2.0 or viewport_size.y < 2.0:
		viewport_size = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#020711"), true)
	if panorama != null:
		draw_texture_rect(panorama, Rect2(0.0, 78.0, viewport_size.x, viewport_size.y - 110.0), false, Color(0.62, 0.75, 0.90, 0.28))
	_draw_stars(viewport_size)
	_draw_moon_horizon(viewport_size)
	_draw_city(viewport_size)
	_draw_personnel(viewport_size)

func _camera_values() -> Dictionary:
	if precinct == null:
		return {"distance":38.0, "target":Vector3.ZERO, "yaw":0.0, "pitch":-0.78}
	return {
		"distance":float(precinct.get("camera_distance")),
		"target":precinct.get("camera_target") as Vector3,
		"yaw":float(precinct.get("camera_yaw")),
		"pitch":float(precinct.get("camera_pitch"))
	}

func _draw_stars(viewport_size: Vector2) -> void:
	for index: int in range(105):
		var x: float = fmod(float(index * 113 + 41), viewport_size.x)
		var y: float = 88.0 + fmod(float(index * 71 + 17), maxf(120.0, viewport_size.y - 250.0))
		var pulse: float = 0.25 + 0.20 * sin(animation_clock * 1.4 + float(index) * 0.61)
		draw_circle(Vector2(x, y), 0.7 + float(index % 3) * 0.42, Color(0.72, 0.89, 1.0, pulse))

func _draw_moon_horizon(viewport_size: Vector2) -> void:
	var horizon_y: float = viewport_size.y - 104.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, horizon_y), Vector2(viewport_size.x * 0.15, horizon_y - 38.0),
		Vector2(viewport_size.x * 0.31, horizon_y - 10.0), Vector2(viewport_size.x * 0.48, horizon_y - 52.0),
		Vector2(viewport_size.x * 0.66, horizon_y - 16.0), Vector2(viewport_size.x * 0.83, horizon_y - 44.0),
		Vector2(viewport_size.x, horizon_y - 4.0), Vector2(viewport_size.x, viewport_size.y), Vector2(0.0, viewport_size.y)
	]), Color("#151E2B"))
	for index: int in range(9):
		var crater_x: float = 70.0 + float(index) * maxf(90.0, viewport_size.x / 9.5)
		var crater_y: float = horizon_y + 24.0 + float(index % 3) * 17.0
		_draw_ellipse(Vector2(crater_x, crater_y), Vector2(30.0 + float(index % 4) * 9.0, 8.0 + float(index % 3) * 3.0), Color(0.04, 0.07, 0.11, 0.72))

func _draw_city(viewport_size: Vector2) -> void:
	room_rects.clear()
	var camera: Dictionary = _camera_values()
	var distance: float = maxf(10.0, float(camera.get("distance", 38.0)))
	var target: Vector3 = camera.get("target", Vector3.ZERO) as Vector3
	var yaw: float = float(camera.get("yaw", 0.0))
	var pitch: float = float(camera.get("pitch", -0.78))
	var zoom: float = clampf(38.0 / distance, 0.72, 1.34)
	var command: String = "city"
	if precinct != null:
		var ribbon: Node = precinct.get_node_or_null("CompactCommandRibbon")
		if ribbon != null:
			command = String(ribbon.get("active_command"))
	var right_margin: float = 455.0 if command != "city" else 205.0
	if viewport_size.x < 1050.0:
		right_margin = 24.0 if command == "city" else 355.0
	var available_left: float = 34.0
	var available_width: float = maxf(680.0, viewport_size.x - available_left - right_margin)
	var base_center_x: float = available_left + available_width * 0.5
	var usable_width: float = available_width * zoom
	var left_margin: float = base_center_x - usable_width * 0.5 - target.x * 8.0 + sin(yaw) * 42.0
	var top_y: float = 176.0 - target.z * 5.0 + (pitch + 0.78) * 80.0
	var room_gap: float = 13.0 * zoom
	var room_width: float = (usable_width - room_gap * 3.0) / 4.0
	var room_height: float = clampf(room_width * 0.62, 118.0, 210.0)
	var corridor_height: float = 54.0 * zoom
	var row_shift: float = sin(yaw) * 36.0
	var station_rect := Rect2(left_margin - 18.0, top_y - 28.0, usable_width + 36.0, room_height * 2.0 + corridor_height + 80.0)
	_draw_panel(station_rect, Color(0.018, 0.050, 0.075, 0.90), Color("#416B80"), 3.0)
	for inset: int in range(3):
		draw_rect(station_rect.grow(-7.0 - inset * 7.0), Color(0.20, 0.40, 0.52, 0.12), false, 1.0)
	var corridor_y: float = top_y + room_height + 17.0
	var corridor_rect := Rect2(left_margin, corridor_y, usable_width, corridor_height)
	_draw_panel(corridor_rect, Color("#17344A"), Color("#65E6FF"), 2.0)
	draw_line(Vector2(corridor_rect.position.x + 12.0, corridor_rect.get_center().y), Vector2(corridor_rect.end.x - 12.0, corridor_rect.get_center().y), Color("#71ECFF", 0.72), 3.0)
	for index: int in range(ROOM_ORDER.size()):
		var room_id: String = ROOM_ORDER[index]
		var column: int = index % 4
		var south: bool = index >= 4
		var row_offset: float = row_shift if not south else -row_shift
		var x: float = left_margin + float(column) * (room_width + room_gap) + row_offset
		var y: float = top_y if not south else corridor_y + corridor_height + 12.0
		var rect := Rect2(x, y, room_width, room_height)
		room_rects[room_id] = rect.grow(4.0)
		_draw_building(room_id, rect, south)
	var title_rect := Rect2(base_center_x - 205.0, top_y - 58.0, 410.0, 31.0)
	_draw_panel(title_rect, Color(0.02, 0.12, 0.18, 0.96), Color("#73E9FF"), 2.0)
	draw_string(ThemeDB.fallback_font, title_rect.position + Vector2(8.0, 22.0), "PEACEKEEPER PRECINCT // EXTERIOR CITY VIEW", HORIZONTAL_ALIGNMENT_CENTER, title_rect.size.x - 16.0, 13, Color("#E8F8FF"))

func _draw_building(room_id: String, rect: Rect2, south: bool) -> void:
	var room: Dictionary = PrecinctState.get_room(room_id)
	var repaired: bool = bool(room.get("repaired", false))
	var level: int = int(room.get("level", 1))
	var accent := Color(String(ROOM_COLORS.get(room_id, "#65E6FF")))
	var front_fill := Color("#243A49") if repaired else Color("#302B31")
	var roof_fill := Color("#3D5665") if repaired else Color("#493A40")
	var side_fill := Color("#162B38") if repaired else Color("#251D23")
	# Pseudo-isometric armored module: front facade, raised roof and visible side wall.
	var roof_offset := Vector2(12.0, -13.0) if not south else Vector2(-12.0, -13.0)
	var front := Rect2(rect.position + Vector2(0.0, 18.0), Vector2(rect.size.x, rect.size.y - 18.0))
	draw_rect(front, front_fill, true)
	draw_rect(front, accent if repaired else Color("#73505A"), false, 3.0)
	var roof_points := PackedVector2Array([
		rect.position + Vector2(0.0, 18.0),
		rect.position + roof_offset,
		Vector2(rect.end.x, rect.position.y) + roof_offset + Vector2(0.0, 18.0),
		Vector2(rect.end.x, rect.position.y + 18.0)
	])
	draw_colored_polygon(roof_points, roof_fill)
	draw_polyline(roof_points, accent if repaired else Color("#73505A"), 2.0)
	var side_points := PackedVector2Array([
		Vector2(rect.end.x, rect.position.y + 18.0),
		Vector2(rect.end.x, rect.end.y),
		Vector2(rect.end.x, rect.end.y) + roof_offset,
		Vector2(rect.end.x, rect.position.y + 18.0) + roof_offset
	])
	draw_colored_polygon(side_points, side_fill)
	_draw_building_identity(room_id, rect, accent, repaired)
	var door_width: float = maxf(34.0, rect.size.x * 0.19)
	var door := Rect2(rect.get_center().x - door_width * 0.5, rect.end.y - 40.0, door_width, 40.0)
	_draw_panel(door, Color("#102631"), accent if repaired else Color("#844B5A"), 2.0)
	for window_index: int in range(3):
		var window_width: float = maxf(25.0, (rect.size.x - door_width - 42.0) / 3.0)
		var wx: float = rect.position.x + 12.0 + window_index * (window_width + 7.0)
		if Rect2(wx, rect.position.y, window_width, 1.0).intersects(Rect2(door.position.x - 3.0, rect.position.y, door.size.x + 6.0, 1.0)):
			wx += door_width + 5.0
		var window := Rect2(wx, rect.position.y + 48.0, window_width, 25.0)
		draw_rect(window, Color(accent, 0.26 if repaired else 0.05), true)
		draw_rect(window, accent if repaired else Color("#614954"), false, 1.0)
	var texture_value: Variant = room_art.get(room_id)
	if texture_value is Texture2D and rect.size.x > 155.0:
		var display := Rect2(rect.position + Vector2(12.0, 82.0), Vector2(rect.size.x - 24.0, maxf(30.0, rect.size.y - 132.0)))
		draw_texture_rect(texture_value as Texture2D, display, false, Color(0.75, 0.90, 1.0, 0.42 if repaired else 0.15))
	var header := Rect2(front.position + Vector2(1.0, 1.0), Vector2(front.size.x - 2.0, 28.0))
	draw_rect(header, Color(accent, 0.18 if repaired else 0.07), true)
	draw_string(ThemeDB.fallback_font, front.position + Vector2(8.0, 21.0), String(ROOM_NAMES.get(room_id, room_id.to_upper())), HORIZONTAL_ALIGNMENT_LEFT, front.size.x - 65.0, 11, Color("#F1FAFF"))
	draw_string(ThemeDB.fallback_font, front.position + Vector2(front.size.x - 57.0, 21.0), "LV %d" % level, HORIZONTAL_ALIGNMENT_RIGHT, 49.0, 10, accent)
	var status_text: String = "ONLINE" if repaired else "DAMAGED // CLICK TO REPAIR"
	draw_string(ThemeDB.fallback_font, front.position + Vector2(8.0, front.size.y - 8.0), status_text, HORIZONTAL_ALIGNMENT_LEFT, front.size.x - 16.0, 9, Color("#75F1C8") if repaired else Color("#FF829A"))
	var tier_count: int = clampi(int(ceil(float(level) / 20.0)), 1, 5)
	for tier: int in range(5):
		var light := Rect2(front.position.x + 8.0 + tier * 13.0, front.end.y - 22.0, 9.0, 4.0)
		draw_rect(light, accent if repaired and tier < tier_count else Color("#18232A"), true)

func _draw_building_identity(room_id: String, rect: Rect2, accent: Color, repaired: bool) -> void:
	var center_x: float = rect.get_center().x
	var roof_y: float = rect.position.y - 13.0
	match room_id:
		"ops":
			draw_circle(Vector2(center_x, roof_y - 9.0), 13.0, Color("#183846"))
			draw_circle(Vector2(center_x, roof_y - 9.0), 8.0, Color(accent, 0.55 if repaired else 0.08))
			for radius: float in [17.0, 22.0]:
				draw_arc(Vector2(center_x, roof_y - 9.0), radius, 0.0, TAU, 24, accent if repaired else Color("#614A54"), 2.0)
		"armory":
			draw_rect(Rect2(center_x - 26.0, roof_y - 15.0, 52.0, 16.0), Color("#3B3027"), true)
			draw_line(Vector2(center_x, roof_y - 13.0), Vector2(center_x + 25.0, roof_y - 28.0), accent, 5.0)
		"cells":
			for x: float in [-24.0, -12.0, 0.0, 12.0, 24.0]:
				draw_rect(Rect2(center_x + x - 3.0, roof_y - 23.0, 6.0, 23.0), Color("#152432"), true)
		"quarters":
			for x: float in [-20.0, 20.0]:
				draw_circle(Vector2(center_x + x, roof_y - 4.0), 15.0, Color("#3A5665"))
				draw_arc(Vector2(center_x + x, roof_y - 4.0), 15.0, PI, TAU, 16, accent, 2.0)
		"medbay":
			draw_circle(Vector2(center_x, roof_y - 5.0), 16.0, Color("#DCEDEA"))
			draw_rect(Rect2(center_x - 4.0, roof_y - 21.0, 8.0, 32.0), accent, true)
			draw_rect(Rect2(center_x - 16.0, roof_y - 9.0, 32.0, 8.0), accent, true)
		"chief":
			draw_rect(Rect2(center_x - 20.0, roof_y - 31.0, 40.0, 31.0), Color("#303B50"), true)
			draw_line(Vector2(center_x, roof_y - 31.0), Vector2(center_x, roof_y - 55.0), Color("#B7C4CA"), 3.0)
			draw_circle(Vector2(center_x, roof_y - 58.0), 5.0, accent if repaired else Color("#6C4A54"))
		"interrogation":
			draw_arc(Vector2(center_x, roof_y - 6.0), 25.0, PI, TAU, 24, accent if repaired else Color("#604A68"), 5.0)
			draw_circle(Vector2(center_x + 7.0, roof_y - 20.0), 5.0, Color("#F3D8FF") if repaired else Color("#604A68"))
		"transfer":
			draw_arc(Vector2(center_x, roof_y + 4.0), 34.0, PI, TAU, 24, accent if repaired else Color("#604A54"), 8.0)
			draw_rect(Rect2(center_x - 37.0, roof_y - 1.0, 74.0, 8.0), Color("#1B3440"), true)

func _draw_personnel(viewport_size: Vector2) -> void:
	var camera: Dictionary = _camera_values()
	var target: Vector3 = camera.get("target", Vector3.ZERO) as Vector3
	var distance: float = maxf(10.0, float(camera.get("distance", 38.0)))
	var zoom: float = clampf(38.0 / distance, 0.72, 1.34)
	var command: String = "city"
	if precinct != null:
		var ribbon: Node = precinct.get_node_or_null("CompactCommandRibbon")
		if ribbon != null:
			command = String(ribbon.get("active_command"))
	var right_margin: float = 455.0 if command != "city" else 205.0
	var usable_width: float = maxf(620.0, viewport_size.x - 34.0 - right_margin) * zoom
	var left_margin: float = 34.0 + maxf(620.0, viewport_size.x - 34.0 - right_margin) * 0.5 - usable_width * 0.5 - target.x * 8.0
	var y: float = 176.0 + clampf((usable_width / 4.0) * 0.62, 118.0, 210.0) + 38.0 - target.z * 5.0
	var roster_count: int = maxi(8, PrecinctState.officers.size() + 4)
	for index: int in range(roster_count):
		var speed: float = 18.0 + float(index % 5) * 4.0
		var travel: float = fmod(animation_clock * speed + float(index) * 83.0, maxf(100.0, usable_width - 42.0))
		var x: float = left_margin + 21.0 + travel
		var lane_y: float = y + float(index % 3) * 10.0
		var body_color: Color = Color("#75E8FF") if index < PrecinctState.officers.size() else Color("#FFD16F")
		draw_circle(Vector2(x, lane_y), 4.2, Color(0.02, 0.05, 0.08, 0.92))
		draw_circle(Vector2(x, lane_y - 1.0), 2.8, body_color)
		draw_line(Vector2(x - 3.0, lane_y + 5.0), Vector2(x + 3.0, lane_y + 5.0), Color(body_color, 0.58), 2.0)

func _draw_panel(rect: Rect2, fill: Color, border: Color, width: float) -> void:
	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, width)

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index: int in range(24):
		var angle: float = TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
