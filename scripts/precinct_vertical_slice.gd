extends Node2D
## MoonGoons precinct management vertical slice.
## All visuals are original code-drawn lunar command art so the prototype has no borrowed APK assets.

const VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)
const PRECINCT_RECT: Rect2 = Rect2(24.0, 104.0, 858.0, 500.0)
const SIDE_RECT: Rect2 = Rect2(898.0, 104.0, 358.0, 500.0)
const BOTTOM_RECT: Rect2 = Rect2(24.0, 620.0, 1232.0, 78.0)

var room_rects: Dictionary = {}
var officer_rects: Dictionary = {}
var call_rects: Dictionary = {}
var action_rects: Dictionary = {}
var selected_room_id: String = "ops"
var selected_call_id: String = ""
var selected_officer_ids: Array[String] = []
var status_message: String = "Select a damaged room to repair, or choose a distress call and officers to dispatch."
var pulse: float = 0.0
var tick_accumulator: float = 0.0

func _ready() -> void:
	_configure_layout()
	PrecinctState.tick()
	PrecinctState.state_changed.connect(_on_state_changed)
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	tick_accumulator += delta
	if tick_accumulator >= 0.25:
		tick_accumulator = 0.0
		PrecinctState.tick()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_handle_press(mouse_event.position)
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		if touch_event.pressed:
			_handle_press(touch_event.position)

func _draw() -> void:
	_draw_space_backdrop()
	_draw_header()
	_draw_precinct_shell()
	_draw_rooms()
	_draw_side_panel()
	_draw_action_deck()
	_draw_footer_status()

func _configure_layout() -> void:
	room_rects.clear()
	var room_ids: Array[String] = ["ops", "armory", "cells", "quarters", "medbay", "chief", "interrogation", "transfer"]
	for index: int in range(room_ids.size()):
		var column: int = index % 4
		var row: int = index / 4
		var room_rect: Rect2 = Rect2(38.0 + float(column) * 208.0, 132.0 + float(row) * 224.0, 194.0, 206.0)
		room_rects[room_ids[index]] = room_rect
	action_rects = {
		"dispatch": Rect2(36.0, 636.0, 140.0, 44.0),
		"repair": Rect2(186.0, 636.0, 140.0, 44.0),
		"research": Rect2(336.0, 636.0, 140.0, 44.0),
		"process": Rect2(486.0, 636.0, 140.0, 44.0),
		"save": Rect2(636.0, 636.0, 140.0, 44.0),
		"load": Rect2(786.0, 636.0, 140.0, 44.0),
		"reset": Rect2(936.0, 636.0, 140.0, 44.0),
		"rts": Rect2(1086.0, 636.0, 156.0, 44.0)
	}

func _handle_press(position: Vector2) -> void:
	for room_id_value: Variant in room_rects.keys():
		var room_id: String = String(room_id_value)
		var room_rect: Rect2 = room_rects[room_id] as Rect2
		if room_rect.has_point(position):
			selected_room_id = room_id
			var room: Dictionary = PrecinctState.get_room(room_id)
			status_message = "%s selected // %s" % [String(room.get("name", "Room")), String(room.get("function", "Unknown function"))]
			queue_redraw()
			return
	for call_id_value: Variant in call_rects.keys():
		var call_id: String = String(call_id_value)
		var call_rect: Rect2 = call_rects[call_id] as Rect2
		if call_rect.has_point(position):
			selected_call_id = call_id
			status_message = "Distress call selected. Choose up to three available officers, then DISPATCH."
			queue_redraw()
			return
	for officer_id_value: Variant in officer_rects.keys():
		var officer_id: String = String(officer_id_value)
		var officer_rect: Rect2 = officer_rects[officer_id] as Rect2
		if officer_rect.has_point(position):
			_toggle_officer(officer_id)
			return
	for action_value: Variant in action_rects.keys():
		var action: String = String(action_value)
		var action_rect: Rect2 = action_rects[action] as Rect2
		if action_rect.has_point(position):
			_handle_action(action)
			return

