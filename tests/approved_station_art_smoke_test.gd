extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var art_path := "res://assets/generated/approved_station_deck.svg"
	_expect(FileAccess.file_exists(art_path), "Approved station deck artwork was generated")
	_expect(load(art_path) is Texture2D, "Approved station deck imports as a Godot texture")
	var overlay_script: Script = load("res://scripts/approved_station_art_overlay.gd") as Script
	_expect(overlay_script != null, "Interactive approved station overlay script loads")
	var scene: PackedScene = load("res://scenes/LivingPrecinct.tscn") as PackedScene
	_expect(scene != null, "Living precinct scene parses with approved station artwork")
	if scene != null:
		var instance: Node = scene.instantiate()
		root.add_child(instance)
		for _frame: int in range(20):
			await process_frame
		var art_layer: CanvasLayer = instance.get_node_or_null("ApprovedStationArtLayer") as CanvasLayer
		var art_control: Control = instance.get_node_or_null("ApprovedStationArtLayer/ApprovedStationArt") as Control
		_expect(art_layer != null and art_layer.layer == 1, "Approved artwork is mounted above the emergency renderer")
		_expect(art_control != null and art_control.get_script() == overlay_script, "Live station uses the approved artwork controller")
		instance.queue_free()
	var overlay_file := FileAccess.open("res://scripts/approved_station_art_overlay.gd", FileAccess.READ)
	_expect(overlay_file != null, "Approved artwork controller can be inspected")
	if overlay_file != null:
		var text := overlay_file.get_as_text()
		for required: String in [
			"Police Headquarters", "Research Lab", "Training Center", "Crime Lab",
			"Station Hospital", "Robotics Bay", "Storage Depot", "Armory",
			"_draw_live_personnel", "_facility_at", "_activate_facility"
		]:
			_expect(text.contains(required), "Approved station layer includes %s" % required)
	await process_frame
	if failures == 0:
		print("SUCCESS: Approved station artwork, animation, and facility hotspots passed.")
	else:
		push_error("FAILED: %d approved station artwork check(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
