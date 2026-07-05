extends "res://scripts/moongoons_rts_phase_eight_syndicate.gd"
## Phase Nine: playable campaign operations and local progression profile.

const CAMPAIGN_PROFILE_PATH := "user://moongoons_campaign_profile.json"

var campaign_rules: Dictionary = {}
var campaign_profile: Dictionary = {}
var campaign_board_open: bool = false
var campaign_result_recorded: bool = false
var campaign_button: Rect2 = Rect2(994.0, 294.0, 248.0, 24.0)
var campaign_panel: Rect2 = Rect2(150.0, 108.0, 670.0, 500.0)
var campaign_start_button: Rect2 = Rect2(592.0, 556.0, 206.0, 32.0)

func _ready() -> void:
	campaign_rules = _load_campaign_rules()
	campaign_profile = _load_campaign_profile()
	_ensure_selected_operation()
	super._ready()
	queue_redraw()

func _reset_match() -> void:
	campaign_result_recorded = false
	super._reset_match()
	_apply_selected_operation_profile()

func _process(delta: float) -> void:
	if campaign_board_open:
		queue_redraw()
		return
	super._process(delta)
	if victory and not campaign_result_recorded:
		_record_operation_completion()
	queue_redraw()

func _handle_hotkey(keycode: Key) -> void:
	if keycode == KEY_C:
		campaign_board_open = not campaign_board_open
		mission_state = "Campaign Operations %s." % ("opened" if campaign_board_open else "closed")
		queue_redraw()
		return
	if campaign_board_open:
		if keycode == KEY_ESCAPE:
			campaign_board_open = false
		elif keycode == KEY_ENTER:
			_start_selected_operation()
		return
	super._handle_hotkey(keycode)

func _handle_left_press(cursor: Vector2) -> void:
	if campaign_board_open:
		_handle_campaign_board_click(cursor)
		return
	if campaign_button.has_point(cursor):
		campaign_board_open = true
		mission_state = "Campaign Operations opened. Select a cleared dispatch or an unlocked next operation."
		queue_redraw()
		return
	super._handle_left_press(cursor)

func _draw_world() -> void:
	super._draw_world()
	_draw_campaign_status_strip()
	if campaign_board_open:
		_draw_campaign_board()

func _draw_sidebar() -> void:
	super._draw_sidebar()
	_draw_campaign_button()

func _draw_campaign_button() -> void:
	draw_style_box(_panel_style(Color("173a4d", 0.96), Color("79d4ff"), 1, 6), campaign_button)
	draw_string(ThemeDB.fallback_font, campaign_button.position + Vector2(10.0, 16.0), "C  CAMPAIGN OPERATIONS", HORIZONTAL_ALIGNMENT_LEFT, 228.0, 10, Color("d6f5ff"))

func _draw_campaign_status_strip() -> void:
	var operation: Dictionary = _selected_operation()
	var strip: Rect2 = Rect2(24.0, 22.0, 470.0, 54.0)
	draw_style_box(_panel_style(Color("0c2236", 0.94), Color("5d9fca"), 1, 7), strip)
	var operation_id: String = String(operation.get("id", "1.01"))
	var title: String = String(operation.get("title", "Campaign Operation"))
	draw_string(ThemeDB.fallback_font, strip.position + Vector2(10.0, 19.0), "CAMPAIGN // %s // %s" % [operation_id, title], HORIZONTAL_ALIGNMENT_LEFT, 448.0, 11, Color("c6efff"))
	var objective: String = String(operation.get("objective", "Destroy the Syndicate Hideout."))
	draw_string(ThemeDB.fallback_font, strip.position + Vector2(10.0, 39.0), objective, HORIZONTAL_ALIGNMENT_LEFT, 448.0, 9, Color("9ec7db"))

