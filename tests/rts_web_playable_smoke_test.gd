extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_validate_web_export_preset()
	_validate_web_playable_files()
	_validate_criminal_web_entry()
	if failures.is_empty():
		print("MoonGoons Take Back cache-safe criminal web playable smoke test passed.")
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
		"html/custom_html_shell=\"res://web/shell_v3.html\"",
		"variant/thread_support=false",
		"progressive_web_app/enabled=false"
	]:
		if not text.contains(required_text):
			failures.append("Web export preset missing: %s" % required_text)
	if text.contains("progressive_web_app/enabled=true"):
		failures.append("PWA mode must remain disabled until the deployment provides every worker dependency.")

func _validate_web_playable_files() -> void:
	for required_path: String in [
		"res://web/shell_v3.html",
		"res://web/legacy-service-worker-reset.js",
		"res://tools/version_web_export.py"
	]:
		if not FileAccess.file_exists(required_path):
			failures.append("Missing web packaging file: %s" % required_path)
	var shell: FileAccess = FileAccess.open("res://web/shell_v3.html", FileAccess.READ)
	if shell == null:
		failures.append("Cache-safe web shell could not be opened.")
		return
	var shell_text: String = shell.get_as_text()
	for required_shell_text: String in [
		"MoonGoons Take Back",
		"$GODOT_URL",
		"$GODOT_CONFIG",
		"__MOONGOONS_BUILD_TOKEN__",
		"SYNDICATE RISING",
		"Loading the Syndicate Rising criminal campaign",
		"clearOldState",
		"Clear old build and reload",
		"WEB_FIX_VERSION = '3'",
		"75000"
	]:
		if not shell_text.contains(required_shell_text):
			failures.append("Web shell missing token or recovery label: %s" % required_shell_text)
	var versioner: FileAccess = FileAccess.open("res://tools/version_web_export.py", FileAccess.READ)
	if versioner == null:
		failures.append("Versioned export tool could not be opened.")
	else:
		var version_text: String = versioner.get_as_text()
		for required_version_text: String in [
			"mainPack",
			"SyndicateEntry.tscn",
			"index.audio.worklet.js",
			"unversioned Godot runtime references"
		]:
			if not version_text.contains(required_version_text):
				failures.append("Versioned export tool missing: %s" % required_version_text)
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

func _validate_criminal_web_entry() -> void:
	var entry_scene: PackedScene = load("res://scenes/SyndicateEntry.tscn") as PackedScene
	var entry_script: Script = load("res://scripts/syndicate_entry.gd") as Script
	if entry_scene == null:
		failures.append("Syndicate web entry scene does not parse.")
	if entry_script == null:
		failures.append("Syndicate web entry controller does not load.")
	elif not entry_script.new().has_method("_route_to_criminal_campaign"):
		failures.append("Syndicate web entry does not route returning and new players.")