func _toggle_officer(officer_id: String) -> void:
	var officer: Dictionary = PrecinctState.get_officer(officer_id)
	if officer.is_empty() or not PrecinctState.officer_available(officer):
		status_message = "%s is not currently available." % String(officer.get("name", "Officer"))
		return
	if selected_officer_ids.has(officer_id):
		selected_officer_ids.erase(officer_id)
		status_message = "%s removed from the patrol team." % String(officer.get("name", "Officer"))
	elif selected_officer_ids.size() >= 3:
		status_message = "Patrol teams are limited to three officers in this prototype."
	else:
		selected_officer_ids.append(officer_id)
		status_message = "%s added to the patrol team." % String(officer.get("name", "Officer"))
	queue_redraw()

func _handle_action(action: String) -> void:
	var result: Dictionary = {}
	match action:
		"dispatch":
			result = PrecinctState.begin_patrol(selected_call_id, selected_officer_ids)
			status_message = String(result.get("message", "Dispatch failed."))
			if bool(result.get("ok", false)):
				get_tree().change_scene_to_file("res://scenes/PrecinctBattle.tscn")
				return
		"repair":
			result = PrecinctState.repair_room(selected_room_id)
			status_message = String(result.get("message", "Repair failed."))
		"research":
			result = PrecinctState.begin_research()
			status_message = String(result.get("message", "Research failed."))
		"process":
			result = PrecinctState.process_prisoner()
			status_message = String(result.get("message", "Processing failed."))
		"save":
			result = PrecinctState.save_game()
			status_message = String(result.get("message", "Save failed."))
		"load":
			result = PrecinctState.load_game()
			status_message = String(result.get("message", "Load failed."))
			selected_officer_ids.clear()
			selected_call_id = ""
		"reset":
			PrecinctState.reset_state()
			selected_officer_ids.clear()
			selected_call_id = ""
			selected_room_id = "ops"
			status_message = "Precinct prototype reset to its opening state."
		"rts":
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
			return
		_:
			pass
	queue_redraw()

func _draw_space_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("030813"))
	draw_rect(Rect2(0.0, 0.0, VIEWPORT_SIZE.x, 92.0), Color("091b34"))
	for index: int in range(80):
		var x: float = fmod(float(index * 97 + 43), VIEWPORT_SIZE.x)
		var y: float = fmod(float(index * 53 + 21), VIEWPORT_SIZE.y)
		var radius: float = 1.0 + float(index % 3) * 0.45
		draw_circle(Vector2(x, y), radius, Color("a9d8ff", 0.26))
	draw_circle(Vector2(1110.0, 38.0), 86.0, Color("7ddcff", 0.035))
	draw_circle(Vector2(1110.0, 38.0), 52.0, Color("7ddcff", 0.025))

