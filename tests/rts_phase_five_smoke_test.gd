extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_validate_siphon_raid_rules()
	_validate_phase_five_script()
	if failures.is_empty():
		print("MoonGoons Take Back Phase Five Siphon Raid smoke test passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _validate_siphon_raid_rules() -> void:
	var file: FileAccess = FileAccess.open("res://data/rts_phase_five_siphon_raids.json", FileAccess.READ)
	if file == null:
		failures.append("Phase Five Siphon Raid rules file could not be opened.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		failures.append("Phase Five Siphon Raid rules file is not valid JSON.")
		return
	var rules: Dictionary = parsed as Dictionary
	var siphon: Dictionary = rules.get("siphon_raids", {}) as Dictionary
	if float(siphon.get("first_deployment_seconds", 0.0)) <= 0.0:
		failures.append("Siphon Raids need a positive first-deployment time.")
	if float(siphon.get("deployment_interval_seconds", 0.0)) <= 0.0:
		failures.append("Siphon Raids need a positive recurring deployment interval.")
	if float(siphon.get("integrity", 0.0)) <= 0.0:
		failures.append("Siphon Arrays need positive integrity.")
	if float(siphon.get("drain_interval_seconds", 0.0)) <= 0.0:
		failures.append("Siphon Raids need a positive drain interval.")
	if int(siphon.get("node_drain_amount", 0)) <= 0 or int(siphon.get("stockpile_drain_amount", 0)) <= 0:
		failures.append("Siphon Raids must drain both a resource node and player stockpile.")
	if int(siphon.get("neutralize_intel_bonus", 0)) <= 0:
		failures.append("Neutralizing a Siphon Array must award positive Intel.")

func _validate_phase_five_script() -> void:
	var phase_five_script: Script = load("res://scripts/moongoons_rts_phase_five.gd") as Script
	if phase_five_script == null:
		failures.append("Phase Five counter-operations controller could not be loaded.")
		return
	var controller: Node = phase_five_script.new() as Node
	if controller == null or not controller.has_method("_deploy_siphon_raid"):
		failures.append("Phase Five controller did not expose Siphon Raid deployment.")
	if controller != null:
		controller.free()
