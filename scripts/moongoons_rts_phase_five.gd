extends "res://scripts/moongoons_rts_phase_four.gd"
## Phase Five: Syndicate Siphon Raids and counter-operations.
## Siphon teams anchor on resource nodes, drain the site and matching stockpile,
## and must be located through scouting or Tactical Scan before they are neutralized.

var siphon_rules: Dictionary = {}
var siphon_operations: Dictionary = {}
var siphon_deployment_clock: float = 0.0

func _ready() -> void:
	siphon_rules = _load_siphon_rules()
	super._ready()
	mission_state = "Hold the frontier. Locate Siphon Raids before the Syndicate empties the lunar economy."
	_log_event("Phase Five online: Syndicate Siphon Raids can now target lunar resource nodes.")
	queue_redraw()

func _reset_match() -> void:
	siphon_operations.clear()
	siphon_deployment_clock = float(_siphon_config().get("first_deployment_seconds", 24.0))
	super._reset_match()

func _process(delta: float) -> void:
	super._process(delta)
	if game_over or victory:
		return
	siphon_deployment_clock -= delta
	if siphon_deployment_clock <= 0.0:
		_deploy_siphon_raid()
		siphon_deployment_clock = float(_siphon_config().get("deployment_interval_seconds", 34.0))
	_update_siphon_operations(delta)
	queue_redraw()

func _draw_world() -> void:
	super._draw_world()
	_draw_visible_siphon_markers()
	_draw_siphon_status_panel()

func _draw_visible_siphon_markers() -> void:
	for enemy: Variant in enemy_units:
		if String(enemy.unit_type) != "siphon" or not _is_point_visible(enemy.pos):
			continue
		var core_color: Color = Color("cf78ff")
		draw_circle(enemy.pos, 30.0, Color(core_color, 0.10))
		draw_circle(enemy.pos, 19.0, Color("31194b"))
		draw_arc(enemy.pos, 19.0, 0.0, TAU, 20, core_color, 2.0)
		draw_line(enemy.pos + Vector2(-12.0, -8.0), enemy.pos + Vector2(12.0, 8.0), core_color, 3.0)
		draw_line(enemy.pos + Vector2(-12.0, 8.0), enemy.pos + Vector2(12.0, -8.0), core_color, 3.0)
		draw_circle(enemy.pos, 6.0, Color("fff0ff"))
		_draw_health_bar(enemy.pos + Vector2(-22.0, -31.0), enemy.hp / enemy.max_hp, core_color, 44.0)
		draw_string(ThemeDB.fallback_font, enemy.pos + Vector2(-33.0, 35.0), "SIPHON ARRAY", HORIZONTAL_ALIGNMENT_CENTER, 66.0, 9, Color("f5d9ff"))

func _deploy_siphon_raid() -> void:
	var candidate_indices: Array[int] = []
	for node_index: int in range(resource_nodes.size()):
		var node: Variant = resource_nodes[node_index]
		if int(node.amount) > 0 and not _node_has_active_siphon(node_index):
			candidate_indices.append(node_index)
	if candidate_indices.is_empty():
		return
	var selected_position: int = rng.randi_range(0, candidate_indices.size() - 1)
	var target_node_index: int = candidate_indices[selected_position]
	var carrier: Variant = _find_or_create_siphon_carrier()
	if carrier == null:
		return
	var target_node: Variant = resource_nodes[target_node_index]
	var offset: Vector2 = Vector2(rng.randf_range(-18.0, 18.0), rng.randf_range(-18.0, 18.0))
	carrier.unit_type = "siphon"
	carrier.pos = target_node.pos + offset
	carrier.hp = float(_siphon_config().get("integrity", 230.0))
	carrier.max_hp = carrier.hp
	carrier.speed = 0.0
	carrier.attack_range = 0.0
	carrier.damage = 0.0
	carrier.cooldown_duration = 1.0
	carrier.cooldown = 0.0
	carrier.tint = Color("cf78ff")
	siphon_operations[String(carrier.id)] = {
		"node_index": target_node_index,
		"resource_id": String(target_node.resource_id),
		"drain_clock": 0.0,
		"self_terminated": false
	}
	mission_state = String(_siphon_config().get("warning_text", "Syndicate signal anomaly detected."))
	_log_event("Counter-intelligence alert: a Siphon Raid has entered the lunar field.")

func _find_or_create_siphon_carrier() -> Variant:
	for enemy: Variant in enemy_units:
		if String(enemy.unit_type) == "runner":
			return enemy
	super._spawn_enemy_wave()
	for enemy: Variant in enemy_units:
		if String(enemy.unit_type) == "runner":
			return enemy
	return null

