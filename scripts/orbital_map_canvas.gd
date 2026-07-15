class_name OrbitalMapCanvas
extends Control
## Radar-style operations map. The player base is permanently centered while
## resource fields, hostile fleets and distress missions orbit around it.

signal marker_selected(marker_type: String, marker_id: String)

var markers: Array[Dictionary] = []
var filter_mode := "all"
var selected_type := ""
var selected_id := ""
var animation_clock := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	animation_clock += delta
	queue_redraw()

func set_markers(value: Array[Dictionary]) -> void:
	markers = value
	queue_redraw()

func set_filter(value: String) -> void:
	filter_mode = value
	queue_redraw()

func select_marker(marker_type: String, marker_id: String) -> void:
	selected_type = marker_type; selected_id = marker_id; queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT: return
	var center := size * 0.5
	var best_distance := 28.0
	var best: Dictionary = {}
	for marker: Dictionary in markers:
		if not _marker_visible(marker): continue
		var screen := center + (marker.get("position", Vector2.ZERO) as Vector2) * _map_scale()
		var distance := screen.distance_to(mouse.position)
		if distance < best_distance:
			best_distance = distance; best = marker
	if not best.is_empty():
		selected_type = String(best.get("type", "")); selected_id = String(best.get("id", "")); marker_selected.emit(selected_type, selected_id); queue_redraw(); accept_event()

func _draw() -> void:
	var viewport_size := size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("020914"), true)
	var center := viewport_size * 0.5
	# Star field.
	for index: int in range(110):
		var x := fmod(float(index * 131 + 43), maxf(1.0, viewport_size.x))
		var y := fmod(float(index * 79 + 29), maxf(1.0, viewport_size.y))
		var pulse := 0.20 + 0.22 * sin(animation_clock * 1.2 + index * 0.43)
		draw_circle(Vector2(x,y), 0.7 + (index % 3) * 0.35, Color(0.68,0.86,1.0,pulse))
	# Radar rings and axes.
	var max_radius := minf(viewport_size.x, viewport_size.y) * 0.43
	for fraction: float in [0.25,0.5,0.75,1.0]:
		draw_arc(center, max_radius * fraction, 0, TAU, 96, Color("31576D",0.55), 1.5)
	for angle: float in [0.0, PI*0.25, PI*0.5, PI*0.75]:
		var vector := Vector2(cos(angle),sin(angle))*max_radius
		draw_line(center-vector,center+vector,Color("27495D",0.42),1.0)
	# Animated scanner sweep.
	var sweep_angle := fmod(animation_clock * 0.38, TAU)
	draw_line(center, center + Vector2(cos(sweep_angle),sin(sweep_angle))*max_radius, Color("66E6FF",0.35), 3.0)
	_draw_base(center)
	for marker: Dictionary in markers:
		if _marker_visible(marker): _draw_marker(marker, center)
	var legend := "BASE CENTER  |  CIRCLE RESOURCE  |  TRIANGLE THREAT  |  DIAMOND MISSION"
	draw_string(ThemeDB.fallback_font, Vector2(16, viewport_size.y-16), legend, HORIZONTAL_ALIGNMENT_LEFT, viewport_size.x-32, 12, Color("A9DCEC"))

func _draw_base(center: Vector2) -> void:
	var pulse := 2.0 + sin(animation_clock * 2.1) * 1.3
	draw_circle(center, 34.0 + pulse, Color("173F52",0.8))
	draw_circle(center, 28.0, Color("2A6277"))
	draw_rect(Rect2(center-Vector2(18,13),Vector2(36,26)),Color("D9F7FF"),true)
	draw_rect(Rect2(center-Vector2(21,16),Vector2(42,32)),Color("68E8FF"),false,2.0)
	draw_rect(Rect2(center+Vector2(-6,-25),Vector2(12,12)),Color("FFE06A"),true)
	draw_string(ThemeDB.fallback_font, center+Vector2(-76,53), "PEACEKEEPER HQ", HORIZONTAL_ALIGNMENT_CENTER,152,13,Color("E8FBFF"))

func _draw_marker(marker: Dictionary, center: Vector2) -> void:
	var position := center + (marker.get("position",Vector2.ZERO) as Vector2) * _map_scale()
	var marker_type := String(marker.get("type", "resource")); var marker_id := String(marker.get("id", "")); var color := Color(String(marker.get("color", "#6DEBFF")))
	var selected := marker_type == selected_type and marker_id == selected_id
	var radius := 12.0 if not selected else 17.0 + sin(animation_clock*3.0)*1.5
	if marker_type == "resource":
		draw_circle(position,radius,Color(color,0.72)); draw_circle(position,radius+4,Color(color,0.75),false,2.0)
	elif marker_type == "threat":
		var points := PackedVector2Array([position+Vector2(0,-radius),position+Vector2(radius,radius),position+Vector2(-radius,radius)])
		draw_colored_polygon(points,Color(color,0.82)); draw_polyline(points,color,2.0)
	else:
		var points := PackedVector2Array([position+Vector2(0,-radius),position+Vector2(radius,0),position+Vector2(0,radius),position+Vector2(-radius,0),position+Vector2(0,-radius)])
		draw_colored_polygon(points,Color(color,0.78)); draw_polyline(points,color,2.0)
	if bool(marker.get("locked",false)):
		draw_line(position-Vector2(8,8),position+Vector2(8,8),Color("87929A"),3.0); draw_line(position+Vector2(-8,8),position+Vector2(8,-8),Color("87929A"),3.0)
	var label := String(marker.get("label", marker_id)).to_upper()
	draw_string(ThemeDB.fallback_font,position+Vector2(-66,radius+18),label,HORIZONTAL_ALIGNMENT_CENTER,132,10,Color("E5F7FF"))
	if selected: draw_arc(position,radius+10,0,TAU,40,Color("FFFFFF"),2.0)

func _marker_visible(marker: Dictionary) -> bool:
	return filter_mode == "all" or String(marker.get("type", "")) == filter_mode

func _map_scale() -> float:
	return minf(size.x,size.y) / 100.0
