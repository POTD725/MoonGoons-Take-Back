extends Node2D
## Compact tactical patrol encounter used by the multi-view precinct hub.

const VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)

var officer_units: Array[Dictionary] = []
var enemy_hp: int = 1
var enemy_max_hp: int = 1
var enemy_power: int = 10
var battle_over: bool = false
var victory: bool = false
var auto_mode: bool = false
var auto_clock: float = 0.0
var pulse: float = 0.0
var turn_number: int = 1
var status_message: String = "Patrol entering the combat zone."
var combat_log: Array[String] = []
var button_rects: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	_configure_buttons()
	if PrecinctState.active_call.is_empty():
		get_tree().call_deferred("change_scene_to_file", "res://scenes/PrecinctVerticalSlice.tscn")
		return
	_setup_battle()
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	if auto_mode and not battle_over:
		auto_clock += delta
		if auto_clock >= 0.75:
			auto_clock = 0.0
			_execute_action("attack")
	queue_redraw()

func _input(event: InputEvent) -> void:
	var point: Vector2 = Vector2.ZERO
	var pressed: bool = false
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		point = mouse_event.position
		pressed = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		point = touch_event.position
		pressed = touch_event.pressed
	if not pressed:
		return
	for action_value: Variant in button_rects.keys():
		var action: String = String(action_value)
		if (button_rects[action] as Rect2).has_point(point):
			_handle_button(action)
			return

func _draw() -> void:
	_draw_backdrop()
	_draw_header()
	_draw_arena()
	_draw_units()
	_draw_enemy()
	_draw_log_panel()
	_draw_commands()

func _configure_buttons() -> void:
	button_rects = {
		"attack": Rect2(42.0, 632.0, 150.0, 48.0),
		"cover": Rect2(204.0, 632.0, 150.0, 48.0),
		"special": Rect2(366.0, 632.0, 150.0, 48.0),
		"auto": Rect2(528.0, 632.0, 150.0, 48.0),
		"retreat": Rect2(690.0, 632.0, 150.0, 48.0),
		"return": Rect2(1000.0, 632.0, 220.0, 48.0)
	}

func _setup_battle() -> void:
	for index: int in range(PrecinctState.active_officers().size()):
		var source: Dictionary = PrecinctState.active_officers()[index]
		officer_units.append({
			"id": String(source.get("id", "")),
			"name": String(source.get("name", "Officer")),
			"class": String(source.get("class", "Guard")),
			"power": int(source.get("power", 50)),
			"defense": int(source.get("defense", 10)),
			"hp": int(source.get("hp", 100)),
			"max_hp": int(source.get("max_hp", 100)),
			"special_ready": true,
			"covering": false,
			"position": Vector2(215.0, 238.0 + float(index) * 115.0)
		})
	enemy_max_hp = int(PrecinctState.active_call.get("enemy_hp", 120))
	enemy_hp = enemy_max_hp
	enemy_power = int(PrecinctState.active_call.get("enemy_power", 14))
	status_message = "CONTACT // %s" % String(PrecinctState.active_call.get("title", "Syndicate threat"))
	_add_log("Patrol entered %s." % String(PrecinctState.active_call.get("sector", "the sector")))
	_add_log("Use ATTACK, COVER, SPECIAL, or AUTO.")

func _handle_button(action: String) -> void:
	if action == "return":
		if battle_over:
			get_tree().change_scene_to_file("res://scenes/PrecinctVerticalSlice.tscn")
		else:
			status_message = "Resolve or retreat before returning."
		return
	if battle_over:
		return
	if action == "auto":
		auto_mode = not auto_mode
		status_message = "AUTO PATROL ENABLED" if auto_mode else "AUTO PATROL DISABLED"
		return
	if action == "retreat":
		_finish_battle(false, "Patrol withdrew under pressure.")
		return
	_execute_action(action)