func _draw_campaign_board() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("00050e", 0.63))
	draw_style_box(_panel_style(Color("071b2c", 0.98), Color("7edcff"), 2, 10), campaign_panel)
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(20.0, 31.0), "MOONGOONS TAKE BACK // CAMPAIGN OPERATIONS", HORIZONTAL_ALIGNMENT_LEFT, 620.0, 18, Color("bff4ff"))
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(20.0, 51.0), "Act I dispatches. Completed operations persist locally on this device.", HORIZONTAL_ALIGNMENT_LEFT, 620.0, 10, Color("85b5cf"))
	var clearance: int = int(campaign_profile.get("clearance", 0))
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(505.0, 31.0), "CLEARANCE %02d" % clearance, HORIZONTAL_ALIGNMENT_RIGHT, 145.0, 11, Color("e8d9a0"))
	var operations: Array = _campaign_operations()
	for index: int in range(operations.size()):
		var operation_value: Variant = operations[index]
		if not (operation_value is Dictionary):
			continue
		var operation: Dictionary = operation_value as Dictionary
		_draw_operation_card(index, operation)
	var selected: Dictionary = _selected_operation()
	var start_label: String = "START OPERATION"
	if not _is_operation_unlocked(selected):
		start_label = "LOCKED // COMPLETE PRIOR DISPATCH"
	draw_style_box(_panel_style(Color("1b4f65", 0.98), Color("80e4ff"), 1, 6), campaign_start_button)
	draw_string(ThemeDB.fallback_font, campaign_start_button.position + Vector2(12.0, 21.0), start_label + "  [ENTER]", HORIZONTAL_ALIGNMENT_CENTER, 182.0, 11, Color("e8fbff"))
	draw_string(ThemeDB.fallback_font, campaign_panel.position + Vector2(20.0, 475.0), "C or ESC closes the board. Select an unlocked card, then start the dispatch.", HORIZONTAL_ALIGNMENT_LEFT, 540.0, 9, Color("88abc0"))

func _draw_operation_card(index: int, operation: Dictionary) -> void:
	var card: Rect2 = _operation_card_rect(index)
	var operation_id: String = String(operation.get("id", ""))
	var is_selected: bool = operation_id == String(campaign_profile.get("selected_operation_id", ""))
	var unlocked: bool = _is_operation_unlocked(operation)
	var completed: bool = _has_completed_operation(operation_id)
	var fill: Color = Color("14384b", 0.98) if unlocked else Color("17212c", 0.98)
	var border: Color = Color("a9f2ff") if is_selected else (Color("4c9cba") if unlocked else Color("46535f"))
	draw_style_box(_panel_style(fill, border, 1, 6), card)
	var status: String = "AVAILABLE"
	if completed:
		status = "COMPLETE"
	elif not unlocked:
		status = "LOCKED"
	draw_string(ThemeDB.fallback_font, card.position + Vector2(12.0, 19.0), "%s // %s" % [operation_id, String(operation.get("title", "Operation"))], HORIZONTAL_ALIGNMENT_LEFT, 430.0, 12, Color("e8fbff") if unlocked else Color("8a99a3"))
	draw_string(ThemeDB.fallback_font, card.position + Vector2(500.0, 19.0), status, HORIZONTAL_ALIGNMENT_RIGHT, 105.0, 10, Color("a8f5cf") if completed else (Color("f6d686") if unlocked else Color("75818a")))
	draw_string(ThemeDB.fallback_font, card.position + Vector2(12.0, 38.0), String(operation.get("objective", "")), HORIZONTAL_ALIGNMENT_LEFT, 590.0, 9, Color("a7c9dc") if unlocked else Color("697783"))
	if is_selected:
		draw_string(ThemeDB.fallback_font, card.position + Vector2(12.0, 54.0), "SELECTED // %s" % String(operation.get("briefing", "")), HORIZONTAL_ALIGNMENT_LEFT, 590.0, 8, Color("8fe4ff"))

func _handle_campaign_board_click(cursor: Vector2) -> void:
	if campaign_start_button.has_point(cursor):
		_start_selected_operation()
		return
	if not campaign_panel.has_point(cursor):
		campaign_board_open = false
		queue_redraw()
		return
	var operations: Array = _campaign_operations()
	for index: int in range(operations.size()):
		var card: Rect2 = _operation_card_rect(index)
		if not card.has_point(cursor):
			continue
		var operation_value: Variant = operations[index]
		if not (operation_value is Dictionary):
			return
		var operation: Dictionary = operation_value as Dictionary
		if not _is_operation_unlocked(operation):
			mission_state = "Operation locked. Complete %s first." % String(operation.get("unlock_after", "the prior dispatch"))
			return
		campaign_profile["selected_operation_id"] = String(operation.get("id", "1.01"))
		_save_campaign_profile()
		mission_state = "Campaign operation selected: %s." % String(operation.get("title", "Operation"))
		queue_redraw()
		return

func _start_selected_operation() -> void:
	var operation: Dictionary = _selected_operation()
	if operation.is_empty():
		return
	if not _is_operation_unlocked(operation):
		mission_state = "Complete the previous campaign operation before starting this one."
		return
	campaign_board_open = false
	_reset_match()
	mission_state = "CAMPAIGN DISPATCH ACTIVE // %s" % String(operation.get("objective", "Destroy the Syndicate Hideout."))
	_log_event("Campaign operation started: %s." % String(operation.get("id", "1.01")))
	queue_redraw()

