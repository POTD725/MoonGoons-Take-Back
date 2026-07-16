extends "res://scripts/rendered_dashboard_controller.gd"
## Live routing fixes for the rendered station dashboard.
## Keeps the hidden compatibility HUD available, but never depends on it for
## missions, officers, orbital maps, equipment, or the return control.

func _build_return_layer() -> void:
	var root_node: Node = get_parent().get_parent()
	return_layer = CanvasLayer.new()
	return_layer.name = "RenderedDashboardReturnLayer"
	return_layer.layer = 300
	return_button = Button.new()
	return_button.name = "ReturnToRenderedStation"
	return_button.position = Vector2(18.0, 18.0)
	return_button.size = Vector2(250.0, 52.0)
	return_button.text = "RETURN TO STATION"
	return_button.icon = GameIconRegistry.icon_for("station_deck", 28)
	return_button.visible = false
	return_button.add_theme_stylebox_override("normal", _button_style(false))
	return_button.add_theme_stylebox_override("hover", _button_style(true))
	return_button.pressed.connect(_return_to_station)
	return_layer.add_child(return_button)
	root_node.call_deferred("add_child", return_layer)

func _open_live_panel(command: String) -> void:
	popup.visible = false
	command_popup.visible = false
	_close_panels_directly()
	var opened: Control = null
	match command:
		"missions":
			precinct.call("_show_tab", "tasks")
			opened = _core_panel("tasks_panel", true)
		"dispatch":
			precinct.call("_show_tab", "patrol")
			opened = _core_panel("patrol_panel", true)
		"officers":
			precinct.call("_show_tab", "officers")
			opened = _core_panel("officer_panel", true)
		"equipment":
			opened = _external_panel("PrecinctProgressionUI", "equipment_panel", true)
		"station":
			opened = _external_panel("StationCommandUI", "panel", true)
		"resources":
			opened = _external_panel("ResourceHarvestController", "panel", true)
		"threats":
			opened = _external_panel("SpaceThreatOperations", "panel", true)
		"side_ops":
			opened = _external_panel("SideOperationsUI", "panel", true)
		"research":
			var overlay: Node = get_node_or_null("/root/AllianceResearchOverlay")
			if overlay != null:
				var value: Variant = overlay.get("panel")
				if value is Control:
					opened = value as Control
					opened.visible = true
	if opened != null:
		opened.move_to_front()
	var dashboard_layer: CanvasLayer = get_parent() as CanvasLayer
	if dashboard_layer != null:
		dashboard_layer.layer = PANEL_BACK_LAYER
	if return_button != null:
		return_button.visible = true
	status_label.text = "%s opened." % command.replace("_", " ").capitalize()

func _return_to_station() -> void:
	_close_panels_directly()
	var dashboard_layer: CanvasLayer = get_parent() as CanvasLayer
	if dashboard_layer != null:
		dashboard_layer.layer = DEFAULT_LAYER
	if return_button != null:
		return_button.visible = false
	popup.visible = false
	command_popup.visible = false
	status_label.text = "Rendered station online. Select a facility, mission, unit, or map panel."

func _close_panels_directly() -> void:
	if precinct == null:
		return
	for property_name: String in ["city_panel", "officer_panel", "patrol_panel", "custody_panel", "tasks_panel"]:
		_core_panel(property_name, false)
	for pair: Array in [
		["PrecinctProgressionUI", "equipment_panel"],
		["StationCommandUI", "panel"],
		["ResourceHarvestController", "panel"],
		["SpaceThreatOperations", "panel"],
		["SideOperationsUI", "panel"]
	]:
		_external_panel(String(pair[0]), String(pair[1]), false)
	var overlay: Node = get_node_or_null("/root/AllianceResearchOverlay")
	if overlay != null:
		var value: Variant = overlay.get("panel")
		if value is Control:
			(value as Control).visible = false

func _core_panel(property_name: String, show: bool) -> Control:
	if precinct == null:
		return null
	var value: Variant = precinct.get(property_name)
	if value is Control:
		var panel := value as Control
		panel.visible = show
		return panel
	return null

func _external_panel(controller_name: String, property_name: String, show: bool) -> Control:
	if precinct == null:
		return null
	var controller: Node = precinct.get_node_or_null(controller_name)
	if controller == null:
		return null
	var value: Variant = controller.get(property_name)
	if value is Control:
		var panel := value as Control
		panel.visible = show
		return panel
	return null
