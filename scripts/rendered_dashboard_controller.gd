extends Control
## Presents the approved rendered MoonGoons dashboard as the live station screen.
## Transparent hotspots connect the artwork to the existing simulation and panels.

@export var precinct_path: NodePath
@export var legacy_hud_path: NodePath

const VIEW := Vector2(720.0, 1280.0)
const ART_RECT := Rect2(0.0, 0.0, 720.0, 1080.0)
const DEFAULT_LAYER: int = 15
const PANEL_BACK_LAYER: int = -20

const FACILITIES: Dictionary = {
	"hq": {
		"title":"POLICE HEADQUARTERS",
		"description":"One connected command building containing Reception, Operations, Chief's Office, Detectives, Cyber Crimes, Bio-Hacking, Holding, Interrogation, and Prisoner Transport.",
		"detail":"9 departments • 12 upgrade items in each • 108 headquarters systems",
		"room":"ops", "primary":"equipment"
	},
	"research": {
		"title":"RESEARCH LAB",
		"description":"Develop station technology, weapons, equipment, alliance research, and advanced counter-Syndicate systems.",
		"detail":"Research speed • technology capacity • power efficiency • prototypes",
		"room":"ops", "primary":"research"
	},
	"training": {
		"title":"TRAINING CENTER",
		"description":"Train guards, patrol specialists, marksmen, and advanced response squads for station and orbital duty.",
		"detail":"Three troop branches • staffing • readiness • specialist certification",
		"room":"quarters", "primary":"officers"
	},
	"crime": {
		"title":"CRIME LAB",
		"description":"Analyze evidence, contraband, forensic samples, cyber traces, and captured Syndicate technology.",
		"detail":"Forensics • evidence quality • case speed • intelligence yield",
		"room":"interrogation", "primary":"equipment"
	},
	"hospital": {
		"title":"STATION HOSPITAL",
		"description":"Treat wounded officers, radiation exposure, bio-hacking injuries, and emergency casualties.",
		"detail":"Healing speed • bed capacity • medical staff • recovery quality",
		"room":"medbay", "primary":"equipment"
	},
	"robotics": {
		"title":"ROBOTICS BAY",
		"description":"Build service robots, tactical drones, repair units, and autonomous station defenders.",
		"detail":"Robot capacity • drone power • automation • defensive response",
		"room":"armory", "primary":"equipment"
	},
	"storage": {
		"title":"STORAGE DEPOT",
		"description":"Store Moonsteel, Helium-3, quantum salvage, evidence, supplies, and pressure-rated cargo.",
		"detail":"Capacity • cargo speed • protected evidence • reserve supplies",
		"room":"transfer", "primary":"resources"
	},
	"armory": {
		"title":"ARMORY",
		"description":"Upgrade Peacekeeper weapons, armor, ammunition, station defenses, and specialist equipment.",
		"detail":"Weapons • armor • ammunition • shields • station defense",
		"room":"armory", "primary":"equipment"
	}
}

const HOTSPOTS: Array[Dictionary] = [
	{"id":"missions", "rect":Rect2(8, 110, 142, 285), "tip":"Open story, daily, event, patrol, and station missions."},
	{"id":"threats", "rect":Rect2(8, 400, 142, 175), "tip":"Open the orbital threat map centered on the Peacekeeper station."},
	{"id":"research", "rect":Rect2(230, 95, 145, 145), "tip":"Research Lab"},
	{"id":"training", "rect":Rect2(455, 120, 170, 145), "tip":"Training Center"},
	{"id":"crime", "rect":Rect2(150, 245, 145, 145), "tip":"Crime Lab"},
	{"id":"hq", "rect":Rect2(280, 230, 185, 185), "tip":"Police Headquarters"},
	{"id":"hospital", "rect":Rect2(520, 285, 165, 145), "tip":"Station Hospital"},
	{"id":"robotics", "rect":Rect2(155, 410, 150, 145), "tip":"Robotics Bay"},
	{"id":"storage", "rect":Rect2(315, 430, 150, 140), "tip":"Storage Depot"},
	{"id":"armory", "rect":Rect2(490, 420, 160, 145), "tip":"Armory"},
	{"id":"departments", "rect":Rect2(8, 605, 525, 315), "tip":"Open Headquarters departments and their twelve-item upgrade grids."},
	{"id":"research_panel", "rect":Rect2(540, 610, 172, 305), "tip":"Open Research Lab details and upgrades."},
	{"id":"patrol", "rect":Rect2(8, 925, 170, 145), "tip":"Launch the Peacekeeper patrol spacecraft."},
	{"id":"officers", "rect":Rect2(180, 925, 175, 145), "tip":"Manage officers and assignments."},
	{"id":"squads", "rect":Rect2(355, 925, 180, 145), "tip":"Manage response squads and troop training."},
	{"id":"robots", "rect":Rect2(535, 925, 177, 145), "tip":"Manage station robots and drones."}
]

