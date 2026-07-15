extends "res://scripts/moongoons_rts_phase_eight_syndicate.gd"
## Godot 4.3-compatible Phase Nine story campaign controller.
## Keeps the fixed MoonGoons campaign route and difficulty selection while
## avoiding engine-version-specific drawing helpers.

const CAMPAIGN_PROFILE_PATH: String = "user://moongoons_campaign_profile.json"

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
		mission_state = "Story Dispatch opened. Choose difficulty and begin the next operation."
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
	draw_style_box(_panel_style(Color("173a4d", 0.96), Color("79d4ff"), 1, 6), campaign_button)
	draw_string(ThemeDB.fallback_font, campaign_button.position + Vector2(10.0, 16.0), "C  STORY DISPATCH", HORIZONTAL_ALIGNMENT_LEFT, 228.0, 10, Color("d6f5ff"))

func _draw_story_status_strip() -> void:
	var operation: Dictionary = _story_operation()
	var strip: Rect2 = Rect2(24.0, 22.0, 500.0, 54.0)
	draw_style_box(_panel_style(Color("0c2236", 0.94), Color("5d9fca"), 1, 7), strip)
	draw_string(ThemeDB.fallback_font, strip.position + Vector2(10.0, 19.0), "STORY // %s // %s" % [String(operation.get("id", "1.01")), String(operation.get("title", "Dispatch"))], HORIZONTAL_ALIGNMENT_LEFT, 370.0, 11, Color("c6efff"))
	draw_string(ThemeDB.fallback_font, strip.position + Vector2(386.0, 19.0), String(_selected_difficulty().get("label", "MEDIUM")), HORIZONTAL_ALIGNMENT_RIGHT, 102.0, 10, Color("f4d98b"))
	draw_string(ThemeDB.fallback_font, strip.position + Vector2(10.0, 39.0), String(operation.get("objective", "Destroy the Syndicate Hideout.")), HORIZONTAL_ALIGNMENT_LEFT, 478.0, 9, Color("9ec7db"))

func _draw_story_dispatch_board() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("00050e", 0.66))
	draw_style_box(_panel_style(Color("071b2c", 0.98), Color("7edcff"), 2, 10), campaign_panel)
	var operation: Dictionary = _story_operation()
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(20.0, 31.0), "MOONGOONS TAKE BACK // %s" % String(operation.get("act", "STORY DISPATCH")), HORIZONTAL_ALIGNMENT_LEFT, 620.0, 18, Color("bff4ff"))
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(20.0, 58.0), "NEXT // %s // %s" % [String(operation.get("id", "1.01")), String(operation.get("title", "Dispatch"))], HORIZONTAL_ALIGNMENT_LEFT, 620.0, 13, Color("f0fcff"))
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(20.0, 89.0), "BRIEFING", HORIZONTAL_ALIGNMENT_LEFT, 620.0, 10, Color("e9d58a"))
	_draw_wrapped_text(String(operation.get("briefing", "")), campaign_panel.position + Vector2(20.0, 108.0), 620.0, 10, Color("b7d6e5"), 5)
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(20.0, 205.0), "PRIMARY OBJECTIVE", HORIZONTAL_ALIGNMENT_LEFT, 620.0, 10, Color("e9d58a"))
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(20.0, 226.0), String(operation.get("objective", "Destroy the Syndicate Hideout.")), HORIZONTAL_ALIGNMENT_LEFT, 620.0, 10, Color("d9f2fc"))
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(20.0, 278.0), "OPPONENT DIFFICULTY", HORIZONTAL_ALIGNMENT_LEFT, 620.0, 11, Color("e9d58a"))
	for difficulty_value: Variant in _campaign_difficulties():
		if not difficulty_value is Dictionary:
			continue
		var difficulty: Dictionary = difficulty_value as Dictionary
		var difficulty_id: String = String(difficulty.get("id", "medium"))
		var button: Rect2 = difficulty_buttons.get(difficulty_id, Rect2()) as Rect2
		var selected: bool = difficulty_id == _selected_difficulty_id()
		draw_style_box(_panel_style(Color("2b5a6f", 0.98) if selected else Color("132b3b", 0.98), Color("b7f3ff") if selected else Color("47748d"), 1, 6), button)
		draw_string(ThemeDB.fallback_font, button.position + Vector2(10.0, 17.0), String(difficulty.get("label", difficulty_id)).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 172.0, 11, Color("f0fcff"))
		draw_string(ThemeDB.fallback_font, button.position + Vector2(10.0, 32.0), String(difficulty.get("description", "")), HORIZONTAL_ALIGNMENT_LEFT, 172.0, 8, Color("b2d4e3"))
	draw_style_box(_panel_style(Color("1b4f65", 0.98), Color("80e4ff"), 1, 6), campaign_start_button)
	draw_string(ThemeDB.fallback_font, campaign_start_button.position + Vector2(12.0, 21.0), "BEGIN NEXT DISPATCH  [ENTER]", HORIZONTAL_ALIGNMENT_CENTER, 218.0, 11, Color("e8fbff"))

