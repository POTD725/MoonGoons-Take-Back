extends "res://scripts/living_precinct_web_backdrop.gd"
## Perspective browser renderer for the 2D/3D hybrid precinct.
## Rear buildings are smaller and higher; front buildings are larger with visible facades.

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
	var title_rect := Rect2(center_x - 220.0, 152.0, 440.0, 32.0)
	_draw_panel(title_rect, Color(0.02, 0.12, 0.18, 0.96), Color("#73E9FF"), 2.0)
	draw_string(ThemeDB.fallback_font, title_rect.position + Vector2(8.0, 22.0), "PEACEKEEPER PRECINCT // 2D + 3D THREE-QUARTER CITY", HORIZONTAL_ALIGNMENT_CENTER, title_rect.size.x - 16.0, 13, Color("#E8F8FF"))

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
		draw_line(start, finish, Color("#315C72"), 22.0)
		draw_line(start, finish, Color("#67E7FF", 0.58), 3.0)
	var back_left: Rect2 = (by_id["ops"] as Dictionary).rect as Rect2
	var back_right: Rect2 = (by_id["quarters"] as Dictionary).rect as Rect2
	var front_left: Rect2 = (by_id["medbay"] as Dictionary).rect as Rect2
	var front_right: Rect2 = (by_id["transfer"] as Dictionary).rect as Rect2
	draw_line(Vector2(back_left.get_center().x, back_left.end.y - 8.0), Vector2(back_right.get_center().x, back_right.end.y - 8.0), Color("#315C72"), 20.0)
	draw_line(Vector2(front_left.get_center().x, front_left.position.y + 10.0), Vector2(front_right.get_center().x, front_right.position.y + 10.0), Color("#315C72"), 22.0)

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
