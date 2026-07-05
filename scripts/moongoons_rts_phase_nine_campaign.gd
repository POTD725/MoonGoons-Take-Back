extends "res://scripts/moongoons_rts_phase_eight_syndicate.gd"
## Phase Nine: story-routed campaign operations and local progression.
## Dispatches advance in narrative order. Opponent difficulty is the player-facing match choice.

const CAMPAIGN_PROFILE_PATH := "user://moongoons_campaign_profile.json"

var campaign_rules: Dictionary = {}
var campaign_profile: Dictionary = {}
var campaign_board_open: bool = false
var campaign_result_recorded: bool = false
var campaign_button: Rect2 = Rect2(994.0, 294.0, 248.0, 24.0)
var campaign_panel: Rect2 = Rect2(150.0, 108.0, 670.0, 430.0)
var campaign_start_button: Rect2 = Rect2(555.0, 486.0, 242.0, 32.0)
var difficulty_buttons: Dictionary = {
	"easy": Rect2(171.0, 415.0, 194.0, 42.0),
	"medium": Rect2(387.0, 415.0, 194.0, 42.0),
	"hard": Rect2(603.0, 415.0, 194.0, 42.0)
}

func _ready() -> void:
	campaign_rules = _load_campaign_rules()
	campaign_profile = _load_campaign_profile()
	_ensure_story_progression()
	super._ready()
	queue_redraw()

func _reset_match() -> void:
	campaign_result_recorded = false
	super._reset_match()
	_apply_story_operation_profile()

func _process(delta: float) -> void:
	if campaign_board_open:
		queue_redraw()
		return
	super._process(delta)
	if victory and not campaign_result_recorded:
		_record_story_completion()
	queue_redraw()

func _handle_hotkey(keycode: Key) -> void:
	if keycode == KEY_C:
		campaign_board_open = not campaign_board_open
		mission_state = "Story Dispatch %s." % ("opened" if campaign_board_open else "closed")
		queue_redraw()
		return
	if campaign_board_open:
		if keycode == KEY_ESCAPE:
			campaign_board_open = false
		elif keycode == KEY_ENTER:
			_start_story_dispatch()
		return
	super._handle_hotkey(keycode)

func _handle_left_press(cursor: Vector2) -> void:
	if campaign_board_open:
		_handle_story_dispatch_click(cursor)
		return
	if campaign_button.has_point(cursor):
		campaign_board_open = true
		mission_state = "Story Dispatch opened. Choose opponent difficulty, then begin the next required operation."
		queue_redraw()
		return
	super._handle_left_press(cursor)

func _draw_world() -> void:
	super._draw_world()
	_draw_story_status_strip()
	if campaign_board_open:
		_draw_story_dispatch_board()

func _draw_sidebar() -> void:
	super._draw_sidebar()
	_draw_story_dispatch_button()

func _draw_story_dispatch_button() -> void:
	draw_style_box(_panel_style(Color("173a4d", 0.96), Color("79d4ff"), 1, 6), campaign_button)
	draw_string(ThemeDB.fallback_font, campaign_button.position + Vector2(10.0, 16.0), "C  STORY DISPATCH", HORIZONTAL_ALIGNMENT_LEFT, 228.0, 10, Color("d6f5ff"))

func _draw_story_status_strip() -> void:
	var operation: Dictionary = _story_operation()
	var strip: Rect2 = Rect2(24.0, 22.0, 500.0, 54.0)
	draw_style_box(_panel_style(Color("0c2236", 0.94), Color("5d9fca"), 1, 7), strip)
	var operation_id: String = String(operation.get("id", "1.01"))
	var title: String = String(operation.get("title", "Story Dispatch"))
	var difficulty_label: String = String(_selected_difficulty().get("label", "MEDIUM"))
	draw_string(ThemeDB.fallback_font, strip.position + Vector2(10.0, 19.0), "STORY // %s // %s" % [operation_id, title], HORIZONTAL_ALIGNMENT_LEFT, 370.0, 11, Color("c6efff"))
	draw_string(ThemeDB.fallback_font, strip.position + Vector2(386.0, 19.0), difficulty_label, HORIZONTAL_ALIGNMENT_RIGHT, 102.0, 10, Color("f4d98b"))
	var objective: String = String(operation.get("objective", "Destroy the Syndicate Hideout."))
	draw_string(ThemeDB.fallback_font, strip.position + Vector2(10.0, 39.0), objective, HORIZONTAL_ALIGNMENT_LEFT, 478.0, 9, Color("9ec7db"))

