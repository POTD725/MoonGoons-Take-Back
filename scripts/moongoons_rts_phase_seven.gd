extends "res://scripts/moongoons_rts_phase_six.gd"
## Phase Seven: terrain-aware navigation and tactical map commands.

const TACTICAL_MAP_RECT := Rect2(994.0, 638.0, 248.0, 54.0)

var navigation_rules: Dictionary = {}
var terrain_overlay_enabled: bool = true
var tactical_map_focus: Vector2 = NEXUS_POSITION

func _ready() -> void:
	navigation_rules = _load_navigation_rules()
	super._ready()
	tactical_map_focus = NEXUS_POSITION
	mission_state = "Terrain routes online. Use the tactical map to direct selected squads around lunar obstacles."
	_log_event("Phase Seven online: terrain affects movement and the tactical map accepts squad commands.")
	queue_redraw()

func _reset_match() -> void:
	super._reset_match()
	tactical_map_focus = NEXUS_POSITION

func _handle_hotkey(keycode: Key) -> void:
	if keycode == KEY_M:
		terrain_overlay_enabled = not terrain_overlay_enabled
		mission_state = "Terrain overlay %s." % ("enabled" if terrain_overlay_enabled else "hidden")
		queue_redraw()
		return
	super._handle_hotkey(keycode)

func _handle_left_press(cursor: Vector2) -> void:
	if not game_over and not victory and _tactical_map_inner_rect().has_point(cursor):
		_issue_tactical_map_command(cursor)
		return
	super._handle_left_press(cursor)

func _draw_field() -> void:
	super._draw_field()
	if terrain_overlay_enabled:
		_draw_navigation_terrain()

func _draw_sidebar() -> void:
	super._draw_sidebar()
	_draw_tactical_map()

func _move_worker(worker: Variant, destination: Vector2, delta: float) -> void:
	worker.pos = _navigate_position(worker.pos, destination, 95.0, delta)

func _move_combat_unit(unit: Variant, destination: Vector2, delta: float) -> void:
	unit.pos = _navigate_position(unit.pos, destination, float(unit.speed), delta)

func _move_enemy(enemy: Variant, destination: Vector2, delta: float) -> void:
	enemy.pos = _navigate_position(enemy.pos, destination, float(enemy.speed), delta)

func _is_valid_build_position(cursor: Vector2) -> bool:
	if not super._is_valid_build_position(cursor):
		return false
	for feature: Variant in _navigation_features():
		if not (feature is Dictionary):
			continue
		var definition: Dictionary = feature as Dictionary
		if String(definition.get("kind", "")) != "obstacle":
			continue
		if cursor.distance_to(_feature_center(definition)) < _feature_radius(definition) + 30.0:
			return false
	return true

func _navigate_position(origin: Vector2, destination: Vector2, base_speed: float, delta: float) -> Vector2:
	if base_speed <= 0.0:
		return origin
	var waypoint: Vector2 = _detour_waypoint(origin, destination)
	var difference: Vector2 = waypoint - origin
	if difference.length() <= 1.0:
		return origin
	var terrain_multiplier: float = _terrain_speed_multiplier(origin)
	var step_length: float = minf(base_speed * terrain_multiplier * delta, difference.length())
	var candidate: Vector2 = origin + difference.normalized() * step_length
	candidate = _push_out_of_navigation_obstacles(candidate)
	return _clamp_to_field(candidate)

func _detour_waypoint(origin: Vector2, destination: Vector2) -> Vector2:
	for feature: Variant in _navigation_features():
		if not (feature is Dictionary):
			continue
		var definition: Dictionary = feature as Dictionary
		if String(definition.get("kind", "")) != "obstacle":
			continue
		var center: Vector2 = _feature_center(definition)
		var clearance: float = _feature_radius(definition) + _unit_clearance() + _detour_clearance()
		if not _segment_hits_circle(origin, destination, center, clearance):
			continue
		var travel: Vector2 = destination - origin
		if travel.length() <= 0.1:
			return destination
		var side: Vector2 = Vector2(-travel.y, travel.x).normalized()
		var left: Vector2 = center + side * clearance
		var right: Vector2 = center - side * clearance
		var left_score: float = left.distance_to(destination) + (10000.0 if not FIELD.grow(-8.0).has_point(left) else 0.0)
		var right_score: float = right.distance_to(destination) + (10000.0 if not FIELD.grow(-8.0).has_point(right) else 0.0)
		return left if left_score <= right_score else right
	return destination

