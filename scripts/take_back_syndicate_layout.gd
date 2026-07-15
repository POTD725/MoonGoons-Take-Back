extends Control
## Portrait command-deck shell patterned after Syndicate Rising's proven mobile layout.
## The existing LivingPrecinct simulation remains live beneath this fixed interface.

@export var precinct_path: NodePath

const VIEW := Vector2(720.0, 1280.0)
const WORLD_RECT := Rect2(0.0, 148.0, 720.0, 822.0)
const EMBLEM: Texture2D = preload("res://assets/android/icon.svg")
const ROOM_ICONS: Dictionary = {
	"ops": preload("res://assets/precinct/rooms/ops_center.svg"),
	"armory": preload("res://assets/precinct/rooms/armory.svg"),
	"cells": preload("res://assets/precinct/rooms/holding_cells.svg"),
	"quarters": preload("res://assets/precinct/rooms/crew_quarters.svg"),
	"medbay": preload("res://assets/precinct/rooms/medbay.svg"),
	"chief": preload("res://assets/precinct/rooms/chief_office.svg"),
	"interrogation": preload("res://assets/precinct/rooms/interrogation.svg"),
	"transfer": preload("res://assets/precinct/rooms/transfer_hall.svg")
}
const ROOM_DESCRIPTIONS: Dictionary = {
	"ops": "Coordinate patrol routes, distress calls, officer assignments, district intelligence, and station-wide response priorities.",
	"armory": "Maintain Peacekeeper weapons, armor, ammunition, pressure-rated gear, and response equipment for orbital duty.",
	"cells": "Secure detainees, scan contraband, process arrests, and prevent Syndicate prisoners from escaping the station.",
	"quarters": "House station personnel, restore stamina, improve morale, and prepare officers for the next duty rotation.",
	"medbay": "Diagnose injuries, stabilize casualties, treat radiation exposure, and return wounded officers to active duty.",
	"chief": "Sets the command cap for every room and item while coordinating authority across the orbital precinct.",
	"interrogation": "Examine evidence, question suspects, measure guilt and stress, and extract reliable criminal intelligence.",
	"transfer": "Inspect prisoners and move them through reinforced airlocks into secure orbital transport craft."
}
const NAV_DATA: Array[Dictionary] = [
	{"id":"station", "title":"STATION", "subtitle":"DECK", "icon":"station_deck"},
	{"id":"missions", "title":"MISSIONS", "subtitle":"DUTY", "icon":"missions"},
	{"id":"operations", "title":"OPERATIONS", "subtitle":"SPACE", "icon":"resources"},
	{"id":"officers", "title":"OFFICERS", "subtitle":"ROSTER", "icon":"officers"},
	{"id":"command", "title":"COMMAND", "subtitle":"SYSTEMS", "icon":"equipment"}
]

var precinct: Node
var selected_room_id: String = "ops"
var active_nav: String = "station"
var message: String = "Drag the station to pan. Select a room for command details."
var refresh_clock: float = 0.0
var audio_muted: bool = false
var buttons: Dictionary = {}
var nav_buttons: Dictionary = {}
var command_drawer: PanelContainer
var command_title: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	precinct = get_node_or_null(precinct_path)
	_build_input_blockers()
	_build_header_buttons()
	_build_camera_buttons()
	_build_inspector_buttons()
	_build_navigation()
	_build_command_drawer()
	call_deferred("_finish_initialization")

func _finish_initialization() -> void:
	for _frame: int in range(64):
		await get_tree().process_frame
	_hide_legacy_gui()
	_sync_selected_room()
	_update_button_states()
	queue_redraw()

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock < 0.18:
		return
	refresh_clock = 0.0
	PrecinctState.tick()
	StationProgression.tick()
	ResourceHarvest.tick()
	_sync_selected_room()
	_hide_legacy_gui()
	_update_button_states()
	queue_redraw()

