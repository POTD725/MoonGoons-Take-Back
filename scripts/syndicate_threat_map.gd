extends Node2D
## Cops-side district map for MoonGoons Take Back.
## Criminal crews appear only as targets for investigation and enforcement.

const VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)
const MAP_RECT: Rect2 = Rect2(26.0, 98.0, 890.0, 540.0)
const PANEL_RECT: Rect2 = Rect2(934.0, 98.0, 320.0, 540.0)

const DISTRICT_POSITIONS: Dictionary = {
	"crater_market": Vector2(210.0, 240.0),
	"tycho_transit": Vector2(450.0, 175.0),
	"blueglass": Vector2(705.0, 235.0),
	"dock_seven": Vector2(245.0, 450.0),
	"signal_canyon": Vector2(485.0, 390.0),
	"mare_highway": Vector2(730.0, 470.0)
}

var selected_id: String = "crater_market"
var district_rects: Dictionary = {}
var button_rects: Dictionary = {
	"investigate": Rect2(956.0, 472.0, 276.0, 42.0),
	"intercept": Rect2(956.0, 522.0, 276.0, 42.0),
	"save": Rect2(956.0, 572.0, 132.0, 38.0),
	"back": Rect2(1100.0, 572.0, 132.0, 38.0)
}
var art: Dictionary = {}
var pulse: float = 0.0
var status_message: String = "Select a district to review Syndicate activity."

func _ready() -> void:
	_load_art()
	selected_id = CounterSyndicate.current_target_id
	CounterSyndicate.threat_changed.connect(_on_threat_changed)
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _input(event: InputEvent) -> void:
	var position: Vector2 = Vector2.ZERO
	var pressed: bool = false
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		position = mouse_event.position
		pressed = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		position = touch_event.position
		pressed = touch_event.pressed
	if not pressed:
		return
	for district_value: Variant in district_rects.keys():
		var district_id: String = String(district_value)
		var rect: Rect2 = district_rects[district_id] as Rect2
		if rect.has_point(position):
			selected_id = district_id
			var result: Dictionary = CounterSyndicate.select_target(district_id)
			status_message = String(result.get("message", "District selected."))
			MoonGoonsAudio.play("click")
			queue_redraw()
			return
	for action_value: Variant in button_rects.keys():
		var action: String = String(action_value)
		var action_rect: Rect2 = button_rects[action] as Rect2
		if action_rect.has_point(position):
			_handle_action(action)
			return

func _handle_action(action: String) -> void:
	match action:
		"investigate":
			var result: Dictionary = CounterSyndicate.investigate_target()
			status_message = String(result.get("message", "Investigation failed."))
			MoonGoonsAudio.play("confirm" if bool(result.get("ok", false)) else "error")
		"intercept":
			var operation_result: Dictionary = _create_targeted_operation()
			status_message = String(operation_result.get("message", "Operation could not be created."))
			MoonGoonsAudio.play("dispatch" if bool(operation_result.get("ok", false)) else "error")
		"save":
			CounterSyndicate.save_state()
			PrecinctState.save_game()
			status_message = "Peacekeeper campaign and precinct state saved."
			MoonGoonsAudio.play("confirm")
		"back":
			MoonGoonsAudio.play("confirm")
			get_tree().change_scene_to_file("res://scenes/LivingPrecinct.tscn")
		_:
			pass
	queue_redraw()

func _create_targeted_operation() -> Dictionary:
	var district: Dictionary = CounterSyndicate.get_district(selected_id)
	if district.is_empty():
		return {"ok": false, "message": "Select a district first."}
	if PrecinctState.patrol_calls.size() >= 4:
		return {"ok": false, "message": "Patrol board is full. Resolve an active operation first."}
	var threat: int = int(district.get("threat", 50))
	var difficulty: int = clampi(1 + threat / 34, 1, 3)
	var title_options: Array[String] = [
		"Intercept Syndicate Score",
		"Raid Exposed Hideout",
		"Break Smuggling Route",
		"Arrest Syndicate Operators"
	]
	var title: String = title_options[(threat + selected_id.length()) % title_options.size()]
	if bool(district.get("hideout_exposed", false)):
		title = "Raid Exposed Syndicate Hideout"
	var call_id: String = "syndicate_%s_%d" % [selected_id, int(Time.get_unix_time_from_system())]
	var operation: Dictionary = {
		"id": call_id,
		"title": title,
		"sector": String(district.get("name", "Lunar District")),
		"district_id": selected_id,
		"enemy_crew": String(district.get("crew", "Syndicate Crew")),
		"difficulty": difficulty,
		"reward": 120 + difficulty * 80,
		"expires_at": int(Time.get_unix_time_from_system()) + 95,
		"enemy_hp": 90 + difficulty * 70,
		"enemy_power": 12 + difficulty * 6,
		"arrestable": true,
		"syndicate_operation": true
	}
	PrecinctState.patrol_calls.append(operation)
	PrecinctState.last_event = "SYNDICATE OPERATION // %s in %s." % [title, String(district.get("name", "district"))]
	PrecinctState.state_changed.emit()
	return {"ok": true, "message": "Operation added to the precinct Patrol board. Return to the precinct and dispatch officers."}

