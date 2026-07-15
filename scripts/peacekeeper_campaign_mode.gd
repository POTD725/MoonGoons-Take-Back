extends Node
## Reframes the living precinct as the single MoonGoons Take Back campaign.
## The separate criminal game is represented only through enemy threat data.

var precinct: Node
var threat_label: Label

func _ready() -> void:
	precinct = get_parent()
	CounterSyndicate.load_state()
	CounterSyndicate.threat_changed.connect(_refresh_threat_hud)
	call_deferred("_apply_peacekeeper_mode")

func _apply_peacekeeper_mode() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_rewire_navigation()
	_update_identity_text()
	_build_threat_hud()
	_refresh_threat_hud()

func _rewire_navigation() -> void:
	var map_button: Button = _find_button(precinct, "CAMPAIGN ROUTER")
	if map_button != null:
		_disconnect_pressed(map_button)
		map_button.text = "SYNDICATE THREAT MAP"
		map_button.custom_minimum_size = Vector2(210.0, 36.0)
		map_button.pressed.connect(_open_threat_map)
	var rts_button: Button = _find_button(precinct, "RTS FRONT")
	if rts_button != null:
		rts_button.text = "SECTOR COMMAND"
		rts_button.tooltip_text = "Open the Peacekeeper RTS front and reclaim lunar territory."

func _update_identity_text() -> void:
	var title: Label = _find_label(precinct, "LIVING LUNAR PRECINCT")
	if title != null:
		title.text = "  MOONGOONS TAKE BACK // LUNAR PEACEKEEPER PRECINCT"
	var status_value: Variant = precinct.get("status_label")
	if status_value is Label:
		(status_value as Label).text = "Peacekeeper command online. Track Syndicate crews, intercept scores, arrest operators, and reclaim the Moon."

func _build_threat_hud() -> void:
	if threat_label != null:
		return
	var layer := CanvasLayer.new()
	layer.name = "PeacekeeperCampaignHUD"
	layer.layer = 35
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.offset_left = -420.0
	panel.offset_top = -116.0
	panel.offset_right = -16.0
	panel.offset_bottom = -76.0
	layer.add_child(panel)
	threat_label = Label.new()
	threat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	threat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	threat_label.add_theme_font_size_override("font_size", 11)
	panel.add_child(threat_label)

func _refresh_threat_hud() -> void:
	if threat_label != null:
		threat_label.text = CounterSyndicate.campaign_status()

func _open_threat_map() -> void:
	CounterSyndicate.save_state()
	MoonGoonsAudio.play("confirm")
	get_tree().change_scene_to_file("res://scenes/SyndicateThreatMap.tscn")

func _disconnect_pressed(button: Button) -> void:
	for connection: Dictionary in button.pressed.get_connections():
		var callable_value: Variant = connection.get("callable")
		if callable_value is Callable:
			button.pressed.disconnect(callable_value as Callable)

func _find_button(root: Node, text_value: String) -> Button:
	if root is Button and (root as Button).text == text_value:
		return root as Button
	for child: Node in root.get_children():
		var found: Button = _find_button(child, text_value)
		if found != null:
			return found
	return null

func _find_label(root: Node, needle: String) -> Label:
	if root is Label and (root as Label).text.contains(needle):
		return root as Label
	for child: Node in root.get_children():
		var found: Label = _find_label(child, needle)
		if found != null:
			return found
	return null
