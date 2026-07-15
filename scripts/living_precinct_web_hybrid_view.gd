extends "res://scripts/living_precinct_web_backdrop.gd"
## Perspective browser renderer for the orbital 2D/3D hybrid station deck.
## Rear modules are smaller and higher; front modules are larger with visible facades.

const HYBRID_WORLD_POSITIONS: Dictionary = {
	"ops": Vector2(-14.25, -7.2),
	"armory": Vector2(-4.75, -7.2),
	"cells": Vector2(4.75, -7.2),
	"quarters": Vector2(14.25, -7.2),
	"medbay": Vector2(-14.25, 7.2),
	"chief": Vector2(-4.75, 7.2),
	"interrogation": Vector2(4.75, 7.2),
	"transfer": Vector2(14.25, 7.2)
}

func _draw_city(viewport_size: Vector2) -> void:
	room_rects.clear()
	var camera: Dictionary = _camera_values()
	var distance: float = maxf(12.0, float(camera.get("distance", 40.0)))
	var target: Vector3 = camera.get("target", Vector3.ZERO) as Vector3
	var yaw: float = float(camera.get("yaw", 0.52))
	var pitch: float = float(camera.get("pitch", -0.43))
	var zoom: float = clampf(40.0 / distance, 0.68, 1.38)
	var command: String = "city"
	if precinct != null:
		var ribbon: Node = precinct.get_node_or_null("CompactCommandRibbon")
		if ribbon != null:
			command = String(ribbon.get("active_command"))
	var right_margin: float = 450.0 if command != "city" else 34.0
	var available_width: float = maxf(720.0, viewport_size.x - right_margin - 32.0)
	var center_x: float = 16.0 + available_width * 0.5
	var center_y: float = viewport_size.y * 0.53
	var world_scale: float = clampf(available_width / 47.0, 17.0, 29.0) * zoom
	var depth_scale: float = clampf(0.55 + absf(pitch) * 0.55, 0.68, 1.0)
	_draw_station_deck_base(viewport_size, center_x, center_y, available_width, world_scale, yaw)
	var projected: Array[Dictionary] = []
	for room_id: String in ROOM_ORDER:
		var world: Vector2 = HYBRID_WORLD_POSITIONS[room_id] as Vector2
		var relative := Vector2(world.x - target.x, world.y - target.z)
		var rotated_x: float = relative.x * cos(yaw) - relative.y * sin(yaw)
		var rotated_z: float = relative.x * sin(yaw) + relative.y * cos(yaw)
		var perspective: float = clampf(1.0 + rotated_z * 0.018, 0.76, 1.20)
		var screen_x: float = center_x + rotated_x * world_scale
		var screen_y: float = center_y + rotated_z * world_scale * depth_scale * 0.55
		var width: float = 8.75 * world_scale * perspective
		var height: float = 5.85 * world_scale * perspective
		projected.append({
			"id": room_id,
			"depth": rotated_z,
			"rect": Rect2(screen_x - width * 0.5, screen_y - height * 0.72, width, height),
			"front": rotated_z >= 0.0
		})
	projected.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.depth) < float(b.depth))
	_draw_projected_corridors(projected)
	for entry: Dictionary in projected:
		var room_id: String = String(entry.id)
		var rect: Rect2 = entry.rect as Rect2
		room_rects[room_id] = rect.grow(5.0)
		_draw_building(room_id, rect, bool(entry.front))
	var title_rect := Rect2(center_x - 245.0, 154.0, 490.0, 34.0)
	_draw_panel(title_rect, Color(0.02, 0.12, 0.18, 0.96), Color("#73E9FF"), 2.0)
	draw_string(ThemeDB.fallback_font, title_rect.position + Vector2(8.0, 23.0), "ORBITAL PEACEKEEPER STATION // COMMAND DECK", HORIZONTAL_ALIGNMENT_CENTER, title_rect.size.x - 16.0, 13, Color("#E8F8FF"))