func _draw_header() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 34.0), "MOONGOONS TAKE BACK", HORIZONTAL_ALIGNMENT_LEFT, 420.0, 24, Color("e9fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 61.0), "LUNAR PRECINCT // COMMAND VERTICAL SLICE", HORIZONTAL_ALIGNMENT_LEFT, 520.0, 13, Color("76dfff"))
	var stats: String = "CREDITS %04d   INTEL %03d   EVIDENCE %02d   PRISONERS %02d   RESEARCH L%d" % [PrecinctState.credits, PrecinctState.intel, PrecinctState.evidence, PrecinctState.prisoners, PrecinctState.research_level]
	draw_string(ThemeDB.fallback_font, Vector2(622.0, 45.0), stats, HORIZONTAL_ALIGNMENT_LEFT, 620.0, 15, Color("b9f5ff"))
	var research_text: String = "READY"
	if PrecinctState.research_end > 0:
		research_text = "%ds" % PrecinctState.seconds_left(PrecinctState.research_end)
	draw_string(ThemeDB.fallback_font, Vector2(622.0, 68.0), "TECH QUEUE: %s" % research_text, HORIZONTAL_ALIGNMENT_LEFT, 250.0, 11, Color("8ab9cc"))
	draw_line(Vector2(0.0, 91.0), Vector2(VIEWPORT_SIZE.x, 91.0), Color("63dbff", 0.42), 2.0)

func _draw_precinct_shell() -> void:
	draw_style_box(_panel_style(Color("071523", 0.95), Color("4fb8d8", 0.52), 2, 14), PRECINCT_RECT)
	draw_string(ThemeDB.fallback_font, Vector2(40.0, 124.0), "PRECINCT CUTAWAY // TAP A ROOM", HORIZONTAL_ALIGNMENT_LEFT, 380.0, 11, Color("83dff7"))
	for column: int in range(5):
		var x: float = 34.0 + float(column) * 208.0
		draw_line(Vector2(x, 126.0), Vector2(x, 592.0), Color("65d7ff", 0.055), 1.0)
	for row: int in range(3):
		var y: float = 128.0 + float(row) * 224.0
		draw_line(Vector2(34.0, y), Vector2(872.0, y), Color("65d7ff", 0.055), 1.0)

func _draw_rooms() -> void:
	for room: Dictionary in PrecinctState.rooms:
		var room_id: String = String(room.get("id", ""))
		if not room_rects.has(room_id):
			continue
		var rect: Rect2 = room_rects[room_id] as Rect2
		var selected: bool = room_id == selected_room_id
		var repaired: bool = bool(room.get("repaired", false))
		var repair_end: int = int(room.get("repair_end", 0))
		var fill: Color = Color("102b3e") if repaired else Color("201a27")
		var border: Color = Color("bff8ff") if selected else (Color("50d2eb") if repaired else Color("b1647c"))
		draw_style_box(_panel_style(fill, border, 2 if selected else 1, 10), rect)
		_draw_room_cutaway(room_id, rect, repaired)
		draw_rect(Rect2(rect.position + Vector2(0.0, 150.0), Vector2(rect.size.x, 56.0)), Color("06121e", 0.90), true)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 169.0), String(room.get("name", "ROOM")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 12, Color("eaffff"))
		var detail: String = "L%d // %s" % [int(room.get("level", 1)), String(room.get("function", ""))]
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 188.0), detail, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 10, Color("8dc3d4"))
		if repaired:
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 202.0), "OPERATIONAL", HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 9, Color("72f0c1"))
		elif repair_end > 0:
			var repair_text: String = "REPAIRING // %ds" % PrecinctState.seconds_left(repair_end)
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 202.0), repair_text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 9, Color("ffd17c"))
		else:
			var cost_text: String = "DAMAGED // %d CR" % int(room.get("repair_cost", 0))
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 202.0), cost_text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16.0, 9, Color("ff8ca8"))

