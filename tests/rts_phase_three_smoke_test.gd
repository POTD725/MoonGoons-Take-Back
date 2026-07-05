extends SceneTree
## Run with:
## godot --headless --path . --script res://tests/rts_phase_three_smoke_test.gd

var failures: Array[String] = []

func _init() -> void:
	_validate_territory_rules()
	_validate_phase_three_script()
	if failures.is_empty():
		print("MoonGoons Take Back Phase Three territory smoke test passed.")
		quit(0)
	for failure: String in failures:
		push_error(failure)
	quit(1)

func _validate_territory_rules() -> void:
	var file: FileAccess = FileAccess.open("res://data/rts_phase_three_territories.json", FileAccess.READ)
	if file == null:
		failures.append("Phase Three territory rules file could not be opened.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		failures.append("Phase Three territory rules file is not valid JSON.")
		return
	var rules: Dictionary = parsed as Dictionary
	var capture_rules: Dictionary = rules.get("capture_rules", {}) as Dictionary
	if float(capture_rules.get("radius", 0.0)) <= 0.0:
		failures.append("Territory capture radius must be positive.")
	if float(capture_rules.get("outpost_income_multiplier", 0.0)) < 2.0:
		failures.append("Forward Relay bonus must double sector income or better.")
	var territories: Array = rules.get("territories", []) as Array
	if territories.size() != 3:
		failures.append("Phase Three must define exactly three opening territories.")
	var ids: Dictionary = {}
	for entry: Variant in territories:
		if not (entry is Dictionary):
			failures.append("Territory entry is not a dictionary.")
			continue
		var territory: Dictionary = entry as Dictionary
		var territory_id: String = String(territory.get("id", ""))
		var position: Array = territory.get("position", []) as Array
		if territory_id.is_empty() or ids.has(territory_id):
			failures.append("Territory identifiers must be unique and non-empty.")
		ids[territory_id] = true
		if position.size() != 2:
			failures.append("Territory %s needs a two-value map position." % territory_id)
		if int(territory.get("income_amount", 0)) <= 0:
			failures.append("Territory %s must produce resources." % territory_id)

func _validate_phase_three_script() -> void:
	var phase_three_script: Script = load("res://scripts/moongoons_rts_phase_three.gd") as Script
	if phase_three_script == null:
		failures.append("Phase Three territory controller could not be loaded.")
