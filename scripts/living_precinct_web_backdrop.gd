extends Control
## Illustrated web fallback for the living precinct.
## The normal 3D station remains active for input and desktop builds, while this
## layer guarantees that browser players never receive an empty black city view.

const ROOM_ORDER: Array[String] = [
	"ops", "armory", "cells", "quarters",
	"medbay", "chief", "interrogation", "transfer"
]
const ROOM_NAMES: Dictionary = {
	"ops":"OPERATIONS", "armory":"ARMORY", "cells":"HOLDING CELLS", "quarters":"CREW QUARTERS",
	"medbay":"MEDBAY", "chief":"CHIEF'S OFFICE", "interrogation":"INTERROGATION", "transfer":"TRANSFER HALL"
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

var animation_clock: float = 0.0
var panorama: Texture2D
var room_art: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = OS.has_feature("web")
	if not visible:
		set_process(false)
		return
	panorama = load("res://assets/shared/syndicate_rising/lunar_surface_panorama.svg") as Texture2D
	for room_id: String in ROOM_ORDER:
		room_art[room_id] = load(String(ROOM_ART_PATHS.get(room_id, ""))) as Texture2D
	if not PrecinctState.state_changed.is_connected(_on_state_changed):
		PrecinctState.state_changed.connect(_on_state_changed)
	queue_redraw()

func _process(delta: float) -> void:
	animation_clock += delta
	queue_redraw()

func _on_state_changed() -> void:
	queue_redraw()

func _draw() -> void:
	var viewport_size: Vector2 = size
	if viewport_size.x < 2.0 or viewport_size.y < 2.0:
		viewport_size = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#020711"), true)
	if panorama != null:
		draw_texture_rect(panorama, Rect2(0.0, 78.0, viewport_size.x, viewport_size.y - 120.0), false, Color(0.72, 0.82, 0.95, 0.42))
	_draw_stars(viewport_size)
	_draw_moon_horizon(viewport_size)
	_draw_station(viewport_size)
	_draw_personnel(viewport_size)

func _draw_stars(viewport_size: Vector2) -> void:
	for index: int in range(110):
		var x: float = fmod(float(index * 113 + 41), viewport_size.x)
		var y: float = 88.0 + fmod(float(index * 71 + 17), maxf(120.0, viewport_size.y - 260.0))
		var pulse: float = 0.28 + 0.22 * sin(animation_clock * 1.4 + float(index) * 0.61)
		draw_circle(Vector2(x, y), 0.7 + float(index % 3) * 0.45, Color(0.72, 0.89, 1.0, pulse))

func _draw_moon_horizon(viewport_size: Vector2) -> void:
	var horizon_y: float = viewport_size.y - 112.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, horizon_y), Vector2(viewport_size.x * 0.15, horizon_y - 38.0),
		Vector2(viewport_size.x * 0.31, horizon_y - 10.0), Vector2(viewport_size.x * 0.48, horizon_y - 52.0),
		Vector2(viewport_size.x * 0.66, horizon_y - 16.0), Vector2(viewport_size.x * 0.83, horizon_y - 44.0),
		Vector2(viewport_size.x, horizon_y - 4.0), Vector2(viewport_size.x, viewport_size.y), Vector2(0.0, viewport_size.y)
	]), Color("#151E2B"))
	for index: int in range(9):
		var crater_x: float = 70.0 + float(index) * maxf(90.0, viewport_size.x / 9.5)
		var crater_y: float = horizon_y + 24.0 + float(index % 3) * 17.0
		draw_ellipse(Vector2(crater_x, crater_y), Vector2(30.0 + float(index % 4) * 9.0, 8.0 + float(index % 3) * 3.0), Color(0.04, 0.07, 0.11, 0.72))