func _draw() -> void:
	_draw_backdrop()
	_draw_header()
	_draw_map()
	_draw_districts()
	_draw_intel_panel()
	_draw_footer()

func _draw_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("020711"))
	var crater: Texture2D = art.get("crater") as Texture2D
	if crater != null:
		for x_index: int in range(5):
			for y_index: int in range(3):
				draw_texture_rect(crater, Rect2(float(x_index) * 290.0 - 50.0, float(y_index) * 250.0, 320.0, 270.0), false, Color(0.35, 0.45, 0.58, 0.16))
	for index: int in range(90):
		var x: float = fmod(float(index * 107 + 37), VIEWPORT_SIZE.x)
		var y: float = fmod(float(index * 61 + 21), VIEWPORT_SIZE.y)
		draw_circle(Vector2(x, y), 0.8 + float(index % 3) * 0.4, Color("a7d9ff", 0.20))

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, VIEWPORT_SIZE.x, 82.0), Color("07192a", 0.97), true)
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 35.0), "MOONGOONS TAKE BACK // SYNDICATE THREAT MAP", HORIZONTAL_ALIGNMENT_LEFT, 760.0, 23, Color("ecfbff"))
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 61.0), "LUNAR PEACEKEEPER COMMAND • INVESTIGATE • INTERCEPT • ARREST • RECLAIM", HORIZONTAL_ALIGNMENT_LEFT, 860.0, 11, Color("72ddf5"))
	draw_string(ThemeDB.fallback_font, Vector2(808.0, 45.0), CounterSyndicate.campaign_status(), HORIZONTAL_ALIGNMENT_RIGHT, 440.0, 11, Color("bcebf4"))
	draw_line(Vector2(0.0, 81.0), Vector2(VIEWPORT_SIZE.x, 81.0), Color("56dfff", 0.48), 2.0)

func _draw_map() -> void:
	draw_style_box(_panel_style(Color("071523", 0.96), Color("3e91ad", 0.55), 2, 14), MAP_RECT)
	for connection: Array in [
		["crater_market", "tycho_transit"], ["tycho_transit", "blueglass"],
		["crater_market", "dock_seven"], ["tycho_transit", "signal_canyon"],
		["blueglass", "mare_highway"], ["dock_seven", "signal_canyon"],
		["signal_canyon", "mare_highway"]
	]:
		var from_pos: Vector2 = DISTRICT_POSITIONS[String(connection[0])] as Vector2
		var to_pos: Vector2 = DISTRICT_POSITIONS[String(connection[1])] as Vector2
		draw_line(from_pos, to_pos, Color("5dcbe8", 0.22), 7.0)
		draw_line(from_pos, to_pos, Color("a6efff", 0.28), 2.0)
	var nexus: Texture2D = art.get("command_nexus") as Texture2D
	if nexus != null:
		draw_texture_rect(nexus, Rect2(365.0, 255.0, 190.0, 170.0), false, Color(0.75, 0.92, 1.0, 0.18))

