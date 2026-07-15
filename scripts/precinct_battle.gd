extends Node2D
## Separate tactical patrol scene for the precinct vertical slice.
## Uses original code-drawn MoonGoons lunar visuals and a compact turn-based combat loop.

const VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)
const ARENA_RECT: Rect2 = Rect2(28.0, 104.0, 920.0, 500.0)
const INFO_RECT: Rect2 = Rect2(966.0, 104.0, 286.0, 500.0)

var officer_units: Array[Dictionary] = []
var enemy_hp: int = 1
var enemy_max_hp: int = 1
var enemy_power: int = 10
var battle_over: bool = false
var victory: bool = false
var auto_mode: bool = false
var auto_timer: float = 0.0
var pulse: float = 0.0
var turn_number: int = 1
var status_message: String = "Patrol entering the combat zone."
var combat_log: Array[String] = []
var button_rects: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_configure_buttons()
	if PrecinctState.active_call.is_empty():
		status_message = "No active patrol call. Returning to the precinct."
		get_tree().call_deferred("change_scene_to_file", "res://scenes/PrecinctVerticalSlice.tscn")
		return
	_setup_battle()
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	if auto_mode and not battle_over:
		auto_timer += delta
		if auto_timer >= 0.75:
			auto_timer = 0.0
			_execute_player_action("attack")
	queue_redraw()

func _input(event: InputEvent) -> void:
	var position: Vector2 = Vector2.ZERO
	var pressed: bool = false
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		position = mouse_event.position
		pressed = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		position = touch_event.position
		pressed = touch_event.pressed
	if not pressed:
		return
	for action_value: Variant in button_rects.keys():
		var action: String = String(action_value)
		var rect: Rect2 = button_rects[action] as Rect2
		if rect.has_point(position):
			_handle_button(action)
			return

func _draw() -> void:
	_draw_backdrop()
	_draw_header()
	_draw_arena()
	_draw_officers()
	_draw_enemy()
	_draw_info_panel()
	_draw_command_deck()

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
	var active_officers: Array[Dictionary] = PrecinctState.active_officers()
	for index: int in range(active_officers.size()):
		var source: Dictionary = active_officers[index]
		var unit: Dictionary = {
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
		}
		officer_units.append(unit)
	enemy_max_hp = int(PrecinctState.active_call.get("enemy_hp", 120))
	enemy_hp = enemy_max_hp
	enemy_power = int(PrecinctState.active_call.get("enemy_power", 14))
	status_message = "CONTACT // %s" % String(PrecinctState.active_call.get("title", "Syndicate threat"))
	_add_log("Patrol entered %s." % String(PrecinctState.active_call.get("sector", "the sector")))
	_add_log("Suspect resistance detected. Use ATTACK, COVER, or SPECIAL.")

func _handle_button(action: String) -> void:
	if action == "return":
		if battle_over:
			get_tree().change_scene_to_file("res://scenes/PrecinctVerticalSlice.tscn")
		else:
			status_message = "Resolve or retreat from the patrol before returning."
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
	_execute_player_action(action)

