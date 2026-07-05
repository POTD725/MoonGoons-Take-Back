extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_validate_story_campaign_rules()
	_validate_campaign_controller()
	if failures.is_empty():
		print("MoonGoons Take Back Phase Nine story campaign smoke test passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _validate_story_campaign_rules() -> void:
	var file: FileAccess = FileAccess.open("res://data/rts_phase_nine_campaign.json", FileAccess.READ)
	if file == null:
		failures.append("Phase Nine story campaign rules file could not be opened.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		failures.append("Phase Nine story campaign rules file is not valid JSON.")
		return
	var rules: Dictionary = parsed as Dictionary
	var profile: Dictionary = rules.get("profile", {}) as Dictionary
	if String(profile.get("default_route_id", "")).is_empty():
		failures.append("Story campaign profile needs a default route id.")
	if String(profile.get("default_operation_id", "")).is_empty():
		failures.append("Story campaign profile needs a default operation id.")
	if String(profile.get("default_difficulty_id", "")).is_empty():
		failures.append("Story campaign profile needs a default difficulty id.")
	var routes: Array = rules.get("campaign_routes", []) as Array
	var available_route_count: int = 0
	var default_route_found: bool = false
	for route_value: Variant in routes:
		if not (route_value is Dictionary):
			failures.append("Campaign route entry is not a dictionary.")
			continue
		var route: Dictionary = route_value as Dictionary
		if bool(route.get("available", false)):
			available_route_count += 1
		if String(route.get("id", "")) == String(profile.get("default_route_id", "")):
			default_route_found = true
	if not default_route_found:
		failures.append("Story campaign default route must reference a defined route.")
	if available_route_count != 1:
		failures.append("Current story campaign must expose exactly one playable route until other races are implemented.")
	var difficulties: Array = rules.get("difficulties", []) as Array
	var required_difficulties: Dictionary = {"easy": false, "medium": false, "hard": false}
	for difficulty_value: Variant in difficulties:
		if not (difficulty_value is Dictionary):
			failures.append("Difficulty entry is not a dictionary.")
			continue
		var difficulty: Dictionary = difficulty_value as Dictionary
		var difficulty_id: String = String(difficulty.get("id", ""))
		if required_difficulties.has(difficulty_id):
			required_difficulties[difficulty_id] = true
		if float(difficulty.get("enemy_integrity_multiplier", 0.0)) <= 0.0 or float(difficulty.get("enemy_damage_multiplier", 0.0)) <= 0.0:
			failures.append("Difficulty %s needs positive enemy strength multipliers." % difficulty_id)
	for difficulty_id_value: Variant in required_difficulties.keys():
		var required_id: String = String(difficulty_id_value)
		if not bool(required_difficulties[required_id]):
			failures.append("Story campaign is missing %s difficulty." % required_id)
	var operations: Array = rules.get("operations", []) as Array
	if operations.size() < 5:
		failures.append("Phase Nine needs at least five opening story operations.")
	var known_ids: Dictionary = {}
	var previous_id: String = ""
	for operation_value: Variant in operations:
		if not (operation_value is Dictionary):
			failures.append("Story operation entry is not a dictionary.")
			continue
		var operation: Dictionary = operation_value as Dictionary
		var operation_id: String = String(operation.get("id", ""))
		if operation_id.is_empty() or known_ids.has(operation_id):
			failures.append("Story operation ids must be unique and non-empty.")
		known_ids[operation_id] = true
		if String(operation.get("route_id", "")) != String(profile.get("default_route_id", "")):
			failures.append("Opening story operations must belong to the active playable route.")
		var prerequisite: String = String(operation.get("unlock_after", ""))
		if not prerequisite.is_empty() and prerequisite != previous_id:
			failures.append("Story operations must form one fixed sequential chain.")
		previous_id = operation_id
		var match_profile: Dictionary = operation.get("match_profile", {}) as Dictionary
		if int(match_profile.get("credits", 0)) <= 0 or float(match_profile.get("hideout_integrity", 0.0)) <= 0.0:
			failures.append("Story operation %s needs playable economy and hideout values." % operation_id)
		var rewards: Dictionary = operation.get("rewards", {}) as Dictionary
		if int(rewards.get("clearance", 0)) <= 0:
			failures.append("Story operation %s needs a positive clearance reward." % operation_id)
	if not known_ids.has(String(profile.get("default_operation_id", ""))):
		failures.append("Story campaign default operation must reference a defined operation.")

func _validate_campaign_controller() -> void:
	var campaign_script: Script = load("res://scripts/moongoons_rts_phase_nine_campaign.gd") as Script
	if campaign_script == null:
		failures.append("Phase Nine story campaign controller could not be loaded.")
		return
	var controller: Node = campaign_script.new() as Node
	if controller == null:
		failures.append("Phase Nine story campaign controller could not be instantiated.")
		return
	for method_name: String in ["_story_operation", "_start_story_dispatch", "_record_story_completion", "_selected_difficulty", "_apply_story_operation_profile"]:
		if not controller.has_method(method_name):
			failures.append("Phase Nine story campaign controller is missing %s." % method_name)
	controller.free()