func _segment_hits_circle(start: Vector2, finish: Vector2, center: Vector2, radius: float) -> bool:
	var segment: Vector2 = finish - start
	var length_squared: float = segment.length_squared()
	if length_squared <= 0.001:
		return start.distance_to(center) <= radius
	var progress: float = clampf((center - start).dot(segment) / length_squared, 0.0, 1.0)
	var nearest: Vector2 = start + segment * progress
	return nearest.distance_to(center) <= radius

func _push_out_of_navigation_obstacles(candidate: Vector2) -> Vector2:
	var resolved: Vector2 = candidate
	for feature: Variant in _navigation_features():
		if not (feature is Dictionary):
			continue
		var definition: Dictionary = feature as Dictionary
		if String(definition.get("kind", "")) != "obstacle":
			continue
		var center: Vector2 = _feature_center(definition)
		var minimum_distance: float = _feature_radius(definition) + _unit_clearance()
		var difference: Vector2 = resolved - center
		if difference.length() >= minimum_distance:
			continue
		var outward: Vector2 = difference.normalized() if difference.length() > 0.1 else Vector2.RIGHT
		resolved = center + outward * minimum_distance
	return resolved

func _terrain_speed_multiplier(position: Vector2) -> float:
	var multiplier: float = 1.0
	for feature: Variant in _navigation_features():
		if not (feature is Dictionary):
			continue
		var definition: Dictionary = feature as Dictionary
		var kind: String = String(definition.get("kind", ""))
		if kind != "slow_zone" and kind != "fast_zone":
			continue
		if _feature_rect(definition).has_point(position):
			multiplier *= float(definition.get("speed_multiplier", 1.0))
	return clampf(multiplier, 0.45, 1.35)

func _issue_tactical_map_command(cursor: Vector2) -> void:
	var target: Vector2 = _tactical_map_to_field(cursor)
	tactical_map_focus = target
	var attack_move: bool = Input.is_key_pressed(KEY_SHIFT)
	_command_selected_combat(target, "", attack_move)
	_command_selected_workers_move(target)
	mission_state = "Tactical map order issued%s." % (" as attack-move" if attack_move else "")
	queue_redraw()

func _draw_navigation_terrain() -> void:
	for feature: Variant in _navigation_features():
		if not (feature is Dictionary):
			continue
		var definition: Dictionary = feature as Dictionary
		var kind: String = String(definition.get("kind", ""))
		match kind:
			"slow_zone":
				var slow_rect: Rect2 = _feature_rect(definition)
				draw_rect(slow_rect, Color("9f6b43", 0.20))
				draw_rect(slow_rect, Color("d29d65", 0.50), false, 1.0)
				draw_string(ThemeDB.fallback_font, slow_rect.position + Vector2(6.0, 15.0), String(definition.get("label", "SLOW TERRAIN")), HORIZONTAL_ALIGNMENT_LEFT, slow_rect.size.x - 12.0, 9, Color("f1c58a"))
			"fast_zone":
				var fast_rect: Rect2 = _feature_rect(definition)
				draw_rect(fast_rect, Color("4e95ba", 0.16))
				draw_rect(fast_rect, Color("80d7f1", 0.42), false, 1.0)
				draw_string(ThemeDB.fallback_font, fast_rect.position + Vector2(6.0, 15.0), String(definition.get("label", "TRANSIT")), HORIZONTAL_ALIGNMENT_LEFT, fast_rect.size.x - 12.0, 9, Color("b8efff"))
			"obstacle":
				var center: Vector2 = _feature_center(definition)
				var radius: float = _feature_radius(definition)
				draw_circle(center, radius, Color("20232f", 0.82))
				draw_arc(center, radius, 0.0, TAU, 24, Color("a6b4c6", 0.68), 2.0)
				draw_string(ThemeDB.fallback_font, center + Vector2(-radius, radius + 16.0), String(definition.get("label", "OBSTACLE")), HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 9, Color("c4d1df"))