func _execute_action(action: String) -> void:
	if battle_over:
		return
	if _living_count() <= 0:
		_finish_battle(false, "The patrol was overwhelmed.")
		return
	var total_damage: int = 0
	match action:
		"attack":
			for unit: Dictionary in officer_units:
				if int(unit.get("hp", 0)) <= 0:
					continue
				unit["covering"] = false
				total_damage += max(5, int(unit.get("power", 50)) / 7) + rng.randi_range(0, 6)
			status_message = "Coordinated volley dealt %d damage." % total_damage
			_add_log("Turn %d: attack dealt %d." % [turn_number, total_damage])
		"cover":
			for unit: Dictionary in officer_units:
				if int(unit.get("hp", 0)) > 0:
					unit["covering"] = true
			status_message = "Patrol formed a defensive shield line."
			_add_log("Turn %d: officers moved into cover." % turn_number)
		"special":
			var used: int = 0
			for unit: Dictionary in officer_units:
				if int(unit.get("hp", 0)) <= 0 or not bool(unit.get("special_ready", false)):
					continue
				unit["special_ready"] = false
				unit["covering"] = false
				used += 1
				var role_name: String = String(unit.get("class", "Guard"))
				if role_name == "Guard":
					total_damage += 15
					unit["hp"] = min(int(unit.get("max_hp", 100)), int(unit.get("hp", 1)) + 10)
				elif role_name == "Biker":
					total_damage += 25
				else:
					total_damage += 31
			if used <= 0:
				status_message = "Special abilities have already been used."
				return
			status_message = "%d special ability(s) dealt %d damage." % [used, total_damage]
			_add_log("Turn %d: specials dealt %d." % [turn_number, total_damage])
		_:
			return
	if total_damage > 0:
		enemy_hp = max(0, enemy_hp - total_damage)
	if enemy_hp <= 0:
		_finish_battle(true, "Suspect subdued and placed under arrest.")
		return
	_enemy_turn()
	turn_number += 1

func _enemy_turn() -> void:
	var candidates: Array[int] = []
	for index: int in range(officer_units.size()):
		if int(officer_units[index].get("hp", 0)) > 0:
			candidates.append(index)
	if candidates.is_empty():
		_finish_battle(false, "The patrol was overwhelmed.")
		return
	var target_index: int = candidates[rng.randi_range(0, candidates.size() - 1)]
	var target: Dictionary = officer_units[target_index]
	var mitigation: int = int(target.get("defense", 0)) / 4
	if bool(target.get("covering", false)):
		mitigation += 12
	var damage: int = max(3, enemy_power + rng.randi_range(0, 7) - mitigation)
	target["hp"] = max(0, int(target.get("hp", 1)) - damage)
	target["covering"] = false
	_add_log("Syndicate fire hit %s for %d." % [String(target.get("name", "Officer")), damage])
	if _living_count() <= 0:
		_finish_battle(false, "The patrol was overwhelmed.")

func _finish_battle(won: bool, message: String) -> void:
	if battle_over:
		return
	battle_over = true
	victory = won
	auto_mode = false
	status_message = message
	_add_log("PATROL SECURED" if won else "PATROL FAILED")
	var hp_results: Dictionary = {}
	for unit: Dictionary in officer_units:
		hp_results[String(unit.get("id", ""))] = max(1, int(unit.get("hp", 1)))
	PrecinctState.finish_patrol(won, hp_results)
	queue_redraw()

func _living_count() -> int:
	var total: int = 0
	for unit: Dictionary in officer_units:
		if int(unit.get("hp", 0)) > 0:
			total += 1
	return total

func _draw_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("020710"))
	for index: int in range(95):
		var x: float = fmod(float(index * 83 + 17), 1280.0)
		var y: float = fmod(float(index * 47 + 29), 720.0)
		draw_circle(Vector2(x, y), 1.0 + float(index % 2), Color("b5d5ff", 0.22))

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 92.0), Color("101a32"), true)
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 35.0), "MOONGOONS PATROL COMBAT", HORIZONTAL_ALIGNMENT_LEFT, 440.0, 23, Color("eafcff"))
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 64.0), "%s // %s // TURN %d" % [String(PrecinctState.active_call.get("title", "ACTIVE PATROL")).to_upper(), String(PrecinctState.active_call.get("sector", "UNKNOWN SECTOR")).to_upper(), turn_number], HORIZONTAL_ALIGNMENT_LEFT, 720.0, 12, Color("82e6ff"))

func _draw_arena() -> void:
	_panel(Rect2(28.0, 104.0, 920.0, 500.0), Color("071421"), Color("4db7d6"), 14)
	for row: int in range(8):
		var y: float = 118.0 + float(row) * 58.0
		draw_line(Vector2(42.0, y), Vector2(930.0, y + 70.0), Color("69d9ff", 0.045), 1.0)