func _draw_room_cutaway(room_id: String, rect: Rect2, repaired: bool) -> void:
	var interior: Rect2 = Rect2(rect.position + Vector2(7.0, 7.0), Vector2(rect.size.x - 14.0, 137.0))
	draw_rect(interior, Color("0a2030") if repaired else Color("15131c"), true)
	draw_rect(Rect2(interior.position + Vector2(0.0, 108.0), Vector2(interior.size.x, 29.0)), Color("183648") if repaired else Color("2a2029"), true)
	for grid_index: int in range(6):
		var gx: float = interior.position.x + float(grid_index) * 32.0
		draw_line(Vector2(gx, interior.position.y + 108.0), Vector2(gx + 18.0, interior.end.y), Color("72d8e8", 0.10), 1.0)
	match room_id:
		"ops":
			_draw_console(interior.position + Vector2(18.0, 38.0), 58.0)
			_draw_console(interior.position + Vector2(100.0, 38.0), 58.0)
			draw_circle(interior.position + Vector2(89.0, 90.0), 17.0, Color("63e7ff", 0.22))
			draw_arc(interior.position + Vector2(89.0, 90.0), 23.0, 0.0, TAU, 24, Color("9af6ff", 0.55), 2.0)
		"armory":
			for rack: int in range(3):
				var rx: float = interior.position.x + 22.0 + float(rack) * 54.0
				draw_rect(Rect2(rx, interior.position.y + 26.0, 35.0, 72.0), Color("172f3e"), true)
				draw_line(Vector2(rx + 8.0, interior.position.y + 42.0), Vector2(rx + 28.0, interior.position.y + 79.0), Color("95e6f6"), 4.0)
		"cells":
			for cell: int in range(2):
				var cx: float = interior.position.x + 17.0 + float(cell) * 85.0
				draw_rect(Rect2(cx, interior.position.y + 22.0, 72.0, 82.0), Color("102633"), true)
				for bar: int in range(6):
					var bx: float = cx + 7.0 + float(bar) * 11.0
					draw_line(Vector2(bx, interior.position.y + 24.0), Vector2(bx, interior.position.y + 102.0), Color("91c9d7"), 2.0)
		"quarters":
			for bunk: int in range(2):
				var by: float = interior.position.y + 27.0 + float(bunk) * 48.0
				draw_rect(Rect2(interior.position.x + 20.0, by, 64.0, 22.0), Color("567080"), true)
				draw_rect(Rect2(interior.position.x + 104.0, by, 64.0, 22.0), Color("567080"), true)
		"medbay":
			draw_rect(Rect2(interior.position + Vector2(25.0, 67.0), Vector2(116.0, 34.0)), Color("d7eef1"), true)
			draw_circle(interior.position + Vector2(143.0, 84.0), 15.0, Color("93f4f0"))
			draw_rect(Rect2(interior.position + Vector2(76.0, 23.0), Vector2(32.0, 8.0)), Color("6affd3"), true)
			draw_rect(Rect2(interior.position + Vector2(88.0, 11.0), Vector2(8.0, 32.0)), Color("6affd3"), true)
		"chief":
			draw_rect(Rect2(interior.position + Vector2(35.0, 61.0), Vector2(112.0, 42.0)), Color("704f39"), true)
			draw_rect(Rect2(interior.position + Vector2(67.0, 25.0), Vector2(50.0, 26.0)), Color("173c53"), true)
			draw_string(ThemeDB.fallback_font, interior.position + Vector2(75.0, 44.0), "MG", HORIZONTAL_ALIGNMENT_CENTER, 34.0, 12, Color("8deaff"))
		"interrogation":
			draw_circle(interior.position + Vector2(91.0, 76.0), 34.0, Color("233b49"))
			draw_rect(Rect2(interior.position + Vector2(36.0, 31.0), Vector2(110.0, 4.0)), Color("f4fbff", 0.75), true)
			draw_circle(interior.position + Vector2(62.0, 76.0), 10.0, Color("88a8b5"))
			draw_circle(interior.position + Vector2(120.0, 76.0), 10.0, Color("88a8b5"))
		"transfer":
			draw_rect(Rect2(interior.position + Vector2(18.0, 34.0), Vector2(146.0, 70.0)), Color("132c39"), true)
			for gate: int in range(8):
				var gate_x: float = interior.position.x + 27.0 + float(gate) * 18.0
				draw_line(Vector2(gate_x, interior.position.y + 36.0), Vector2(gate_x, interior.position.y + 102.0), Color("6bb6ca"), 2.0)
		_:
			pass
	if not repaired:
		draw_line(interior.position + Vector2(14.0, 12.0), interior.position + Vector2(64.0, 58.0), Color("ff688c", 0.65), 3.0)
		draw_line(interior.position + Vector2(64.0, 58.0), interior.position + Vector2(47.0, 95.0), Color("ff688c", 0.65), 2.0)
		draw_line(interior.position + Vector2(140.0, 17.0), interior.position + Vector2(112.0, 63.0), Color("ffb16f", 0.55), 2.0)
		draw_rect(interior, Color("35111c", 0.18 + sin(pulse * 2.0) * 0.03), true)