func _draw() -> void:
	_draw_header()
	_draw_camera_strip()
	_draw_world_frame()
	_draw_inspector()
	_draw_navigation_backplate()

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, VIEW.x, 96.0), Color("07131f", 0.995), true)
	draw_line(Vector2(0.0, 96.0), Vector2(VIEW.x, 96.0), Color("67e7ff", 0.78), 2.0)
	draw_texture_rect(EMBLEM, Rect2(10.0, 10.0, 70.0, 70.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 33.0), "MOONGOONS: TAKE BACK", HORIZONTAL_ALIGNMENT_LEFT, 430.0, 20, Color("edfaff"))
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 56.0), "CR %d  INTEL %d  EVID %d  HELD %d  REP %d" % [PrecinctState.credits, PrecinctState.intel, PrecinctState.evidence, PrecinctState.prisoners, PrecinctMeta.reputation], HORIZONTAL_ALIGNMENT_LEFT, 520.0, 9, Color("72efd5"))
	draw_string(ThemeDB.fallback_font, Vector2(88.0, 78.0), "ORE %d  HE-3 %d  Q-SALV %d  HULL %d  STATION L%d" % [ResourceHarvest.resource_amount("moonsteel"), ResourceHarvest.resource_amount("helium3"), ResourceHarvest.resource_amount("quantum_salvage"), StationProgression.station_hull, StationProgression.station_level], HORIZONTAL_ALIGNMENT_LEFT, 530.0, 9, Color("ffd36f"))

func _draw_camera_strip() -> void:
	draw_rect(Rect2(0.0, 96.0, VIEW.x, 52.0), Color("0a1a28", 0.97), true)
	var controller: Node = _camera_controller()
	var mode: String = String(controller.get("current_mode")) if controller != null else "three_quarter"
	var camera_distance: int = int(round(float(precinct.get("camera_distance")))) if precinct != null else 40
	draw_string(ThemeDB.fallback_font, Vector2(17.0, 119.0), "DRAG TO PAN  •  STATION CAMERA  •  RANGE %d" % camera_distance, HORIZONTAL_ALIGNMENT_LEFT, 305.0, 9, Color("c5d9e7"))
	draw_string(ThemeDB.fallback_font, Vector2(17.0, 138.0), "%s  •  THREAT: %s" % [mode.replace("_", " ").to_upper(), _threat_label()], HORIZONTAL_ALIGNMENT_LEFT, 402.0, 8, Color("ffad80") if _threat_label() != "CLEAR" else Color("79ead6"))

func _draw_world_frame() -> void:
	draw_rect(Rect2(0.0, 148.0, VIEW.x, 4.0), Color("28465a"), true)
	draw_rect(Rect2(0.0, 966.0, VIEW.x, 4.0), Color("28465a"), true)
	draw_line(Vector2(8.0, 154.0), Vector2(8.0, 962.0), Color("67e7ff", 0.36), 2.0)
	draw_line(Vector2(712.0, 154.0), Vector2(712.0, 962.0), Color("67e7ff", 0.36), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(18.0, 170.0), "ORBITAL PRECINCT // DECK VIEW", HORIZONTAL_ALIGNMENT_LEFT, 310.0, 9, Color("8cecff", 0.72))
	draw_string(ThemeDB.fallback_font, Vector2(470.0, 170.0), "O2 100%  GRAV 1.0  SEALS GREEN", HORIZONTAL_ALIGNMENT_RIGHT, 232.0, 8, Color("8ff0c8", 0.72))

