extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_validate_recon_rules()
	_validate_phase_four_script()
	if failures.is_empty():
		print("MoonGoons Take Back Phase Four recon smoke test passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _validate_recon_rules() -> void:
	var file: FileAccess = FileAccess.open("res://data/rts_phase_four_recon.json", FileAccess.READ)
	if file == null:
		failures.append("Phase Four recon rules file could not be opened.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		failures.append("Phase Four recon rules file is not valid JSON.")
		return
	var rules: Dictionary = parsed as Dictionary
	var fog: Dictionary = rules.get("fog", {}) as Dictionary
	var scan: Dictionary = rules.get("tactical_scan", {}) as Dictionary
	if int(fog.get("tile_size", 0)) < 16:
		failures.append("Fog tiles must be at least 16 pixels for a stable grid.")
	if float(fog.get("unexplored_opacity", 0.0)) <= float(fog.get("explored_opacity", 1.0)):
		failures.append("Unexplored fog must be denser than explored fog.")
	if float(fog.get("deputy_vision_radius", 0.0)) <= float(fog.get("worker_vision_radius", 0.0)):
		failures.append("Patrol Deputies must reveal farther than Survey Drones.")
	if float(fog.get("relay_vision_radius", 0.0)) <= float(fog.get("secured_sector_vision_radius", 0.0)):
		failures.append("Communications Relays must provide stronger sight than an unfortified sector.")
	if int(scan.get("intel_cost", 0)) <= 0:
		failures.append("Tactical Scan must cost positive Intel.")
	if float(scan.get("duration_seconds", 0.0)) <= 0.0 or float(scan.get("radius", 0.0)) <= 0.0:
		failures.append("Tactical Scan must have positive duration and radius.")

func _validate_phase_four_script() -> void:
	var phase_four_script: Script = load("res://scripts/moongoons_rts_phase_four.gd") as Script
	if phase_four_script == null:
		failures.append("Phase Four recon controller could not be loaded.")
		return
	var controller: Node = phase_four_script.new() as Node
	if controller == null or not controller.has_method("_activate_tactical_scan"):
		failures.append("Phase Four recon controller did not expose Tactical Scan.")
	if controller != null:
		controller.free()