func _draw_console(position: Vector2, width: float) -> void:
	draw_rect(Rect2(position, Vector2(width, 42.0)), Color("173c51"), true)
	draw_rect(Rect2(position + Vector2(5.0, 5.0), Vector2(width - 10.0, 22.0)), Color("0d788e", 0.68), true)
	draw_line(position + Vector2(7.0, 34.0), position + Vector2(width - 7.0, 34.0), Color("9df5ff"), 2.0)

func _draw_side_panel() -> void:
	draw_style_box(_panel_style(Color("071523", 0.97), Color("4fb8d8", 0.52), 2, 14), SIDE_RECT)
	draw_string(ThemeDB.fallback_font, Vector2(914.0, 128.0), "DISTRESS BOARD", HORIZONTAL_ALIGNMENT_LEFT, 190.0, 13, Color("8deaff"))
	_draw_calls()
	draw_line(Vector2(912.0, 324.0), Vector2(1240.0, 324.0), Color("6ddfff", 0.24), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(914.0, 347.0), "OFFICER ROSTER // SELECT UP TO 3", HORIZONTAL_ALIGNMENT_LEFT, 290.0, 11, Color("8deaff"))
	_draw_officers()

func _draw_calls() -> void:
	call_rects.clear()
	if PrecinctState.patrol_calls.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(916.0, 172.0), "No active calls. Scanners are sweeping the district...", HORIZONTAL_ALIGNMENT_LEFT, 320.0, 11, Color("7397aa"))
		var next_seconds: int = PrecinctState.seconds_left(PrecinctState.next_call_at)
		draw_string(ThemeDB.fallback_font, Vector2(916.0, 194.0), "NEXT SCAN WINDOW // %ds" % next_seconds, HORIZONTAL_ALIGNMENT_LEFT, 300.0, 10, Color("5fb8cb"))
		return
	for index: int in range(PrecinctState.patrol_calls.size()):
		var call: Dictionary = PrecinctState.patrol_calls[index]
		var call_id: String = String(call.get("id", ""))
		var rect: Rect2 = Rect2(914.0, 145.0 + float(index) * 57.0, 326.0, 50.0)
		call_rects[call_id] = rect
		var selected: bool = call_id == selected_call_id
		var difficulty: int = int(call.get("difficulty", 1))
		var border: Color = Color("eafcff") if selected else _difficulty_color(difficulty)
		draw_style_box(_panel_style(Color("10273a"), border, 2 if selected else 1, 8), rect)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 17.0), String(call.get("title", "CALL")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 225.0, 10, Color("ecfbff"))
		var detail: String = "%s // D%d // %d CR" % [String(call.get("sector", "Sector")), difficulty, int(call.get("reward", 0))]
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 36.0), detail, HORIZONTAL_ALIGNMENT_LEFT, 260.0, 9, Color("91bdca"))
		var remaining: int = PrecinctState.seconds_left(int(call.get("expires_at", 0)))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(270.0, 29.0), "%02ds" % remaining, HORIZONTAL_ALIGNMENT_CENTER, 46.0, 12, Color("ffb27c"))

func _draw_officers() -> void:
	officer_rects.clear()
	for index: int in range(PrecinctState.officers.size()):
		var officer: Dictionary = PrecinctState.officers[index]
		var officer_id: String = String(officer.get("id", ""))
		var rect: Rect2 = Rect2(914.0, 360.0 + float(index) * 56.0, 326.0, 49.0)
		officer_rects[officer_id] = rect
		var selected: bool = selected_officer_ids.has(officer_id)
		var available: bool = PrecinctState.officer_available(officer)
		var border: Color = Color("b9fff1") if selected else (Color("4eaac2") if available else Color("6f5361"))
		draw_style_box(_panel_style(Color("0d2232"), border, 2 if selected else 1, 8), rect)
		_draw_officer_portrait(rect.position + Vector2(25.0, 24.0), String(officer.get("class", "Guard")), available)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(50.0, 18.0), String(officer.get("name", "Officer")), HORIZONTAL_ALIGNMENT_LEFT, 125.0, 11, Color("edfbff"))
		var stats: String = "%s  PWR %d  HP %d/%d" % [String(officer.get("class", "")), int(officer.get("power", 0)), int(officer.get("hp", 0)), int(officer.get("max_hp", 0))]
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(50.0, 36.0), stats, HORIZONTAL_ALIGNMENT_LEFT, 210.0, 9, Color("87b4c4"))
		var duty: String = _officer_status(officer)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(254.0, 29.0), duty, HORIZONTAL_ALIGNMENT_CENTER, 62.0, 9, Color("72f0c1") if available else Color("ff9db4"))

