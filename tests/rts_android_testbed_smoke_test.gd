extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_validate_main_scene_points_to_android_testbed()
	_validate_android_testbed_controller()
	_validate_production_art_overlay()
	_validate_android_export_preset()
	_validate_android_icon_assets()
	if failures.is_empty():
		print("MoonGoons Take Back Android touch and RTS art smoke test passed.")
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
	if not text.contains("res://scripts/rts_visual_overlay.gd"):
		failures.append("Main scene must attach the established MoonGoons RTS art layer.")
	if not text.contains("ProductionArtOverlay"):
		failures.append("Main scene is missing the production art overlay node.")

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

func _validate_production_art_overlay() -> void:
	var overlay_script: Script = load("res://scripts/rts_visual_overlay.gd") as Script
	if overlay_script == null:
		failures.append("RTS production art overlay could not be loaded.")
		return
	var overlay: Node = overlay_script.new() as Node
	for method_name: String in [
		"_draw_crater_art",
		"_draw_resource_art",
		"_draw_structure_art",
		"_draw_unit_art",
		"_draw_enemy_art",
		"_draw_clean_header"
	]:
		if not overlay.has_method(method_name):
			failures.append("RTS art overlay is missing %s." % method_name)
	overlay.free()
	var source: FileAccess = FileAccess.open("res://scripts/rts_visual_overlay.gd", FileAccess.READ)
	if source != null:
		var source_text: String = source.get_as_text()
		for required_skin: String in [
			"command_nexus",
			"tactical_armory",
			"builder_drone",
			"patrol_deputy",
			"shield_deputy",
			"ore_deposit",
			"evidence_cache",
			"wrecked_shuttle",
			"crater"
		]:
			if not source_text.contains(required_skin):
				failures.append("RTS art overlay does not use skin: %s" % required_skin)
		if not source_text.contains("CAMPAIGN HUB"):
			failures.append("RTS art overlay lacks a visible Campaign Hub return button.")

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