func _draw_tactical_map() -> void:
	draw_style_box(_panel_style(Color("0b2033", 0.96), Color("4d7899"), 1, 7), TACTICAL_MAP_RECT)
	draw_string(ThemeDB.fallback_font, TACTICAL_MAP_RECT.position + Vector2(9.0, 13.0), "TACTICAL MAP // CLICK: MOVE // SHIFT: ATTACK", HORIZONTAL_ALIGNMENT_LEFT, 228.0, 8, Color("9cc9e2"))
	var inner: Rect2 = _tactical_map_inner_rect()
	draw_rect(inner, Color("172c37"))
	for feature: Variant in _navigation_features():
		if not (feature is Dictionary):
			continue
		var definition: Dictionary = feature as Dictionary
		if String(definition.get("kind", "")) == "obstacle":
			draw_circle(_field_to_tactical_map(_feature_center(definition)), 2.5, Color("a6b4c6"))
	for worker: Variant in workers:
		draw_circle(_field_to_tactical_map(worker.pos), 1.5, Color("75e7ff"))
	for unit: Variant in combat_units:
		draw_circle(_field_to_tactical_map(unit.pos), 1.8, Color("7ef5d0"))
	for enemy: Variant in enemy_units:
		draw_circle(_field_to_tactical_map(enemy.pos), 1.6, Color("ff6f92"))
	for sector: Variant in territory_sectors:
		var sector_color: Color = _territory_color(sector)
		draw_circle(_field_to_tactical_map(sector.pos), 2.2, sector_color)
	var focus: Vector2 = _field_to_tactical_map(tactical_map_focus)
	draw_line(focus + Vector2(-3.0, 0.0), focus + Vector2(3.0, 0.0), Color("fff5a8"), 1.0)
	draw_line(focus + Vector2(0.0, -3.0), focus + Vector2(0.0, 3.0), Color("fff5a8"), 1.0)
	draw_rect(inner, Color("86b6d0"), false, 1.0)

func _tactical_map_inner_rect() -> Rect2:
	return Rect2(TACTICAL_MAP_RECT.position + Vector2(8.0, 20.0), Vector2(TACTICAL_MAP_RECT.size.x - 16.0, TACTICAL_MAP_RECT.size.y - 28.0))

func _field_to_tactical_map(point: Vector2) -> Vector2:
	var inner: Rect2 = _tactical_map_inner_rect()
	var normalized: Vector2 = Vector2((point.x - FIELD.position.x) / FIELD.size.x, (point.y - FIELD.position.y) / FIELD.size.y)
	return inner.position + Vector2(normalized.x * inner.size.x, normalized.y * inner.size.y)

func _tactical_map_to_field(point: Vector2) -> Vector2:
	var inner: Rect2 = _tactical_map_inner_rect()
	var normalized: Vector2 = Vector2((point.x - inner.position.x) / inner.size.x, (point.y - inner.position.y) / inner.size.y)
	return _clamp_to_field(FIELD.position + Vector2(normalized.x * FIELD.size.x, normalized.y * FIELD.size.y))

func _navigation_features() -> Array:
	var navigation: Dictionary = navigation_rules.get("navigation", {}) as Dictionary
	var features: Variant = navigation.get("features", [])
	return features as Array if features is Array else []

func _feature_center(definition: Dictionary) -> Vector2:
	var values: Array = definition.get("center", [0.0, 0.0]) as Array
	var x_value: float = float(values[0]) if values.size() > 0 else 0.0
	var y_value: float = float(values[1]) if values.size() > 1 else 0.0
	return Vector2(x_value, y_value)

func _feature_radius(definition: Dictionary) -> float:
	return maxf(1.0, float(definition.get("radius", 1.0)))

func _feature_rect(definition: Dictionary) -> Rect2:
	var values: Array = definition.get("rect", [0.0, 0.0, 0.0, 0.0]) as Array
	if values.size() != 4:
		return Rect2()
	return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))

func _unit_clearance() -> float:
	var navigation: Dictionary = navigation_rules.get("navigation", {}) as Dictionary
	return float(navigation.get("unit_clearance", 18.0))

func _detour_clearance() -> float:
	var navigation: Dictionary = navigation_rules.get("navigation", {}) as Dictionary
	return float(navigation.get("detour_clearance", 30.0))

func _load_navigation_rules() -> Dictionary:
	var path: String = "res://data/rts_phase_seven_navigation.json"
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
