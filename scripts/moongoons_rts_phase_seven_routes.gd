extends "res://scripts/moongoons_rts_phase_seven.gd"
## Phase Seven continuation: queued routes and formation-aware movement orders.
## Ctrl + right-click queues movement. Ctrl + Shift + right-click queues attack-move.

var route_queues: Dictionary = {}

func _handle_right_click(cursor: Vector2) -> void:
	if not game_over and not victory and FIELD.has_point(cursor) and Input.is_key_pressed(KEY_CTRL):
		_queue_selected_route_command(cursor, Input.is_key_pressed(KEY_SHIFT))
		return
	super._handle_right_click(cursor)

func _draw_world() -> void:
	super._draw_world()
	_draw_queued_routes()

func _move_worker(worker: Variant, destination: Vector2, delta: float) -> void:
	super._move_worker(worker, destination, delta)
	_advance_route_if_arrived(String(worker.id), worker)

func _move_combat_unit(unit: Variant, destination: Vector2, delta: float) -> void:
	super._move_combat_unit(unit, destination, delta)
	_advance_route_if_arrived(String(unit.id), unit)

func _remove_worker(worker: Variant) -> void:
	route_queues.erase(String(worker.id))
	super._remove_worker(worker)

func _remove_combat_unit(unit: Variant) -> void:
	route_queues.erase(String(unit.id))
	super._remove_combat_unit(unit)

func _queue_selected_route_command(destination: Vector2, attack_move: bool) -> void:
	var selected_count: int = 0
	var formation_index: int = 0
	for unit: Variant in combat_units:
		if not bool(unit.selected):
			continue
		var unit_destination: Vector2 = _clamp_to_field(destination + _route_formation_offset(formation_index))
		_queue_or_issue_combat_route(unit, unit_destination, attack_move)
		selected_count += 1
		formation_index += 1
	for worker: Variant in workers:
		if not bool(worker.selected):
			continue
		var worker_destination: Vector2 = _clamp_to_field(destination + _route_formation_offset(formation_index))
		_queue_or_issue_worker_route(worker, worker_destination)
		selected_count += 1
		formation_index += 1
	if selected_count <= 0:
		mission_state = "Select units before queuing a route."
		return
	mission_state = "%d unit(s) received a queued %s route." % [selected_count, "attack-move" if attack_move else "movement"]
	_log_event("Queued route added for %d selected unit(s)." % selected_count)
	queue_redraw()

func _queue_or_issue_combat_route(unit: Variant, destination: Vector2, attack_move: bool) -> void:
	if _has_active_direct_order(unit):
		_append_route_point(String(unit.id), destination)
		return
	unit.target = destination
	unit.target_enemy_id = ""
	unit.order = "attack_move" if attack_move else "move"
	route_queues.erase(String(unit.id))

func _queue_or_issue_worker_route(worker: Variant, destination: Vector2) -> void:
	if String(worker.state) == "move" and worker.pos.distance_to(worker.target) > _route_arrival_radius():
		_append_route_point(String(worker.id), destination)
		return
	worker.target = destination
	worker.state = "move"
	worker.build_structure_id = ""
	route_queues.erase(String(worker.id))

func _has_active_direct_order(unit: Variant) -> bool:
	var order_name: String = String(unit.order)
	if order_name != "move" and order_name != "attack_move":
		return false
	return unit.pos.distance_to(unit.target) > _route_arrival_radius()

func _append_route_point(unit_id: String, destination: Vector2) -> void:
	var route: Array = _route_for(unit_id)
	if route.size() >= _max_route_waypoints():
		route.pop_front()
	route.append(destination)
	route_queues[unit_id] = route

func _advance_route_if_arrived(unit_id: String, agent: Variant) -> void:
	if agent.pos.distance_to(agent.target) > _route_arrival_radius():
		return
	var route: Array = _route_for(unit_id)
	if route.is_empty():
		return
	var next_target_value: Variant = route.pop_front()
	if next_target_value is Vector2:
		agent.target = next_target_value
	route_queues[unit_id] = route
	if route.is_empty():
		route_queues.erase(unit_id)

func _route_for(unit_id: String) -> Array:
	var stored: Variant = route_queues.get(unit_id, [])
	if stored is Array:
		return (stored as Array).duplicate()
	return []

func _route_formation_offset(index: int) -> Vector2:
	var column: int = index % 4
	var row: int = index / 4
	return Vector2(float(column * 18 - 27), float(row * 18 - 18))

func _draw_queued_routes() -> void:
	for worker: Variant in workers:
		_draw_agent_route(worker, Color("75e7ff"))
	for unit: Variant in combat_units:
		_draw_agent_route(unit, Color("7ef5d0"))

func _draw_agent_route(agent: Variant, route_color: Color) -> void:
	var route: Array = _route_for(String(agent.id))
	if route.is_empty():
		return
	var previous: Vector2 = agent.pos
	if agent.pos.distance_to(agent.target) > _route_arrival_radius():
		draw_line(previous, agent.target, Color(route_color, 0.55), 1.5)
		draw_circle(agent.target, 3.0, Color(route_color, 0.82))
		previous = agent.target
	for point_value: Variant in route:
		if not (point_value is Vector2):
			continue
		var point: Vector2 = point_value
		draw_line(previous, point, Color(route_color, 0.82), 1.5)
		draw_circle(point, 3.4, route_color)
		previous = point

func _route_arrival_radius() -> float:
	var queue_rules: Dictionary = _route_queue_rules()
	return maxf(4.0, float(queue_rules.get("arrival_radius", 14.0)))

func _max_route_waypoints() -> int:
	var queue_rules: Dictionary = _route_queue_rules()
	return clampi(int(queue_rules.get("max_waypoints", 6)), 1, 12)

func _route_queue_rules() -> Dictionary:
	var navigation: Dictionary = navigation_rules.get("navigation", {}) as Dictionary
	return navigation.get("route_queue", {}) as Dictionary