func _draw_inspector() -> void:
	draw_rect(Rect2(0.0, 970.0, VIEW.x, 190.0), Color("060d17", 0.997), true)
	draw_line(Vector2(0.0, 970.0), Vector2(VIEW.x, 970.0), Color("69839b"), 2.0)
	var panel_rect := Rect2(18.0, 982.0, 684.0, 166.0)
	draw_style_box(_panel_style(Color("0a1421"), Color("6f879e"), 12), panel_rect)
	var room: Dictionary = PrecinctState.get_room(selected_room_id)
	if room.is_empty():
		return
	var icon: Texture2D = ROOM_ICONS.get(selected_room_id) as Texture2D
	if icon != null:
		draw_texture_rect(icon, Rect2(388.0, 995.0, 66.0, 66.0), false)
	var repaired: bool = bool(room.get("repaired", false))
	var repair_end: int = int(room.get("repair_end", 0))
	var status: String = "OPERATIONAL" if repaired else ("REPAIRING" if repair_end > 0 else "DAMAGED")
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 1010.0), String(room.get("name", "Room")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 345.0, 18, Color("f5f8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 1034.0), "%s  •  LEVEL %d  •  EQUIPMENT RATING %d" % [status, int(room.get("level", 1)), PrecinctEquipment.room_operational_rating(selected_room_id)], HORIZONTAL_ALIGNMENT_LEFT, 635.0, 10, Color("70ead5") if repaired else Color("ff9a88"))
	draw_multiline_string(ThemeDB.fallback_font, Vector2(34.0, 1058.0), String(ROOM_DESCRIPTIONS.get(selected_room_id, "Peacekeeper station module.")), HORIZONTAL_ALIGNMENT_LEFT, 420.0, 10, 2, Color("c6d1df"))
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 1128.0), message, HORIZONTAL_ALIGNMENT_LEFT, 430.0, 9, Color("aec0d2"))

func _draw_navigation_backplate() -> void:
	draw_rect(Rect2(0.0, 1160.0, VIEW.x, 120.0), Color("050a12", 0.998), true)
	draw_line(Vector2(0.0, 1160.0), Vector2(VIEW.x, 1160.0), Color("36586b"), 2.0)

func _build_input_blockers() -> void:
	for rect: Rect2 in [Rect2(0.0, 0.0, 720.0, 148.0), Rect2(0.0, 970.0, 720.0, 310.0)]:
		var blocker := Control.new()
		blocker.position = rect.position
		blocker.size = rect.size
		blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(blocker)

func _build_header_buttons() -> void:
	_make_button("sound", Rect2(626.0, 10.0, 76.0, 30.0), "MUTE", "Mute or restore all station audio.", "close", _toggle_audio)
	_make_button("load", Rect2(626.0, 48.0, 76.0, 30.0), "LOAD", "Load the most recently saved Peacekeeper station state.", "save", _load_game)

func _build_camera_buttons() -> void:
	_make_button("cutaway", Rect2(329.0, 104.0, 96.0, 38.0), "CUTAWAY", "Open or close the selected room cutaway.", "cutaway", _toggle_cutaway)
	_make_button("zoom_out", Rect2(429.0, 104.0, 38.0, 38.0), "-", "Move the station camera farther away.", "zoom_out", _zoom_out)
	_make_button("zoom_in", Rect2(471.0, 104.0, 38.0, 38.0), "+", "Move the station camera closer.", "zoom_in", _zoom_in)
	_make_button("rotate", Rect2(513.0, 104.0, 88.0, 38.0), "ROTATE", "Rotate the three-quarter station view.", "next", _rotate)
	_make_button("center", Rect2(605.0, 104.0, 97.0, 38.0), "CENTER", "Return to the default Station Deck view.", "station_deck", _center)

func _build_inspector_buttons() -> void:
	_make_button("room_action", Rect2(471.0, 1062.0, 106.0, 56.0), "REPAIR", "Repair or upgrade the selected station module.", "upgrade", _room_action)
	_make_button("room_operation", Rect2(585.0, 1062.0, 117.0, 56.0), "EQUIPMENT", "Open the selected room's equipment, levels, costs, timers, and styles.", "equipment", _open_equipment)

