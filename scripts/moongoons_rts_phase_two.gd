extends "res://scripts/moongoons_rts_match_launch.gd"
## Phase Two: data-driven production, control groups, rally points,
## auto-harvest, adaptive pressure, and Riot Vanguard Shield Wall.

var game_data: MoonGoonsGameData = MoonGoonsGameData.new()
var phase_rules: Dictionary = {}
var control_groups: Dictionary = {}
var shield_wall_states: Dictionary = {}
var nexus_rally_point := Vector2.ZERO
var armory_rally_point := Vector2.ZERO
var enemy_response_stage := 0

func _ready() -> void:
	nexus_rally_point = NEXUS_POSITION + Vector2(92.0, 76.0)
	armory_rally_point = NEXUS_POSITION + Vector2(124.0, 42.0)
	super._ready()
	if not game_data.load_all():
		_log_event("Data catalog fallback active. RTS values are using safe local defaults.")
	phase_rules = _load_phase_rules()
	mission_state = "Harvest, expand capacity, assemble a force, and destroy the Syndicate hideout."
	_log_event("Phase Two command systems online: control groups, rally points, and Shield Wall.")
	queue_redraw()

func _process(delta: float) -> void:
	var pre_shield_health: Dictionary = _capture_shielded_health()
	super._process(delta)
	if game_over or victory:
		return
	_resolve_shield_wall(delta, pre_shield_health)
	_auto_assign_idle_workers()
	_update_enemy_response()
	queue_redraw()

func _handle_hotkey(keycode: Key) -> void:
	if keycode >= KEY_1 and keycode <= KEY_5:
		var group_id: int = int(keycode) - int(KEY_0)
		if Input.is_key_pressed(KEY_SHIFT):
			_assign_control_group(group_id)
		else:
			_recall_control_group(group_id)
		return
	match keycode:
		KEY_H:
			_hold_selected_combat_units()
			return
		KEY_S:
			_activate_shield_wall()
			return
		_:
			super._handle_hotkey(keycode)

func _handle_right_click(cursor: Vector2) -> void:
	if Input.is_key_pressed(KEY_SHIFT) and FIELD.has_point(cursor):
		_set_rally_points(cursor)
		return
	super._handle_right_click(cursor)

func _queue_deputy() -> void:
	var profile: Dictionary = game_data.get_unit("lunar_peacekeepers", "pk_patrol_deputy")
	if profile.is_empty():
		super._queue_deputy()
		return
	var cost: Dictionary = profile.get("cost", {})
	var credit_cost: int = int(cost.get("credits", DEPUTY_COST_CREDITS))
	var alloy_cost: int = int(cost.get("lunar_alloy", 0))
	var capacity_cost: int = int(cost.get("command_capacity", DEPUTY_CAPACITY))
	if not _can_afford(credit_cost, alloy_cost, capacity_cost):
		mission_state = "Need Credits, Lunar Alloy, and Command Capacity for a Patrol Deputy."
		return
	_spend(credit_cost, alloy_cost, capacity_cost)
	nexus_queue.append({"unit_type": "deputy", "remaining": 5.0})
	_log_event("Patrol Deputy queued from the live unit catalog.")

func _queue_vanguard() -> void:
	if not _has_complete_structure("armory"):
		mission_state = "Tactical Armory required before Riot Vanguard production."
		return
	var profile: Dictionary = game_data.get_unit("lunar_peacekeepers", "pk_riot_vanguard")
	if profile.is_empty():
		super._queue_vanguard()
		return
	var cost: Dictionary = profile.get("cost", {})
	var credit_cost: int = int(cost.get("credits", VANGUARD_COST_CREDITS))
	var alloy_cost: int = int(cost.get("lunar_alloy", VANGUARD_COST_ALLOY))
	var capacity_cost: int = int(cost.get("command_capacity", VANGUARD_CAPACITY))
	if not _can_afford(credit_cost, alloy_cost, capacity_cost):
		mission_state = "Need Credits, Lunar Alloy, and 2 Command Capacity for a Riot Vanguard."
		return
	_spend(credit_cost, alloy_cost, capacity_cost)
	armory_queue.append({"unit_type": "vanguard", "remaining": 8.0})
	_log_event("Riot Vanguard queued from the live unit catalog.")

func _spawn_combat_unit(unit_type: String, spawn_position: Vector2) -> void:
	super._spawn_combat_unit(unit_type, spawn_position)
	if combat_units.is_empty():
		return
	var unit: Variant = combat_units[combat_units.size() - 1]
	if unit_type == "vanguard":
		shield_wall_states[unit.id] = {"remaining": 0.0, "cooldown": 0.0, "barrier": 0.0}
		unit.target = armory_rally_point
	else:
		unit.target = nexus_rally_point
	unit.order = "move"

