extends SceneTree

var failures: int = 0

const FRAME_NAMES: Array[String] = [
	"crater_market_blackout",
	"ghost_key_heist",
	"station_reactivation",
	"patrol_launch",
	"syndicate_assault",
	"victory_reclaim"
]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for frame_name: String in FRAME_NAMES:
		var path := "res://assets/generated/cinematics/%s.svg" % frame_name
		_expect(FileAccess.file_exists(path), "Generated cinematic frame exists: %s" % frame_name)
		_expect(load(path) is Texture2D, "Cinematic frame imports as a texture: %s" % frame_name)
	var take_back_script: Script = load("res://scripts/take_back_cinematic.gd") as Script
	var syndicate_script: Script = load("res://scripts/syndicate_cutscene.gd") as Script
	_expect(take_back_script != null, "Take Back cinematic controller loads")
	_expect(syndicate_script != null, "Syndicate cinematic controller loads")
	_validate_script("res://scripts/take_back_cinematic.gd", [
		"crater_market_blackout.svg", "ghost_key_heist.svg", "station_reactivation.svg",
		"patrol_launch.svg", "syndicate_assault.svg", "victory_reclaim.svg",
		"_draw_cinematic_art", "_draw_scene_animation", "transition", "drift_x", "zoom"
	])
	_validate_script("res://scripts/syndicate_cutscene.gd", [
		"crater_market_blackout.svg", "ghost_key_heist.svg", "syndicate_assault.svg",
		"victory_reclaim.svg", "_draw_panel_art", "_draw_motion", "transition", "drift", "zoom"
	])
	var generator := FileAccess.open("res://tools/generate_approved_cinematic_art.py", FileAccess.READ)
	_expect(generator != null, "Cinematic artwork generator is included")
	if generator != null:
		var generator_text := generator.get_as_text()
		for name: String in FRAME_NAMES:
			_expect(generator_text.contains("%s.svg" % name), "Generator produces %s" % name)
	await process_frame
	if failures == 0:
		print("SUCCESS: Approved animated station cutscenes passed.")
	else:
		push_error("FAILED: %d cinematic artwork check(s) failed." % failures)
	quit(failures)

func _validate_script(path: String, tokens: Array[String]) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(file != null, "Cinematic script can be inspected: %s" % path.get_file())
	if file == null:
		return
	var text := file.get_as_text()
	for token: String in tokens:
		_expect(text.contains(token), "%s contains %s" % [path.get_file(), token])

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