func _draw_officer_portrait(center: Vector2, officer_class: String, available: bool) -> void:
	var body_color: Color = Color("64d6e8")
	if officer_class == "Biker":
		body_color = Color("d889ff")
	elif officer_class == "Marksman":
		body_color = Color("ffd17e")
	if not available:
		body_color = body_color.darkened(0.55)
	draw_circle(center, 17.0, Color("06111b"))
	draw_circle(center, 14.0, body_color)
	draw_circle(center + Vector2(-5.0, -2.0), 2.4, Color("06111b"))
	draw_circle(center + Vector2(5.0, -2.0), 2.4, Color("06111b"))
	draw_arc(center, 18.0, PI, TAU, 18, Color("aaf7ff", 0.72), 2.0)

func _draw_action_deck() -> void:
	draw_style_box(_panel_style(Color("071523", 0.98), Color("4fb8d8", 0.44), 1, 12), BOTTOM_RECT)
	var labels: Dictionary = {
		"dispatch": "DISPATCH",
		"repair": "REPAIR ROOM",
		"research": "RESEARCH",
		"process": "PROCESS",
		"save": "SAVE",
		"load": "LOAD",
		"reset": "RESET SLICE",
		"rts": "RTS FRONT"
	}
	for action_value: Variant in action_rects.keys():
		var action: String = String(action_value)
		var rect: Rect2 = action_rects[action] as Rect2
		var active: bool = (action == "dispatch" and not selected_call_id.is_empty() and not selected_officer_ids.is_empty()) or (action == "repair" and not selected_room_id.is_empty())
		var fill: Color = Color("1e5366") if active else Color("112b3d")
		var border: Color = Color("b9f9ff") if active else Color("3e7f96")
		draw_style_box(_panel_style(fill, border, 1, 8), rect)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(5.0, 27.0), String(labels.get(action, action.to_upper())), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10.0, 11, Color("e9fbff"))

func _draw_footer_status() -> void:
	var selected_room: Dictionary = PrecinctState.get_room(selected_room_id)
	var room_text: String = String(selected_room.get("name", "No room"))
	var team_text: String = "%d OFFICER(S)" % selected_officer_ids.size()
	var call_text: String = "NO CALL"
	if not selected_call_id.is_empty():
		call_text = selected_call_id.to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(38.0, 711.0), "SELECTED: %s // %s // %s" % [room_text.to_upper(), call_text, team_text], HORIZONTAL_ALIGNMENT_LEFT, 520.0, 9, Color("7eb3c3"))
	draw_string(ThemeDB.fallback_font, Vector2(520.0, 711.0), status_message, HORIZONTAL_ALIGNMENT_LEFT, 720.0, 9, Color("c5eff7"))

func _officer_status(officer: Dictionary) -> String:
	var injured_left: int = PrecinctState.seconds_left(int(officer.get("injured_until", 0)))
	if injured_left > 0:
		return "MED %ds" % injured_left
	var busy_left: int = PrecinctState.seconds_left(int(officer.get("busy_until", 0)))
	if busy_left > 0:
		return "BUSY %ds" % busy_left
	return "READY"

func _difficulty_color(difficulty: int) -> Color:
	if difficulty >= 3:
		return Color("ff6488")
	if difficulty == 2:
		return Color("ffc36e")
	return Color("6ce9c1")

func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func _on_state_changed() -> void:
	queue_redraw()
