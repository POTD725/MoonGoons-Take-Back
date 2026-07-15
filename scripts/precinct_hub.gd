extends Node2D
## MoonGoons precinct hub with layered, clickable views inspired by the
## screen hierarchy of mobile city-building strategy games.
## All names, code, visuals, balance, and writing are original MoonGoons work.

const VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)
const CONTENT_RECT: Rect2 = Rect2(18.0, 84.0, 1244.0, 558.0)
const NAV_RECT: Rect2 = Rect2(0.0, 650.0, 1280.0, 70.0)
const VIEWS: Array[String] = ["city", "buildings", "officers", "patrol", "custody", "tasks"]
const VIEW_LABELS: Dictionary = {
	"city": "PRECINCT",
	"buildings": "BUILDINGS",
	"officers": "OFFICERS",
	"patrol": "PATROL",
	"custody": "CUSTODY",
	"tasks": "TASKS"
}
const ROOM_IDS: Array[String] = ["ops", "armory", "cells", "quarters", "medbay", "chief", "interrogation", "transfer"]
const ROOM_SKINS: Dictionary = {
	"ops": "command_nexus",
	"armory": "tactical_armory",
	"cells": "cargo_wall",
	"quarters": "cargo_crate",
	"medbay": "machine_shop",
	"chief": "command_nexus",
	"interrogation": "evidence_cache",
	"transfer": "wrecked_shuttle"
}

var current_view: String = "city"
var selected_room_id: String = "ops"
var selected_officer_id: String = "officer_1"
var selected_call_id: String = ""
var selected_team: Array[String] = []
var modal_mode: String = ""
var status_message: String = "Welcome to Lunar Precinct Command. Select a building or use the navigation deck."
var pulse: float = 0.0
var tick_accumulator: float = 0.0

var nav_rects: Dictionary = {}
var room_rects: Dictionary = {}
var officer_rects: Dictionary = {}
var call_rects: Dictionary = {}
var action_rects: Dictionary = {}
var task_rects: Dictionary = {}
var modal_rects: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	PrecinctState.tick()
	if not PrecinctState.state_changed.is_connected(_on_state_changed):
		PrecinctState.state_changed.connect(_on_state_changed)
	if not PrecinctMeta.meta_changed.is_connected(_on_state_changed):
		PrecinctMeta.meta_changed.connect(_on_state_changed)
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	tick_accumulator += delta
	if tick_accumulator >= 0.25:
		tick_accumulator = 0.0
		PrecinctState.tick()
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
	if pressed:
		_handle_press(position)

func _draw() -> void:
	nav_rects.clear()
	room_rects.clear()
	officer_rects.clear()
	call_rects.clear()
	action_rects.clear()
	task_rects.clear()
	modal_rects.clear()
	_draw_backdrop()
	_draw_header()
	match current_view:
		"city": _draw_city_view()
		"buildings": _draw_buildings_view()
		"officers": _draw_officers_view()
		"patrol": _draw_patrol_view()
		"custody": _draw_custody_view()
		"tasks": _draw_tasks_view()
		_: _draw_city_view()
	_draw_navigation()
	_draw_status_toast()
	if not modal_mode.is_empty():
		_draw_modal()
	if PrecinctMeta.tutorial_step < 6:
		_draw_tutorial()

func _handle_press(position: Vector2) -> void:
	if PrecinctMeta.tutorial_step < 6:
		if Rect2(884.0, 535.0, 150.0, 46.0).has_point(position):
			PrecinctMeta.advance_tutorial()
			return
		if Rect2(1046.0, 535.0, 150.0, 46.0).has_point(position):
			PrecinctMeta.dismiss_tutorial()
			return
	if not modal_mode.is_empty():
		for key_value: Variant in modal_rects.keys():
			var key: String = String(key_value)
			var rect: Rect2 = modal_rects[key] as Rect2
			if rect.has_point(position):
				_handle_modal_action(key)
				return
		return
	for view_value: Variant in nav_rects.keys():
		var view_id: String = String(view_value)
		var nav_rect: Rect2 = nav_rects[view_id] as Rect2
		if nav_rect.has_point(position):
			current_view = view_id
			status_message = "%s view opened." % String(VIEW_LABELS.get(view_id, view_id)).capitalize()
			queue_redraw()
			return
	for room_value: Variant in room_rects.keys():
		var room_id: String = String(room_value)
		var room_rect: Rect2 = room_rects[room_id] as Rect2
		if room_rect.has_point(position):
			selected_room_id = room_id
			current_view = "buildings"
			status_message = "%s opened." % String(PrecinctState.get_room(room_id).get("name", "Building"))
			queue_redraw()
			return
	for officer_value: Variant in officer_rects.keys():
		var officer_id: String = String(officer_value)
		var officer_rect: Rect2 = officer_rects[officer_id] as Rect2
		if officer_rect.has_point(position):
			if current_view == "patrol":
				_toggle_team_officer(officer_id)
			else:
				selected_officer_id = officer_id
				current_view = "officers"
				status_message = "%s personnel file opened." % String(PrecinctState.get_officer(officer_id).get("name", "Officer"))
			queue_redraw()
			return
	for call_value: Variant in call_rects.keys():
		var call_id: String = String(call_value)
		var call_rect: Rect2 = call_rects[call_id] as Rect2
		if call_rect.has_point(position):
			selected_call_id = call_id
			status_message = "Patrol target selected. Build a formation and dispatch."
			queue_redraw()
			return
	for task_value: Variant in task_rects.keys():
		var task_id: String = String(task_value)
		var task_rect: Rect2 = task_rects[task_id] as Rect2
		if task_rect.has_point(position):
			var result: Dictionary = PrecinctMeta.claim_task(task_id)
			status_message = String(result.get("message", "Task action failed."))
			queue_redraw()
			return
	for action_value: Variant in action_rects.keys():
		var action: String = String(action_value)
		var action_rect: Rect2 = action_rects[action] as Rect2
		if action_rect.has_point(position):
			_handle_action(action)
			return