func _execute_player_action(action: String) -> void:
	if battle_over:
		return
	var living_count: int = 0
	for unit: Dictionary in officer_units:
		if int(unit.get("hp", 0)) > 0:
			living_count += 1
	if living_count <= 0:
		_finish_battle(false, "All officers were forced out of the combat zone.")
		return
	var total_damage: int = 0
	match action:
		"attack":
			for unit: Dictionary in officer_units:
				if int(unit.get("hp", 0)) <= 0:
					continue
				unit["covering"] = false
				var base_damage: int = max(5, int(unit.get("power", 50)) / 7)
				total_damage += base_damage + _rng.randi_range(0, 6)
			status_message = "Patrol volley landed for %d damage." % total_damage
			_add_log("Turn %d: coordinated attack dealt %d." % [turn_number, total_damage])
		"cover":
			for unit: Dictionary in officer_units:
				if int(unit.get("hp", 0)) > 0:
					unit["covering"] = true
			status_message = "Patrol formed a defensive shield line."
			_add_log("Turn %d: officers moved into cover." % turn_number)
		"special":
			var specials_used: int = 0
			for unit: Dictionary in officer_units:
				if int(unit.get("hp", 0)) <= 0 or not bool(unit.get("special_ready", false)):
					continue
				unit["special_ready"] = false
				unit["covering"] = false
				specials_used += 1
				var class_name: String = String(unit.get("class", "Guard"))
				if class_name == "Guard":
					total_damage += 15
					unit["hp"] = min(int(unit.get("max_hp", 100)), int(unit.get("hp", 1)) + 10)
				elif class_name == "Biker":
					total_damage += 25
				else:
					total_damage += 31
			if specials_used <= 0:
				status_message = "Officer special abilities have already been used."
				return
			status_message = "%d officer special(s) struck for %d damage." % [specials_used, total_damage]
			_add_log("Turn %d: lunar specials dealt %d." % [turn_number, total_damage])
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
	var living_indices: Array[int] = []
	for index: int in range(officer_units.size()):
		if int(officer_units[index].get("hp", 0)) > 0:
			living_indices.append(index)
	if living_indices.is_empty():
		_finish_battle(false, "The patrol was overwhelmed.")
		return
	var target_list_index: int = _rng.randi_range(0, living_indices.size() - 1)
	var target_index: int = living_indices[target_list_index]
	var target: Dictionary = officer_units[target_index]
	var raw_damage: int = enemy_power + _rng.randi_range(0, 7)
	var mitigation: int = int(target.get("defense", 0)) / 4
	if bool(target.get("covering", false)):
		mitigation += 12
	var damage: int = max(3, raw_damage - mitigation)
	target["hp"] = max(0, int(target.get("hp", 1)) - damage)
	target["covering"] = false
	_add_log("Syndicate fire hit %s for %d." % [String(target.get("name", "Officer")), damage])
	if int(target.get("hp", 0)) <= 0:
		_add_log("%s was forced out of the fight." % String(target.get("name", "Officer")))
	var survivors: int = 0
	for unit: Dictionary in officer_units:
		if int(unit.get("hp", 0)) > 0:
			survivors += 1
	if survivors <= 0:
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

func _draw_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("020710"))
	draw_rect(Rect2(0.0, 0.0, VIEWPORT_SIZE.x, 92.0), Color("101a32"))
	for index: int in range(95):
		var x: float = fmod(float(index * 83 + 17), VIEWPORT_SIZE.x)
		var y: float = fmod(float(index * 47 + 29), VIEWPORT_SIZE.y)
		draw_circle(Vector2(x, y), 1.0 + float(index % 2), Color("b5d5ff", 0.22))
	draw_circle(Vector2(1118.0, 46.0), 72.0, Color("eafcff", 0.045))
	draw_circle(Vector2(1118.0, 46.0), 51.0, Color("eafcff", 0.035))

func _draw_header() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 35.0), "MOONGOONS PATROL COMBAT", HORIZONTAL_ALIGNMENT_LEFT, 440.0, 23, Color("eafcff"))
	var call_title: String = String(PrecinctState.active_call.get("title", "ACTIVE PATROL")).to_upper()
	var sector: String = String(PrecinctState.active_call.get("sector", "UNKNOWN SECTOR")).to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 64.0), "%s // %s // TURN %d" % [call_title, sector, turn_number], HORIZONTAL_ALIGNMENT_LEFT, 720.0, 12, Color("82e6ff"))
	draw_string(ThemeDB.fallback_font, Vector2(846.0, 52.0), "THREAT D%d" % int(PrecinctState.active_call.get("difficulty", 1)), HORIZONTAL_ALIGNMENT_LEFT, 180.0, 15, _difficulty_color(int(PrecinctState.active_call.get("difficulty", 1))))
	draw_line(Vector2(0.0, 91.0), Vector2(VIEWPORT_SIZE.x, 91.0), Color("66dfff", 0.42), 2.0)

func _draw_arena() -> void:
	draw_style_box(_panel_style(Color("071421", 0.98), Color("4db7d6", 0.52), 2, 14), ARENA_RECT)
	var battlefield: Rect2 = ARENA_RECT.grow(-12.0)
	draw_rect(battlefield, Color("0b1b29"), true)
	for row: int in range(8):
		var y: float = battlefield.position.y + float(row) * 58.0
		draw_line(Vector2(battlefield.position.x, y), Vector2(battlefield.end.x, y + 70.0), Color("69d9ff", 0.045), 1.0)
	for crater: int in range(7):
		var center: Vector2 = Vector2(370.0 + float(crater % 4) * 130.0, 190.0 + float(crater / 4) * 250.0)
		draw_circle(center, 28.0 + float(crater % 3) * 9.0, Color("142635"))
		draw_arc(center, 28.0 + float(crater % 3) * 9.0, 0.0, TAU, 28, Color("55758b", 0.27), 2.0)
	draw_rect(Rect2(548.0, 168.0, 270.0, 310.0), Color("2c1020", 0.16), true)
	draw_string(ThemeDB.fallback_font, Vector2(58.0, 132.0), "AUTHORITY PATROL LINE", HORIZONTAL_ALIGNMENT_LEFT, 280.0, 10, Color("72dfec"))
	draw_string(ThemeDB.fallback_font, Vector2(655.0, 132.0), "SYNDICATE CONTROL", HORIZONTAL_ALIGNMENT_LEFT, 220.0, 10, Color("ff718f"))