func _draw_story_dispatch_board() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("00050e", 0.63))
	draw_style_box(_panel_style(Color("071b2c", 0.98), Color("7edcff"), 2, 10), campaign_panel)
	var operation: Dictionary = _story_operation()
	var route: Dictionary = _active_route()
	var act_label: String = String(operation.get("act", "STORY DISPATCH"))
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(20.0, 31.0), "MOONGOONS TAKE BACK // %s" % act_label, HORIZONTAL_ALIGNMENT_LEFT, 620.0, 18, Color("bff4ff"))
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(20.0, 51.0), "ROUTE: %s // The next dispatch follows the story automatically." % String(route.get("label", "LUNAR PEACEKEEPERS")), HORIZONTAL_ALIGNMENT_LEFT, 620.0, 10, Color("85b5cf"))
	var clearance: int = int(campaign_profile.get("clearance", 0))
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(505.0, 31.0), "CLEARANCE %02d" % clearance, HORIZONTAL_ALIGNMENT_RIGHT, 145.0, 11, Color("e8d9a0"))
	_draw_story_operation_panel(operation)
	_draw_difficulty_selection()
	var complete: bool = _story_route_complete()
	var start_label: String = "BEGIN NEXT DISPATCH"
	if complete:
		start_label = "ACT I COMPLETE // REPLAY FINALE"
	draw_style_box(_panel_style(Color("1b4f65", 0.98), Color("80e4ff"), 1, 6), campaign_start_button)
	draw_string(ThemeDB.fallback_font, campaign_start_button.position + Vector2(12.0, 21.0), start_label + "  [ENTER]", HORIZONTAL_ALIGNMENT_CENTER, 218.0, 11, Color("e8fbff"))
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(20.0, 392.0), "Only opponent difficulty is selectable. C or ESC closes this dispatch screen.", HORIZONTAL_ALIGNMENT_LEFT, 610.0, 9, Color("88abc0"))

