extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_validate_main_scene_points_to_android_testbed()
	_validate_android_testbed_controller()
	_validate_android_export_preset()
	_validate_android_icon_assets()
	if failures.is_empty():
		print("MoonGoons Take Back Android touch testbed smoke test passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _validate_main_scene_points_to_android_testbed() -> void:
	var file: FileAccess = FileAccess.open("res://scenes/Main.tscn", FileAccess.READ)
	if file == null:
		failures.append("Main scene could not be opened.")
		return
	var text: String = file.get_as_text()
	if not text.contains("res://scripts/moongoons_rts_android_testbed.gd"):
		failures.append("Main scene must launch the Android testbed script.")

func _validate_android_testbed_controller() -> void:
	var android_script: Script = load("res://scripts/moongoons_rts_android_testbed.gd") as Script
	if android_script == null:
		failures.append("Android testbed script could not be loaded.")
		return
	var controller: Node = android_script.new() as Node
	if controller == null:
		failures.append("Android testbed script could not be instantiated.")
		return
	for method_name: String in [
		"_handle_screen_touch",
		"_handle_screen_drag",
		"_draw_touch_command_deck",
		"_issue_touch_order",
		"_select_all_playable_units",
		"_touch_button_label"
	]:
		if not controller.has_method(method_name):
			failures.append("Android testbed controller is missing %s." % method_name)
	controller.free()

func _validate_android_export_preset() -> void:
	var file: FileAccess = FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	if file == null:
		failures.append("Android export preset could not be opened.")
		return
	var text: String = file.get_as_text()
	for required_text: String in [
		"name=\"Android Test APK\"",
		"platform=\"Android\"",
		"export_path=\"builds/android/MoonGoonsTakeBack-debug.apk\"",
		"package/unique_name=\"com.moongoons.takeback\"",
		"architectures/arm64-v8a=true"
	]:
		if not text.contains(required_text):
			failures.append("Android export preset missing: %s" % required_text)

func _validate_android_icon_assets() -> void:
	for path: String in [
		"res://assets/android/icon.svg",
		"res://assets/android/icon_foreground.svg",
		"res://assets/android/icon_background.svg",
		"res://assets/android/icon_monochrome.svg"
	]:
		if not FileAccess.file_exists(path):
			failures.append("Missing Android icon asset: %s" % path)