func _build_navigation() -> void:
	var rects: Array[Rect2] = [
		Rect2(8.0, 1170.0, 134.0, 96.0), Rect2(150.0, 1170.0, 134.0, 96.0),
		Rect2(292.0, 1170.0, 134.0, 96.0), Rect2(434.0, 1170.0, 134.0, 96.0),
		Rect2(576.0, 1170.0, 136.0, 96.0)
	]
	for index: int in range(NAV_DATA.size()):
		var data: Dictionary = NAV_DATA[index]
		var id: String = String(data.get("id", "station"))
		var label: String = "%s\n%s" % [String(data.get("title", "STATION")), String(data.get("subtitle", "DECK"))]
		var button := _make_button("nav_%s" % id, rects[index], label, _nav_tooltip(id), String(data.get("icon", "station_deck")), _on_nav_pressed.bind(id))
		button.add_theme_font_size_override("font_size", 11)
		button.icon_max_width = 34
		nav_buttons[id] = button

func _build_command_drawer() -> void:
	command_drawer = PanelContainer.new()
	command_drawer.name = "CommandSystemsDrawer"
	command_drawer.position = Vector2(354.0, 598.0)
	command_drawer.size = Vector2(348.0, 352.0)
	command_drawer.visible = false
	command_drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	command_drawer.add_theme_stylebox_override("panel", _panel_style(Color("07131f", 0.99), Color("67e7ff"), 12))
	add_child(command_drawer)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	command_drawer.add_child(column)
	command_title = Label.new()
	command_title.text = "COMMAND SYSTEMS"
	command_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	command_title.add_theme_font_size_override("font_size", 16)
	column.add_child(command_title)
	var systems: Array[Dictionary] = [
		{"id":"equipment", "label":"ROOM EQUIPMENT", "icon":"equipment"},
		{"id":"station", "label":"STATION DEFENSE", "icon":"shield"},
		{"id":"threats", "label":"SPACE THREATS", "icon":"threats"},
		{"id":"side_ops", "label":"SIDE OPERATIONS", "icon":"side_ops"},
		{"id":"research", "label":"ALLIANCE RESEARCH", "icon":"research"}
	]
	for data: Dictionary in systems:
		var button := Button.new()
		button.text = String(data.get("label", "SYSTEM"))
		button.custom_minimum_size = Vector2(320.0, 48.0)
		button.icon = GameIconRegistry.icon_for(String(data.get("icon", "equipment")), 30)
		button.icon_max_width = 30
		button.tooltip_text = _system_tooltip(String(data.get("id", "equipment")))
		button.add_theme_stylebox_override("normal", _button_style(false))
		button.add_theme_stylebox_override("hover", _button_style(true))
		button.pressed.connect(_open_system.bind(String(data.get("id", "equipment"))))
		column.add_child(button)
	var close := Button.new()
	close.text = "CLOSE COMMAND SYSTEMS"
	close.custom_minimum_size = Vector2(320.0, 40.0)
	close.icon = GameIconRegistry.icon_for("close", 26)
	close.add_theme_stylebox_override("normal", _button_style(false))
	close.add_theme_stylebox_override("hover", _button_style(true))
	close.pressed.connect(func() -> void: command_drawer.visible = false)
	column.add_child(close)