var precinct: Node
var legacy_hud: Control
var dashboard_texture: Texture2D
var status_label: Label
var popup: PanelContainer
var popup_title: Label
var popup_description: Label
var popup_detail: Label
var popup_primary: Button
var popup_upgrade: Button
var active_facility: String = ""
var command_popup: PanelContainer
var return_layer: CanvasLayer
var return_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	process_mode = Node.PROCESS_MODE_ALWAYS
	precinct = get_node_or_null(precinct_path)
	legacy_hud = get_node_or_null(legacy_hud_path) as Control
	dashboard_texture = RenderedDashboardAsset.load_texture()
	_hide_old_visual_shells()
	_build_hotspots()
	_build_bottom_navigation()
	_build_facility_popup()
	_build_command_popup()
	_build_return_layer()
	set_process(true)
	queue_redraw()

func _process(_delta: float) -> void:
	_hide_old_visual_shells()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("020711"), true)
	if dashboard_texture != null:
		draw_texture_rect(dashboard_texture, ART_RECT, false)
	else:
		draw_rect(ART_RECT, Color("170b12"), true)
		draw_string(ThemeDB.fallback_font, Vector2(35.0, 300.0), "RENDERED DASHBOARD FAILED TO LOAD", HORIZONTAL_ALIGNMENT_CENTER, 650.0, 24, Color("ff7f91"))
	_draw_bottom_backplate()

func _draw_bottom_backplate() -> void:
	draw_rect(Rect2(0.0, 1080.0, 720.0, 200.0), Color("050b14", 0.995), true)
	draw_line(Vector2(0.0, 1080.0), Vector2(720.0, 1080.0), Color("64e9ff", 0.8), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(16.0, 1101.0), "PEACEKEEPER COMMAND DOCK", HORIZONTAL_ALIGNMENT_LEFT, 350.0, 10, Color("8beeff"))
	draw_string(ThemeDB.fallback_font, Vector2(400.0, 1101.0), "Select a rendered facility for its live options", HORIZONTAL_ALIGNMENT_RIGHT, 302.0, 9, Color("b8cad8"))

func _hide_old_visual_shells() -> void:
	if legacy_hud != null:
		legacy_hud.visible = false
	if precinct == null:
		return
	for node_path: String in ["PrecinctWebBackdropLayer", "ApprovedStationArtLayer", "StationBoardFrameLayer"]:
		var layer: CanvasLayer = precinct.get_node_or_null(node_path) as CanvasLayer
		if layer != null:
			layer.visible = false
	for node_path: String in ["CompactCommandRibbonLayer", "HybridViewControlsLayer"]:
		var old_layer: CanvasLayer = precinct.get_node_or_null(node_path) as CanvasLayer
		if old_layer != null:
			old_layer.visible = false

func _build_hotspots() -> void:
	for data: Dictionary in HOTSPOTS:
		var id: String = String(data.get("id", "station"))
		var button := Button.new()
		button.name = "hotspot_%s" % id
		button.position = (data.get("rect", Rect2()) as Rect2).position
		button.size = (data.get("rect", Rect2()) as Rect2).size
		button.text = ""
		button.tooltip_text = String(data.get("tip", id.capitalize()))
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", _transparent_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0)))
		button.add_theme_stylebox_override("hover", _transparent_style(Color(0.2, 0.85, 1.0, 0.08), Color(0.4, 0.95, 1.0, 0.9)))
		button.add_theme_stylebox_override("pressed", _transparent_style(Color(1.0, 0.7, 0.25, 0.12), Color(1.0, 0.75, 0.3, 0.95)))
		button.pressed.connect(_on_hotspot_pressed.bind(id))
		add_child(button)

