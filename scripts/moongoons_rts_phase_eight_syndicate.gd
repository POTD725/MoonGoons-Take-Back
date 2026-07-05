extends "res://scripts/moongoons_rts_phase_seven_routes.gd"
## Phase Eight: first live Syndicate faction economy and doctrine progression.
## The enemy war chest grows from hideout income and active Siphon Arrays.

var syndicate_rules: Dictionary = {}
var syndicate_war_chest: float = 0.0
var syndicate_doctrine_index: int = 0
var previous_active_siphon_count: int = 0
var previous_captured_sector_count: int = 0

func _ready() -> void:
	syndicate_rules = _load_syndicate_rules()
	super._ready()
	mission_state = "Syndicate economy active. Cut Siphon Raids and reclaim sectors before the War Chest unlocks new doctrines."
	_log_event("Phase Eight online: Syndicate War Chest and doctrine progression are active.")
	queue_redraw()

func _reset_match() -> void:
	syndicate_war_chest = 0.0
	syndicate_doctrine_index = 0
	previous_active_siphon_count = 0
	previous_captured_sector_count = 0
	super._reset_match()

func _process(delta: float) -> void:
	super._process(delta)
	if game_over or victory:
		return
	_update_syndicate_economy(delta)
	queue_redraw()

func _spawn_enemy_wave() -> void:
	var previous_count: int = enemy_units.size()
	super._spawn_enemy_wave()
	for index: int in range(previous_count, enemy_units.size()):
		var enemy: Variant = enemy_units[index]
		_apply_syndicate_doctrines_to_enemy(enemy, index - previous_count)
	if syndicate_doctrine_index >= 3:
		var relay_doctrine: Dictionary = _doctrine_at(2)
		var minimum_interval: float = float(relay_doctrine.get("minimum_wave_interval_seconds", 5.0))
		var reduction: float = float(relay_doctrine.get("wave_timer_reduction_seconds", 2.0))
		enemy_spawn_clock = maxf(minimum_interval, enemy_spawn_clock - reduction)

func _draw_world() -> void:
	super._draw_world()
	_draw_syndicate_economy_panel()
	_draw_visible_shade_markers()

func _update_syndicate_economy(delta: float) -> void:
	var active_siphons: int = siphon_operations.size()
	var economy: Dictionary = _syndicate_economy_rules()
	var passive_income: float = float(economy.get("base_war_chest_income_per_second", 1.1))
	var siphon_income: float = float(economy.get("active_siphon_income_per_second", 2.2))
	syndicate_war_chest += delta * (passive_income + siphon_income * float(active_siphons))
	if active_siphons < previous_active_siphon_count:
		var loss_per_siphon: float = float(economy.get("siphon_neutralization_loss", 24.0))
		var lost_siphons: int = previous_active_siphon_count - active_siphons
		syndicate_war_chest = maxf(0.0, syndicate_war_chest - loss_per_siphon * float(lost_siphons))
		_log_event("Siphon neutralization disrupted Syndicate funding.")
	if captured_sector_count > previous_captured_sector_count:
		var loss_per_sector: float = float(economy.get("sector_recapture_loss", 18.0))
		var reclaimed_count: int = captured_sector_count - previous_captured_sector_count
		syndicate_war_chest = maxf(0.0, syndicate_war_chest - loss_per_sector * float(reclaimed_count))
		_log_event("Peacekeeper sector reclamation disrupted Syndicate funding.")
	previous_active_siphon_count = active_siphons
	previous_captured_sector_count = captured_sector_count
	_unlock_available_syndicate_doctrines()

func _unlock_available_syndicate_doctrines() -> void:
	var doctrines: Array = _syndicate_doctrines()
	while syndicate_doctrine_index < doctrines.size():
		var doctrine_value: Variant = doctrines[syndicate_doctrine_index]
		var doctrine: Dictionary = doctrine_value as Dictionary if doctrine_value is Dictionary else {}
		var required_chest: float = float(doctrine.get("war_chest_required", INF))
		if syndicate_war_chest < required_chest:
			return
		syndicate_doctrine_index += 1
		var label: String = String(doctrine.get("label", "SYNDICATE DOCTRINE"))
		mission_state = "Syndicate doctrine detected: %s. Adapt your patrols." % label
		_log_event("Enemy faction escalation: %s unlocked." % label)