func _draw_station(viewport_size: Vector2) -> void:
	var left_margin: float = 54.0
	var right_margin: float = 218.0 if viewport_size.x >= 1000.0 else 26.0
	var top_y: float = 154.0
	var usable_width: float = maxf(680.0, viewport_size.x - left_margin - right_margin)
	var room_gap: float = 10.0
	var room_width: float = (usable_width - room_gap * 3.0) / 4.0
	var available_height: float = maxf(410.0, viewport_size.y - 260.0)
	var room_height: float = clampf((available_height - 72.0) * 0.5, 138.0, 218.0)
	var station_height: float = room_height * 2.0 + 72.0
	var station_rect := Rect2(left_margin - 15.0, top_y - 18.0, usable_width + 30.0, station_height + 36.0)
	_draw_panel(station_rect, Color(0.025, 0.065, 0.10, 0.95), Color("#4B7189"), 4.0)
	for inset: int in range(3):
		draw_rect(station_rect.grow(-8.0 - float(inset) * 7.0), Color(0.18, 0.35, 0.47, 0.16), false, 2.0)

	var corridor_y: float = top_y + room_height + 7.0
	var corridor_rect := Rect2(left_margin, corridor_y, usable_width, 58.0)
	_draw_panel(corridor_rect, Color("#17344A"), Color("#65E6FF"), 2.0)
	for strip: int in range(20):
		var strip_x: float = corridor_rect.position.x + 12.0 + float(strip) * (corridor_rect.size.x - 24.0) / 20.0
		draw_line(Vector2(strip_x, corridor_y + 8.0), Vector2(strip_x, corridor_y + 50.0), Color(0.38, 0.79, 0.94, 0.16), 1.0)
	draw_line(Vector2(left_margin + 12.0, corridor_y + 29.0), Vector2(left_margin + usable_width - 12.0, corridor_y + 29.0), Color("#71ECFF", 0.72), 3.0)

	for index: int in range(ROOM_ORDER.size()):
		var room_id: String = ROOM_ORDER[index]
		var column: int = index % 4
		var south: bool = index >= 4
		var x: float = left_margin + float(column) * (room_width + room_gap)
		var y: float = top_y if not south else corridor_y + 65.0
		_draw_room(room_id, Rect2(x, y, room_width, room_height), south)

	var header_rect := Rect2(left_margin + usable_width * 0.31, top_y - 42.0, usable_width * 0.38, 30.0)
	_draw_panel(header_rect, Color(0.02, 0.12, 0.18, 0.94), Color("#73E9FF"), 2.0)
	draw_string(ThemeDB.fallback_font, header_rect.position + Vector2(8.0, 21.0), "PEACEKEEPER ORBITAL PRECINCT // CITY VIEW", HORIZONTAL_ALIGNMENT_CENTER, header_rect.size.x - 16.0, 13, Color("#E8F8FF"))

func _draw_room(room_id: String, rect: Rect2, south: bool) -> void:
	var room: Dictionary = PrecinctState.get_room(room_id)
	var repaired: bool = bool(room.get("repaired", false))
	var level: int = int(room.get("level", 1))
	var accent := Color(String(ROOM_COLORS.get(room_id, "#65E6FF")))
	var fill := Color(0.035, 0.075, 0.105, 0.97) if repaired else Color(0.055, 0.055, 0.065, 0.98)
	_draw_panel(rect, fill, accent if repaired else Color("#73505A"), 3.0)
	var art_rect := Rect2(rect.position + Vector2(7.0, 29.0), Vector2(rect.size.x - 14.0, rect.size.y - 57.0))
	var texture_value: Variant = room_art.get(room_id)
	if texture_value is Texture2D:
		draw_texture_rect(texture_value as Texture2D, art_rect, false, Color.WHITE if repaired else Color(0.36, 0.38, 0.43, 0.92))
	else:
		draw_rect(art_rect, Color(0.08, 0.14, 0.19, 1.0), true)
	var header := Rect2(rect.position + Vector2(1.0, 1.0), Vector2(rect.size.x - 2.0, 26.0))
	draw_rect(header, Color(accent, 0.16 if repaired else 0.08), true)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 20.0), String(ROOM_NAMES.get(room_id, room_id.to_upper())), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 70.0, 12, Color("#F1FAFF"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(rect.size.x - 63.0, 20.0), "LV %d" % level, HORIZONTAL_ALIGNMENT_RIGHT, 54.0, 11, accent)
	var status_text: String = "ONLINE" if repaired else "DAMAGED"
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, rect.size.y - 8.0), status_text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 10, Color("#75F1C8") if repaired else Color("#FF829A"))
	var door_x: float = rect.position.x + rect.size.x * 0.5 - 18.0
	var door_y: float = rect.end.y - 4.0 if not south else rect.position.y - 7.0
	_draw_panel(Rect2(door_x, door_y, 36.0, 11.0), Color("#152B3C"), accent, 1.5)

func _draw_personnel(viewport_size: Vector2) -> void:
	var left_margin: float = 54.0
	var right_margin: float = 218.0 if viewport_size.x >= 1000.0 else 26.0
	var usable_width: float = maxf(680.0, viewport_size.x - left_margin - right_margin)
	var available_height: float = maxf(410.0, viewport_size.y - 260.0)
	var room_height: float = clampf((available_height - 72.0) * 0.5, 138.0, 218.0)
	var corridor_y: float = 154.0 + room_height + 7.0
	var roster_count: int = maxi(8, PrecinctState.officers.size() + 4)
	for index: int in range(roster_count):
		var lane: float = float(index % 3)
		var speed: float = 18.0 + float(index % 5) * 4.0
		var travel: float = fmod(animation_clock * speed + float(index) * 83.0, usable_width - 42.0)
		var x: float = left_margin + 21.0 + travel
		var y: float = corridor_y + 17.0 + lane * 12.0
		var body_color: Color = Color("#75E8FF") if index < PrecinctState.officers.size() else Color("#FFD16F")
		draw_circle(Vector2(x, y), 4.2, Color(0.02, 0.05, 0.08, 0.92))
		draw_circle(Vector2(x, y - 1.0), 2.8, body_color)
		draw_line(Vector2(x - 3.0, y + 5.0), Vector2(x + 3.0, y + 5.0), Color(body_color, 0.58), 2.0)

func _draw_panel(rect: Rect2, fill: Color, border: Color, width: float) -> void:
	draw_rect(rect, fill, true)
	draw_rect(rect, border, false, width)

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index: int in range(24):
		var angle: float = TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