func _build_bottom_navigation() -> void:
	var nav: Array[Dictionary] = [
		{"id":"station", "label":"STATION", "icon":"station_deck"},
		{"id":"missions", "label":"MISSIONS", "icon":"missions"},
		{"id":"operations", "label":"ORBITAL MAP", "icon":"resources"},
		{"id":"officers", "label":"OFFICERS", "icon":"officers"},
		{"id":"command", "label":"COMMAND", "icon":"equipment"}
	]
	for index: int in range(nav.size()):
		var data: Dictionary = nav[index]
		var button := Button.new()
		button.name = "rendered_nav_%s" % String(data.get("id", "station"))
		button.position = Vector2(8.0 + float(index) * 142.0, 1110.0)
		button.size = Vector2(134.0, 74.0)
		button.text = String(data.get("label", "STATION"))
		button.icon = GameIconRegistry.icon_for(String(data.get("icon", "station_deck")), 30)
		button.expand_icon = false
		button.add_theme_font_size_override("font_size", 10)
		button.add_theme_stylebox_override("normal", _button_style(false))
		button.add_theme_stylebox_override("hover", _button_style(true))
		button.add_theme_stylebox_override("pressed", _button_style(true))
		button.pressed.connect(_on_navigation_pressed.bind(String(data.get("id", "station"))))
		add_child(button)
	status_label = Label.new()
	status_label.position = Vector2(14.0, 1194.0)
	status_label.size = Vector2(692.0, 70.0)
	status_label.text = "Rendered station online. Select a facility, mission, unit, or map panel."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color("b9d7e7"))
	add_child(status_label)

func _build_facility_popup() -> void:
	popup = PanelContainer.new()
	popup.name = "RenderedFacilityPopup"
	popup.position = Vector2(265.0, 660.0)
	popup.size = Vector2(430.0, 390.0)
	popup.visible = false
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.add_theme_stylebox_override("panel", _panel_style())
	add_child(popup)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	popup.add_child(column)
	popup_title = Label.new()
	popup_title.add_theme_font_size_override("font_size", 20)
	popup_title.add_theme_color_override("font_color", Color("f1fbff"))
	column.add_child(popup_title)
	popup_description = Label.new()
	popup_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_description.custom_minimum_size = Vector2(390.0, 100.0)
	popup_description.add_theme_font_size_override("font_size", 12)
	popup_description.add_theme_color_override("font_color", Color("bed2df"))
	column.add_child(popup_description)
	popup_detail = Label.new()
	popup_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_detail.custom_minimum_size = Vector2(390.0, 55.0)
	popup_detail.add_theme_font_size_override("font_size", 11)
	popup_detail.add_theme_color_override("font_color", Color("ffd37b"))
	column.add_child(popup_detail)
	popup_primary = _popup_button("OPEN FACILITY", _facility_primary)
	column.add_child(popup_primary)
	popup_upgrade = _popup_button("UPGRADES & SYSTEMS", _facility_upgrade)
	column.add_child(popup_upgrade)
	column.add_child(_popup_button("CLOSE", _close_popup))

func _build_command_popup() -> void:
	command_popup = PanelContainer.new()
	command_popup.name = "RenderedCommandPopup"
	command_popup.position = Vector2(300.0, 590.0)
	command_popup.size = Vector2(395.0, 455.0)
	command_popup.visible = false
	command_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	command_popup.add_theme_stylebox_override("panel", _panel_style())
	add_child(command_popup)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	command_popup.add_child(column)
	var title := Label.new()
	title.text = "COMMAND SYSTEMS"
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)
	for data: Dictionary in [
		{"label":"ROOM EQUIPMENT", "command":"equipment"},
		{"label":"STATION DEFENSE", "command":"station"},
		{"label":"SPACE THREATS", "command":"threats"},
		{"label":"SIDE OPERATIONS", "command":"side_ops"},
		{"label":"ALLIANCE RESEARCH", "command":"research"}
	]:
		column.add_child(_popup_button(String(data.get("label", "SYSTEM")), _open_live_panel.bind(String(data.get("command", "equipment")))))
	column.add_child(_popup_button("CLOSE", _close_command_popup))