func _handle_action(action: String) -> void:
	var result: Dictionary = {}
	match action:
		"repair_room":
			result = PrecinctState.repair_room(selected_room_id)
		"upgrade_room":
			result = PrecinctMeta.upgrade_room(selected_room_id)
		"assign_room":
			modal_mode = "assign_officer"
			queue_redraw()
			return
		"clear_assignment":
			result = PrecinctMeta.unassign_room(selected_room_id)
		"train_officer":
			result = PrecinctMeta.train_officer(selected_officer_id)
		"heal_officer":
			result = PrecinctMeta.heal_officer(selected_officer_id)
		"assign_officer":
			modal_mode = "assign_room"
			queue_redraw()
			return
		"dispatch":
			result = PrecinctState.begin_patrol(selected_call_id, selected_team)
			if bool(result.get("ok", false)):
				status_message = String(result.get("message", "Patrol dispatched."))
				get_tree().change_scene_to_file("res://scenes/PrecinctBattle.tscn")
				return
		"process":
			result = PrecinctMeta.custody_action("process")
		"interrogate":
			result = PrecinctMeta.custody_action("interrogate")
		"transfer":
			result = PrecinctMeta.custody_action("transfer")
		"research":
			result = PrecinctState.begin_research()
		"save":
			result = PrecinctState.save_game()
			PrecinctMeta.save_meta()
		"load":
			result = PrecinctState.load_game()
			PrecinctMeta.load_meta()
		"reset":
			PrecinctState.reset_state()
			PrecinctMeta.reset_meta()
			selected_room_id = "ops"
			selected_officer_id = "officer_1"
			selected_call_id = ""
			selected_team.clear()
			result = {"ok": true, "message": "MoonGoons precinct campaign reset."}
		"rts":
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
			return
		_:
			return
	status_message = String(result.get("message", "Action completed."))
	queue_redraw()

func _handle_modal_action(key: String) -> void:
	if key == "close":
		modal_mode = ""
		queue_redraw()
		return
	var result: Dictionary = {}
	if modal_mode == "assign_officer" and key.begins_with("officer:"):
		result = PrecinctMeta.assign_officer(key.trim_prefix("officer:"), selected_room_id)
	elif modal_mode == "assign_room" and key.begins_with("room:"):
		result = PrecinctMeta.assign_officer(selected_officer_id, key.trim_prefix("room:"))
	status_message = String(result.get("message", "Assignment failed."))
	if bool(result.get("ok", false)):
		modal_mode = ""
	queue_redraw()

func _toggle_team_officer(officer_id: String) -> void:
	var officer: Dictionary = PrecinctState.get_officer(officer_id)
	if officer.is_empty() or not PrecinctState.officer_available(officer):
		status_message = "That officer is unavailable."
		return
	if selected_team.has(officer_id):
		selected_team.erase(officer_id)
		status_message = "%s removed from formation." % String(officer.get("name", "Officer"))
	elif selected_team.size() >= 3:
		status_message = "Patrol formations are limited to three officers."
	else:
		selected_team.append(officer_id)
		status_message = "%s added to formation." % String(officer.get("name", "Officer"))
	queue_redraw()

func _draw_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("020711"))
	for index: int in range(95):
		var x: float = fmod(float(index * 89 + 31), VIEWPORT_SIZE.x)
		var y: float = fmod(float(index * 47 + 17), VIEWPORT_SIZE.y)
		draw_circle(Vector2(x, y), 1.0 + float(index % 3) * 0.35, Color("b7e7ff", 0.18))
	draw_circle(Vector2(1088.0, 128.0), 118.0, Color("5bd8ff", 0.035))
	draw_circle(Vector2(1088.0, 128.0), 72.0, Color("5bd8ff", 0.025))

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 76.0), Color("07192c"), true)
	draw_line(Vector2(0.0, 76.0), Vector2(1280.0, 76.0), Color("63dfff", 0.42), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(22.0, 29.0), "MOONGOONS", HORIZONTAL_ALIGNMENT_LEFT, 230.0, 21, Color("eefcff"))
	draw_string(ThemeDB.fallback_font, Vector2(22.0, 54.0), "LUNAR PRECINCT COMMAND // CHAPTER %d" % PrecinctMeta.chapter, HORIZONTAL_ALIGNMENT_LEFT, 420.0, 11, Color("72dfff"))
	_draw_resource_chip(Vector2(482.0, 15.0), "CREDITS", "%d" % PrecinctState.credits, Color("ffd37b"))
	_draw_resource_chip(Vector2(652.0, 15.0), "INTEL", "%d" % PrecinctState.intel, Color("79eaff"))
	_draw_resource_chip(Vector2(822.0, 15.0), "EVIDENCE", "%d" % PrecinctState.evidence, Color("d6a6ff"))
	_draw_resource_chip(Vector2(992.0, 15.0), "REP", "%d" % PrecinctMeta.reputation, Color("7ff0bd"))
	var settings_rect: Rect2 = Rect2(1178.0, 15.0, 78.0, 45.0)
	action_rects["save"] = Rect2(1178.0, 15.0, 36.0, 45.0)
	action_rects["load"] = Rect2(1220.0, 15.0, 36.0, 45.0)
	draw_style_box(_panel_style(Color("0e2b40"), Color("4c9eb8"), 1, 10), settings_rect)
	draw_string(ThemeDB.fallback_font, Vector2(1182.0, 42.0), "S", HORIZONTAL_ALIGNMENT_CENTER, 28.0, 15, Color("eafcff"))
	draw_string(ThemeDB.fallback_font, Vector2(1224.0, 42.0), "L", HORIZONTAL_ALIGNMENT_CENTER, 28.0, 15, Color("eafcff"))

func _draw_city_view() -> void:
	draw_style_box(_panel_style(Color("071522", 0.96), Color("4fb8d8", 0.44), 2, 16), CONTENT_RECT)
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 109.0), "PRECINCT CITY", HORIZONTAL_ALIGNMENT_LEFT, 300.0, 17, Color("eafcff"))
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 130.0), "Select any division to open its building window", HORIZONTAL_ALIGNMENT_LEFT, 420.0, 10, Color("7fb8c9"))
	var map_rect: Rect2 = Rect2(30.0, 144.0, 920.0, 480.0)
	draw_rect(map_rect, Color("0a1e2e"), true)
	for road: int in range(4):
		var y: float = 200.0 + float(road) * 104.0
		draw_line(Vector2(42.0, y), Vector2(934.0, y + 30.0), Color("7693a3", 0.14), 22.0)
		draw_line(Vector2(42.0, y), Vector2(934.0, y + 30.0), Color("70e3ff", 0.08), 2.0)
	for index: int in range(ROOM_IDS.size()):
		var room_id: String = ROOM_IDS[index]
		var room: Dictionary = PrecinctState.get_room(room_id)
		var column: int = index % 4
		var row: int = index / 4
		var rect: Rect2 = Rect2(58.0 + float(column) * 218.0, 166.0 + float(row) * 222.0, 188.0, 184.0)
		room_rects[room_id] = rect
		var repaired: bool = bool(room.get("repaired", false))
		var selected: bool = room_id == selected_room_id
		var border: Color = Color("dffcff") if selected else (Color("5de0c0") if repaired else Color("d36582"))
		draw_style_box(_panel_style(Color("10283a"), border, 2 if selected else 1, 14), rect)
		_draw_skin(String(ROOM_SKINS.get(room_id, "command_nexus")), Rect2(rect.position + Vector2(8.0, 8.0), Vector2(172.0, 118.0)), _room_tint(room_id, repaired))
		draw_rect(Rect2(rect.position + Vector2(0.0, 126.0), Vector2(rect.size.x, 58.0)), Color("06121d", 0.93), true)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 146.0), String(room.get("name", "DIVISION")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 172.0, 10, Color("f1fdff"))
		var state_text: String = "OPERATIONAL"
		if int(room.get("repair_end", 0)) > 0:
			state_text = "REPAIR %ds" % PrecinctState.seconds_left(int(room.get("repair_end", 0)))
		elif not repaired:
			state_text = "DAMAGED"
		var assignment: String = PrecinctMeta.assigned_officer_id(room_id)
		if not assignment.is_empty():
			state_text += " // STAFFED"
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 167.0), "L%d // %s" % [int(room.get("level", 1)), state_text], HORIZONTAL_ALIGNMENT_LEFT, 172.0, 9, Color("72d6e7") if repaired else Color("ff9cb1"))
	_draw_city_sidebar()