func _draw_wrapped_text(text: String, start: Vector2, width: float, font_size: int, color: Color, max_lines: int) -> void:
	var words: PackedStringArray = text.split(" ", false)
	var line_text: String = ""
	var line_index: int = 0
	for word: String in words:
		var candidate: String = word if line_text.is_empty() else line_text + " " + word
		if ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > width and not line_text.is_empty():
			draw_string(ThemeDB.fallback_font, start + Vector2(0.0, float(line_index * 15)), line_text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)
			line_index += 1
			if line_index >= max_lines:
				return
			line_text = word
		else:
			line_text = candidate
	if not line_text.is_empty() and line_index < max_lines:
		draw_string(ThemeDB.fallback_font, start + Vector2(0.0, float(line_index * 15)), line_text, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _handle_story_dispatch_click(cursor: Vector2) -> void:
	if campaign_start_button.has_point(cursor):
		_start_story_dispatch()
		return
	for difficulty_value: Variant in difficulty_buttons.keys():
		var difficulty_id: String = String(difficulty_value)
		var button: Rect2 = difficulty_buttons[difficulty_id] as Rect2
		if button.has_point(cursor):
			campaign_profile["difficulty_id"] = difficulty_id
			_save_campaign_profile()
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
	_log_event("Story dispatch started: %s." % String(operation.get("id", "1.01")))
	queue_redraw()

func _apply_story_operation_profile() -> void:
	var operation: Dictionary = _story_operation()
	var profile: Dictionary = operation.get("match_profile", {}) as Dictionary
	var difficulty: Dictionary = _selected_difficulty()
	credits = int(profile.get("credits", credits))
	lunar_alloy = int(profile.get("lunar_alloy", lunar_alloy))
	intel = int(profile.get("intel", intel))
	command_max = int(profile.get("command_max", command_max))
	nexus_integrity = float(profile.get("nexus_integrity", nexus_integrity))
	syndicate_hideout_hp = float(profile.get("hideout_integrity", syndicate_hideout_hp)) * float(difficulty.get("enemy_integrity_multiplier", 1.0))
	enemy_spawn_clock = maxf(2.0, float(profile.get("first_enemy_wave_seconds", enemy_spawn_clock)) * float(difficulty.get("first_enemy_wave_multiplier", 1.0)))
	syndicate_war_chest = float(profile.get("syndicate_war_chest", syndicate_war_chest)) * float(difficulty.get("initial_war_chest_multiplier", 1.0))

func _record_story_completion() -> void:
	campaign_result_recorded = true
	var operation: Dictionary = _story_operation()
	var operation_id: String = String(operation.get("id", "1.01"))
	var completed: Array = campaign_profile.get("completed_operations", []) as Array
	if not completed.has(operation_id):
		completed.append(operation_id)
	campaign_profile["completed_operations"] = completed
	var rewards: Dictionary = operation.get("rewards", {}) as Dictionary
	campaign_profile["clearance"] = int(campaign_profile.get("clearance", 0)) + int(rewards.get("clearance", 1))
	campaign_profile["current_operation_id"] = _next_operation_id(operation_id)
	_save_campaign_profile()

func _story_operation() -> Dictionary:
	var operations: Array = campaign_rules.get("operations", []) as Array
	var current_id: String = String(campaign_profile.get("current_operation_id", "1.01"))
	for operation_value: Variant in operations:
		if operation_value is Dictionary and String((operation_value as Dictionary).get("id", "")) == current_id:
			return operation_value as Dictionary
	return operations[0] as Dictionary if not operations.is_empty() else {}

func _selected_difficulty() -> Dictionary:
	var selected_id: String = _selected_difficulty_id()
	for difficulty_value: Variant in _campaign_difficulties():
		if difficulty_value is Dictionary and String((difficulty_value as Dictionary).get("id", "")) == selected_id:
			return difficulty_value as Dictionary
	return {"id":"medium", "label":"MEDIUM"}

func _selected_difficulty_id() -> String:
	return String(campaign_profile.get("difficulty_id", "medium"))

func _campaign_difficulties() -> Array:
	return campaign_rules.get("difficulties", []) as Array

func _next_operation_id(current_id: String) -> String:
	var operations: Array = campaign_rules.get("operations", []) as Array
	for index: int in range(operations.size()):
		var operation: Dictionary = operations[index] as Dictionary
		if String(operation.get("id", "")) == current_id:
			if index + 1 < operations.size():
				return String((operations[index + 1] as Dictionary).get("id", current_id))
			return current_id
	return current_id

func _ensure_story_progression() -> void:
	if campaign_profile.is_empty():
		campaign_profile = {
			"route_id": "lunar_peacekeepers",
			"current_operation_id": "1.01",
			"difficulty_id": "medium",
			"completed_operations": [],
			"clearance": 0
		}

func _load_campaign_rules() -> Dictionary:
	var file: FileAccess = FileAccess.open("res://data/rts_phase_nine_campaign.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}

func _load_campaign_profile() -> Dictionary:
	if not FileAccess.file_exists(CAMPAIGN_PROFILE_PATH):
		return {}
	var file: FileAccess = FileAccess.open(CAMPAIGN_PROFILE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}

func _save_campaign_profile() -> void:
	var file: FileAccess = FileAccess.open(CAMPAIGN_PROFILE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(campaign_profile))
