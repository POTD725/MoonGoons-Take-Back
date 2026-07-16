extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	for index: int in range(RenderedDashboardAsset.CHUNK_COUNT):
		var path: String = "%s/chunk_%02d.txt" % [RenderedDashboardAsset.CHUNK_DIRECTORY, index]
		_expect(FileAccess.file_exists(path), "Rendered dashboard chunk %02d exists" % index)
	var encoded: String = RenderedDashboardAsset.encoded_payload()
	_expect(encoded.length() == RenderedDashboardAsset.EXPECTED_BASE64_LENGTH, "Rendered dashboard payload has the exact verified length")
	var image: Image = RenderedDashboardAsset.load_image()
	_expect(image != null, "Rendered dashboard JPEG decodes")
	if image != null:
		_expect(image.get_width() == 360 and image.get_height() == 540, "Rendered dashboard has the approved 360x540 source dimensions")
	var texture: Texture2D = RenderedDashboardAsset.load_texture()
	_expect(texture != null, "Rendered dashboard becomes a live Godot texture")
	var controller_script: Script = load("res://scripts/rendered_dashboard_controller.gd") as Script
	_expect(controller_script != null, "Rendered dashboard interaction controller loads")
	var scene: PackedScene = load("res://scenes/PeacekeeperStationDeck.tscn") as PackedScene
	_expect(scene != null, "Peacekeeper station deck parses with the rendered dashboard")
	if scene != null:
		var instance: Node = scene.instantiate()
		root.add_child(instance)
		for _frame: int in range(96):
			await process_frame
		var rendered_layer: CanvasLayer = instance.get_node_or_null("RenderedDashboardLayer") as CanvasLayer
		var controller: Control = instance.get_node_or_null("RenderedDashboardLayer/RenderedDashboard") as Control
		var legacy_layer: CanvasLayer = instance.get_node_or_null("SyndicateParityLayer") as CanvasLayer
		_expect(rendered_layer != null and rendered_layer.layer == 15, "Rendered dashboard is the primary station canvas")
		_expect(legacy_layer != null and not legacy_layer.visible, "Old procedural portrait shell is disabled")
		_expect(controller != null and controller.get_script() == controller_script, "Station uses the rendered dashboard controller")
		if controller != null:
			var dashboard_texture: Variant = controller.get("dashboard_texture")
			_expect(dashboard_texture is Texture2D, "Live station holds the decoded rendered texture")
			for hotspot_name: String in [
				"hotspot_missions", "hotspot_threats", "hotspot_hq", "hotspot_research",
				"hotspot_training", "hotspot_crime", "hotspot_hospital", "hotspot_robotics",
				"hotspot_storage", "hotspot_armory", "hotspot_patrol", "hotspot_officers",
				"hotspot_squads", "hotspot_robots"
			]:
				_expect(controller.get_node_or_null(hotspot_name) is Button, "%s is clickable" % hotspot_name)
			for nav_name: String in ["rendered_nav_station", "rendered_nav_missions", "rendered_nav_operations", "rendered_nav_officers", "rendered_nav_command"]:
				_expect(controller.get_node_or_null(nav_name) is Button, "%s exists" % nav_name)
			var hq_button: Button = controller.get_node_or_null("hotspot_hq") as Button
			if hq_button != null:
				hq_button.pressed.emit()
				await process_frame
				var popup: PanelContainer = controller.get_node_or_null("RenderedFacilityPopup") as PanelContainer
				_expect(popup != null and popup.visible, "Touching Headquarters opens its contextual popup")
				var title_value: Variant = controller.get("popup_title")
				_expect(title_value is Label and (title_value as Label).text.contains("POLICE HEADQUARTERS"), "Headquarters popup identifies the unified police building")
			var missions_button: Button = controller.get_node_or_null("rendered_nav_missions") as Button
			if missions_button != null:
				missions_button.pressed.emit()
				for _frame: int in range(8):
					await process_frame
				var return_button: Button = instance.get_node_or_null("RenderedDashboardReturnLayer/ReturnToRenderedStation") as Button
				_expect(return_button != null and return_button.visible, "Opening a live panel exposes a rendered-station return control")
				var precinct: Node = instance.get_node_or_null("LivingPrecinct")
				var tasks_value: Variant = precinct.get("tasks_panel") if precinct != null else null
				_expect(tasks_value is Control and (tasks_value as Control).visible, "Rendered Missions navigation reaches the live mission board")
				controller.call("_return_to_station")
				await process_frame
				_expect(rendered_layer.layer == 15 and not return_button.visible, "Returning restores the rendered station dashboard")
		instance.queue_free()
	await process_frame
	if failures == 0:
		print("SUCCESS: Real rendered dashboard asset, hotspots, popups, and live navigation passed.")
	else:
		push_error("FAILED: %d rendered dashboard check(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