func _make_button(id: String, rect: Rect2, label: String, tooltip: String, icon_key: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = id
	button.position = rect.position
	button.size = rect.size
	button.text = label
	button.tooltip_text = tooltip
	button.icon = GameIconRegistry.icon_for(icon_key, 26)
	button.icon_max_width = 26
	button.expand_icon = false
	button.add_theme_font_size_override("font_size", 8)
	button.add_theme_stylebox_override("normal", _button_style(false))
	button.add_theme_stylebox_override("hover", _button_style(true))
	button.add_theme_stylebox_override("pressed", _button_style(true))
	button.pressed.connect(callback)
	add_child(button)
	buttons[id] = button
	return button

func _sync_selected_room() -> void:
	if precinct == null:
		return
	var candidate: String = String(precinct.get("selected_room_id"))
	if candidate.is_empty():
		candidate = selected_room_id
	if candidate != selected_room_id:
		selected_room_id = candidate
		var room: Dictionary = PrecinctState.get_room(selected_room_id)
		message = "%s selected." % String(room.get("name", "Station module"))

func _room_action() -> void:
	var room: Dictionary = PrecinctState.get_room(selected_room_id)
	if room.is_empty():
		return
	var result: Dictionary
	if bool(room.get("repaired", false)):
		result = PrecinctMeta.upgrade_room(selected_room_id)
	else:
		result = PrecinctState.repair_room(selected_room_id)
	message = String(result.get("message", "Station action complete."))
	MoonGoonsAudio.play("upgrade" if bool(result.get("ok", false)) else "error")
	queue_redraw()

func _open_equipment() -> void:
	active_nav = "command"
	command_drawer.visible = false
	_activate_internal("equipment")

func _on_nav_pressed(id: String) -> void:
	active_nav = id
	command_drawer.visible = false
	match id:
		"station": _activate_internal("city")
		"missions": _activate_internal("missions")
		"operations": _activate_internal("resources")
		"officers": _activate_internal("officers")
		"command": command_drawer.visible = true
	_update_button_states()
	MoonGoonsAudio.play("click")

func _open_system(id: String) -> void:
	command_drawer.visible = false
	active_nav = "command"
	_activate_internal(id)
	MoonGoonsAudio.play("click")

func _activate_internal(command_id: String) -> void:
	var ribbon: Node = precinct.get_node_or_null("CompactCommandRibbon") if precinct != null else null
	if ribbon != null and ribbon.has_method("_activate"):
		ribbon.call("_activate", command_id)
		call_deferred("_place_active_tray")
	message = "%s console opened." % command_id.replace("_", " ").capitalize()

func _place_active_tray() -> void:
	await get_tree().process_frame
	var ribbon: Node = precinct.get_node_or_null("CompactCommandRibbon") if precinct != null else null
	if ribbon == null or not ribbon.has_method("_active_tray"):
		return
	var tray_value: Variant = ribbon.call("_active_tray")
	if tray_value is Control:
		var tray := tray_value as Control
		tray.position = Vector2(366.0, 160.0)
		tray.size = Vector2(338.0, 790.0)
		tray.custom_minimum_size = Vector2.ZERO
		tray.visible = true
		tray.move_to_front()

func _toggle_cutaway() -> void:
	var controller: Node = _camera_controller()
	if controller == null:
		return
	if String(controller.get("current_mode")) == "cutaway":
		controller.call("set_three_quarter_view")
	else:
		controller.call("set_cutaway_view")
	MoonGoonsAudio.play("click")

func _zoom_out() -> void:
	var controller: Node = _camera_controller()
	if controller != null:
		controller.call("zoom_out")

func _zoom_in() -> void:
	var controller: Node = _camera_controller()
	if controller != null:
		controller.call("zoom_in")

func _rotate() -> void:
	var controller: Node = _camera_controller()
	if controller != null:
		controller.call("rotate_right")

func _center() -> void:
	var controller: Node = _camera_controller()
	if controller != null:
		controller.call("set_three_quarter_view")
	message = "Station camera recentered."

func _camera_controller() -> Node:
	return precinct.get_node_or_null("HybridCameraController") if precinct != null else null

func _toggle_audio() -> void:
	audio_muted = not audio_muted
	AudioServer.set_bus_mute(0, audio_muted)
	message = "Station audio muted." if audio_muted else "Station audio restored."
	_update_button_states()

func _load_game() -> void:
	var result: Dictionary = PrecinctState.load_game()
	message = String(result.get("message", "Save state loaded."))
	MoonGoonsAudio.play("confirm" if bool(result.get("ok", false)) else "error")

func _update_button_states() -> void:
	if buttons.has("sound"):
		(buttons["sound"] as Button).text = "AUDIO" if audio_muted else "MUTE"
	if buttons.has("room_action"):
		var room: Dictionary = PrecinctState.get_room(selected_room_id)
		var action := buttons["room_action"] as Button
		if int(room.get("repair_end", 0)) > 0:
			action.text = "REPAIRING"
			action.disabled = true
		elif bool(room.get("repaired", false)):
			action.text = "UPGRADE"
			action.disabled = false
		else:
			action.text = "REPAIR"
			action.disabled = false
	for key_value: Variant in nav_buttons.keys():
		var id: String = String(key_value)
		var button := nav_buttons[id] as Button
		button.add_theme_stylebox_override("normal", _button_style(id == active_nav))

func _hide_legacy_gui() -> void:
	if precinct == null:
		return
	var hide_paths: Array[String] = [
		"StationBoardFrameLayer/StationBoardFrame",
		"CompactCommandRibbonLayer/CompactCommandRibbon",
		"HybridViewControlsLayer/HybridViewControls",
		"EquipmentProgressionLayer/EquipmentToggle",
		"StationCommandLayer/StationCommandButton",
		"SideOperationsLayer/SideOperationsButton",
		"ResourceHarvestLayer/ResourceHarvestButton",
		"SpaceThreatOperationsLayer/SpaceThreatButton"
	]
	for path: String in hide_paths:
		var control: CanvasItem = precinct.get_node_or_null(path) as CanvasItem
		if control != null:
			control.visible = false
	var ribbon: Node = precinct.get_node_or_null("CompactCommandRibbon")
	if ribbon != null:
		ribbon.set_process(false)
	var interface: Node = precinct.get_node_or_null("Interface")
	if interface != null:
		for button: Button in _find_buttons(interface):
			if button.text in ["CITY", "OFFICERS", "PATROL", "CUSTODY", "TASKS", "MISSIONS", "CAMPAIGN ROUTER", "RTS FRONT"]:
				button.visible = false
	for button: Button in _find_buttons(precinct):
		if button.name in ["RoomDetailsToggle", "EquipmentToggle", "StationCommandButton", "ResourceMapButton", "SpaceThreatsButton", "SideOperationsButton"]:
			button.visible = false

func _find_buttons(root: Node) -> Array[Button]:
	var result: Array[Button] = []
	if root is Button:
		result.append(root as Button)
	for child: Node in root.get_children():
		result.append_array(_find_buttons(child))
	return result

func _threat_label() -> String:
	if not StationProgression.active_marauder_wave.is_empty():
		return "MARAUDER ATTACK"
	if SpaceThreats.active_target_id != "":
		return "SYNDICATE CONTACT"
	return "CLEAR"

func _nav_tooltip(id: String) -> String:
	match id:
		"station": return "Return to the playable orbital station deck and room selection view."
		"missions": return "Review chapter objectives, daily duty, patrol, defense, and resource missions."
		"operations": return "Manage asteroid, moon, and wreck harvesting operations across nearby space."
		"officers": return "Inspect, train, heal, and assign Peacekeeper personnel."
	return "Open equipment, station defenses, threats, side operations, and Alliance research."

func _system_tooltip(id: String) -> String:
	match id:
		"equipment": return "Inspect every room item, picture, level, effect, cost, requirement, and timer."
		"station": return "Upgrade the station, hull, shields, turrets, rail weapons, and interceptors."
		"threats": return "Track and engage Syndicate fleets, criminals, marauders, and command carriers."
		"side_ops": return "Run engine, weapons, medical, and interrogation interaction puzzles."
	return "Advance Construction, Technology, and Weapons research from level 1 through 100."

func _button_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("173549", 0.98) if active else Color("0a1722", 0.96)
	style.border_color = Color("67e7ff") if active else Color("36586b")
	style.set_border_width_all(2 if active else 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 5.0
	style.content_margin_right = 5.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style

func _panel_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
