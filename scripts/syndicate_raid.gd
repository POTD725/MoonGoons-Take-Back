extends Node2D
## Tactical criminal job scene with textured characters, sound, and chapter routing.

const VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)
const ARENA_RECT: Rect2 = Rect2(28.0, 104.0, 920.0, 500.0)
const INFO_RECT: Rect2 = Rect2(966.0, 104.0, 286.0, 500.0)
const PORTRAITS: Dictionary = {
	"crew_1": preload("res://assets/syndicate/portraits/nyx_raze.svg"),
	"crew_2": preload("res://assets/syndicate/portraits/vox_13.svg"),
	"crew_3": preload("res://assets/syndicate/portraits/cinder_quell.svg"),
	"crew_4": preload("res://assets/syndicate/portraits/grit_mercer.svg")
}
const ENEMY_TEXTURE: Texture2D = preload("res://assets/syndicate/enemies/peacekeeper_response.svg")

var crew_units: Array[Dictionary] = []
var enemy_hp: int = 1
var enemy_max_hp: int = 1
var enemy_power: int = 10
var battle_over: bool = false
var victory: bool = false
var auto_mode: bool = false
var auto_timer: float = 0.0
var pulse: float = 0.0
var turn_number: int = 1
var status_message: String = "Crew slipping into the target zone."
var combat_log: Array[String] = []
var button_rects: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_configure_buttons()
	if SyndicateState.active_job.is_empty():
		status_message = "No live score. Returning to the hideout."
		get_tree().call_deferred("change_scene_to_file", "res://scenes/SyndicateHideout.tscn")
		return
	_setup_battle()
	SyndicateAudio.play_music("combat")
	SyndicateAudio.play_sfx("warning")
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	if auto_mode and not battle_over:
		auto_timer += delta
		if auto_timer >= 0.75:
			auto_timer = 0.0
			_execute_player_action("strike")
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
	_draw_crew()
	_draw_enemy()
	_draw_info_panel()
	_draw_command_deck()

func _configure_buttons() -> void:
	button_rects = {
		"strike": Rect2(42.0, 632.0, 150.0, 48.0),
		"evade": Rect2(204.0, 632.0, 150.0, 48.0),
		"special": Rect2(366.0, 632.0, 150.0, 48.0),
		"auto": Rect2(528.0, 632.0, 150.0, 48.0),
		"abort": Rect2(690.0, 632.0, 150.0, 48.0),
		"return": Rect2(1000.0, 632.0, 220.0, 48.0)
	}

func _setup_battle() -> void:
	var active_members: Array[Dictionary] = SyndicateState.active_crew()
	for index: int in range(active_members.size()):
		var source: Dictionary = active_members[index]
		var unit: Dictionary = {
			"id": String(source.get("id", "")),
			"name": String(source.get("name", "Crew")),
			"class": String(source.get("class", "Enforcer")),
			"level": int(source.get("level", 1)),
			"power": int(source.get("power", 50)),
			"defense": int(source.get("defense", 10)),
			"hp": int(source.get("hp", 100)),
			"max_hp": int(source.get("max_hp", 100)),
			"special_ready": true,
			"evading": false,
			"position": Vector2(190.0, 214.0 + float(index) * 105.0)
		}
		crew_units.append(unit)
	enemy_max_hp = int(SyndicateState.active_job.get("enemy_hp", 120))
	enemy_hp = enemy_max_hp
	enemy_power = int(SyndicateState.active_job.get("enemy_power", 14))
	status_message = "CONTACT // %s response team" % String(SyndicateState.active_job.get("target", "Peacekeeper"))
	_add_log("Crew entered %s." % String(SyndicateState.active_job.get("sector", "the sector")))
	_add_log("Security response detected. Use STRIKE, EVADE, or SPECIAL.")

func _handle_button(action: String) -> void:
	if action == "return":
		if battle_over:
			SyndicateAudio.play_sfx("click")
			if not SyndicateState.pending_cutscene.is_empty():
				get_tree().change_scene_to_file("res://scenes/SyndicateCutscene.tscn")
			else:
				SyndicateAudio.play_music("hideout")
				get_tree().change_scene_to_file("res://scenes/SyndicateHideout.tscn")
		else:
			status_message = "Finish or abort the job before returning."
			SyndicateAudio.play_sfx("warning")
		return
	if battle_over:
		return
	if action == "auto":
		auto_mode = not auto_mode
		status_message = "AUTO RAID ENABLED" if auto_mode else "AUTO RAID DISABLED"
		SyndicateAudio.play_sfx("click")
		return
	if action == "abort":
		_finish_battle(false, "Crew burned the route and escaped empty-handed.")
		return
	_execute_player_action(action)