func _draw_units() -> void:
	for unit: Dictionary in officer_units:
		var center: Vector2 = unit.get("position", Vector2.ZERO) as Vector2
		var hp: int = int(unit.get("hp", 0))
		var max_hp: int = int(unit.get("max_hp", 1))
		var role_name: String = String(unit.get("class", "Guard"))
		var body: Color = Color("5dd8e8")
		if role_name == "Biker": body = Color("c47cff")
		elif role_name == "Marksman": body = Color("f4c86d")
		if hp <= 0: body = Color("343944")
		if bool(unit.get("covering", false)) and hp > 0:
			draw_arc(center, 44.0 + sin(pulse * 3.0) * 2.0, -2.5, 0.5, 28, Color("8cf4ff", 0.78), 5.0)
		draw_circle(center, 34.0, Color("06101b"))
		draw_circle(center, 29.0, body)
		draw_string(ThemeDB.fallback_font, center + Vector2(-72.0, 56.0), String(unit.get("name", "Officer")), HORIZONTAL_ALIGNMENT_CENTER, 144.0, 11, Color("eafcff"))
		_health_bar(Rect2(center + Vector2(-58.0, 78.0), Vector2(116.0, 10.0)), hp, max_hp, Color("55e4bd"))

func _draw_enemy() -> void:
	var center: Vector2 = Vector2(717.0, 322.0)
	var danger: Color = Color("ff557a") if enemy_hp > 0 else Color("3b3540")
	for ring: int in range(3):
		draw_arc(center, 60.0 + float(ring) * 14.0 + sin(pulse * 2.0 + float(ring)) * 3.0, 0.0, TAU, 36, Color(danger.r, danger.g, danger.b, 0.18 - float(ring) * 0.035), 3.0)
	draw_circle(center, 52.0, Color("170711"))
	draw_circle(center, 45.0, danger)
	draw_string(ThemeDB.fallback_font, center + Vector2(-95.0, 77.0), "SYNDICATE SUSPECT", HORIZONTAL_ALIGNMENT_CENTER, 190.0, 13, Color("ffeaf0"))
	_health_bar(Rect2(center + Vector2(-85.0, 94.0), Vector2(170.0, 12.0)), enemy_hp, enemy_max_hp, danger)

func _draw_log_panel() -> void:
	_panel(Rect2(966.0, 104.0, 286.0, 500.0), Color("071421"), Color("4db7d6"), 14)
	draw_string(ThemeDB.fallback_font, Vector2(982.0, 132.0), "TACTICAL FEED", HORIZONTAL_ALIGNMENT_LEFT, 190.0, 13, Color("8deaff"))
	for index: int in range(combat_log.size()):
		draw_string(ThemeDB.fallback_font, Vector2(982.0, 174.0 + float(index) * 62.0), combat_log[index], HORIZONTAL_ALIGNMENT_LEFT, 252.0, 10, Color("b1d7e1"))
	if battle_over:
		var result_color: Color = Color("6ff0c1") if victory else Color("ff7592")
		draw_string(ThemeDB.fallback_font, Vector2(992.0, 530.0), "PATROL SECURED" if victory else "PATROL FAILED", HORIZONTAL_ALIGNMENT_CENTER, 234.0, 17, result_color)

func _draw_commands() -> void:
	_panel(Rect2(28.0, 618.0, 1224.0, 78.0), Color("071421"), Color("4db7d6"), 12)
	var labels: Dictionary = {"attack":"ATTACK", "cover":"COVER", "special":"SPECIAL", "auto":"AUTO ON" if auto_mode else "AUTO", "retreat":"RETREAT", "return":"RETURN TO PRECINCT"}
	for action_value: Variant in button_rects.keys():
		var action: String = String(action_value)
		var rect: Rect2 = button_rects[action] as Rect2
		var enabled: bool = not battle_over or action == "return"
		if action == "return" and not battle_over: enabled = false
		_panel(rect, Color("1c5266") if action == "auto" and auto_mode else Color("102c3f"), Color("b9f9ff") if enabled else Color("43515b"), 8)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(5.0, 29.0), String(labels.get(action, action.to_upper())), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10.0, 12, Color("eafcff") if enabled else Color("697984"))
	draw_string(ThemeDB.fallback_font, Vector2(44.0, 710.0), status_message, HORIZONTAL_ALIGNMENT_LEFT, 1170.0, 10, Color("bcebf4"))

func _health_bar(rect: Rect2, hp: int, maximum: int, fill: Color) -> void:
	draw_rect(rect, Color("03080e"), true)
	var ratio: float = clamp(float(hp) / float(max(1, maximum)), 0.0, 1.0)
	draw_rect(Rect2(rect.position + Vector2(1.0, 1.0), Vector2((rect.size.x - 2.0) * ratio, rect.size.y - 2.0)), fill, true)
	draw_rect(rect, Color("a6dce8", 0.35), false, 1.0)

func _panel(rect: Rect2, fill: Color, border: Color, radius: int) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	draw_style_box(style, rect)

func _add_log(text: String) -> void:
	combat_log.push_front(text)
	if combat_log.size() > 6:
		combat_log.resize(6)