func _apply_syndicate_doctrines_to_enemy(enemy: Variant, wave_index: int) -> void:
	if String(enemy.unit_type) == "runner" and syndicate_doctrine_index >= 1 and wave_index % 2 == 0:
		var ghost_protocol: Dictionary = _doctrine_at(0)
		var variant: Dictionary = ghost_protocol.get("runner_variant", {}) as Dictionary
		enemy.unit_type = String(variant.get("unit_type", "shade"))
		enemy.max_hp = float(variant.get("integrity", 52.0))
		enemy.hp = enemy.max_hp
		enemy.speed = float(variant.get("speed", 92.0))
		enemy.attack_range = float(variant.get("attack_range", 62.0))
		enemy.damage = float(variant.get("damage", 13.0))
		enemy.cooldown_duration = float(variant.get("cooldown_seconds", 0.5))
		enemy.tint = Color("ad74ff")
	elif String(enemy.unit_type) == "bruiser" and syndicate_doctrine_index >= 2:
		var forge: Dictionary = _doctrine_at(1)
		var bonus: Dictionary = forge.get("bruiser_bonus", {}) as Dictionary
		var hp_multiplier: float = float(bonus.get("integrity_multiplier", 1.28))
		var damage_multiplier: float = float(bonus.get("damage_multiplier", 1.25))
		enemy.max_hp *= hp_multiplier
		enemy.hp = enemy.max_hp
		enemy.damage *= damage_multiplier
		enemy.tint = Color("ffbd69")

func _draw_syndicate_economy_panel() -> void:
	var panel: Rect2 = Rect2(632.0, 98.0, 312.0, 58.0)
	draw_style_box(_panel_style(Color("33142f", 0.94), Color("c56ef5"), 1, 8), panel)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(11.0, 18.0), "SYNDICATE WAR CHEST", HORIZONTAL_ALIGNMENT_LEFT, 160.0, 11, Color("f2c8ff"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(174.0, 18.0), "%03d" % int(syndicate_war_chest), HORIZONTAL_ALIGNMENT_RIGHT, 126.0, 14, Color("fff0ff"))
	var doctrine_label: String = "BASE OPERATIONS"
	if syndicate_doctrine_index > 0:
		doctrine_label = String(_doctrine_at(syndicate_doctrine_index - 1).get("label", "ACTIVE DOCTRINE"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(11.0, 36.0), "ACTIVE: %s" % doctrine_label, HORIZONTAL_ALIGNMENT_LEFT, 290.0, 9, Color("dca6f5"))
	var next_label: String = "ALL DOCTRINES UNLOCKED"
	if syndicate_doctrine_index < _syndicate_doctrines().size():
		var next_doctrine: Dictionary = _doctrine_at(syndicate_doctrine_index)
		next_label = "NEXT: %s @ %d" % [String(next_doctrine.get("label", "UNKNOWN")), int(float(next_doctrine.get("war_chest_required", 0.0)))]
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(11.0, 51.0), next_label, HORIZONTAL_ALIGNMENT_LEFT, 290.0, 8, Color("b97ccc"))

func _draw_visible_shade_markers() -> void:
	for enemy: Variant in enemy_units:
		if String(enemy.unit_type) != "shade" or not _is_point_visible(enemy.pos):
			continue
		draw_circle(enemy.pos, 19.0, Color("ad74ff", 0.12))
		draw_arc(enemy.pos, 19.0, 0.0, TAU, 18, Color("d8b8ff"), 1.5)
		draw_string(ThemeDB.fallback_font, enemy.pos + Vector2(-22.0, -25.0), "SHADE", HORIZONTAL_ALIGNMENT_CENTER, 44.0, 8, Color("e9d6ff"))

func _syndicate_economy_rules() -> Dictionary:
	return syndicate_rules.get("syndicate_economy", {}) as Dictionary

func _syndicate_doctrines() -> Array:
	var doctrines: Variant = syndicate_rules.get("doctrines", [])
	if doctrines is Array:
		return doctrines as Array
	return []

func _doctrine_at(index: int) -> Dictionary:
	var doctrines: Array = _syndicate_doctrines()
	if index < 0 or index >= doctrines.size():
		return {}
	var doctrine: Variant = doctrines[index]
	if doctrine is Dictionary:
		return doctrine as Dictionary
	return {}

func _load_syndicate_rules() -> Dictionary:
	var path: String = "res://data/rts_phase_eight_syndicate.json"
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