func _draw_world() -> void:
	super._draw_world()
	_draw_rally_marker(nexus_rally_point, Color("65e9ff"), "NEXUS RALLY")
	if _has_complete_structure("armory"):
		_draw_rally_marker(armory_rally_point, Color("7ef5d0"), "ARMORY RALLY")
	_draw_shield_wall_effects()

func _draw_sidebar() -> void:
	super._draw_sidebar()
	var group_text := _control_group_summary()
	draw_string(ThemeDB.fallback_font, Vector2(994.0, 688.0), group_text, HORIZONTAL_ALIGNMENT_LEFT, 248.0, 9, Color("a9c6d8"))

func _assign_control_group(group_id: int) -> void:
	var tokens: Array[String] = []
	for worker: Variant in workers:
		if worker.selected:
			tokens.append("worker:%s" % String(worker.id))
	for unit: Variant in combat_units:
		if unit.selected:
			tokens.append("combat:%s" % String(unit.id))
	if tokens.is_empty():
		mission_state = "Select units before assigning a control group."
		return
	control_groups[group_id] = tokens
	mission_state = "Control group %d assigned with %d unit(s)." % [group_id, tokens.size()]
	_log_event("Control group %d assigned." % group_id)

func _recall_control_group(group_id: int) -> void:
	var tokens: Variant = control_groups.get(group_id, [])
	if not (tokens is Array) or (tokens as Array).is_empty():
		mission_state = "Control group %d is empty." % group_id
		return
	_clear_selection()
	var selected_count := 0
	for token_value: Variant in tokens as Array:
		var token := String(token_value)
		if token.begins_with("worker:"):
			var worker_id := token.trim_prefix("worker:")
			for worker: Variant in workers:
				if String(worker.id) == worker_id:
					worker.selected = true
					selected_count += 1
		elif token.begins_with("combat:"):
			var unit_id := token.trim_prefix("combat:")
			for unit: Variant in combat_units:
				if String(unit.id) == unit_id:
					unit.selected = true
					selected_count += 1
	mission_state = "Control group %d recalled: %d unit(s)." % [group_id, selected_count]

func _hold_selected_combat_units() -> void:
	var held_count := 0
	for unit: Variant in combat_units:
		if unit.selected:
			unit.order = "hold"
			unit.target_enemy_id = ""
			unit.target = unit.pos
			held_count += 1
	if held_count > 0:
		mission_state = "%d combat unit(s) holding position." % held_count

func _activate_shield_wall() -> void:
	var ability: Dictionary = _shield_wall_rules()
	var duration: float = float(ability.get("duration_seconds", 6.0))
	var cooldown: float = float(ability.get("cooldown_seconds", 14.0))
	var activated_count := 0
	for unit: Variant in combat_units:
		if not unit.selected or String(unit.unit_type) != "vanguard":
			continue
		var state: Dictionary = shield_wall_states.get(String(unit.id), {"remaining": 0.0, "cooldown": 0.0, "barrier": 0.0})
		if float(state.get("remaining", 0.0)) > 0.0 or float(state.get("cooldown", 0.0)) > 0.0:
			continue
		state["remaining"] = duration
		state["cooldown"] = cooldown
		state["barrier"] = 90.0
		shield_wall_states[unit.id] = state
		unit.order = "hold"
		unit.target = unit.pos
		unit.speed = 40.0
		activated_count += 1
	if activated_count > 0:
		mission_state = "Shield Wall active. Riot Vanguards brace and absorb incoming fire."
		_log_event("%d Riot Vanguard Shield Wall(s) activated." % activated_count)
	else:
		mission_state = "Select ready Riot Vanguards to activate Shield Wall."

func _capture_shielded_health() -> Dictionary:
	var result: Dictionary = {}
	for unit: Variant in combat_units:
		var state: Dictionary = shield_wall_states.get(String(unit.id), {})
		if float(state.get("remaining", 0.0)) > 0.0:
			result[unit.id] = float(unit.hp)
	return result

func _resolve_shield_wall(delta: float, health_before: Dictionary) -> void:
	for unit: Variant in combat_units:
		if String(unit.unit_type) != "vanguard":
			continue
		var state: Dictionary = shield_wall_states.get(String(unit.id), {"remaining": 0.0, "cooldown": 0.0, "barrier": 0.0})
		var remaining: float = maxf(0.0, float(state.get("remaining", 0.0)) - delta)
		var cooldown: float = maxf(0.0, float(state.get("cooldown", 0.0)) - delta)
		if health_before.has(unit.id):
			var before_hp: float = float(health_before.get(unit.id, unit.hp))
			var damage_taken: float = maxf(0.0, before_hp - float(unit.hp))
			var barrier: float = float(state.get("barrier", 0.0))
			var absorbed: float = minf(damage_taken * 0.55, barrier)
			unit.hp = minf(unit.max_hp, unit.hp + absorbed)
			state["barrier"] = maxf(0.0, barrier - absorbed)
		state["remaining"] = remaining
		state["cooldown"] = cooldown
		if remaining <= 0.0:
			unit.speed = 72.0
		shield_wall_states[unit.id] = state

