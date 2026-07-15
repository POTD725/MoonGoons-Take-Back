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
		"variant/thread_support=false",
		"progressive_web_app/enabled=false"
	]:
		if not text.contains(required_text):
			failures.append("Web export preset missing: %s" % required_text)
	if text.contains("progressive_web_app/enabled=true"):
		failures.append("PWA mode must remain disabled until the deployment provides every worker dependency.")

func _validate_web_playable_files() -> void:
	if not FileAccess.file_exists("res://web/shell.html"):
		failures.append("Missing custom web playable shell.")
		return
	if not FileAccess.file_exists("res://web/legacy-service-worker-reset.js"):
		failures.append("Missing one-release legacy service-worker reset script.")
	var shell: FileAccess = FileAccess.open("res://web/shell.html", FileAccess.READ)
	if shell == null:
		failures.append("Custom web playable shell could not be opened.")
		return
	var shell_text: String = shell.get_as_text()
	for required_shell_text: String in [
		"MoonGoons Take Back",
		"$GODOT_URL",
		"$GODOT_CONFIG",
		"Peacekeeper Station",
		"Preparing the MoonGoons Peacekeeper station",
		"clearLegacyWebState",
		"Clear cache and reload",
		"75000",
		"FIT WIDTH",
		"FULLSCREEN",
		"zoom-in-button",
		"zoom-out-button",
		"canvasStage.style.width",
		"ZOOM_STORAGE_KEY"
	]:
		if not shell_text.contains(required_shell_text):
			failures.append("Web shell missing token, scaler, or recovery label: %s" % required_shell_text)
	var reset_file: FileAccess = FileAccess.open("res://web/legacy-service-worker-reset.js", FileAccess.READ)
	if reset_file == null:
		failures.append("Legacy service-worker reset script could not be opened.")
		return
	var reset_text: String = reset_file.get_as_text()
	for required_reset_text: String in [
		"MoonGoons Take B-sw-cache-",
		"self.registration.unregister()",
		"cache: 'no-store'",
		"webfix"
	]:
		if not reset_text.contains(required_reset_text):
			failures.append("Legacy service-worker reset missing: %s" % required_reset_text)