func _apply_selected_operation_profile() -> void:
	var operation: Dictionary = _selected_operation()
	var profile_value: Variant = operation.get("match_profile", {})
	var profile: Dictionary = profile_value as Dictionary if profile_value is Dictionary else {}
	credits = int(profile.get("credits", credits))
	lunar_alloy = int(profile.get("lunar_alloy", lunar_alloy))
	intel = int(profile.get("intel", intel))
	command_max = int(profile.get("command_max", command_max))
	nexus_integrity = float(profile.get("nexus_integrity", nexus_integrity))
	syndicate_hideout_hp = float(profile.get("hideout_integrity", syndicate_hideout_hp))
	enemy_spawn_clock = float(profile.get("first_enemy_wave_seconds", enemy_spawn_clock))
	syndicate_war_chest = float(profile.get("syndicate_war_chest", syndicate_war_chest))
	mission_state = "CAMPAIGN READY // %s" % String(operation.get("objective", "Destroy the Syndicate Hideout."))

func _record_operation_completion() -> void:
	campaign_result_recorded = true
	var operation: Dictionary = _selected_operation()
	var operation_id: String = String(operation.get("id", ""))
	if operation_id.is_empty():
		return
	if _has_completed_operation(operation_id):
		_log_event("Campaign replay complete: %s." % operation_id)
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
	_save_campaign_profile()
	var next_operation: Dictionary = _next_operation_after(operation_id)
	if not next_operation.is_empty():
		campaign_profile["selected_operation_id"] = String(next_operation.get("id", operation_id))
		_save_campaign_profile()
		mission_state = "OPERATION COMPLETE // Clearance +%d // Next dispatch unlocked." % gained_clearance
	_log_event("Campaign operation %s completed. Clearance +%d, Intel Cache +%d." % [operation_id, gained_clearance, gained_intel])

func _selected_operation() -> Dictionary:
	var selected_id: String = String(campaign_profile.get("selected_operation_id", _default_operation_id()))
	var selected: Dictionary = _operation_by_id(selected_id)
	if not selected.is_empty():
		return selected
	return _operation_by_id(_first_unlocked_operation_id())

func _operation_by_id(operation_id: String) -> Dictionary:
	for operation_value: Variant in _campaign_operations():
		if operation_value is Dictionary:
			var operation: Dictionary = operation_value as Dictionary
			if String(operation.get("id", "")) == operation_id:
				return operation
	return {}

func _next_operation_after(operation_id: String) -> Dictionary:
	for operation_value: Variant in _campaign_operations():
		if operation_value is Dictionary:
			var operation: Dictionary = operation_value as Dictionary
			if String(operation.get("unlock_after", "")) == operation_id:
				return operation
	return {}

func _is_operation_unlocked(operation: Dictionary) -> bool:
	var prerequisite: String = String(operation.get("unlock_after", ""))
	return prerequisite.is_empty() or _has_completed_operation(prerequisite)

func _has_completed_operation(operation_id: String) -> bool:
	return _completed_operations().has(operation_id)

func _completed_operations() -> Array:
	var completed_value: Variant = campaign_profile.get("completed_operation_ids", [])
	if completed_value is Array:
		return (completed_value as Array).duplicate()
	return []

func _operation_card_rect(index: int) -> Rect2:
	return Rect2(campaign_panel.position + Vector2(20.0, 64.0 + float(index) * 72.0), Vector2(630.0, 64.0))

func _campaign_operations() -> Array:
	var operations_value: Variant = campaign_rules.get("operations", [])
	if operations_value is Array:
		return operations_value as Array
	return []

func _campaign_profile_config() -> Dictionary:
	var profile_value: Variant = campaign_rules.get("profile", {})
	return profile_value as Dictionary if profile_value is Dictionary else {}

func _default_operation_id() -> String:
	return String(_campaign_profile_config().get("default_operation_id", "1.01"))

func _first_unlocked_operation_id() -> String:
	for operation_value: Variant in _campaign_operations():
		if operation_value is Dictionary:
			var operation: Dictionary = operation_value as Dictionary
			if _is_operation_unlocked(operation):
				return String(operation.get("id", _default_operation_id()))
	return _default_operation_id()

func _ensure_selected_operation() -> void:
	var selected_id: String = String(campaign_profile.get("selected_operation_id", ""))
	var selected: Dictionary = _operation_by_id(selected_id)
	if selected.is_empty() or not _is_operation_unlocked(selected):
		campaign_profile["selected_operation_id"] = _first_unlocked_operation_id()
		_save_campaign_profile()

func _load_campaign_profile() -> Dictionary:
	var fallback: Dictionary = {
		"profile_version": 1,
		"selected_operation_id": _default_operation_id(),
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
	for key: String in fallback.keys():
		if not loaded.has(key):
			loaded[key] = fallback[key]
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
