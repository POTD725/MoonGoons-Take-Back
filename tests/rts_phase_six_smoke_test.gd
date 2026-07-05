extends SceneTree
## Run with:
## godot --headless --path . --script res://tests/rts_phase_six_smoke_test.gd

var failures: Array[String] = []

func _init() -> void:
	_validate_devtool_rules()
	_validate_phase_six_script()
	if failures.is_empty():
		print("MoonGoons Take Back Phase Six developer console smoke test passed.")
		quit(0)
	for failure: String in failures:
		push_error(failure)
	quit(1)

func _validate_devtool_rules() -> void:
	var file: FileAccess = FileAccess.open("res://data/rts_phase_six_devtools.json", FileAccess.READ)
	if file == null:
		failures.append("Phase Six developer tools rules file could not be opened.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		failures.append("Phase Six developer tools rules file is not valid JSON.")
		return
	var rules: Dictionary = parsed as Dictionary
	var console: Dictionary = rules.get("developer_console", {}) as Dictionary
	if not bool(console.get("enabled", false)):
		failures.append("Developer console must be enabled for debug builds.")
	if bool(console.get("allow_release", true)):
		failures.append("Developer console must remain disabled in release builds by default.")
	if String(console.get("toggle_hotkey", "")) != "F1":
		failures.append("Developer console toggle must be F1.")
	if int(console.get("max_history_lines", 0)) < 4:
		failures.append("Developer console history must retain at least four lines.")
	var commands: Array = console.get("commands", []) as Array
	for command_name: String in ["help", "status", "spawn <worker|deputy|vanguard> [count]", "siphon", "reveal [seconds]", "restart"]:
		if not commands.has(command_name):
			failures.append("Developer console command is missing: %s" % command_name)

func _validate_phase_six_script() -> void:
	var phase_six_script: Script = load("res://scripts/moongoons_rts_phase_six.gd") as Script
	if phase_six_script == null:
		failures.append("Phase Six developer console controller could not be loaded.")
		return
	var controller: Node = phase_six_script.new() as Node
	if controller == null or not controller.has_method("_execute_developer_command"):
		failures.append("Phase Six controller did not expose the developer console command executor.")
	if controller != null:
		controller.free()
