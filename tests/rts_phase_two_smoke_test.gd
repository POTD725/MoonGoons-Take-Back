extends SceneTree
## Run with:
## godot --headless --path . --script res://tests/rts_phase_two_smoke_test.gd

var failures: Array[String] = []

func _init() -> void:
	_validate_phase_two_data()
	_validate_phase_two_script()
	if failures.is_empty():
		print("MoonGoons Take Back phase two smoke test passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _validate_phase_two_data() -> void:
	var file: FileAccess = FileAccess.open("res://data/rts_phase_two_rules.json", FileAccess.READ)
	if file == null:
		failures.append("Phase two rules file could not be opened.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		failures.append("Phase two rules file is not valid JSON.")
		return
	var rules: Dictionary = parsed as Dictionary
	var command_features: Dictionary = rules.get("command_features", {})
	var control_groups: Array = command_features.get("control_groups", [])
	if control_groups.size() != 5:
		failures.append("Phase two must define five control groups.")
	var peacekeepers: Dictionary = rules.get("peacekeeper_runtime", {})
	var vanguard: Dictionary = peacekeepers.get("riot_vanguard", {})
	var ability: Dictionary = vanguard.get("active_ability", {})
	if String(ability.get("id", "")) != "shield_wall":
		failures.append("Riot Vanguard Shield Wall definition is missing.")

func _validate_phase_two_script() -> void:
	var phase_script: Script = load("res://scripts/moongoons_rts_phase_two.gd") as Script
	if phase_script == null:
		failures.append("Phase two RTS controller could not be loaded.")
		return
	var game_data := MoonGoonsGameData.new()
	if not game_data.load_all():
		failures.append("Game data failed to load for phase two: %s" % ", ".join(game_data.errors))
		return
	if game_data.get_unit("lunar_peacekeepers", "pk_patrol_deputy").is_empty():
		failures.append("Phase two cannot resolve the Patrol Deputy catalog entry.")
	if game_data.get_unit("lunar_peacekeepers", "pk_riot_vanguard").is_empty():
		failures.append("Phase two cannot resolve the Riot Vanguard catalog entry.")
