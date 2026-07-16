extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(String(ProjectSettings.get_setting("application/run/main_scene", "")) == "res://scenes/PeacekeeperStationDeck.tscn", "Portrait Peacekeeper deck is the main scene")
	_expect(int(ProjectSettings.get_setting("display/window/size/viewport_width", 0)) == 720, "Viewport matches Syndicate Rising's 720-pixel mobile width")
	_expect(int(ProjectSettings.get_setting("display/window/size/viewport_height", 0)) == 1280, "Viewport matches Syndicate Rising's 1280-pixel mobile height")
	_expect(String(ProjectSettings.get_setting("display/window/stretch/aspect", "")) == "keep", "Portrait GUI preserves its authored aspect ratio")

	var shell_file: FileAccess = FileAccess.open("res://web/shell.html", FileAccess.READ)
	_expect(shell_file != null, "Custom web shell is available")
	if shell_file != null:
		var shell: String = shell_file.get_as_text()
		_expect(shell.contains("id=\"fit-button\"") and shell.contains("id=\"width-button\""), "Web mode exposes Fit and Fit Width display controls")
		_expect(shell.contains("id=\"zoom-in-button\"") and shell.contains("id=\"zoom-out-button\""), "Web mode exposes direct zoom buttons")
		_expect(shell.contains("id=\"fullscreen-button\""), "Web mode exposes fullscreen")
		_expect(shell.contains("Ctrl/Cmd +") and shell.contains("ZOOM_STORAGE_KEY"), "Web zoom includes keyboard shortcuts and remembered preferences")
		_expect(shell.contains("canvasStage.style.width") and shell.contains("canvasStage.style.height"), "Web zoom resizes the actual Godot canvas stage")
		_expect(shell.contains("displayMode = window.matchMedia") and shell.contains("'width'"), "Web shell retains responsive Fit Width support")

	var patrol_icon: Texture2D = load("res://assets/ui/patrol_spacecraft.svg") as Texture2D
	_expect(patrol_icon != null, "Patrol uses a Peacekeeper spacecraft icon asset")

	var packed: PackedScene = load("res://scenes/PeacekeeperStationDeck.tscn") as PackedScene
	_expect(packed != null, "Syndicate-style Peacekeeper station scene loads")
	if packed == null:
		quit(failures)
		return
	var instance: Node = packed.instantiate()
	root.add_child(instance)
	for _frame: int in range(96):
		await process_frame

	var precinct: Node = instance.get_node_or_null("LivingPrecinct")
	var hud: Control = instance.get_node_or_null("SyndicateParityLayer/SyndicateParityHUD") as Control
	_expect(precinct != null, "The complete living precinct simulation remains mounted under the new GUI")
	_expect(hud != null, "Fixed Syndicate-style compatibility controller exists")
	if hud != null:
		var station: Button = hud.get_node_or_null("nav_station") as Button
		var missions: Button = hud.get_node_or_null("nav_missions") as Button
		var operations: Button = hud.get_node_or_null("nav_operations") as Button
		var officers: Button = hud.get_node_or_null("nav_officers") as Button
		var command: Button = hud.get_node_or_null("nav_command") as Button
		_expect(station != null and missions != null and operations != null and officers != null and command != null, "Five compatibility navigation controllers remain available")
		if station != null and command != null:
			_expect(is_equal_approx(station.position.y, 1170.0) and is_equal_approx(command.position.y, 1170.0), "Compatibility navigation retains the authored inspector band")
			_expect(station.icon != null and command.icon != null, "Compatibility navigation retains picture icons")
		var cutaway: Button = hud.get_node_or_null("cutaway") as Button
		var rotate: Button = hud.get_node_or_null("rotate") as Button
		var center: Button = hud.get_node_or_null("center") as Button
		_expect(cutaway != null and rotate != null and center != null, "Compact camera controller provides cutaway, rotate, and center commands")
		var room_action: Button = hud.get_node_or_null("room_action") as Button
		var room_operation: Button = hud.get_node_or_null("room_operation") as Button
		_expect(room_action != null and room_operation != null, "Room inspector controller exposes primary and equipment actions")
		if room_action != null:
			_expect(is_equal_approx(room_action.position.y, 1062.0), "Room action retains the inspector action band")
		var drawer: PanelContainer = hud.get_node_or_null("CommandSystemsDrawer") as PanelContainer
		_expect(drawer != null, "Command Systems controller groups equipment, defense, threats, side ops, and research")

		if precinct != null:
			precinct.set("selected_room_id", "armory")
			for _frame: int in range(20):
				await process_frame
			_expect(String(hud.get("selected_room_id")) == "armory", "Compatibility inspector follows room selection from the live station")

		var nav_audit: Array[Dictionary] = [
			{"button":station, "id":"station", "panel":""},
			{"button":missions, "id":"missions", "panel":"tasks_panel"},
			{"button":operations, "id":"operations", "panel":"resource"},
			{"button":officers, "id":"officers", "panel":"officer_panel"},
			{"button":command, "id":"command", "panel":"drawer"}
		]
		for audit: Dictionary in nav_audit:
			var button: Button = audit.get("button") as Button
			if button == null:
				continue
			button.pressed.emit()
			for _frame: int in range(8):
				await process_frame
			var id: String = String(audit.get("id", ""))
			_expect(String(hud.get("active_nav")) == id, "%s compatibility command reaches its controller" % id.capitalize())
			var panel_key: String = String(audit.get("panel", ""))
			if panel_key == "tasks_panel":
				var tasks_value: Variant = precinct.get("tasks_panel")
				_expect(tasks_value is Control and (tasks_value as Control).visible, "Missions controller opens the live mission board")
			elif panel_key == "resource":
				var resource_controller: Node = precinct.get_node_or_null("ResourceHarvestController")
				var resource_panel: Variant = resource_controller.get("panel") if resource_controller != null else null
				_expect(resource_panel is Control and (resource_panel as Control).visible, "Operations controller opens the live orbital resource map")
			elif panel_key == "officer_panel":
				var officer_value: Variant = precinct.get("officer_panel")
				_expect(officer_value is Control and (officer_value as Control).visible, "Officers controller opens the live roster")
			elif panel_key == "drawer":
				_expect(drawer != null and drawer.visible, "Command controller opens its grouped systems state")

	if precinct != null:
		var old_ribbon: Control = precinct.get_node_or_null("CompactCommandRibbonLayer/CompactCommandRibbon") as Control
		var old_camera: Control = precinct.get_node_or_null("HybridViewControlsLayer/HybridViewControls") as Control
		_expect(old_ribbon == null or not old_ribbon.is_visible_in_tree(), "Legacy landscape command ribbon is hidden")
		_expect(old_camera == null or not old_camera.is_visible_in_tree(), "Legacy landscape camera bar is hidden")
		var personnel: Node = precinct.get_node_or_null("LivingPrecinctWorld/Personnel")
		_expect(personnel != null and personnel.get_child_count() >= 10, "Station screen contains a populated NPC crew")
		if personnel != null and personnel.get_child_count() > 0:
			var animated_count: int = 0
			var moving_count: int = 0
			var starts: Dictionary = {}
			for npc: Node in personnel.get_children():
				if npc.is_in_group("animated_station_npcs"):
					animated_count += 1
				starts[npc.get_instance_id()] = (npc as Node3D).position
			for _frame: int in range(45):
				await process_frame
			for npc: Node in personnel.get_children():
				var old_position: Vector3 = starts.get(npc.get_instance_id(), (npc as Node3D).position)
				if (npc as Node3D).position.distance_to(old_position) > 0.015:
					moving_count += 1
			_expect(animated_count == personnel.get_child_count(), "Every visible NPC uses the articulated animation rig")
			_expect(moving_count > 0, "NPCs visibly walk and work on the station screen")

	instance.queue_free()
	await process_frame
	if failures == 0:
		print("SUCCESS: Rendered GUI compatibility, working links, web zoom, Patrol spacecraft, and animated NPCs passed.")
	else:
		push_error("FAILED: %d rendered GUI compatibility check(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
