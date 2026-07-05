extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_validate_campaign_rules()
	_validate_campaign_controller()
	if failures.is_empty():
		print("MoonGoons Take Back Phase Nine campaign smoke test passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _validate_campaign_rules() -> void:
	var file: FileAccess = FileAccess.open("res://data/rts_phase_nine_campaign.json", FileAccess.READ)
	if file == null:
		failures.append("Phase Nine campaign rules file could not be opened.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		failures.append("Phase Nine campaign rules file is not valid JSON.")
		return
	var rules: Dictionary = parsed as Dictionary
	var profile: Dictionary = rules.get("profile", {}) as Dictionary
	if String(profile.get("default_operation_id", "")).is_empty():
		failures.append("Campaign profile needs a default operation id.")
	var operations: Array = rules.get("operations", []) as Array
	if operations.size() < 5:
		failures.append("Phase Nine needs at least five opening campaign operations.")
	var known_ids: Dictionary = {}
	var previous_id: String = ""
	for operation_value: Variant in operations:
		if not (operation_value is Dictionary):
			failures.append("Campaign operation entry is not a dictionary.")
			continue
		var operation: Dictionary = operation_value as Dictionary
		var operation_id: String = String(operation.get("id", ""))
		if operation_id.is_empty() or known_ids.has(operation_id):
			failures.append("Campaign operation ids must be unique and non-empty.")
		known_ids[operation_id] = true
		var prerequisite: String = String(operation.get("unlock_after", ""))
		if not prerequisite.is_empty() and prerequisite != previous_id:
			failures.append("Campaign operations must form a sequential opening dispatch chain.")
		previous_id = operation_id
		var match_profile: Dictionary = operation.get("match_profile", {}) as Dictionary
		if int(match_profile.get("credits", 0)) <= 0 or float(match_profile.get("hideout_integrity", 0.0)) <= 0.0:
			failures.append("Campaign operation %s needs playable economy and hideout values." % operation_id)
		var rewards: Dictionary = operation.get("rewards", {}) as Dictionary
		if int(rewards.get("clearance", 0)) <= 0:
			failures.append("Campaign operation %s needs a positive clearance reward." % operation_id)
	if not known_ids.has(String(profile.get("default_operation_id", ""))):
		failures.append("Campaign default operation must reference a defined operation.")

func _validate_campaign_controller() -> void:
	var campaign_script: Script = load("res://scripts/moongoons_rts_phase_nine_campaign.gd") as Script
	if campaign_script == null:
		failures.append("Phase Nine campaign controller could not be loaded.")
		return
	var controller: Node = campaign_script.new() as Node
	if controller == null:
		failures.append("Phase Nine campaign controller could not be instantiated.")
		return
	for method_name: String in ["_start_selected_operation", "_record_operation_completion", "_load_campaign_profile", "_save_campaign_profile"]:
		if not controller.has_method(method_name):
			failures.append("Phase Nine campaign controller is missing %s." % method_name)
	controller.free()