func _auto_assign_idle_workers() -> void:
	for worker: Variant in workers:
		if String(worker.state) != "idle":
			continue
		var resource_index := _best_auto_resource_for(worker.pos)
		if resource_index < 0:
			continue
		worker.resource_node_index = resource_index
		worker.state = "to_resource"
		var node: Variant = resource_nodes[resource_index]
		worker.target = node.pos

func _best_auto_resource_for(origin: Vector2) -> int:
	var desired_resource := "lunar_alloy" if lunar_alloy < 40 else "credits"
	var best_index := -1
	var best_distance := INF
	for index: int in range(resource_nodes.size()):
		var node: Variant = resource_nodes[index]
		if int(node.amount) <= 0 or String(node.resource_id) != desired_resource:
			continue
		var distance: float = origin.distance_squared_to(node.pos)
		if distance < best_distance:
			best_index = index
			best_distance = distance
	if best_index >= 0:
		return best_index
	for index: int in range(resource_nodes.size()):
		var node: Variant = resource_nodes[index]
		if int(node.amount) > 0:
			return index
	return -1

func _set_rally_points(destination: Vector2) -> void:
	nexus_rally_point = destination
	armory_rally_point = destination + Vector2(26.0, 18.0)
	mission_state = "Production rally point set. New units will deploy toward the marker."
	_log_event("Nexus and Armory rally points updated.")

func _update_enemy_response() -> void:
	var deputy_count := 0
	var vanguard_count := 0
	var relay_count := 0
	for unit: Variant in combat_units:
		if String(unit.unit_type) == "vanguard":
			vanguard_count += 1
		else:
			deputy_count += 1
	for structure: Variant in structures:
		if String(structure.structure_type) == "relay" and bool(structure.complete):
			relay_count += 1
	var score := deputy_count + vanguard_count * 2 + relay_count
	if score >= 7 and enemy_response_stage == 0:
		enemy_response_stage = 1
		enemy_spawn_clock = minf(enemy_spawn_clock, 4.0)
		_log_event("Syndicate scouts detect your expansion. Raids are accelerating.")
	elif score >= 12 and enemy_response_stage == 1:
		enemy_response_stage = 2
		enemy_spawn_clock = minf(enemy_spawn_clock, 3.0)
		_log_event("Syndicate command escalates: Bruiser pressure expected at the resource line.")

func _draw_rally_marker(position: Vector2, color: Color, label: String) -> void:
	if not FIELD.has_point(position):
		return
	draw_arc(position, 19.0, 0.0, TAU, 18, Color(color, 0.8), 1.5)
	draw_line(position + Vector2(-10.0, 0.0), position + Vector2(10.0, 0.0), color, 1.5)
	draw_line(position + Vector2(0.0, -10.0), position + Vector2(0.0, 10.0), color, 1.5)
	draw_string(ThemeDB.fallback_font, position + Vector2(-30.0, 34.0), label, HORIZONTAL_ALIGNMENT_LEFT, 70.0, 9, color)

func _draw_shield_wall_effects() -> void:
	for unit: Variant in combat_units:
		var state: Dictionary = shield_wall_states.get(String(unit.id), {})
		if float(state.get("remaining", 0.0)) <= 0.0:
			continue
		draw_arc(unit.pos, 27.0, -PI * 0.82, PI * 0.82, 18, Color("7ef5d0"), 3.0)
		draw_arc(unit.pos, 31.0, -PI * 0.82, PI * 0.82, 18, Color("dffff5", 0.5), 1.0)

func _control_group_summary() -> String:
	var pieces: Array[String] = []
	for group_id: int in [1, 2, 3, 4, 5]:
		var members: Variant = control_groups.get(group_id, [])
		if members is Array and not (members as Array).is_empty():
			pieces.append("%d:%d" % [group_id, (members as Array).size()])
	return "Groups: %s // Shift+Right-click: rally" % (" ".join(pieces) if not pieces.is_empty() else "none")

func _shield_wall_rules() -> Dictionary:
	var factions: Dictionary = phase_rules.get("peacekeeper_runtime", {})
	var vanguard: Dictionary = factions.get("riot_vanguard", {})
	return vanguard.get("active_ability", {}) as Dictionary

func _load_phase_rules() -> Dictionary:
	var path := "res://data/rts_phase_two_rules.json"
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
