extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_validate_web_export_preset()
	_validate_web_playable_files()
	if failures.is_empty():
		print("MoonGoons Take Back web playable smoke test passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _validate_web_export_preset() -> void:
	var file: FileAccess = FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	if file == null:
		failures.append("Export presets file could not be opened.")
		return
	var text: String = file.get_as_text()
	for required_text: String in [
		"name=\"Web Playable\"",
		"platform=\"Web\"",
		"export_path=\"builds/web/index.html\"",
		"custom_features=\"web,html5,playable,touch\"",
		"html/custom_html_shell=\"res://web/shell.html\"",
		"progressive_web_app/enabled=true"
	]:
		if not text.contains(required_text):
			failures.append("Web export preset missing: %s" % required_text)

func _validate_web_playable_files() -> void:
	if not FileAccess.file_exists("res://web/shell.html"):
		failures.append("Missing custom web playable shell.")
		return
	var shell: FileAccess = FileAccess.open("res://web/shell.html", FileAccess.READ)
	if shell == null:
		failures.append("Custom web playable shell could not be opened.")
		return
	var shell_text: String = shell.get_as_text()
	for required_shell_text: String in [
		"MoonGoons Take Back",
		"$GODOT_URL",
		"$GODOT_CONFIG",
		"Precinct Vertical Slice",
		"Loading lunar precinct command systems",
		"attack, cover, use specials"
	]:
		if not shell_text.contains(required_shell_text):
			failures.append("Web shell missing token or label: %s" % required_shell_text)