func _build_return_layer() -> void:
	var root_node: Node = get_parent().get_parent()
	return_layer = CanvasLayer.new()
	return_layer.name = "RenderedDashboardReturnLayer"
	return_layer.layer = 300
	root_node.add_child(return_layer)
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

func _on_hotspot_pressed(id: String) -> void:
	match id:
		"missions": _open_live_panel("missions")
		"threats": _open_live_panel("threats")
		"departments": _show_facility("hq")
		"research_panel": _show_facility("research")
		"patrol": _open_live_panel("dispatch")
		"officers": _open_live_panel("officers")
		"squads": _open_live_panel("officers")
		"robots": _show_facility("robotics")
		_: _show_facility(id)

func _on_navigation_pressed(id: String) -> void:
	match id:
		"station": _return_to_station()
		"missions": _open_live_panel("missions")
		"operations": _open_live_panel("resources")
		"officers": _open_live_panel("officers")
		"command":
			popup.visible = false
			command_popup.visible = true
			status_label.text = "Choose a station command system."

func _show_facility(id: String) -> void:
	if not FACILITIES.has(id):
		return
	active_facility = id
	var data: Dictionary = FACILITIES[id] as Dictionary
	popup_title.text = String(data.get("title", "FACILITY"))
	popup_description.text = String(data.get("description", "Open station facility."))
	popup_detail.text = String(data.get("detail", "Upgradeable station system."))
	popup_primary.text = "OPEN %s" % String(data.get("title", "FACILITY"))
	popup.visible = true
	command_popup.visible = false
	status_label.text = "%s selected. Choose an action." % String(data.get("title", "Facility"))
	popup.move_to_front()

func _facility_primary() -> void:
	if not FACILITIES.has(active_facility):
		return
	var data: Dictionary = FACILITIES[active_facility] as Dictionary
	var room_id: String = String(data.get("room", "ops"))
	_select_room(room_id)
	status_label.text = "%s selected in the live station state." % String(data.get("title", "Facility"))

func _facility_upgrade() -> void:
	if not FACILITIES.has(active_facility):
		return
	var data: Dictionary = FACILITIES[active_facility] as Dictionary
	_open_live_panel(String(data.get("primary", "equipment")))

func _select_room(room_id: String) -> void:
	if precinct == null:
		return
	precinct.set("selected_room_id", room_id)
	var room_nodes_value: Variant = precinct.get("room_nodes")
	if room_nodes_value is Dictionary:
		var room: Node3D = (room_nodes_value as Dictionary).get(room_id) as Node3D
		if room != null:
			precinct.set("camera_target", room.position)

func _open_live_panel(command: String) -> void:
	popup.visible = false
	command_popup.visible = false
	if legacy_hud != null and legacy_hud.has_method("_activate_internal"):
		legacy_hud.call("_activate_internal", command)
	var dashboard_layer: CanvasLayer = get_parent() as CanvasLayer
	if dashboard_layer != null:
		dashboard_layer.layer = PANEL_BACK_LAYER
	return_button.visible = true
	status_label.text = "%s opened." % command.replace("_", " ").capitalize()

func _return_to_station() -> void:
	if legacy_hud != null and legacy_hud.has_method("_close_live_trays"):
		legacy_hud.call("_close_live_trays")
	var dashboard_layer: CanvasLayer = get_parent() as CanvasLayer
	if dashboard_layer != null:
		dashboard_layer.layer = DEFAULT_LAYER
	return_button.visible = false
	popup.visible = false
	command_popup.visible = false
	status_label.text = "Rendered station online. Select a facility, mission, unit, or map panel."

func _close_popup() -> void:
	popup.visible = false
	status_label.text = "Facility card closed."

func _close_command_popup() -> void:
	command_popup.visible = false
	status_label.text = "Command menu closed."

func _popup_button(label: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(380.0, 48.0)
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_stylebox_override("normal", _button_style(false))
	button.add_theme_stylebox_override("hover", _button_style(true))
	button.add_theme_stylebox_override("pressed", _button_style(true))
	button.pressed.connect(callback)
	return button

func _transparent_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func _button_style(highlighted: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("17364a", 0.98) if highlighted else Color("0a1c2a", 0.98)
	style.border_color = Color("65edff") if highlighted else Color("365f74")
	style.set_border_width_all(2 if highlighted else 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("07131f", 0.985)
	style.border_color = Color("65edff", 0.9)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	return style