func _draw_station_deck_base(viewport_size: Vector2, center_x: float, center_y: float, available_width: float, world_scale: float, yaw: float) -> void:
	var half_width: float = minf(available_width * 0.49, world_scale * 23.0)
	var deck_top: float = maxf(188.0, center_y - world_scale * 8.7)
	var deck_bottom: float = minf(viewport_size.y - 54.0, center_y + world_scale * 10.2)
	var skew: float = sin(yaw) * 32.0
	var hull := PackedVector2Array([
		Vector2(center_x - half_width * 0.82 + skew, deck_top),
		Vector2(center_x + half_width * 0.82 + skew, deck_top),
		Vector2(center_x + half_width, deck_bottom),
		Vector2(center_x - half_width, deck_bottom)
	])
	draw_colored_polygon(hull, Color(0.035, 0.075, 0.10, 0.94))
	draw_polyline(hull, Color("#4F7C91", 0.90), 4.0)
	# Armored pressure-deck plates.
	for row: int in range(7):
		var t: float = float(row) / 6.0
		var y: float = lerpf(deck_top, deck_bottom, t)
		var row_half: float = lerpf(half_width * 0.82, half_width, t)
		draw_line(Vector2(center_x - row_half + skew * (1.0 - t), y), Vector2(center_x + row_half + skew * (1.0 - t), y), Color(0.28, 0.58, 0.70, 0.16), 2.0)
	for column: int in range(-6, 7):
		var ratio: float = float(column) / 6.0
		draw_line(Vector2(center_x + ratio * half_width * 0.82 + skew, deck_top), Vector2(center_x + ratio * half_width, deck_bottom), Color(0.28, 0.58, 0.70, 0.13), 1.5)
	# Central reactor bus and pressure ring.
	var core := Vector2(center_x, center_y + 34.0)
	var pulse: float = 0.32 + 0.18 * sin(animation_clock * 1.9)
	for radius: float in [34.0, 47.0, 61.0]:
		draw_arc(core, radius, 0.0, TAU, 48, Color(0.38, 0.91, 1.0, pulse * 0.48), 2.0)
	draw_circle(core, 7.0, Color("#FFD36A", 0.68))
	# Port and starboard service trunks.
	for side: float in [-1.0, 1.0]:
		var trunk_x: float = center_x + side * half_width * 0.92
		draw_line(Vector2(trunk_x + skew, deck_top + 20.0), Vector2(trunk_x, deck_bottom - 18.0), Color("#274E63"), 18.0)
		draw_line(Vector2(trunk_x + skew, deck_top + 20.0), Vector2(trunk_x, deck_bottom - 18.0), Color("#67E7FF", 0.42), 2.0)