func _draw_districts() -> void:
	district_rects.clear()
	for district: Dictionary in CounterSyndicate.district_catalog():
		var district_id: String = String(district.get("id", ""))
		if not DISTRICT_POSITIONS.has(district_id):
			continue
		var center: Vector2 = DISTRICT_POSITIONS[district_id] as Vector2
		var rect: Rect2 = Rect2(center - Vector2(82.0, 48.0), Vector2(164.0, 96.0))
		district_rects[district_id] = rect
		var selected: bool = district_id == selected_id
		var threat: int = int(district.get("threat", 0))
		var control: int = int(district.get("control", 0))
		var threat_color: Color = Color("ff5e7d") if threat >= 67 else (Color("ffc36e") if threat >= 34 else Color("6ce9c1"))
		var border: Color = Color("eaffff") if selected else threat_color
		draw_style_box(_panel_style(Color("0b1b2b", 0.96), border, 3 if selected else 1, 11), rect)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 23.0), String(district.get("name", "DISTRICT")).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 11, Color("f2fbff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 45.0), "THREAT %d%%" % threat, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 10, threat_color)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 64.0), "AUTHORITY %d%%" % control, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 9, Color("72e5ff"))
		var intel: int = int(district.get("intel", 0))
		draw_rect(Rect2(rect.position + Vector2(13.0, 76.0), Vector2(138.0, 7.0)), Color("02070d"), true)
		draw_rect(Rect2(rect.position + Vector2(13.0, 76.0), Vector2(138.0 * float(intel) / 100.0, 7.0)), Color("ab7cff"), true)

func _draw_intel_panel() -> void:
	draw_style_box(_panel_style(Color("071523", 0.98), Color("3e91ad", 0.55), 2, 14), PANEL_RECT)
	var district: Dictionary = CounterSyndicate.get_district(selected_id)
	draw_string(ThemeDB.fallback_font, Vector2(952.0, 132.0), "TARGET INTELLIGENCE", HORIZONTAL_ALIGNMENT_LEFT, 275.0, 14, Color("8ceaff"))
	if district.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(952.0, 174.0), "Select a lunar district.", HORIZONTAL_ALIGNMENT_LEFT, 275.0, 11, Color("9bb7c4"))
		return
	draw_string(ThemeDB.fallback_font, Vector2(952.0, 172.0), String(district.get("name", "DISTRICT")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 275.0, 18, Color("f2fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(952.0, 203.0), "HOSTILE CREW", HORIZONTAL_ALIGNMENT_LEFT, 275.0, 9, Color("ff8ba4"))
	draw_string(ThemeDB.fallback_font, Vector2(952.0, 225.0), String(district.get("crew", "Syndicate Crew")), HORIZONTAL_ALIGNMENT_LEFT, 275.0, 12, Color("ffdce4"))
	draw_string(ThemeDB.fallback_font, Vector2(952.0, 259.0), "KNOWN ACTIVITY", HORIZONTAL_ALIGNMENT_LEFT, 275.0, 9, Color("ffca7a"))
	draw_multiline_string(ThemeDB.fallback_font, Vector2(952.0, 281.0), String(district.get("activity", "Unknown activity")), HORIZONTAL_ALIGNMENT_LEFT, 275.0, 12, -1, Color("d0e6ed"))
	var hideout_text: String = "EXPOSED" if bool(district.get("hideout_exposed", false)) else "HIDDEN"
	draw_string(ThemeDB.fallback_font, Vector2(952.0, 350.0), "HIDEOUT: %s" % hideout_text, HORIZONTAL_ALIGNMENT_LEFT, 275.0, 11, Color("6ff0c1") if hideout_text == "EXPOSED" else Color("ff7c98"))
	draw_string(ThemeDB.fallback_font, Vector2(952.0, 379.0), "INTEL EXPOSURE %d%%" % int(district.get("intel", 0)), HORIZONTAL_ALIGNMENT_LEFT, 275.0, 11, Color("ba9bff"))
	draw_multiline_string(ThemeDB.fallback_font, Vector2(952.0, 414.0), CounterSyndicate.last_briefing, HORIZONTAL_ALIGNMENT_LEFT, 275.0, 10, -1, Color("9fc4d0"))
	_draw_button("investigate", "SPEND 5 INTEL • INVESTIGATE")
	_draw_button("intercept", "CREATE INTERCEPT OPERATION")
	_draw_button("save", "SAVE")
	_draw_button("back", "PRECINCT")

func _draw_button(action: String, label: String) -> void:
	var rect: Rect2 = button_rects[action] as Rect2
	draw_style_box(_panel_style(Color("12344a"), Color("59cbe8"), 1, 8), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 26.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 10, Color("effcff"))

func _draw_footer() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(30.0, 680.0), status_message, HORIZONTAL_ALIGNMENT_LEFT, 900.0, 11, Color("b9dce5"))
	draw_string(ThemeDB.fallback_font, Vector2(945.0, 680.0), "TAKE BACK THE MOON • DISTRICT BY DISTRICT", HORIZONTAL_ALIGNMENT_RIGHT, 300.0, 10, Color("73ddf3"))

func _load_art() -> void:
	var paths: Dictionary = {
		"crater": "res://assets/skins/moongoons/crater.png",
		"command_nexus": "res://assets/skins/moongoons/command_nexus.png",
		"wrecked_shuttle": "res://assets/skins/moongoons/wrecked_shuttle.png",
		"patrol_deputy": "res://assets/skins/moongoons/patrol_deputy.png"
	}
	for key_value: Variant in paths.keys():
		var key: String = String(key_value)
		var path: String = String(paths[key])
		if ResourceLoader.exists(path):
			art[key] = load(path) as Texture2D

func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style

func _on_threat_changed() -> void:
	queue_redraw()