func _draw_city_sidebar() -> void:
	var side: Rect2 = Rect2(970.0, 96.0, 276.0, 528.0)
	draw_style_box(_panel_style(Color("0a1c2b"), Color("397f96"), 1, 14), side)
	draw_string(ThemeDB.fallback_font, Vector2(986.0, 122.0), "COMMAND QUEUE", HORIZONTAL_ALIGNMENT_LEFT, 230.0, 13, Color("8ceaff"))
	_draw_queue_card(Rect2(986.0, 140.0, 244.0, 84.0), "RESEARCH", _research_status(), "research")
	var call_text: String = "%d ACTIVE CALL(S)" % PrecinctState.patrol_calls.size()
	_draw_queue_card(Rect2(986.0, 236.0, 244.0, 84.0), "PATROL BOARD", call_text, "open_patrol")
	var prisoner_text: String = "%d IN CUSTODY" % PrecinctState.prisoners
	_draw_queue_card(Rect2(986.0, 332.0, 244.0, 84.0), "DETENTION", prisoner_text, "open_custody")
	var ready_tasks: int = _ready_task_count()
	_draw_queue_card(Rect2(986.0, 428.0, 244.0, 84.0), "OBJECTIVES", "%d REWARD(S) READY" % ready_tasks, "open_tasks")
	action_rects["rts"] = Rect2(986.0, 530.0, 244.0, 58.0)
	draw_style_box(_panel_style(Color("1b3550"), Color("7fc9e4"), 1, 10), action_rects["rts"] as Rect2)
	draw_string(ThemeDB.fallback_font, Vector2(994.0, 565.0), "OPEN RTS FRONT", HORIZONTAL_ALIGNMENT_CENTER, 228.0, 12, Color("eafcff"))

func _draw_queue_card(rect: Rect2, title: String, detail: String, action: String) -> void:
	action_rects[action] = rect
	draw_style_box(_panel_style(Color("10283a"), Color("3d8ca5"), 1, 10), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 24.0), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20.0, 11, Color("eefcff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 51.0), detail, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20.0, 10, Color("82bbcb"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(200.0, 57.0), ">", HORIZONTAL_ALIGNMENT_CENTER, 28.0, 18, Color("7eeaff"))

func _draw_buildings_view() -> void:
	draw_style_box(_panel_style(Color("071522", 0.96), Color("4fb8d8", 0.44), 2, 16), CONTENT_RECT)
	var room: Dictionary = PrecinctState.get_room(selected_room_id)
	var repaired: bool = bool(room.get("repaired", false))
	var left: Rect2 = Rect2(34.0, 102.0, 720.0, 500.0)
	var right: Rect2 = Rect2(774.0, 102.0, 466.0, 500.0)
	draw_style_box(_panel_style(Color("0b2030"), Color("3d8ca5"), 1, 14), left)
	draw_style_box(_panel_style(Color("0b2030"), Color("3d8ca5"), 1, 14), right)
	_draw_skin(String(ROOM_SKINS.get(selected_room_id, "command_nexus")), Rect2(52.0, 122.0, 684.0, 316.0), _room_tint(selected_room_id, repaired))
	draw_rect(Rect2(52.0, 122.0, 684.0, 316.0), Color(0.02, 0.07, 0.11, 0.12 if repaired else 0.44), true)
	draw_string(ThemeDB.fallback_font, Vector2(54.0, 468.0), String(room.get("name", "BUILDING")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 500.0, 22, Color("effdff"))
	draw_string(ThemeDB.fallback_font, Vector2(54.0, 495.0), "%s DIVISION // LEVEL %d" % [String(room.get("function", "")), int(room.get("level", 1))], HORIZONTAL_ALIGNMENT_LEFT, 500.0, 12, Color("82dff0"))
	var assigned_id: String = PrecinctMeta.assigned_officer_id(selected_room_id)
	var assignment_text: String = "UNSTAFFED"
	if not assigned_id.is_empty():
		assignment_text = String(PrecinctState.get_officer(assigned_id).get("name", "Assigned Officer")).to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(54.0, 523.0), "ASSIGNMENT // %s" % assignment_text, HORIZONTAL_ALIGNMENT_LEFT, 500.0, 11, Color("a9c8d3"))
	_draw_building_actions(room, repaired)
	draw_string(ThemeDB.fallback_font, Vector2(792.0, 130.0), "PRECINCT DIVISIONS", HORIZONTAL_ALIGNMENT_LEFT, 300.0, 13, Color("8ceaff"))
	for index: int in range(ROOM_IDS.size()):
		var room_id: String = ROOM_IDS[index]
		var list_room: Dictionary = PrecinctState.get_room(room_id)
		var rect: Rect2 = Rect2(792.0, 146.0 + float(index) * 54.0, 430.0, 46.0)
		room_rects[room_id] = rect
		var selected: bool = room_id == selected_room_id
		draw_style_box(_panel_style(Color("173246") if selected else Color("102535"), Color("b7f8ff") if selected else Color("356f84"), 2 if selected else 1, 8), rect)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 19.0), String(list_room.get("name", "Room")), HORIZONTAL_ALIGNMENT_LEFT, 260.0, 10, Color("edfaff"))
		var status: String = "L%d" % int(list_room.get("level", 1))
		status += " // ONLINE" if bool(list_room.get("repaired", false)) else " // DAMAGED"
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(276.0, 19.0), status, HORIZONTAL_ALIGNMENT_RIGHT, 140.0, 9, Color("71d9bb") if bool(list_room.get("repaired", false)) else Color("ff8da8"))