func _draw_officers() -> void:
	for index: int in range(officer_units.size()):
		var unit: Dictionary = officer_units[index]
		var center: Vector2 = unit.get("position", Vector2.ZERO) as Vector2
		var hp: int = int(unit.get("hp", 0))
		var max_hp: int = int(unit.get("max_hp", 1))
		var alive: bool = hp > 0
		var class_name: String = String(unit.get("class", "Guard"))
		var body_color: Color = _class_color(class_name)
		if not alive:
			body_color = Color("343944")
		if bool(unit.get("covering", false)) and alive:
			draw_arc(center, 44.0 + sin(pulse * 3.0) * 2.0, -2.5, 0.5, 28, Color("8cf4ff", 0.78), 5.0)
		draw_circle(center, 34.0, Color("06101b"))
		draw_circle(center, 29.0, body_color)
		draw_polygon(PackedVector2Array([center + Vector2(-17.0, -17.0), center + Vector2(-8.0, -40.0), center + Vector2(0.0, -22.0)]), PackedColorArray([body_color, body_color, body_color]))
		draw_polygon(PackedVector2Array([center + Vector2(17.0, -17.0), center + Vector2(8.0, -40.0), center + Vector2(0.0, -22.0)]), PackedColorArray([body_color, body_color, body_color]))
		draw_circle(center + Vector2(-9.0, -4.0), 4.0, Color("06101b"))
		draw_circle(center + Vector2(9.0, -4.0), 4.0, Color("06101b"))
		draw_line(center + Vector2(-9.0, 13.0), center + Vector2(9.0, 13.0), Color("06101b"), 3.0)
		var name_position: Vector2 = center + Vector2(-72.0, 54.0)
		draw_string(ThemeDB.fallback_font, name_position, String(unit.get("name", "Officer")), HORIZONTAL_ALIGNMENT_CENTER, 144.0, 11, Color("eafcff"))
		draw_string(ThemeDB.fallback_font, name_position + Vector2(0.0, 17.0), class_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 144.0, 9, Color("86bccb"))
		_draw_health_bar(Rect2(center + Vector2(-58.0, 78.0), Vector2(116.0, 10.0)), hp, max_hp, Color("55e4bd"))
		if bool(unit.get("special_ready", false)) and alive:
			draw_circle(center + Vector2(37.0, -32.0), 8.0 + sin(pulse * 4.0), Color("ffd773", 0.78))

func _draw_enemy() -> void:
	var center: Vector2 = Vector2(717.0, 322.0)
	var danger_color: Color = Color("ff557a") if enemy_hp > 0 else Color("3b3540")
	for ring: int in range(3):
		draw_arc(center, 60.0 + float(ring) * 14.0 + sin(pulse * 2.0 + float(ring)) * 3.0, 0.0, TAU, 36, Color(danger_color, 0.18 - float(ring) * 0.035), 3.0)
	draw_circle(center, 52.0, Color("170711"))
	draw_circle(center, 45.0, danger_color)
	draw_polygon(PackedVector2Array([center + Vector2(-30.0, -28.0), center + Vector2(-12.0, -74.0), center + Vector2(3.0, -38.0)]), PackedColorArray([danger_color, danger_color, danger_color]))
	draw_polygon(PackedVector2Array([center + Vector2(30.0, -28.0), center + Vector2(12.0, -74.0), center + Vector2(-3.0, -38.0)]), PackedColorArray([danger_color, danger_color, danger_color]))
	draw_circle(center + Vector2(-15.0, -8.0), 6.0, Color("fff1a8"))
	draw_circle(center + Vector2(15.0, -8.0), 6.0, Color("fff1a8"))
	draw_line(center + Vector2(-17.0, 19.0), center + Vector2(17.0, 19.0), Color("250613"), 5.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-95.0, 77.0), "SYNDICATE SUSPECT", HORIZONTAL_ALIGNMENT_CENTER, 190.0, 13, Color("ffeaf0"))
	_draw_health_bar(Rect2(center + Vector2(-85.0, 94.0), Vector2(170.0, 12.0)), enemy_hp, enemy_max_hp, danger_color)