func _execute_player_action(action: String) -> void:
	if battle_over:
		return
	var living_count: int = 0
	for unit: Dictionary in crew_units:
		if int(unit.get("hp", 0)) > 0:
			living_count += 1
	if living_count <= 0:
		_finish_battle(false, "The crew was forced out of the target zone.")
		return
	var total_damage: int = 0
	match action:
		"strike":
			for unit: Dictionary in crew_units:
				if int(unit.get("hp", 0)) <= 0:
					continue
				unit["evading"] = false
				var base_damage: int = max(5, int(unit.get("power", 50)) / 7)
				total_damage += base_damage + _rng.randi_range(0, 6)
			status_message = "Crew volley cracked security for %d damage." % total_damage
			_add_log("Turn %d: coordinated strike dealt %d." % [turn_number, total_damage])
			SyndicateAudio.play_sfx("hit")
		"evade":
			for unit: Dictionary in crew_units:
				if int(unit.get("hp", 0)) > 0:
					unit["evading"] = true
			status_message = "Crew scattered into cover and false sensor trails."
			_add_log("Turn %d: crew entered evade stance." % turn_number)
			SyndicateAudio.play_sfx("click")
		"special":
			var specials_used: int = 0
			for unit: Dictionary in crew_units:
				if int(unit.get("hp", 0)) <= 0 or not bool(unit.get("special_ready", false)):
					continue
				unit["special_ready"] = false
				unit["evading"] = false
				specials_used += 1
				var crew_class: String = String(unit.get("class", "Enforcer"))
				if crew_class == "Enforcer":
					total_damage += 17 + int(unit.get("level", 1))
					unit["hp"] = min(int(unit.get("max_hp", 100)), int(unit.get("hp", 1)) + 10)
				elif crew_class == "Runner":
					total_damage += 26 + int(unit.get("level", 1))
					unit["evading"] = true
				else:
					total_damage += 32 + int(unit.get("level", 1)) * 2
			if specials_used <= 0:
				status_message = "Crew special abilities are already spent."
				SyndicateAudio.play_sfx("warning")
				return
			status_message = "%d crew special(s) landed for %d damage." % [specials_used, total_damage]
			_add_log("Turn %d: underworld specials dealt %d." % [turn_number, total_damage])
			SyndicateAudio.play_sfx("special")
		_:
			return
	if total_damage > 0:
		enemy_hp = max(0, enemy_hp - total_damage)
	if enemy_hp <= 0:
		_finish_battle(true, "Security broken. Cargo and credits secured.")
		return
	_enemy_turn()
	turn_number += 1

func _enemy_turn() -> void:
	var living_indices: Array[int] = []
	for index: int in range(crew_units.size()):
		if int(crew_units[index].get("hp", 0)) > 0:
			living_indices.append(index)
	if living_indices.is_empty():
		_finish_battle(false, "The response team overwhelmed the crew.")
		return
	var target_index: int = living_indices[_rng.randi_range(0, living_indices.size() - 1)]
	var target: Dictionary = crew_units[target_index]
	var raw_damage: int = enemy_power + _rng.randi_range(0, 7)
	var mitigation: int = int(target.get("defense", 0)) / 4
	if bool(target.get("evading", false)):
		mitigation += 12
	var damage: int = max(3, raw_damage - mitigation)
	target["hp"] = max(0, int(target.get("hp", 1)) - damage)
	target["evading"] = false
	_add_log("Security fire hit %s for %d." % [String(target.get("name", "Crew")), damage])
	SyndicateAudio.play_sfx("hit")
	if int(target.get("hp", 0)) <= 0:
		_add_log("%s was forced out of the job." % String(target.get("name", "Crew")))
	var survivors: int = 0
	for unit: Dictionary in crew_units:
		if int(unit.get("hp", 0)) > 0:
			survivors += 1
	if survivors <= 0:
		_finish_battle(false, "The response team overwhelmed the crew.")

func _finish_battle(won: bool, message: String) -> void:
	if battle_over:
		return
	battle_over = true
	victory = won
	auto_mode = false
	status_message = message
	_add_log("SCORE SECURED" if won else "SCORE BURNED")
	var hp_results: Dictionary = {}
	for unit: Dictionary in crew_units:
		hp_results[String(unit.get("id", ""))] = max(1, int(unit.get("hp", 1)))
	SyndicateState.finish_job(won, hp_results)
	SyndicateAudio.play_sfx("victory" if won else "defeat")
	queue_redraw()

