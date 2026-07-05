class_name MoonGoonsDebugConsole
extends RefCounted
## Developer-only command parser.
## It returns validated action requests; a debug-build mission controller decides how to apply them.

const MAX_TIME_SCALE := 4.0
const MIN_TIME_SCALE := 0.1
const INTEL_CAP := 200

var enabled := false

func set_enabled(is_enabled: bool) -> void:
	enabled = is_enabled

func execute(command_line: String) -> Dictionary:
	if not enabled:
		return _error("Debug console is disabled.")
	var tokens := command_line.strip_edges().split(" ", false)
	if tokens.is_empty():
		return _error("Enter a command.")
	var command := String(tokens[0]).to_lower()
	match command:
		"mg_give_credits":
			return _integer_action(tokens, "give_credits", "amount")
		"mg_give_alloy":
			return _integer_action(tokens, "give_alloy", "amount")
		"mg_give_evidence":
			return _integer_action(tokens, "give_evidence", "amount")
		"mg_unlock_intel":
			return _success("set_intel", {"amount": INTEL_CAP})
		"mg_reveal_map":
			return _success("reveal_map")
		"mg_spawn_unit":
			if tokens.size() != 2:
				return _error("Usage: mg_spawn_unit <unit_id>")
			return _success("spawn_unit", {"unit_id": String(tokens[1])})
		"mg_kill_selected":
			return _success("kill_selected")
		"mg_freeze_ai":
			return _success("toggle_ai_freeze")
		"mg_game_speed":
			return _speed_action(tokens)
		"help", "mg_help":
			return _success("help", {"commands": supported_commands()})
	return _error("Unknown command: %s" % command)

func supported_commands() -> Array[String]:
	return [
		"mg_give_credits <integer>",
		"mg_give_alloy <integer>",
		"mg_unlock_intel",
		"mg_give_evidence <integer>",
		"mg_reveal_map",
		"mg_spawn_unit <unit_id>",
		"mg_kill_selected",
		"mg_freeze_ai",
		"mg_game_speed <0.1-4.0>",
		"mg_help"
	]

func _integer_action(tokens: PackedStringArray, action: String, field_name: String) -> Dictionary:
	if tokens.size() != 2 or not String(tokens[1]).is_valid_int():
		return _error("Usage: %s <integer>" % String(tokens[0]))
	return _success(action, {field_name: int(tokens[1])})

func _speed_action(tokens: PackedStringArray) -> Dictionary:
	if tokens.size() != 2 or not String(tokens[1]).is_valid_float():
		return _error("Usage: mg_game_speed <0.1-4.0>")
	var requested := clampf(float(tokens[1]), MIN_TIME_SCALE, MAX_TIME_SCALE)
	return _success("set_game_speed", {"time_scale": requested})

func _success(action: String, payload: Dictionary = {}) -> Dictionary:
	return {"ok": true, "action": action, "payload": payload}

func _error(message: String) -> Dictionary:
	return {"ok": false, "error": message}