func _draw_story_operation_panel(operation: Dictionary) -> void:
	var panel: Rect2 = Rect2(campaign_panel.position + Vector2(20.0, 68.0), Vector2(630.0, 222.0))
	draw_style_box(_panel_style(Color("123246", 0.98), Color("5aaccb"), 1, 7), panel)
	var operation_id: String = String(operation.get("id", "1.01"))
	var title: String = String(operation.get("title", "Story Dispatch"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(16.0, 25.0), "NEXT STORY DISPATCH // %s" % operation_id, HORIZONTAL_ALIGNMENT_LEFT, 590.0, 11, Color("89dff8"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(16.0, 49.0), title, HORIZONTAL_ALIGNMENT_LEFT, 590.0, 18, Color("f0fcff"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(16.0, 78.0), "BRIEFING", HORIZONTAL_ALIGNMENT_LEFT, 590.0, 10, Color("e9d58a"))
	draw_multiline_text(String(operation.get("briefing", "")), panel.position + Vector2(16.0, 98.0), 592.0, 10, Color("b7d6e5"), 4)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(16.0, 183.0), "PRIMARY OBJECTIVE", HORIZONTAL_ALIGNMENT_LEFT, 590.0, 10, Color("e9d58a"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(16.0, 204.0), String(operation.get("objective", "Destroy the Syndicate Hideout.")), HORIZONTAL_ALIGNMENT_LEFT, 592.0, 10, Color("d9f2fc"))

func _draw_difficulty_selection() -> void:
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(20.0, 326.0), "OPPONENT DIFFICULTY", HORIZONTAL_ALIGNMENT_LEFT, 620.0, 11, Color("e9d58a"))
	for difficulty_value: Variant in _campaign_difficulties():
		if not (difficulty_value is Dictionary):
			continue
		var difficulty: Dictionary = difficulty_value as Dictionary
		var difficulty_id: String = String(difficulty.get("id", "medium"))
		var button_value: Variant = difficulty_buttons.get(difficulty_id, Rect2())
		if not (button_value is Rect2):
			continue
		var button: Rect2 = button_value as Rect2
		var selected: bool = difficulty_id == _selected_difficulty_id()
		var fill: Color = Color("2b5a6f", 0.98) if selected else Color("132b3b", 0.98)
		var border: Color = Color("b7f3ff") if selected else Color("47748d")
		draw_style_box(_panel_style(fill, border, 1, 6), button)
		draw_string(ThemeDB.fallback_font, button.position + Vector2(10.0, 16.0), String(difficulty.get("label", difficulty_id)).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 172.0, 11, Color("f0fcff"))
		draw_string(ThemeDB.fallback_font, button.position + Vector2(10.0, 31.0), String(difficulty.get("description", "")), HORIZONTAL_ALIGNMENT_LEFT, 172.0, 8, Color("b2d4e3"))

func _draw_multiline_text(text: String, start: Vector2, width: float, font_size: int, color: Color, max_lines: int) -> void:
	var words: PackedStringArray = text.split(" ", false)
	var line: String = ""
	var line_index: int = 0
	for word: String in words:
		var candidate: String = word if line.is_empty() else line + " " + word
		if ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > width and not line.is_empty():
			draw_string(ThemeDB.fallback_font, start + Vector2(0.0, float(line_index * 15)), line, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)
			line_index += 1
			if line_index >= max_lines:
				return
			line = word
		else:
			line = candidate
	if not line.is_empty() and line_index < max_lines:
		draw_string(ThemeDB.fallback_font, start + Vector2(0.0, float(line_index * 15)), line, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _handle_story_dispatch_click(cursor: Vector2) -> void:
	if campaign_start_button.has_point(cursor):
		_start_story_dispatch()
		return
	for difficulty_id_value: Variant in difficulty_buttons.keys():
		var difficulty_id: String = String(difficulty_id_value)
		var button_value: Variant = difficulty_buttons[difficulty_id]
		if button_value is Rect2 and (button_value as Rect2).has_point(cursor):
			campaign_profile["difficulty_id"] = difficulty_id
			_save_campaign_profile()
			mission_state = "Opponent difficulty selected: %s." % String(_difficulty_by_id(difficulty_id).get("label", difficulty_id)).to_upper()
			queue_redraw()
			return
	if not campaign_panel.has_point(cursor):
		campaign_board_open = false
		queue_redraw()

func _start_story_dispatch() -> void:
	campaign_board_open = false
	_reset_match()
	var operation: Dictionary = _story_operation()
	mission_state = "STORY DISPATCH ACTIVE // %s" % String(operation.get("objective", "Destroy the Syndicate Hideout."))
	_log_event("Story dispatch started: %s on %s difficulty." % [String(operation.get("id", "1.01")), String(_selected_difficulty().get("label", "MEDIUM"))])
	queue_redraw()

func _apply_story_operation_profile() -> void:
	var operation: Dictionary = _story_operation()
	var profile_value: Variant = operation.get("match_profile", {})
	var profile: Dictionary = profile_value as Dictionary if profile_value is Dictionary else {}
	var difficulty: Dictionary = _selected_difficulty()
	credits = int(profile.get("credits", credits))
	lunar_alloy = int(profile.get("lunar_alloy", lunar_alloy))
	intel = int(profile.get("intel", intel))
	command_max = int(profile.get("command_max", command_max))
	nexus_integrity = float(profile.get("nexus_integrity", nexus_integrity))
	syndicate_hideout_hp = float(profile.get("hideout_integrity", syndicate_hideout_hp))
	enemy_spawn_clock = maxf(2.0, float(profile.get("first_enemy_wave_seconds", enemy_spawn_clock)) * float(difficulty.get("first_enemy_wave_multiplier", 1.0)))
	syndicate_war_chest = float(profile.get("syndicate_war_chest", syndicate_war_chest)) * float(difficulty.get("initial_war_chest_multiplier", 1.0))
	mission_state = "STORY READY // %s // %s" % [String(operation.get("objective", "Destroy the Syndicate Hideout.")), String(difficulty.get("label", "MEDIUM"))]

func _spawn_enemy_wave() -> void:
	super._spawn_enemy_wave()
	var difficulty: Dictionary = _selected_difficulty()
	var interval_multiplier: float = float(difficulty.get("enemy_wave_interval_multiplier", 1.0))
	enemy_spawn_clock = maxf(4.0, enemy_spawn_clock * interval_multiplier)

func _apply_syndicate_doctrines_to_enemy(enemy: Variant, wave_index: int) -> void:
	super._apply_syndicate_doctrines_to_enemy(enemy, wave_index)
	var difficulty: Dictionary = _selected_difficulty()
	var integrity_multiplier: float = float(difficulty.get("enemy_integrity_multiplier", 1.0))
	var damage_multiplier: float = float(difficulty.get("enemy_damage_multiplier", 1.0))
	enemy.max_hp *= integrity_multiplier
	enemy.hp = enemy.max_hp
	enemy.damage *= damage_multiplier

func _record_story_completion() -> void:
	campaign_result_recorded = true
	var operation: Dictionary = _story_operation()
	var operation_id: String = String(operation.get("id", ""))
	if operation_id.is_empty():
		return
	if _has_completed_operation(operation_id):
		_log_event("Story dispatch replay complete: %s." % operation_id)
		return
	var completed: Array = _completed_operations()
	completed.append(operation_id)
	campaign_profile["completed_operation_ids"] = completed
	var rewards_value: Variant = operation.get("rewards", {})
	var rewards: Dictionary = rewards_value as Dictionary if rewards_value is Dictionary else {}
	var gained_clearance: int = int(rewards.get("clearance", 0))
	var gained_intel: int = int(rewards.get("intel_cache", 0))
	campaign_profile["clearance"] = int(campaign_profile.get("clearance", 0)) + gained_clearance
	campaign_profile["intel_cache"] = int(campaign_profile.get("intel_cache", 0)) + gained_intel
	_ensure_story_progression()
	_save_campaign_profile()
	if _story_route_complete():
		mission_state = "ACT I COMPLETE // Clearance +%d // Breakwater secured." % gained_clearance
	else:
		mission_state = "DISPATCH COMPLETE // Clearance +%d // Next story operation ready." % gained_clearance
	_log_event("Story dispatch %s completed. Clearance +%d, Intel Cache +%d." % [operation_id, gained_clearance, gained_intel])

func _story_operation() -> Dictionary:
	var route_id: String = _active_route_id()
	for operation_value: Variant in _campaign_operations():
		if not (operation_value is Dictionary):
			continue
		var operation: Dictionary = operation_value as Dictionary
		if String(operation.get("route_id", route_id)) != route_id:
			continue
		var operation_id: String = String(operation.get("id", ""))
		if not _has_completed_operation(operation_id):
			return operation
	var final_operation: Dictionary = {}
	for operation_value: Variant in _campaign_operations():
		if operation_value is Dictionary:
			var operation: Dictionary = operation_value as Dictionary
			if String(operation.get("route_id", route_id)) == route_id:
				final_operation = operation
	return final_operation

func _story_route_complete() -> bool:
	var route_id: String = _active_route_id()
	var found_operation: bool = false
	for operation_value: Variant in _campaign_operations():
		if operation_value is Dictionary:
			var operation: Dictionary = operation_value as Dictionary
			if String(operation.get("route_id", route_id)) != route_id:
				continue
			found_operation = true
			if not _has_completed_operation(String(operation.get("id", ""))):
				return false
	return found_operation

func _ensure_story_progression() -> void:
	var route: Dictionary = _active_route()
	if route.is_empty() or not bool(route.get("available", false)):
		campaign_profile["route_id"] = _default_route_id()
	var story_operation: Dictionary = _story_operation()
	if not story_operation.is_empty():
		campaign_profile["selected_operation_id"] = String(story_operation.get("id", _default_operation_id()))
	if _difficulty_by_id(_selected_difficulty_id()).is_empty():
		campaign_profile["difficulty_id"] = _default_difficulty_id()

func _active_route_id() -> String:
	var route_id: String = String(campaign_profile.get("route_id", _default_route_id()))
	var route: Dictionary = _route_by_id(route_id)
	if route.is_empty() or not bool(route.get("available", false)):
		return _default_route_id()
	return route_id

func _active_route() -> Dictionary:
	return _route_by_id(_active_route_id())

func _route_by_id(route_id: String) -> Dictionary:
	for route_value: Variant in _campaign_routes():
		if route_value is Dictionary:
			var route: Dictionary = route_value as Dictionary
			if String(route.get("id", "")) == route_id:
				return route
	return {}

func _selected_difficulty_id() -> String:
	var difficulty_id: String = String(campaign_profile.get("difficulty_id", _default_difficulty_id()))
	if _difficulty_by_id(difficulty_id).is_empty():
		return _default_difficulty_id()
	return difficulty_id

func _selected_difficulty() -> Dictionary:
	return _difficulty_by_id(_selected_difficulty_id())

func _difficulty_by_id(difficulty_id: String) -> Dictionary:
	for difficulty_value: Variant in _campaign_difficulties():
		if difficulty_value is Dictionary:
			var difficulty: Dictionary = difficulty_value as Dictionary
			if String(difficulty.get("id", "")) == difficulty_id:
				return difficulty
	return {}

func _has_completed_operation(operation_id: String) -> bool:
	return _completed_operations().has(operation_id)

func _completed_operations() -> Array:
	var completed_value: Variant = campaign_profile.get("completed_operation_ids", [])
	if completed_value is Array:
		return (completed_value as Array).duplicate()
	return []

func _campaign_operations() -> Array:
	var operations_value: Variant = campaign_rules.get("operations", [])
	if operations_value is Array:
		return operations_value as Array
	return []

func _campaign_routes() -> Array:
	var routes_value: Variant = campaign_rules.get("campaign_routes", [])
	if routes_value is Array:
		return routes_value as Array
	return []

func _campaign_difficulties() -> Array:
	var difficulties_value: Variant = campaign_rules.get("difficulties", [])
	if difficulties_value is Array:
		return difficulties_value as Array
	return []

func _campaign_profile_config() -> Dictionary:
	var profile_value: Variant = campaign_rules.get("profile", {})
	return profile_value as Dictionary if profile_value is Dictionary else {}

func _default_route_id() -> String:
	return String(_campaign_profile_config().get("default_route_id", "lunar_peacekeepers"))

func _default_operation_id() -> String:
	return String(_campaign_profile_config().get("default_operation_id", "1.01"))

func _default_difficulty_id() -> String:
	return String(_campaign_profile_config().get("default_difficulty_id", "medium"))

func _load_campaign_profile() -> Dictionary:
	var fallback: Dictionary = {
		"profile_version": int(_campaign_profile_config().get("profile_version", 2)),
		"route_id": _default_route_id(),
		"selected_operation_id": _default_operation_id(),
		"difficulty_id": _default_difficulty_id(),
		"completed_operation_ids": [],
		"clearance": 0,
		"intel_cache": 0
	}
	if not FileAccess.file_exists(CAMPAIGN_PROFILE_PATH):
		return fallback
	var file: FileAccess = FileAccess.open(CAMPAIGN_PROFILE_PATH, FileAccess.READ)
	if file == null:
		return fallback
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return fallback
	var loaded: Dictionary = parsed as Dictionary
	for key_value: Variant in fallback.keys():
		var key: String = String(key_value)
		if not loaded.has(key):
			loaded[key] = fallback[key]
	loaded["profile_version"] = int(fallback["profile_version"])
	return loaded

func _save_campaign_profile() -> void:
	var file: FileAccess = FileAccess.open(CAMPAIGN_PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(campaign_profile, "  "))

func _load_campaign_rules() -> Dictionary:
	var path: String = "res://data/rts_phase_nine_campaign.json"
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