func _draw_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("05020b"))
	draw_rect(Rect2(0.0, 0.0, VIEWPORT_SIZE.x, 92.0), Color("1c0d24"))
	for index: int in range(96):
		var x: float = fmod(float(index * 89 + 19), VIEWPORT_SIZE.x)
		var y: float = fmod(float(index * 53 + 31), VIEWPORT_SIZE.y)
		draw_circle(Vector2(x, y), 1.0 + float(index % 2), Color("d9b3ff", 0.20))
	draw_circle(Vector2(1120.0, 47.0), 74.0, Color("ff5e9c", 0.045))
	draw_circle(Vector2(1120.0, 47.0), 51.0, Color("b967ff", 0.035))

func _draw_header() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 35.0), "SYNDICATE JOB COMBAT", HORIZONTAL_ALIGNMENT_LEFT, 440.0, 23, Color("fff3fb"))
	var job_title: String = String(SyndicateState.active_job.get("title", "ACTIVE SCORE")).to_upper()
	var sector: String = String(SyndicateState.active_job.get("sector", "UNKNOWN SECTOR")).to_upper()
	var story_text: String = " // STORY" if bool(SyndicateState.active_job.get("story", false)) else ""
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 64.0), "%s // %s // TURN %d%s" % [job_title, sector, turn_number, story_text], HORIZONTAL_ALIGNMENT_LEFT, 760.0, 12, Color("ff8fc4"))
	draw_string(ThemeDB.fallback_font, Vector2(846.0, 52.0), "RESPONSE D%d" % int(SyndicateState.active_job.get("difficulty", 1)), HORIZONTAL_ALIGNMENT_LEFT, 180.0, 15, _difficulty_color(int(SyndicateState.active_job.get("difficulty", 1))))
	draw_line(Vector2(0.0, 91.0), Vector2(VIEWPORT_SIZE.x, 91.0), Color("ff5c9d", 0.46), 2.0)

func _draw_arena() -> void:
	draw_style_box(_panel_style(Color("130a18", 0.98), Color("9d4bb7", 0.58), 2, 14), ARENA_RECT)
	var battlefield: Rect2 = ARENA_RECT.grow(-12.0)
	draw_rect(battlefield, Color("1a1020"), true)
	for row: int in range(8):
		var y: float = battlefield.position.y + float(row) * 58.0
		draw_line(Vector2(battlefield.position.x, y), Vector2(battlefield.end.x, y + 70.0), Color("e16dff", 0.045), 1.0)
	for crate: int in range(7):
		var center: Vector2 = Vector2(365.0 + float(crate % 4) * 130.0, 190.0 + float(crate / 4) * 250.0)
		draw_rect(Rect2(center - Vector2(28.0, 22.0), Vector2(56.0, 44.0)), Color("312033"), true)
		draw_rect(Rect2(center - Vector2(28.0, 22.0), Vector2(56.0, 44.0)), Color("8a587c", 0.34), false, 2.0)
	draw_rect(Rect2(548.0, 168.0, 270.0, 310.0), Color("341123", 0.20), true)
	draw_string(ThemeDB.fallback_font, Vector2(574.0, 198.0), "TARGET SECURITY ZONE", HORIZONTAL_ALIGNMENT_CENTER, 220.0, 11, Color("ff8aae", 0.70))

func _draw_crew() -> void:
	for unit: Dictionary in crew_units:
		var center: Vector2 = unit.get("position", Vector2.ZERO) as Vector2
		var alive: bool = int(unit.get("hp", 0)) > 0
		var texture: Texture2D = PORTRAITS[String(unit.get("id", "crew_1"))] as Texture2D
		if bool(unit.get("evading", false)) and alive:
			draw_arc(center, 51.0 + sin(pulse * 4.0) * 3.0, 0.0, TAU, 32, Color("d78cff", 0.70), 3.0)
		draw_texture_rect(texture, Rect2(center - Vector2(43.0, 43.0), Vector2(86.0, 86.0)), false)
		if not alive:
			draw_rect(Rect2(center - Vector2(43.0, 43.0), Vector2(86.0, 86.0)), Color("08050b", 0.72), true)
		draw_string(ThemeDB.fallback_font, center + Vector2(-70.0, 59.0), "%s  L%d" % [unit.get("name", "Crew"), unit.get("level", 1)], HORIZONTAL_ALIGNMENT_CENTER, 140.0, 11, Color("fff4fb"))
		_draw_health_bar(Rect2(center + Vector2(-62.0, 70.0), Vector2(124.0, 9.0)), int(unit.get("hp", 0)), int(unit.get("max_hp", 100)), Color("ff5f91"))