func _draw_projected_corridors(projected: Array[Dictionary]) -> void:
	if projected.size() < 8:
		return
	var by_id: Dictionary = {}
	for entry: Dictionary in projected:
		by_id[String(entry.id)] = entry
	for column: int in range(4):
		var back_id: String = ROOM_ORDER[column]
		var front_id: String = ROOM_ORDER[column + 4]
		var back_rect: Rect2 = (by_id[back_id] as Dictionary).rect as Rect2
		var front_rect: Rect2 = (by_id[front_id] as Dictionary).rect as Rect2
		var start := Vector2(back_rect.get_center().x, back_rect.end.y - 10.0)
		var finish := Vector2(front_rect.get_center().x, front_rect.position.y + 12.0)
		draw_line(start, finish, Color("#1B3A4B"), 28.0)
		draw_line(start, finish, Color("#315C72"), 22.0)
		draw_line(start, finish, Color("#67E7FF", 0.58), 3.0)
	var back_left: Rect2 = (by_id["ops"] as Dictionary).rect as Rect2
	var back_right: Rect2 = (by_id["quarters"] as Dictionary).rect as Rect2
	var front_left: Rect2 = (by_id["medbay"] as Dictionary).rect as Rect2
	var front_right: Rect2 = (by_id["transfer"] as Dictionary).rect as Rect2
	draw_line(Vector2(back_left.get_center().x, back_left.end.y - 8.0), Vector2(back_right.get_center().x, back_right.end.y - 8.0), Color("#183747"), 28.0)
	draw_line(Vector2(back_left.get_center().x, back_left.end.y - 8.0), Vector2(back_right.get_center().x, back_right.end.y - 8.0), Color("#315C72"), 20.0)
	draw_line(Vector2(front_left.get_center().x, front_left.position.y + 10.0), Vector2(front_right.get_center().x, front_right.position.y + 10.0), Color("#183747"), 30.0)
	draw_line(Vector2(front_left.get_center().x, front_left.position.y + 10.0), Vector2(front_right.get_center().x, front_right.position.y + 10.0), Color("#315C72"), 22.0)
	# Docking tunnel and transfer airlock indicate that every module belongs to one station.
	var transfer_rect: Rect2 = (by_id["transfer"] as Dictionary).rect as Rect2
	var dock_start := Vector2(transfer_rect.end.x - 8.0, transfer_rect.get_center().y)
	var dock_end := dock_start + Vector2(90.0, 0.0)
	draw_line(dock_start, dock_end, Color("#183747"), 30.0)
	draw_line(dock_start, dock_end, Color("#67E7FF", 0.52), 3.0)
	draw_string(ThemeDB.fallback_font, dock_end + Vector2(-72.0, -19.0), "DOCK 03", HORIZONTAL_ALIGNMENT_LEFT, 72.0, 9, Color("#8FEAFF"))

func _draw_personnel(viewport_size: Vector2) -> void:
	var camera: Dictionary = _camera_values()
	var distance: float = maxf(12.0, float(camera.get("distance", 40.0)))
	var target: Vector3 = camera.get("target", Vector3.ZERO) as Vector3
	var yaw: float = float(camera.get("yaw", 0.52))
	var pitch: float = float(camera.get("pitch", -0.43))
	var zoom: float = clampf(40.0 / distance, 0.68, 1.38)
	var command: String = "city"
	if precinct != null:
		var ribbon: Node = precinct.get_node_or_null("CompactCommandRibbon")
		if ribbon != null:
			command = String(ribbon.get("active_command"))
	var right_margin: float = 450.0 if command != "city" else 34.0
	var available_width: float = maxf(720.0, viewport_size.x - right_margin - 32.0)
	var center_x: float = 16.0 + available_width * 0.5
	var center_y: float = viewport_size.y * 0.53
	var world_scale: float = clampf(available_width / 47.0, 17.0, 29.0) * zoom
	var depth_scale: float = clampf(0.55 + absf(pitch) * 0.55, 0.68, 1.0)
	var roster_count: int = maxi(8, PrecinctState.officers.size() + 4)
	for index: int in range(roster_count):
		var progress: float = fmod(animation_clock * (0.07 + float(index % 5) * 0.012) + float(index) * 0.13, 1.0)
		var world_x: float = lerpf(-17.0, 17.0, progress)
		var world_z: float = -0.9 + float(index % 3) * 0.9
		var relative := Vector2(world_x - target.x, world_z - target.z)
		var rotated_x: float = relative.x * cos(yaw) - relative.y * sin(yaw)
		var rotated_z: float = relative.x * sin(yaw) + relative.y * cos(yaw)
		var perspective: float = clampf(1.0 + rotated_z * 0.018, 0.76, 1.20)
		var screen := Vector2(center_x + rotated_x * world_scale, center_y + rotated_z * world_scale * depth_scale * 0.55)
		var body_color: Color = Color("#75E8FF") if index < PrecinctState.officers.size() else Color("#FFD16F")
		draw_circle(screen, 4.4 * perspective, Color(0.02, 0.05, 0.08, 0.92))
		draw_circle(screen + Vector2(0.0, -2.0 * perspective), 2.8 * perspective, body_color)
		draw_line(screen + Vector2(-3.0, 5.0) * perspective, screen + Vector2(3.0, 5.0) * perspective, Color(body_color, 0.58), 2.0 * perspective)
