extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(String(ProjectSettings.get_setting("application/run/main_scene", "")) == "res://scenes/PeacekeeperStationDeck.tscn", "Portrait Peacekeeper deck is the main scene")
	_expect(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) == 720, "Viewport matches Syndicate Rising's 720-pixel mobile width")
	_expect(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) == 1280, "Viewport matches Syndicate Rising's 1280-pixel mobile height")
	_expect(String(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "keep", "Portrait GUI preserves its authored aspect ratio")

	var packed: PackedScene = load("res://scenes/PeacekeeperStationDeck.tscn") as PackedScene
	_expect(packed != null, "Syndicate-style Peacekeeper station scene loads")
	if packed == null:
		quit(failures)
		return
	var instance: Node = packed.instantiate()
	root.add_child(instance)
	for _frame: int in range(86):
		await process_frame

	var precinct: Node = instance.get_node_or_null("LivingPrecinct")
	var hud: Control = instance.get_node_or_null("SyndicateParityLayer/SyndicateParityHUD") as Control
	_expect(precinct != null, "The complete living precinct simulation remains mounted under the new GUI")
	_expect(hud != null, "Fixed Syndicate-style status, inspector, and navigation HUD exists")
	if hud != null:
		var station: Button = hud.get_node_or_null("nav_station") as Button
		var missions: Button = hud.get_node_or_null("nav_missions") as Button
		var operations: Button = hud.get_node_or_null("nav_operations") as Button
		var officers: Button = hud.get_node_or_null("nav_officers") as Button
		var command: Button = hud.get_node_or_null("nav_command") as Button
		_expect(station != null and missions != null and operations != null and officers != null and command != null, "Five large bottom navigation tabs mirror Syndicate Rising's layout")
		if station != null and command != null:
			_expect(is_equal_approx(station.position.y, 1170.0) and is_equal_approx(command.position.y, 1170.0), "Bottom navigation is anchored to the same 1170-1266 band")
			_expect(station.icon != null and command.icon != null, "Bottom navigation tabs use picture icons")
		var cutaway: Button = hud.get_node_or_null("cutaway") as Button
		var rotate: Button = hud.get_node_or_null("rotate") as Button
		var center: Button = hud.get_node_or_null("center") as Button
		_expect(cutaway != null and rotate != null and center != null, "Compact camera strip provides cutaway, rotate, and center controls")
		var room_action: Button = hud.get_node_or_null("room_action") as Button
		var room_operation: Button = hud.get_node_or_null("room_operation") as Button
		_expect(room_action != null and room_operation != null, "Persistent room inspector exposes primary and equipment actions")
		if room_action != null:
			_expect(is_equal_approx(room_action.position.y, 1062.0), "Room action occupies Syndicate Rising's inspector action band")
		var drawer: PanelContainer = hud.get_node_or_null("CommandSystemsDrawer") as PanelContainer
		_expect(drawer != null, "Command Systems drawer groups equipment, defense, threats, side ops, and research")
		if precinct != null:
			precinct.set("selected_room_id", "armory")
			for _frame: int in range(3):
				await process_frame
			_expect(String(hud.get("selected_room_id")) == "armory", "HUD inspector follows room selection from the live station")

	if precinct != null:
		var old_ribbon: Control = precinct.get_node_or_null("CompactCommandRibbonLayer/CompactCommandRibbon") as Control
		var old_camera: Control = precinct.get_node_or_null("HybridViewControlsLayer/HybridViewControls") as Control
		_expect(old_ribbon == null or not old_ribbon.visible, "Legacy landscape command ribbon is hidden")
		_expect(old_camera == null or not old_camera.visible, "Legacy landscape camera bar is hidden")

	instance.queue_free()
	await process_frame
	if failures == 0:
		print("SUCCESS: Syndicate Rising layout parity passed.")
	else:
		push_error("FAILED: %d Syndicate layout parity check(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