func _update_siphon_operations(delta: float) -> void:
	var stale_operation_ids: Array[String] = []
	for operation_id_value: Variant in siphon_operations.keys():
		var operation_id: String = String(operation_id_value)
		var operation: Dictionary = siphon_operations.get(operation_id, {}) as Dictionary
		var carrier: Variant = _enemy_by_id(operation_id)
		if carrier == null:
			if not bool(operation.get("self_terminated", false)):
				intel += int(_siphon_config().get("neutralize_intel_bonus", 3))
				_log_event("Siphon Array neutralized. Counter-intelligence recovered +%d Intel." % int(_siphon_config().get("neutralize_intel_bonus", 3)))
			stale_operation_ids.append(operation_id)
			continue
		var target_node_index: int = int(operation.get("node_index", -1))
		if target_node_index < 0 or target_node_index >= resource_nodes.size():
			operation["self_terminated"] = true
			carrier.hp = 0.0
			siphon_operations[operation_id] = operation
			continue
		var target_node: Variant = resource_nodes[target_node_index]
		if int(target_node.amount) <= 0:
			operation["self_terminated"] = true
			carrier.hp = 0.0
			siphon_operations[operation_id] = operation
			_log_event("Siphon Array lost its resource source and shut down.")
			continue
		var drain_clock: float = float(operation.get("drain_clock", 0.0)) + delta
		var drain_interval: float = float(_siphon_config().get("drain_interval_seconds", 3.5))
		if drain_clock < drain_interval:
			operation["drain_clock"] = drain_clock
			siphon_operations[operation_id] = operation
			continue
		operation["drain_clock"] = 0.0
		siphon_operations[operation_id] = operation
		_execute_siphon_drain(target_node, String(operation.get("resource_id", "credits")))
	for stale_id: String in stale_operation_ids:
		siphon_operations.erase(stale_id)

func _execute_siphon_drain(target_node: Variant, resource_id: String) -> void:
	var node_drain_limit: int = int(_siphon_config().get("node_drain_amount", 8))
	var node_drain: int = mini(node_drain_limit, int(target_node.amount))
	target_node.amount -= node_drain
	var stockpile_drain_limit: int = int(_siphon_config().get("stockpile_drain_amount", 5))
	var stockpile_drain: int = 0
	if resource_id == "lunar_alloy":
		stockpile_drain = mini(stockpile_drain_limit, lunar_alloy)
		lunar_alloy = maxi(0, lunar_alloy - stockpile_drain)
	else:
		stockpile_drain = mini(stockpile_drain_limit, credits)
		credits = maxi(0, credits - stockpile_drain)
	_log_event("Siphon Raid stole %d node units and %d %s from stockpile." % [node_drain, stockpile_drain, _sector_resource_label(resource_id)])

func _node_has_active_siphon(node_index: int) -> bool:
	for operation_value: Variant in siphon_operations.values():
		if operation_value is Dictionary and int((operation_value as Dictionary).get("node_index", -1)) == node_index:
			return true
	return false

func _draw_siphon_status_panel() -> void:
	var panel: Rect2 = Rect2(450.0, 618.0, 500.0, 62.0)
	var operation_count: int = siphon_operations.size()
	var active: bool = operation_count > 0
	var fill: Color = Color("391b43", 0.92) if active else Color("102238", 0.92)
	var border: Color = Color("cf78ff") if active else Color("476d87")
	draw_style_box(_panel_style(fill, border, 1, 8), panel)
	var title: String = "COUNTER-INTELLIGENCE ALERT" if active else "COUNTER-INTELLIGENCE"
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12.0, 20.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("f3dcff") if active else Color("a9cae2"))
	var detail: String = "No active Siphon signals. Next intercept window: %0.0fs." % maxf(0.0, siphon_deployment_clock)
	if active:
		detail = "%d Siphon Array(s) active. Scout the fog or use Tactical Scan, then destroy the array." % operation_count
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12.0, 41.0), detail, HORIZONTAL_ALIGNMENT_LEFT, 474.0, 11, Color("f3e8ff") if active else Color("b7d5e6"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12.0, 57.0), "Neutralized arrays recover bonus Intel. Unchecked arrays drain the node and matching stockpile.", HORIZONTAL_ALIGNMENT_LEFT, 474.0, 9, Color("c9a8da") if active else Color("84a8c1"))

func _siphon_config() -> Dictionary:
	return siphon_rules.get("siphon_raids", {}) as Dictionary

func _load_siphon_rules() -> Dictionary:
	var path: String = "res://data/rts_phase_five_siphon_raids.json"
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