func _draw_building_actions(room: Dictionary, repaired: bool) -> void:
	var y: float = 548.0
	if not repaired:
		_draw_action_button("repair_room", Rect2(54.0, y, 190.0, 42.0), "REPAIR %d CR" % int(room.get("repair_cost", 0)), true)
	else:
		var level: int = int(room.get("level", 1))
		_draw_action_button("upgrade_room", Rect2(54.0, y, 190.0, 42.0), "UPGRADE %d CR" % (90 + level * 55), true)
	_draw_action_button("assign_room", Rect2(258.0, y, 190.0, 42.0), "ASSIGN OFFICER", repaired)
	_draw_action_button("clear_assignment", Rect2(462.0, y, 190.0, 42.0), "CLEAR STAFF", not PrecinctMeta.assigned_officer_id(selected_room_id).is_empty())

func _draw_officers_view() -> void:
	draw_style_box(_panel_style(Color("071522", 0.96), Color("4fb8d8", 0.44), 2, 16), CONTENT_RECT)
	var roster_rect: Rect2 = Rect2(32.0, 102.0, 358.0, 510.0)
	var detail_rect: Rect2 = Rect2(408.0, 102.0, 832.0, 510.0)
	draw_style_box(_panel_style(Color("0b2030"), Color("3d8ca5"), 1, 14), roster_rect)
	draw_style_box(_panel_style(Color("0b2030"), Color("3d8ca5"), 1, 14), detail_rect)
	draw_string(ThemeDB.fallback_font, Vector2(50.0, 130.0), "OFFICER ROSTER", HORIZONTAL_ALIGNMENT_LEFT, 280.0, 14, Color("8ceaff"))
	for index: int in range(PrecinctState.officers.size()):
		var officer: Dictionary = PrecinctState.officers[index]
		var officer_id: String = String(officer.get("id", ""))
		var rect: Rect2 = Rect2(48.0, 148.0 + float(index) * 104.0, 326.0, 88.0)
		officer_rects[officer_id] = rect
		var selected: bool = officer_id == selected_officer_id
		draw_style_box(_panel_style(Color("173246") if selected else Color("102535"), Color("c9fbff") if selected else Color("356f84"), 2 if selected else 1, 10), rect)
		_draw_officer_skin(officer, Rect2(rect.position + Vector2(7.0, 7.0), Vector2(72.0, 72.0)))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(90.0, 25.0), String(officer.get("name", "Officer")), HORIZONTAL_ALIGNMENT_LEFT, 170.0, 12, Color("eefcff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(90.0, 46.0), "%s // LEVEL %d" % [String(officer.get("class", "")), int(officer.get("level", 1))], HORIZONTAL_ALIGNMENT_LEFT, 190.0, 9, Color("86c5d6"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(90.0, 68.0), _officer_status(officer), HORIZONTAL_ALIGNMENT_LEFT, 190.0, 9, Color("72efbd") if PrecinctState.officer_available(officer) else Color("ff93ad"))
	_draw_officer_detail()

func _draw_officer_detail() -> void:
	var officer: Dictionary = PrecinctState.get_officer(selected_officer_id)
	if officer.is_empty():
		return
	_draw_officer_skin(officer, Rect2(442.0, 132.0, 310.0, 310.0))
	draw_string(ThemeDB.fallback_font, Vector2(782.0, 154.0), String(officer.get("name", "OFFICER")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 420.0, 23, Color("effdff"))
	draw_string(ThemeDB.fallback_font, Vector2(782.0, 181.0), "%s // %s // LEVEL %d" % [String(officer.get("rarity", "Common")).to_upper(), String(officer.get("class", "Guard")).to_upper(), int(officer.get("level", 1))], HORIZONTAL_ALIGNMENT_LEFT, 420.0, 11, Color("83e6f7"))
	_draw_stat_bar(Vector2(782.0, 222.0), "HEALTH", int(officer.get("hp", 0)), int(officer.get("max_hp", 100)), Color("62e1b7"))
	_draw_stat_bar(Vector2(782.0, 272.0), "POWER", int(officer.get("power", 0)), 180, Color("ffd17a"))
	_draw_stat_bar(Vector2(782.0, 322.0), "DEFENSE", int(officer.get("defense", 0)), 80, Color("83c8ff"))
	_draw_stat_bar(Vector2(782.0, 372.0), "EXPERIENCE", int(officer.get("xp", 0)), 100, Color("d394ff"))
	var assigned_room: String = PrecinctMeta.assigned_room_id(selected_officer_id)
	var assignment_text: String = "UNASSIGNED"
	if not assigned_room.is_empty():
		assignment_text = String(PrecinctState.get_room(assigned_room).get("name", "Room")).to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(782.0, 426.0), "CURRENT POST // %s" % assignment_text, HORIZONTAL_ALIGNMENT_LEFT, 420.0, 11, Color("a9c8d3"))
	_draw_action_button("train_officer", Rect2(448.0, 526.0, 220.0, 50.0), "TRAIN OFFICER", PrecinctState.officer_available(officer))
	_draw_action_button("heal_officer", Rect2(684.0, 526.0, 220.0, 50.0), "MEDBAY TREATMENT", true)
	_draw_action_button("assign_officer", Rect2(920.0, 526.0, 286.0, 50.0), "ASSIGN TO DIVISION", true)

func _draw_patrol_view() -> void:
	draw_style_box(_panel_style(Color("071522", 0.96), Color("4fb8d8", 0.44), 2, 16), CONTENT_RECT)
	var calls_panel: Rect2 = Rect2(30.0, 102.0, 370.0, 510.0)
	var mission_panel: Rect2 = Rect2(418.0, 102.0, 430.0, 510.0)
	var team_panel: Rect2 = Rect2(866.0, 102.0, 374.0, 510.0)
	draw_style_box(_panel_style(Color("0b2030"), Color("3d8ca5"), 1, 14), calls_panel)
	draw_style_box(_panel_style(Color("0b2030"), Color("3d8ca5"), 1, 14), mission_panel)
	draw_style_box(_panel_style(Color("0b2030"), Color("3d8ca5"), 1, 14), team_panel)
	draw_string(ThemeDB.fallback_font, Vector2(48.0, 130.0), "DISTRESS CALLS", HORIZONTAL_ALIGNMENT_LEFT, 280.0, 14, Color("8ceaff"))
	if PrecinctState.patrol_calls.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(48.0, 170.0), "Scanners are sweeping the district.", HORIZONTAL_ALIGNMENT_LEFT, 320.0, 10, Color("86aebb"))
		draw_string(ThemeDB.fallback_font, Vector2(48.0, 194.0), "Next signal window: %ds" % PrecinctState.seconds_left(PrecinctState.next_call_at), HORIZONTAL_ALIGNMENT_LEFT, 320.0, 10, Color("69d7ea"))
	for index: int in range(PrecinctState.patrol_calls.size()):
		var call: Dictionary = PrecinctState.patrol_calls[index]
		var call_id: String = String(call.get("id", ""))
		var rect: Rect2 = Rect2(46.0, 148.0 + float(index) * 104.0, 338.0, 88.0)
		call_rects[call_id] = rect
		var selected: bool = call_id == selected_call_id
		draw_style_box(_panel_style(Color("173246") if selected else Color("102535"), Color("f1fdff") if selected else _difficulty_color(int(call.get("difficulty", 1))), 2 if selected else 1, 10), rect)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 24.0), String(call.get("title", "CALL")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 260.0, 11, Color("effdff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 48.0), String(call.get("sector", "Sector")), HORIZONTAL_ALIGNMENT_LEFT, 230.0, 9, Color("88bdcb"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 70.0), "D%d // %d CR // %ds" % [int(call.get("difficulty", 1)), int(call.get("reward", 0)), PrecinctState.seconds_left(int(call.get("expires_at", 0)))], HORIZONTAL_ALIGNMENT_LEFT, 290.0, 9, Color("ffc27e"))
	_draw_selected_call_details()
	_draw_formation_panel()

func _draw_selected_call_details() -> void:
	var call: Dictionary = _selected_call()
	if call.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(440.0, 138.0), "SELECT A DISTRESS CALL", HORIZONTAL_ALIGNMENT_LEFT, 370.0, 15, Color("8ceaff"))
		_draw_skin("evidence_cache", Rect2(486.0, 212.0, 292.0, 292.0), Color(0.65, 0.84, 1.0, 0.36))
		return
	draw_string(ThemeDB.fallback_font, Vector2(440.0, 138.0), String(call.get("title", "PATROL")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 390.0, 16, Color("effdff"))
	draw_string(ThemeDB.fallback_font, Vector2(440.0, 165.0), String(call.get("sector", "Sector")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 390.0, 11, Color("7fe0f0"))
	_draw_skin("wrecked_shuttle", Rect2(468.0, 188.0, 330.0, 240.0), Color(0.76, 0.88, 1.0, 0.70))
	var difficulty: int = int(call.get("difficulty", 1))
	draw_string(ThemeDB.fallback_font, Vector2(448.0, 460.0), "THREAT LEVEL", HORIZONTAL_ALIGNMENT_LEFT, 160.0, 10, Color("89bdca"))
	draw_string(ThemeDB.fallback_font, Vector2(628.0, 460.0), "D%d" % difficulty, HORIZONTAL_ALIGNMENT_RIGHT, 160.0, 13, _difficulty_color(difficulty))
	draw_string(ThemeDB.fallback_font, Vector2(448.0, 492.0), "REWARD", HORIZONTAL_ALIGNMENT_LEFT, 160.0, 10, Color("89bdca"))
	draw_string(ThemeDB.fallback_font, Vector2(628.0, 492.0), "%d CREDITS" % int(call.get("reward", 0)), HORIZONTAL_ALIGNMENT_RIGHT, 160.0, 12, Color("ffd17a"))
	draw_string(ThemeDB.fallback_font, Vector2(448.0, 524.0), "ARREST OPPORTUNITY", HORIZONTAL_ALIGNMENT_LEFT, 200.0, 10, Color("89bdca"))
	draw_string(ThemeDB.fallback_font, Vector2(658.0, 524.0), "YES" if bool(call.get("arrestable", true)) else "NO", HORIZONTAL_ALIGNMENT_RIGHT, 130.0, 12, Color("72efbd"))
	_draw_action_button("dispatch", Rect2(448.0, 548.0, 370.0, 44.0), "DISPATCH FORMATION", not selected_team.is_empty())

func _draw_formation_panel() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(884.0, 130.0), "PATROL FORMATION %d/3" % selected_team.size(), HORIZONTAL_ALIGNMENT_LEFT, 320.0, 14, Color("8ceaff"))
	for index: int in range(PrecinctState.officers.size()):
		var officer: Dictionary = PrecinctState.officers[index]
		var officer_id: String = String(officer.get("id", ""))
		var rect: Rect2 = Rect2(884.0, 148.0 + float(index) * 104.0, 338.0, 88.0)
		officer_rects[officer_id] = rect
		var selected: bool = selected_team.has(officer_id)
		var available: bool = PrecinctState.officer_available(officer)
		draw_style_box(_panel_style(Color("173246") if selected else Color("102535"), Color("a9fff0") if selected else (Color("386f83") if available else Color("6d4250")), 2 if selected else 1, 10), rect)
		_draw_officer_skin(officer, Rect2(rect.position + Vector2(7.0, 7.0), Vector2(72.0, 72.0)))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(90.0, 26.0), String(officer.get("name", "Officer")), HORIZONTAL_ALIGNMENT_LEFT, 190.0, 11, Color("effdff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(90.0, 49.0), "%s // PWR %d" % [String(officer.get("class", "")), int(officer.get("power", 0))], HORIZONTAL_ALIGNMENT_LEFT, 190.0, 9, Color("86bdca"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(90.0, 70.0), "SELECTED" if selected else _officer_status(officer), HORIZONTAL_ALIGNMENT_LEFT, 190.0, 9, Color("72efbd") if available else Color("ff93ad"))

func _draw_custody_view() -> void:
	draw_style_box(_panel_style(Color("071522", 0.96), Color("4fb8d8", 0.44), 2, 16), CONTENT_RECT)
	var visual: Rect2 = Rect2(32.0, 102.0, 620.0, 510.0)
	var actions: Rect2 = Rect2(672.0, 102.0, 568.0, 510.0)
	draw_style_box(_panel_style(Color("0b2030"), Color("3d8ca5"), 1, 14), visual)
	draw_style_box(_panel_style(Color("0b2030"), Color("3d8ca5"), 1, 14), actions)
	_draw_skin("cargo_wall", Rect2(54.0, 124.0, 576.0, 342.0), Color(0.82, 0.91, 1.0, 0.82))
	_draw_skin("evidence_cache", Rect2(430.0, 318.0, 160.0, 160.0), Color(1.0, 0.78, 0.44, 0.78))
	draw_string(ThemeDB.fallback_font, Vector2(54.0, 500.0), "HOLDING CELLS", HORIZONTAL_ALIGNMENT_LEFT, 400.0, 22, Color("effdff"))
	draw_string(ThemeDB.fallback_font, Vector2(54.0, 531.0), "%d PRISONER(S) AWAITING ACTION" % PrecinctState.prisoners, HORIZONTAL_ALIGNMENT_LEFT, 500.0, 12, Color("ffc77e"))
	draw_string(ThemeDB.fallback_font, Vector2(694.0, 132.0), "CUSTODY ACTIONS", HORIZONTAL_ALIGNMENT_LEFT, 300.0, 14, Color("8ceaff"))
	_draw_custody_card(Rect2(694.0, 156.0, 524.0, 112.0), "PROCESS CASE", "Standard booking and evidence review.", "+70 credits // +4 intel", "process", PrecinctState.is_room_repaired("cells"))
	_draw_custody_card(Rect2(694.0, 282.0, 524.0, 112.0), "INTERROGATE", "Question the suspect about Syndicate activity.", "+10 intel // +1 evidence", "interrogate", PrecinctState.is_room_repaired("interrogation"))
	_draw_custody_card(Rect2(694.0, 408.0, 524.0, 112.0), "SECURE TRANSFER", "Move the prisoner to an orbital detention site.", "+125 credits", "transfer", PrecinctState.is_room_repaired("transfer"))
	draw_string(ThemeDB.fallback_font, Vector2(694.0, 566.0), "Interrogated: %d   Transferred: %d" % [PrecinctMeta.prisoners_interrogated, PrecinctMeta.prisoners_transferred], HORIZONTAL_ALIGNMENT_LEFT, 500.0, 10, Color("8eb8c6"))

func _draw_custody_card(rect: Rect2, title: String, description: String, reward: String, action: String, unlocked: bool) -> void:
	action_rects[action] = rect
	draw_style_box(_panel_style(Color("143044") if unlocked else Color("241c29"), Color("4a9ab4") if unlocked else Color("795264"), 1, 12), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 28.0), title, HORIZONTAL_ALIGNMENT_LEFT, 250.0, 13, Color("effdff") if unlocked else Color("9d8c94"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 55.0), description, HORIZONTAL_ALIGNMENT_LEFT, 470.0, 10, Color("98c2cf") if unlocked else Color("7b6870"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 84.0), reward if unlocked else "DIVISION LOCKED", HORIZONTAL_ALIGNMENT_LEFT, 460.0, 10, Color("ffd17a") if unlocked else Color("ff8da8"))

func _draw_tasks_view() -> void:
	draw_style_box(_panel_style(Color("071522", 0.96), Color("4fb8d8", 0.44), 2, 16), CONTENT_RECT)
	draw_string(ThemeDB.fallback_font, Vector2(36.0, 116.0), "CHAPTER & DAILY OBJECTIVES", HORIZONTAL_ALIGNMENT_LEFT, 500.0, 17, Color("effdff"))
	draw_string(ThemeDB.fallback_font, Vector2(36.0, 138.0), "Complete objectives to unlock resources and precinct reputation.", HORIZONTAL_ALIGNMENT_LEFT, 600.0, 10, Color("83b8c7"))
	var tasks: Array[Dictionary] = PrecinctMeta.task_catalog()
	for index: int in range(tasks.size()):
		var task: Dictionary = tasks[index]
		var column: int = index % 2
		var row: int = index / 2
		var rect: Rect2 = Rect2(38.0 + float(column) * 608.0, 158.0 + float(row) * 142.0, 588.0, 124.0)
		var task_id: String = String(task.get("id", ""))
		var progress: int = int(task.get("progress", 0))
		var target: int = int(task.get("target", 1))
		var complete: bool = progress >= target
		var claimed: bool = PrecinctMeta.task_claimed(task_id)
		draw_style_box(_panel_style(Color("123043") if complete else Color("0f2535"), Color("71e5bd") if complete else Color("3f7e94"), 2 if complete else 1, 12), rect)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 24.0), String(task.get("group", "TASK")), HORIZONTAL_ALIGNMENT_LEFT, 120.0, 9, Color("7ce8fb"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 49.0), String(task.get("title", "Objective")), HORIZONTAL_ALIGNMENT_LEFT, 340.0, 13, Color("effdff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 72.0), String(task.get("description", "")), HORIZONTAL_ALIGNMENT_LEFT, 400.0, 9, Color("8db9c7"))
		_draw_progress_bar(Rect2(rect.position + Vector2(16.0, 88.0), Vector2(360.0, 12.0)), progress, target, Color("6ce6bd"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(386.0, 34.0), "+%d CR" % int(task.get("reward_credits", 0)), HORIZONTAL_ALIGNMENT_CENTER, 176.0, 10, Color("ffd17a"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(386.0, 54.0), "+%d INTEL" % int(task.get("reward_intel", 0)), HORIZONTAL_ALIGNMENT_CENTER, 176.0, 9, Color("7eeaff"))
		var button: Rect2 = Rect2(rect.position + Vector2(404.0, 72.0), Vector2(142.0, 36.0))
		task_rects[task_id] = button
		draw_style_box(_panel_style(Color("1c5a4a") if complete and not claimed else Color("25313a"), Color("88f6d3") if complete and not claimed else Color("566570"), 1, 8), button)
		var label: String = "CLAIM" if complete and not claimed else ("CLAIMED" if claimed else "%d/%d" % [min(progress, target), target])
		draw_string(ThemeDB.fallback_font, button.position + Vector2(5.0, 23.0), label, HORIZONTAL_ALIGNMENT_CENTER, button.size.x - 10.0, 10, Color("effdff") if complete and not claimed else Color("8799a3"))

func _draw_navigation() -> void:
	draw_rect(NAV_RECT, Color("061522"), true)
	draw_line(Vector2(0.0, 650.0), Vector2(1280.0, 650.0), Color("60dfff", 0.42), 2.0)
	for index: int in range(VIEWS.size()):
		var view_id: String = VIEWS[index]
		var rect: Rect2 = Rect2(float(index) * 213.333, 652.0, 213.333, 66.0)
		nav_rects[view_id] = rect
		var selected: bool = view_id == current_view
		if selected:
			draw_rect(Rect2(rect.position + Vector2(8.0, 5.0), rect.size - Vector2(16.0, 10.0)), Color("163d51"), true)
			draw_line(Vector2(rect.position.x + 18.0, 654.0), Vector2(rect.end.x - 18.0, 654.0), Color("8ff3ff"), 3.0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 39.0), String(VIEW_LABELS.get(view_id, view_id)).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 11, Color("eafcff") if selected else Color("7ea4b2"))
		var badge: int = _nav_badge(view_id)
		if badge > 0:
			draw_circle(rect.position + Vector2(180.0, 17.0), 11.0, Color("ff5d80"))
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(170.0, 21.0), "%d" % badge, HORIZONTAL_ALIGNMENT_CENTER, 20.0, 9, Color.WHITE)

func _draw_status_toast() -> void:
	var rect: Rect2 = Rect2(402.0, 614.0, 476.0, 30.0)
	draw_style_box(_panel_style(Color("07131d", 0.92), Color("37788f", 0.62), 1, 10), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 20.0), status_message, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 9, Color("bcebf4"))

func _draw_modal() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color(0.0, 0.0, 0.0, 0.62), true)
	var panel: Rect2 = Rect2(292.0, 112.0, 696.0, 480.0)
	draw_style_box(_panel_style(Color("0a1d2c"), Color("8ceaff"), 2, 16), panel)
	modal_rects["close"] = Rect2(918.0, 126.0, 46.0, 38.0)
	draw_style_box(_panel_style(Color("2d2630"), Color("ff8da8"), 1, 8), modal_rects["close"] as Rect2)
	draw_string(ThemeDB.fallback_font, Vector2(925.0, 151.0), "X", HORIZONTAL_ALIGNMENT_CENTER, 32.0, 13, Color("fff1f5"))
	if modal_mode == "assign_officer":
		draw_string(ThemeDB.fallback_font, Vector2(320.0, 152.0), "ASSIGN OFFICER TO %s" % String(PrecinctState.get_room(selected_room_id).get("name", "DIVISION")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 560.0, 16, Color("effdff"))
		for index: int in range(PrecinctState.officers.size()):
			var officer: Dictionary = PrecinctState.officers[index]
			var officer_id: String = String(officer.get("id", ""))
			var rect: Rect2 = Rect2(324.0, 184.0 + float(index) * 90.0, 632.0, 74.0)
			modal_rects["officer:" + officer_id] = rect
			_draw_assignment_officer_row(rect, officer)
	elif modal_mode == "assign_room":
		draw_string(ThemeDB.fallback_font, Vector2(320.0, 152.0), "ASSIGN %s TO A DIVISION" % String(PrecinctState.get_officer(selected_officer_id).get("name", "OFFICER")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 560.0, 16, Color("effdff"))
		for index: int in range(ROOM_IDS.size()):
			var room_id: String = ROOM_IDS[index]
			var room: Dictionary = PrecinctState.get_room(room_id)
			var column: int = index % 2
			var row: int = index / 2
			var rect: Rect2 = Rect2(324.0 + float(column) * 314.0, 184.0 + float(row) * 90.0, 298.0, 74.0)
			modal_rects["room:" + room_id] = rect
			_draw_assignment_room_row(rect, room)

func _draw_assignment_officer_row(rect: Rect2, officer: Dictionary) -> void:
	var available: bool = PrecinctState.officer_available(officer)
	draw_style_box(_panel_style(Color("123044") if available else Color("241c29"), Color("4a98b0") if available else Color("795264"), 1, 10), rect)
	_draw_officer_skin(officer, Rect2(rect.position + Vector2(6.0, 6.0), Vector2(62.0, 62.0)))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(82.0, 29.0), String(officer.get("name", "Officer")), HORIZONTAL_ALIGNMENT_LEFT, 250.0, 12, Color("effdff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(82.0, 52.0), "%s // LEVEL %d // %s" % [String(officer.get("class", "")), int(officer.get("level", 1)), _officer_status(officer)], HORIZONTAL_ALIGNMENT_LEFT, 390.0, 9, Color("89bdca"))
	var assigned: String = PrecinctMeta.assigned_room_id(String(officer.get("id", "")))
	if not assigned.is_empty():
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(480.0, 42.0), "POSTED", HORIZONTAL_ALIGNMENT_CENTER, 120.0, 10, Color("ffd17a"))

func _draw_assignment_room_row(rect: Rect2, room: Dictionary) -> void:
	var repaired: bool = bool(room.get("repaired", false))
	draw_style_box(_panel_style(Color("123044") if repaired else Color("241c29"), Color("4a98b0") if repaired else Color("795264"), 1, 10), rect)
	_draw_skin(String(ROOM_SKINS.get(String(room.get("id", "")), "command_nexus")), Rect2(rect.position + Vector2(6.0, 6.0), Vector2(62.0, 62.0)), _room_tint(String(room.get("id", "")), repaired))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(78.0, 29.0), String(room.get("name", "Room")), HORIZONTAL_ALIGNMENT_LEFT, 206.0, 10, Color("effdff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(78.0, 51.0), "L%d // %s" % [int(room.get("level", 1)), "ONLINE" if repaired else "LOCKED"], HORIZONTAL_ALIGNMENT_LEFT, 206.0, 9, Color("72efbd") if repaired else Color("ff8da8"))

func _draw_tutorial() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color(0.0, 0.0, 0.0, 0.48), true)
	var panel: Rect2 = Rect2(300.0, 410.0, 680.0, 188.0)
	draw_style_box(_panel_style(Color("0a1e2e"), Color("8ceaff"), 2, 16), panel)
	var steps: Array[Dictionary] = [
		{"title":"WELCOME, CHIEF", "text":"Your lunar precinct is damaged. Restore divisions, staff rooms, and answer distress calls."},
		{"title":"PRECINCT CITY", "text":"Every building is clickable. Select a division to open its detailed action window."},
		{"title":"BUILDING WINDOWS", "text":"Repair, upgrade, assign staff, and inspect timers from the Buildings view."},
		{"title":"OFFICER ROSTER", "text":"Open personnel files to train, heal, and post officers to precinct divisions."},
		{"title":"PATROL FORMATION", "text":"Choose a distress call, tap up to three officers, then dispatch them into tactical combat."},
		{"title":"CUSTODY & TASKS", "text":"Process arrests through different custody actions and claim chapter or daily rewards."}
	]
	var step: Dictionary = steps[clamp(PrecinctMeta.tutorial_step, 0, steps.size() - 1)]
	draw_string(ThemeDB.fallback_font, Vector2(330.0, 450.0), String(step.get("title", "TUTORIAL")), HORIZONTAL_ALIGNMENT_LEFT, 600.0, 18, Color("effdff"))
	draw_string(ThemeDB.fallback_font, Vector2(330.0, 487.0), String(step.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, 600.0, 11, Color("a4d0dc"))
	draw_string(ThemeDB.fallback_font, Vector2(330.0, 517.0), "STEP %d OF %d" % [PrecinctMeta.tutorial_step + 1, steps.size()], HORIZONTAL_ALIGNMENT_LEFT, 250.0, 9, Color("70dff2"))
	draw_style_box(_panel_style(Color("15546a"), Color("9af5ff"), 1, 10), Rect2(884.0, 535.0, 150.0, 46.0))
	draw_string(ThemeDB.fallback_font, Vector2(892.0, 563.0), "NEXT", HORIZONTAL_ALIGNMENT_CENTER, 134.0, 11, Color("effdff"))
	draw_style_box(_panel_style(Color("2a2932"), Color("7b8790"), 1, 10), Rect2(1046.0, 535.0, 150.0, 46.0))
	draw_string(ThemeDB.fallback_font, Vector2(1054.0, 563.0), "SKIP", HORIZONTAL_ALIGNMENT_CENTER, 134.0, 11, Color("b9c5ca"))

func _draw_action_button(action: String, rect: Rect2, label: String, enabled: bool) -> void:
	action_rects[action] = rect
	draw_style_box(_panel_style(Color("174f62") if enabled else Color("252e35"), Color("a6f6ff") if enabled else Color("56636b"), 1, 9), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(6.0, 27.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 12.0, 10, Color("effdff") if enabled else Color("77858c"))

func _draw_resource_chip(position: Vector2, label: String, value: String, accent: Color) -> void:
	var rect: Rect2 = Rect2(position, Vector2(154.0, 44.0))
	draw_style_box(_panel_style(Color("0d293c"), Color(accent, 0.52), 1, 10), rect)
	draw_string(ThemeDB.fallback_font, position + Vector2(10.0, 17.0), label, HORIZONTAL_ALIGNMENT_LEFT, 72.0, 8, Color("91b9c6"))
	draw_string(ThemeDB.fallback_font, position + Vector2(76.0, 29.0), value, HORIZONTAL_ALIGNMENT_RIGHT, 66.0, 13, accent)

func _draw_officer_skin(officer: Dictionary, rect: Rect2) -> void:
	var class_name: String = String(officer.get("class", "Guard"))
	var skin_name: String = "patrol_deputy"
	var tint: Color = Color.WHITE
	if class_name == "Guard":
		skin_name = "shield_deputy"
	elif class_name == "Biker":
		tint = Color(0.88, 0.65, 1.0, 1.0)
	elif class_name == "Marksman":
		tint = Color(1.0, 0.82, 0.44, 1.0)
	if not PrecinctState.officer_available(officer):
		tint = tint.darkened(0.52)
	draw_style_box(_panel_style(Color("06111b"), Color("66bfd5", 0.58), 1, 10), rect)
	_draw_skin(skin_name, rect.grow(-3.0), tint)

func _draw_skin(skin_name: String, rect: Rect2, tint: Color) -> void:
	if MoonGoonsSkins == null:
		return
	var texture: Texture2D = MoonGoonsSkins.get_texture(skin_name)
	if texture != null:
		draw_texture_rect(texture, rect, false, tint)

func _draw_stat_bar(position: Vector2, label: String, value: int, maximum: int, accent: Color) -> void:
	draw_string(ThemeDB.fallback_font, position, label, HORIZONTAL_ALIGNMENT_LEFT, 140.0, 9, Color("9bc0cb"))
	_draw_progress_bar(Rect2(position + Vector2(0.0, 12.0), Vector2(360.0, 15.0)), value, maximum, accent)
	draw_string(ThemeDB.fallback_font, position + Vector2(368.0, 23.0), "%d/%d" % [value, maximum], HORIZONTAL_ALIGNMENT_RIGHT, 70.0, 9, Color("eafcff"))

func _draw_progress_bar(rect: Rect2, value: int, maximum: int, accent: Color) -> void:
	draw_rect(rect, Color("06111b"), true)
	var ratio: float = clamp(float(value) / float(max(1, maximum)), 0.0, 1.0)
	draw_rect(Rect2(rect.position + Vector2(1.0, 1.0), Vector2((rect.size.x - 2.0) * ratio, rect.size.y - 2.0)), accent, true)
	draw_rect(rect, Color("7fc7d8", 0.32), false, 1.0)

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

func _room_tint(room_id: String, repaired: bool) -> Color:
	var tint: Color = Color.WHITE
	match room_id:
		"armory": tint = Color(0.88, 0.76, 1.0, 1.0)
		"cells": tint = Color(1.0, 0.76, 0.44, 1.0)
		"quarters": tint = Color(0.72, 0.90, 1.0, 1.0)
		"medbay": tint = Color(0.55, 1.0, 0.82, 1.0)
		"chief": tint = Color(1.0, 0.88, 0.55, 1.0)
		"interrogation": tint = Color(0.76, 0.68, 1.0, 1.0)
		"transfer": tint = Color(0.72, 0.88, 1.0, 1.0)
		_: tint = Color.WHITE
	if not repaired:
		tint = Color(tint.r * 0.48, tint.g * 0.48, tint.b * 0.48, 0.82)
	return tint

func _officer_status(officer: Dictionary) -> String:
	var injured_left: int = PrecinctState.seconds_left(int(officer.get("injured_until", 0)))
	if injured_left > 0:
		return "MEDBAY %ds" % injured_left
	var busy_left: int = PrecinctState.seconds_left(int(officer.get("busy_until", 0)))
	if busy_left > 0:
		return "BUSY %ds" % busy_left
	return "READY"

func _research_status() -> String:
	if PrecinctState.research_end > 0:
		return "LEVEL %d // %ds" % [PrecinctState.research_level + 1, PrecinctState.seconds_left(PrecinctState.research_end)]
	return "LEVEL %d // READY" % PrecinctState.research_level

func _selected_call() -> Dictionary:
	for call: Dictionary in PrecinctState.patrol_calls:
		if String(call.get("id", "")) == selected_call_id:
			return call
	return {}

func _ready_task_count() -> int:
	var total: int = 0
	for task: Dictionary in PrecinctMeta.task_catalog():
		var task_id: String = String(task.get("id", ""))
		if int(task.get("progress", 0)) >= int(task.get("target", 1)) and not PrecinctMeta.task_claimed(task_id):
			total += 1
	return total

func _nav_badge(view_id: String) -> int:
	match view_id:
		"buildings":
			var damaged: int = 0
			for room: Dictionary in PrecinctState.rooms:
				if not bool(room.get("repaired", false)):
					damaged += 1
			return damaged
		"patrol": return PrecinctState.patrol_calls.size()
		"custody": return PrecinctState.prisoners
		"tasks": return _ready_task_count()
		_: return 0

func _difficulty_color(difficulty: int) -> Color:
	if difficulty >= 3:
		return Color("ff6488")
	if difficulty == 2:
		return Color("ffc36e")
	return Color("6ce9c1")

func _on_state_changed() -> void:
	queue_redraw()
