extends Control
## Displays the approved isometric orbital-station artwork above the emergency
## procedural renderer while preserving live game state, panels, and controls.

const ART_PATH: String = "res://assets/generated/approved_station_deck.svg"
const DESIGN_SIZE := Vector2(720.0, 760.0)
const FACILITIES: Dictionary = {
	"research": {"rect": Rect2(112, 100, 186, 190), "title": "Research Lab", "description": "Develop station technology, equipment, weapons, and alliance research."},
	"training": {"rect": Rect2(420, 100, 190, 190), "title": "Training Center", "description": "Train guards, patrol specialists, marksmen, and advanced response teams."},
	"hq": {"rect": Rect2(238, 180, 244, 270), "title": "Police Headquarters", "description": "Open Reception, Detectives, Cyber Crimes, Bio-Hacking, Transport, Interrogation, and command upgrades."},
	"crime": {"rect": Rect2(88, 280, 170, 190), "title": "Crime Lab", "description": "Analyze evidence, contraband, forensic samples, and Syndicate technology."},
	"hospital": {"rect": Rect2(470, 280, 170, 190), "title": "Station Hospital", "description": "Heal officers, improve recovery times, and upgrade medical capacity."},
	"robotics": {"rect": Rect2(135, 445, 175, 190), "title": "Robotics Bay", "description": "Build service robots, tactical drones, repair units, and autonomous defenders."},
	"storage": {"rect": Rect2(285, 475, 155, 190), "title": "Storage Depot", "description": "Increase resource capacity, evidence storage, supply reserves, and cargo handling."},
	"armory": {"rect": Rect2(425, 445, 175, 190), "title": "Armory", "description": "Upgrade weapons, armor, defensive systems, and specialist equipment."}
}

var precinct: Node
var art_texture: Texture2D
var art_rect := Rect2()
var art_scale: float = 1.0
var hovered_facility: String = ""
var animation_clock: float = 0.0
var status_message: String = ""
var status_until: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	process_mode = Node.PROCESS_MODE_ALWAYS
	precinct = get_parent().get_parent()
	art_texture = load(ART_PATH) as Texture2D
	if OS.has_feature("web"):
		var old_backdrop: CanvasLayer = precinct.get_node_or_null("PrecinctWebBackdropLayer") as CanvasLayer
		if old_backdrop != null:
			old_backdrop.visible = false
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	animation_clock += delta
	_update_hover(get_local_mouse_position())
	queue_redraw()

func _draw() -> void:
	var top_margin: float = clampf(size.y * 0.105, 108.0, 145.0)
	var available_height: float = maxf(480.0, size.y - top_margin - 300.0)
	art_scale = minf(size.x / DESIGN_SIZE.x, available_height / DESIGN_SIZE.y)
	var rendered_size: Vector2 = DESIGN_SIZE * art_scale
	art_rect = Rect2(Vector2((size.x - rendered_size.x) * 0.5, top_margin), rendered_size)
	if art_texture != null:
		draw_texture_rect(art_texture, art_rect, false)
	else:
		draw_rect(art_rect, Color("#06111d"), true)
		draw_string(ThemeDB.fallback_font, art_rect.get_center(), "GENERATING STATION ART...", HORIZONTAL_ALIGNMENT_CENTER, 300.0, 18, Color("#7ee7ff"))
	_draw_hover_state()
	_draw_live_personnel()
	_draw_status_message()

func _draw_hover_state() -> void:
	if hovered_facility.is_empty() or not FACILITIES.has(hovered_facility):
		return
	var data: Dictionary = FACILITIES[hovered_facility] as Dictionary
	var local_rect: Rect2 = data.get("rect", Rect2()) as Rect2
	var screen_rect := Rect2(art_rect.position + local_rect.position * art_scale, local_rect.size * art_scale)
	var pulse: float = 0.45 + 0.35 * sin(animation_clock * 4.0)
	draw_rect(screen_rect, Color(0.35, 0.93, 1.0, 0.08 + pulse * 0.08), true)
	draw_rect(screen_rect, Color(0.45, 0.95, 1.0, 0.72), false, maxf(2.0, art_scale * 2.0))
	var label_width: float = minf(420.0, size.x - 30.0)
	var label_rect := Rect2(Vector2((size.x - label_width) * 0.5, art_rect.end.y - 48.0), Vector2(label_width, 42.0))
	draw_style_box(_tooltip_box(), label_rect)
	draw_string(ThemeDB.fallback_font, label_rect.position + Vector2(10.0, 17.0), String(data.get("title", "Facility")), HORIZONTAL_ALIGNMENT_LEFT, label_rect.size.x - 20.0, 13, Color("#f0fbff"))
	draw_string(ThemeDB.fallback_font, label_rect.position + Vector2(10.0, 33.0), String(data.get("description", "Open facility options.")), HORIZONTAL_ALIGNMENT_LEFT, label_rect.size.x - 20.0, 9, Color("#8fdced"))