func _draw_info_panel() -> void:
	draw_style_box(_panel_style(Color("071421", 0.98), Color("4db7d6", 0.52), 2, 14), INFO_RECT)
	draw_string(ThemeDB.fallback_font, Vector2(982.0, 132.0), "TACTICAL FEED", HORIZONTAL_ALIGNMENT_LEFT, 190.0, 13, Color("8deaff"))
	draw_line(Vector2(980.0, 145.0), Vector2(1238.0, 145.0), Color("66dfff", 0.24), 1.0)
	for index: int in range(combat_log.size()):
		var y: float = 174.0 + float(index) * 62.0
		draw_string(ThemeDB.fallback_font, Vector2(982.0, y), combat_log[index], HORIZONTAL_ALIGNMENT_LEFT, 252.0, 10, Color("b1d7e1"))
	if battle_over:
		var result_color: Color = Color("6ff0c1") if victory else Color("ff7592")
		draw_rect(Rect2(982.0, 500.0, 254.0, 76.0), Color(result_color, 0.12), true)
		draw_rect(Rect2(982.0, 500.0, 254.0, 76.0), result_color, false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(992.0, 530.0), "PATROL SECURED" if victory else "PATROL FAILED", HORIZONTAL_ALIGNMENT_CENTER, 234.0, 17, result_color)
		draw_string(ThemeDB.fallback_font, Vector2(992.0, 555.0), "Use RETURN TO PRECINCT", HORIZONTAL_ALIGNMENT_CENTER, 234.0, 10, Color("c8e7ee"))

func _draw_command_deck() -> void:
	draw_style_box(_panel_style(Color("071421", 0.98), Color("4db7d6", 0.46), 1, 12), Rect2(28.0, 618.0, 1224.0, 78.0))
	var labels: Dictionary = {
		"attack": "ATTACK",
		"cover": "COVER",
		"special": "SPECIAL",
		"auto": "AUTO ON" if auto_mode else "AUTO",
		"retreat": "RETREAT",
		"return": "RETURN TO PRECINCT"
	}
	for action_value: Variant in button_rects.keys():
		var action: String = String(action_value)
		var rect: Rect2 = button_rects[action] as Rect2
		var enabled: bool = not battle_over or action == "return"
		if action == "return" and not battle_over:
			enabled = false
		var fill: Color = Color("1c5266") if (action == "auto" and auto_mode) else Color("102c3f")
		if not enabled:
			fill = Color("18202a")
		var border: Color = Color("b9f9ff") if enabled else Color("43515b")
		draw_style_box(_panel_style(fill, border, 1, 8), rect)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(5.0, 29.0), String(labels.get(action, action.to_upper())), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10.0, 12, Color("eafcff") if enabled else Color("697984"))
	draw_string(ThemeDB.fallback_font, Vector2(44.0, 710.0), status_message, HORIZONTAL_ALIGNMENT_LEFT, 1170.0, 10, Color("bcebf4"))

func _draw_health_bar(rect: Rect2, hp: int, max_hp: int, fill_color: Color) -> void:
	draw_rect(rect, Color("03080e"), true)
	var ratio: float = clamp(float(hp) / float(max(1, max_hp)), 0.0, 1.0)
	draw_rect(Rect2(rect.position + Vector2(1.0, 1.0), Vector2((rect.size.x - 2.0) * ratio, rect.size.y - 2.0)), fill_color, true)
	draw_rect(rect, Color("a6dce8", 0.35), false, 1.0)

func _class_color(class_name: String) -> Color:
	if class_name == "Biker":
		return Color("c47cff")
	if class_name == "Marksman":
		return Color("f4c86d")
	return Color("5dd8e8")

func _difficulty_color(difficulty: int) -> Color:
	if difficulty >= 3:
		return Color("ff6488")
	if difficulty == 2:
		return Color("ffc36e")
	return Color("6ce9c1")

func _add_log(text: String) -> void:
	combat_log.push_front(text)
	if combat_log.size() > 6:
		combat_log.resize(6)

func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
