extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_validate_syndicate_rules()
	_validate_phase_eight_controller()
	if failures.is_empty():
		print("MoonGoons Take Back Phase Eight Syndicate economy smoke test passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _validate_syndicate_rules() -> void:
	var file: FileAccess = FileAccess.open("res://data/rts_phase_eight_syndicate.json", FileAccess.READ)
	if file == null:
		failures.append("Phase Eight Syndicate rules file could not be opened.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		failures.append("Phase Eight Syndicate rules file is not valid JSON.")
		return
	var rules: Dictionary = parsed as Dictionary
	var economy: Dictionary = rules.get("syndicate_economy", {}) as Dictionary
	if float(economy.get("base_war_chest_income_per_second", 0.0)) <= 0.0:
		failures.append("Syndicate War Chest needs positive base income.")
	if float(economy.get("active_siphon_income_per_second", 0.0)) <= 0.0:
		failures.append("Active Siphon Arrays must contribute to the War Chest.")
	var doctrines: Array = rules.get("doctrines", []) as Array
	if doctrines.size() != 3:
		failures.append("Phase Eight needs three opening Syndicate doctrines.")
	var previous_threshold: float = 0.0
	for doctrine_value: Variant in doctrines:
		if not (doctrine_value is Dictionary):
			failures.append("Syndicate doctrine must be a dictionary.")
			continue
		var doctrine: Dictionary = doctrine_value as Dictionary
		var threshold: float = float(doctrine.get("war_chest_required", 0.0))
		if threshold <= previous_threshold:
			failures.append("Syndicate doctrine thresholds must be strictly increasing.")
		previous_threshold = threshold
	var roster: Array = rules.get("roster", []) as Array
	for required_unit: String in ["runner", "shade", "bruiser", "siphon_array"]:
		var found: bool = false
		for entry: Variant in roster:
			if entry is Dictionary and String((entry as Dictionary).get("id", "")) == required_unit:
				found = true
		if not found:
			failures.append("Syndicate roster is missing %s." % required_unit)

func _validate_phase_eight_controller() -> void:
	var phase_eight_script: Script = load("res://scripts/moongoons_rts_phase_eight_syndicate.gd") as Script
	if phase_eight_script == null:
		failures.append("Phase Eight Syndicate controller could not be loaded.")
		return
	var controller: Node = phase_eight_script.new() as Node
	if controller == null:
		failures.append("Phase Eight Syndicate controller could not be instantiated.")
		return
	for method_name: String in ["_update_syndicate_economy", "_apply_syndicate_doctrines_to_enemy", "_unlock_available_syndicate_doctrines"]:
		if not controller.has_method(method_name):
			failures.append("Phase Eight Syndicate controller is missing %s." % method_name)
	controller.free()