func _draw_live_personnel() -> void:
	if art_rect.size.x <= 1.0:
		return
	for index: int in range(10):
		var travel: float = fmod(animation_clock * (26.0 + float(index % 4) * 5.0) + float(index) * 61.0, 460.0)
		var design_position := Vector2(125.0 + travel, 350.0 + sin(animation_clock * 1.4 + float(index)) * 34.0 + float(index % 3) * 34.0)
		var p: Vector2 = art_rect.position + design_position * art_scale
		var body_color: Color = Color("#7ee7ff") if index < 6 else Color("#ffc36c")
		draw_circle(p - Vector2(0.0, 5.0 * art_scale), maxf(2.0, 2.4 * art_scale), Color("#dffaff"))
		draw_line(p - Vector2(0.0, 2.0 * art_scale), p + Vector2(0.0, 7.0 * art_scale), body_color, maxf(1.5, 1.8 * art_scale))
		var step: float = sin(animation_clock * 9.0 + float(index)) * 4.0 * art_scale
		draw_line(p + Vector2(0.0, 7.0 * art_scale), p + Vector2(-4.0 * art_scale, 13.0 * art_scale + step), body_color, maxf(1.2, 1.5 * art_scale))
		draw_line(p + Vector2(0.0, 7.0 * art_scale), p + Vector2(4.0 * art_scale, 13.0 * art_scale - step), body_color, maxf(1.2, 1.5 * art_scale))

func _draw_status_message() -> void:
	if status_message.is_empty() or animation_clock > status_until:
		return
	var rect := Rect2(Vector2(70.0, art_rect.position.y + 18.0), Vector2(size.x - 140.0, 36.0))
	draw_style_box(_tooltip_box(), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 23.0), status_message, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 12, Color("#dffaff"))

func _gui_input(event: InputEvent) -> void:
	var pointer_position: Vector2
	var activated: bool = false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		pointer_position = mouse_event.position
		activated = true
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if not touch_event.pressed:
			return
		pointer_position = touch_event.position
		activated = true
	if not activated:
		return
	var facility_id: String = _facility_at(pointer_position)
	if facility_id.is_empty():
		return
	_activate_facility(facility_id)
	accept_event()

func _update_hover(pointer_position: Vector2) -> void:
	var new_hover: String = _facility_at(pointer_position)
	if new_hover == hovered_facility:
		return
	hovered_facility = new_hover
	if hovered_facility.is_empty():
		tooltip_text = ""
	else:
		var data: Dictionary = FACILITIES[hovered_facility] as Dictionary
		tooltip_text = "%s\n%s" % [String(data.get("title", "Facility")), String(data.get("description", ""))]

func _facility_at(pointer_position: Vector2) -> String:
	if art_scale <= 0.0 or not art_rect.has_point(pointer_position):
		return ""
	var design_position: Vector2 = (pointer_position - art_rect.position) / art_scale
	for facility_value: Variant in FACILITIES.keys():
		var facility_id: String = String(facility_value)
		var data: Dictionary = FACILITIES[facility_id] as Dictionary
		var rect: Rect2 = data.get("rect", Rect2()) as Rect2
		if rect.has_point(design_position):
			return facility_id
	return ""

func _activate_facility(facility_id: String) -> void:
	match facility_id:
		"hq":
			_select_room("ops", "Police Headquarters opened")
		"research":
			_open_research()
		"training":
			_open_core_panel("officer_panel", "Training and officer roster opened")
		"crime":
			_select_room("interrogation", "Crime Lab and investigation systems opened")
		"hospital":
			_select_room("medbay", "Station Hospital opened")
		"robotics":
			_open_external_panel("PrecinctProgressionUI", "equipment_panel", "Robotics and equipment systems opened")
		"storage":
			_open_external_panel("ResourceHarvestController", "panel", "Storage and resource operations opened")
		"armory":
			_select_room("armory", "Armory opened")
	MoonGoonsAudio.play("door")

func _select_room(room_id: String, message: String) -> void:
	if precinct == null:
		return
	precinct.set("selected_room_id", room_id)
	var room_nodes_value: Variant = precinct.get("room_nodes")
	if room_nodes_value is Dictionary:
		var room: Node3D = (room_nodes_value as Dictionary).get(room_id) as Node3D
		if room != null:
			precinct.set("camera_target", room.position)
	precinct.call("_show_tab", "city")
	var panel_value: Variant = precinct.get("city_panel")
	if panel_value is Control:
		(panel_value as Control).visible = true
	_show_status(message)

func _open_core_panel(property_name: String, message: String) -> void:
	if precinct == null:
		return
	var panel_value: Variant = precinct.get(property_name)
	if panel_value is Control:
		(panel_value as Control).visible = true
	_show_status(message)

func _open_external_panel(controller_name: String, property_name: String, message: String) -> void:
	if precinct == null:
		return
	var controller: Node = precinct.get_node_or_null(controller_name)
	if controller != null:
		var panel_value: Variant = controller.get(property_name)
		if panel_value is Control:
			(panel_value as Control).visible = true
	_show_status(message)

func _open_research() -> void:
	var overlay: Node = get_node_or_null("/root/AllianceResearchOverlay")
	if overlay != null:
		var panel_value: Variant = overlay.get("panel")
		if panel_value is Control:
			(panel_value as Control).visible = true
		_show_status("Alliance Research opened")
		return
	_open_external_panel("PrecinctProgressionUI", "equipment_panel", "Research equipment opened")

func _show_status(message: String) -> void:
	status_message = message
	status_until = animation_clock + 2.4
	queue_redraw()

func _tooltip_box() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#06131f", 0.96)
	style.border_color = Color("#63e8ff", 0.75)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	return style