func _draw_enemy() -> void:
	var rect: Rect2 = Rect2(628.0, 205.0, 205.0, 205.0)
	draw_texture_rect(ENEMY_TEXTURE, rect, false)
	if enemy_hp <= 0:
		draw_rect(rect, Color("07060a", 0.72), true)
	draw_string(ThemeDB.fallback_font, Vector2(620.0, 445.0), String(SyndicateState.active_job.get("target", "SECURITY")).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 220.0, 12, Color("d9f8ff"))
	_draw_health_bar(Rect2(648.0, 460.0, 164.0, 12.0), enemy_hp, enemy_max_hp, Color("62dfff"))

func _draw_info_panel() -> void:
	draw_style_box(_panel_style(Color("130a18", 0.98), Color("9d4bb7", 0.58), 2, 14), INFO_RECT)
	draw_string(ThemeDB.fallback_font, Vector2(984.0, 132.0), "JOB FEED", HORIZONTAL_ALIGNMENT_LEFT, 160.0, 13, Color("ff91c5"))
	_draw_wrapped(status_message, Vector2(984.0, 158.0), 250.0, 10, Color("f0d5e5"))
	draw_line(Vector2(980.0, 194.0), Vector2(1238.0, 194.0), Color("d26dff", 0.25), 1.0)
	for index: int in range(combat_log.size()):
		var y: float = 220.0 + float(index) * 39.0
		_draw_wrapped(combat_log[index], Vector2(984.0, y), 246.0, 9, Color("bb98ae"))
	if battle_over:
		var banner_color: Color = Color("72f0c1") if victory else Color("ff5f7f")
		draw_rect(Rect2(984.0, 528.0, 250.0, 50.0), Color(banner_color, 0.16), true)
		draw_rect(Rect2(984.0, 528.0, 250.0, 50.0), banner_color, false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(990.0, 559.0), "SCORE SECURED" if victory else "SCORE BURNED", HORIZONTAL_ALIGNMENT_CENTER, 238.0, 14, banner_color)

func _draw_command_deck() -> void:
	var labels: Dictionary = {
		"strike": "STRIKE",
		"evade": "EVADE",
		"special": "SPECIAL",
		"auto": "AUTO ON" if auto_mode else "AUTO",
		"abort": "ABORT",
		"return": "CONTINUE STORY" if battle_over and not SyndicateState.pending_cutscene.is_empty() else "RETURN TO HIDEOUT"
	}
	for action_value: Variant in button_rects.keys():
		var action: String = String(action_value)
		var rect: Rect2 = button_rects[action] as Rect2
		var enabled: bool = not battle_over or action == "return"
		var fill: Color = Color("59204a") if enabled else Color("241523")
		var border: Color = Color("ff85bd") if enabled else Color("5d4455")
		if action == "return" and battle_over:
			fill = Color("23614f") if victory else Color("64253a")
			border = Color("dfffee") if victory else Color("ffc0cf")
		draw_style_box(_panel_style(fill, border, 1, 8), rect)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(5.0, 30.0), String(labels.get(action, action.to_upper())), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10.0, 10, Color("fff5fb"))

func _draw_health_bar(rect: Rect2, current: int, maximum: int, bar_color: Color) -> void:
	draw_rect(rect, Color("120b13"), true)
	var ratio: float = 0.0 if maximum <= 0 else clampf(float(current) / float(maximum), 0.0, 1.0)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y)), bar_color, true)
	draw_rect(rect, Color("f5d7e7", 0.35), false, 1.0)

func _draw_wrapped(text: String, origin: Vector2, width: float, font_size: int, color: Color) -> void:
	var words: PackedStringArray = text.split(" ")
	var line: String = ""
	var y: float = origin.y
	for word: String in words:
		var candidate: String = word if line.is_empty() else line + " " + word
		if ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > width and not line.is_empty():
			draw_string(ThemeDB.fallback_font, Vector2(origin.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)
			line = word
			y += float(font_size + 5)
		else:
			line = candidate
	if not line.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(origin.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _add_log(message: String) -> void:
	combat_log.push_front(message)
	if combat_log.size() > 8:
		combat_log.resize(8)

func _difficulty_color(difficulty: int) -> Color:
	if difficulty <= 1:
		return Color("72f0c1")
	if difficulty == 2:
		return Color("ffbd67")
	return Color("ff5f7f")

func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
