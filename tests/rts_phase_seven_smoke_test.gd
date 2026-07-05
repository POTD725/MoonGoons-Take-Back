extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_validate_navigation_rules()
	_validate_phase_seven_script()
	if failures.is_empty():
		print("MoonGoons Take Back Phase Seven terrain and navigation smoke test passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _validate_navigation_rules() -> void:
	var file: FileAccess = FileAccess.open("res://data/rts_phase_seven_navigation.json", FileAccess.READ)
	if file == null:
		failures.append("Phase Seven navigation rules file could not be opened.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		failures.append("Phase Seven navigation rules file is not valid JSON.")
		return
	var rules: Dictionary = parsed as Dictionary
	var navigation: Dictionary = rules.get("navigation", {}) as Dictionary
	if float(navigation.get("unit_clearance", 0.0)) <= 0.0:
		failures.append("Navigation unit clearance must be positive.")
	if float(navigation.get("detour_clearance", 0.0)) <= 0.0:
		failures.append("Navigation detour clearance must be positive.")
	var features: Array = navigation.get("features", []) as Array
	var obstacle_count: int = 0
	var slow_count: int = 0
	var fast_count: int = 0
	for entry: Variant in features:
		if not (entry is Dictionary):
			failures.append("Navigation feature is not a dictionary.")
			continue
		var feature: Dictionary = entry as Dictionary
		match String(feature.get("kind", "")):
			"obstacle":
				obstacle_count += 1
				if float(feature.get("radius", 0.0)) <= 0.0:
					failures.append("Navigation obstacle needs a positive radius.")
			"slow_zone":
				slow_count += 1
			"fast_zone":
				fast_count += 1
		if String(feature.get("id", "")).is_empty():
			failures.append("Navigation feature id cannot be empty.")
	if obstacle_count < 3 or slow_count < 1 or fast_count < 1:
		failures.append("Phase Seven needs obstacles plus slow and fast terrain.")

func _validate_phase_seven_script() -> void:
	var phase_seven_script: Script = load("res://scripts/moongoons_rts_phase_seven.gd") as Script
	if phase_seven_script == null:
		failures.append("Phase Seven terrain controller could not be loaded.")
		return
	var controller: Node = phase_seven_script.new() as Node
	if controller == null or not controller.has_method("_navigate_position") or not controller.has_method("_issue_tactical_map_command"):
		failures.append("Phase Seven controller did not expose navigation and tactical-map commands.")
	if controller != null:
		controller.free()
