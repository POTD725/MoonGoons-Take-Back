extends Node2D
## MoonGoons precinct hub with layered, clickable mobile-strategy views.
## The uploaded APK informs only broad screen-flow ideas. All code, art mapping,
## names, writing, and balancing are original MoonGoons work.

const VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)
const VIEWS: Array[String] = ["city", "buildings", "officers", "patrol", "custody", "tasks"]
const VIEW_LABELS: Dictionary = {
	"city":"PRECINCT", "buildings":"BUILDINGS", "officers":"OFFICERS",
	"patrol":"PATROL", "custody":"CUSTODY", "tasks":"TASKS"
}
const ROOM_IDS: Array[String] = ["ops", "armory", "cells", "quarters", "medbay", "chief", "interrogation", "transfer"]
const ROOM_SKINS: Dictionary = {
	"ops":"command_nexus", "armory":"tactical_armory", "cells":"cargo_wall",
	"quarters":"cargo_crate", "medbay":"machine_shop", "chief":"command_nexus",
	"interrogation":"evidence_cache", "transfer":"wrecked_shuttle"
}

var primary_views: Array[String] = VIEWS.duplicate()
var current_view: String = "city"
var selected_room_id: String = "ops"
var selected_officer_id: String = "officer_1"
var selected_call_id: String = ""
var selected_team: Array[String] = []
var modal_mode: String = ""
var status_message: String = "Select a precinct division or use the command navigation."
var pulse: float = 0.0
var tick_clock: float = 0.0

var nav_hits: Dictionary = {}
var room_hits: Dictionary = {}
var officer_hits: Dictionary = {}
var call_hits: Dictionary = {}
var action_hits: Dictionary = {}
var task_hits: Dictionary = {}
var modal_hits: Dictionary = {}

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
	tick_clock += delta
	if tick_clock >= 0.25:
		tick_clock = 0.0
		PrecinctState.tick()
	queue_redraw()

func _input(event: InputEvent) -> void:
	var point: Vector2 = Vector2.ZERO
	var pressed: bool = false
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		point = mouse_event.position
		pressed = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		point = touch_event.position
		pressed = touch_event.pressed
	if pressed:
		_handle_press(point)

func _draw() -> void:
	_clear_hits()
	_draw_backdrop()
	_draw_header()
	match current_view:
		"buildings": _draw_buildings()
		"officers": _draw_officers()
		"patrol": _draw_patrol()
		"custody": _draw_custody()
		"tasks": _draw_tasks()
		_: _draw_city()
	_draw_navigation()
	_draw_status()
	if not modal_mode.is_empty():
		_draw_assignment_modal()
	if PrecinctMeta.tutorial_step < 6:
		_draw_tutorial()

func _clear_hits() -> void:
	nav_hits.clear()
	room_hits.clear()
	officer_hits.clear()
	call_hits.clear()
	action_hits.clear()
	task_hits.clear()
	modal_hits.clear()

func _handle_press(point: Vector2) -> void:
	if PrecinctMeta.tutorial_step < 6:
		if Rect2(850.0, 535.0, 150.0, 46.0).has_point(point):
			PrecinctMeta.advance_tutorial()
		elif Rect2(1014.0, 535.0, 150.0, 46.0).has_point(point):
			PrecinctMeta.dismiss_tutorial()
		return
	if not modal_mode.is_empty():
		for key_value: Variant in modal_hits.keys():
			var key: String = String(key_value)
			if (modal_hits[key] as Rect2).has_point(point):
				_handle_modal(key)
				return
		return
	for view_value: Variant in nav_hits.keys():
		var view_id: String = String(view_value)
		if (nav_hits[view_id] as Rect2).has_point(point):
			current_view = view_id
			status_message = "%s view opened." % String(VIEW_LABELS.get(view_id, view_id))
			queue_redraw()
			return
	for room_value: Variant in room_hits.keys():
		var room_id: String = String(room_value)
		if (room_hits[room_id] as Rect2).has_point(point):
			selected_room_id = room_id
			current_view = "buildings"
			status_message = "%s opened." % String(PrecinctState.get_room(room_id).get("name", "Building"))
			queue_redraw()
			return
	for officer_value: Variant in officer_hits.keys():
		var officer_id: String = String(officer_value)
		if (officer_hits[officer_id] as Rect2).has_point(point):
			if current_view == "patrol":
				_toggle_team(officer_id)
			else:
				selected_officer_id = officer_id
				current_view = "officers"
			queue_redraw()
			return
	for call_value: Variant in call_hits.keys():
		var call_id: String = String(call_value)
		if (call_hits[call_id] as Rect2).has_point(point):
			selected_call_id = call_id
			status_message = "Distress call selected. Choose a formation."
			queue_redraw()
			return
	for task_value: Variant in task_hits.keys():
		var task_id: String = String(task_value)
		if (task_hits[task_id] as Rect2).has_point(point):
			var task_result: Dictionary = PrecinctMeta.claim_task(task_id)
			status_message = String(task_result.get("message", "Task action failed."))
			queue_redraw()
			return
	for action_value: Variant in action_hits.keys():
		var action: String = String(action_value)
		if (action_hits[action] as Rect2).has_point(point):
			_handle_action(action)
			return

func _handle_action(action: String) -> void:
	var result: Dictionary = {}
	match action:
		"repair": result = PrecinctState.repair_room(selected_room_id)
		"upgrade": result = PrecinctMeta.upgrade_room(selected_room_id)
		"assign_room":
			modal_mode = "assign_officer"
			queue_redraw()
			return
		"clear_staff": result = PrecinctMeta.unassign_room(selected_room_id)
		"train": result = PrecinctMeta.train_officer(selected_officer_id)
		"heal": result = PrecinctMeta.heal_officer(selected_officer_id)
		"post_officer":
			modal_mode = "assign_room"
			queue_redraw()
			return
		"dispatch":
			result = PrecinctState.begin_patrol(selected_call_id, selected_team)
			if bool(result.get("ok", false)):
				get_tree().change_scene_to_file("res://scenes/PrecinctBattle.tscn")
				return
		"process": result = PrecinctMeta.custody_action("process")
		"interrogate": result = PrecinctMeta.custody_action("interrogate")
		"transfer": result = PrecinctMeta.custody_action("transfer")
		"research": result = PrecinctState.begin_research()
		"open_patrol": current_view = "patrol"
		"open_custody": current_view = "custody"
		"open_tasks": current_view = "tasks"
		"save":
			result = PrecinctState.save_game()
			PrecinctMeta.save_meta()
		"load":
			result = PrecinctState.load_game()
			PrecinctMeta.load_meta()
		"reset":
			PrecinctState.reset_state()
			PrecinctMeta.reset_meta()
			selected_team.clear()
			selected_call_id = ""
			result = {"ok":true, "message":"Precinct campaign reset."}
		"rts":
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
			return
		_: return
	if not result.is_empty():
		status_message = String(result.get("message", "Action completed."))
	queue_redraw()

func _handle_modal(key: String) -> void:
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

func _toggle_team(officer_id: String) -> void:
	var officer: Dictionary = PrecinctState.get_officer(officer_id)
	if officer.is_empty() or not PrecinctState.officer_available(officer):
		status_message = "That officer is unavailable."
		return
	if selected_team.has(officer_id):
		selected_team.erase(officer_id)
	elif selected_team.size() < 3:
		selected_team.append(officer_id)
	else:
		status_message = "Patrol formations are limited to three officers."
	queue_redraw()

func _draw_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("020711"))
	for index: int in range(85):
		var x: float = fmod(float(index * 91 + 29), 1280.0)
		var y: float = fmod(float(index * 53 + 19), 720.0)
		draw_circle(Vector2(x, y), 1.0 + float(index % 3) * 0.35, Color("b8e8ff", 0.18))

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, 1280.0, 76.0), Color("07192c"), true)
	draw_line(Vector2(0.0, 76.0), Vector2(1280.0, 76.0), Color("63dfff", 0.42), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(22.0, 31.0), "MOONGOONS", HORIZONTAL_ALIGNMENT_LEFT, 230.0, 21, Color("eefcff"))
	draw_string(ThemeDB.fallback_font, Vector2(22.0, 55.0), "LUNAR PRECINCT COMMAND // CHAPTER %d" % PrecinctMeta.chapter, HORIZONTAL_ALIGNMENT_LEFT, 420.0, 11, Color("72dfff"))
	_draw_chip(Vector2(458.0, 15.0), "CREDITS", PrecinctState.credits, Color("ffd37b"))
	_draw_chip(Vector2(628.0, 15.0), "INTEL", PrecinctState.intel, Color("79eaff"))
	_draw_chip(Vector2(798.0, 15.0), "EVIDENCE", PrecinctState.evidence, Color("d6a6ff"))
	_draw_chip(Vector2(968.0, 15.0), "REP", PrecinctMeta.reputation, Color("7ff0bd"))
	_button("save", Rect2(1152.0, 15.0, 48.0, 44.0), "S", true)
	_button("load", Rect2(1208.0, 15.0, 48.0, 44.0), "L", true)

func _draw_city() -> void:
	_panel(Rect2(18.0, 88.0, 936.0, 544.0), Color("081a28"), Color("478ba2"), 14)
	draw_string(ThemeDB.fallback_font, Vector2(34.0, 116.0), "PRECINCT CITY // SELECT A DIVISION", HORIZONTAL_ALIGNMENT_LEFT, 500.0, 15, Color("eafcff"))
	for index: int in range(ROOM_IDS.size()):
		var room_id: String = ROOM_IDS[index]
		var room: Dictionary = PrecinctState.get_room(room_id)
		var column: int = index % 4
		var row: int = index / 4
		var rect: Rect2 = Rect2(42.0 + float(column) * 224.0, 140.0 + float(row) * 232.0, 202.0, 205.0)
		room_hits[room_id] = rect
		var online: bool = bool(room.get("repaired", false))
		_panel(rect, Color("102b3e"), Color("62e5c5") if online else Color("d15d7c"), 12)
		_draw_skin(String(ROOM_SKINS.get(room_id, "command_nexus")), Rect2(rect.position + Vector2(8.0, 8.0), Vector2(186.0, 136.0)), _room_tint(room_id, online))
		draw_rect(Rect2(rect.position + Vector2(0.0, 146.0), Vector2(rect.size.x, 59.0)), Color("06121e", 0.94), true)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 166.0), String(room.get("name", "ROOM")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 186.0, 10, Color("effdff"))
		var state_text: String = "ONLINE" if online else "DAMAGED"
		if int(room.get("repair_end", 0)) > 0:
			state_text = "REPAIR %ds" % PrecinctState.seconds_left(int(room.get("repair_end", 0)))
		if not PrecinctMeta.assigned_officer_id(room_id).is_empty():
			state_text += " // STAFFED"
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 188.0), "L%d // %s" % [int(room.get("level", 1)), state_text], HORIZONTAL_ALIGNMENT_LEFT, 186.0, 9, Color("74dff0") if online else Color("ff9ab0"))
	_panel(Rect2(972.0, 88.0, 290.0, 544.0), Color("081a28"), Color("478ba2"), 14)
	draw_string(ThemeDB.fallback_font, Vector2(990.0, 116.0), "COMMAND QUEUE", HORIZONTAL_ALIGNMENT_LEFT, 240.0, 14, Color("8ceaff"))
	_queue_card("research", Rect2(990.0, 138.0, 254.0, 82.0), "RESEARCH", _research_text())
	_queue_card("open_patrol", Rect2(990.0, 232.0, 254.0, 82.0), "PATROL BOARD", "%d ACTIVE CALL(S)" % PrecinctState.patrol_calls.size())
	_queue_card("open_custody", Rect2(990.0, 326.0, 254.0, 82.0), "CUSTODY", "%d PRISONER(S)" % PrecinctState.prisoners)
	_queue_card("open_tasks", Rect2(990.0, 420.0, 254.0, 82.0), "OBJECTIVES", "%d REWARD(S) READY" % _ready_task_count())
	_button("rts", Rect2(990.0, 526.0, 254.0, 58.0), "OPEN RTS FRONT", true)

func _draw_buildings() -> void:
	var room: Dictionary = PrecinctState.get_room(selected_room_id)
	var online: bool = bool(room.get("repaired", false))
	_panel(Rect2(24.0, 92.0, 760.0, 520.0), Color("0a1e2d"), Color("478ba2"), 14)
	_draw_skin(String(ROOM_SKINS.get(selected_room_id, "command_nexus")), Rect2(42.0, 112.0, 724.0, 326.0), _room_tint(selected_room_id, online))
	draw_rect(Rect2(42.0, 112.0, 724.0, 326.0), Color(0.02, 0.06, 0.10, 0.12 if online else 0.48), true)
	draw_string(ThemeDB.fallback_font, Vector2(44.0, 472.0), String(room.get("name", "BUILDING")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 620.0, 22, Color("effdff"))
	draw_string(ThemeDB.fallback_font, Vector2(44.0, 500.0), "%s // LEVEL %d" % [String(room.get("function", "")), int(room.get("level", 1))], HORIZONTAL_ALIGNMENT_LEFT, 620.0, 12, Color("80dff0"))
	var staff_id: String = PrecinctMeta.assigned_officer_id(selected_room_id)
	var staff_text: String = "UNSTAFFED"
	if not staff_id.is_empty():
		staff_text = String(PrecinctState.get_officer(staff_id).get("name", "Officer")).to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(44.0, 526.0), "ASSIGNMENT // %s" % staff_text, HORIZONTAL_ALIGNMENT_LEFT, 620.0, 10, Color("a8cbd5"))
	if online:
		_button("upgrade", Rect2(44.0, 552.0, 216.0, 44.0), "UPGRADE", true)
	else:
		_button("repair", Rect2(44.0, 552.0, 216.0, 44.0), "REPAIR %d CR" % int(room.get("repair_cost", 0)), true)
	_button("assign_room", Rect2(276.0, 552.0, 216.0, 44.0), "ASSIGN OFFICER", online)
	_button("clear_staff", Rect2(508.0, 552.0, 216.0, 44.0), "CLEAR STAFF", not staff_id.is_empty())
	_panel(Rect2(804.0, 92.0, 450.0, 520.0), Color("0a1e2d"), Color("478ba2"), 14)
	draw_string(ThemeDB.fallback_font, Vector2(824.0, 120.0), "PRECINCT DIVISIONS", HORIZONTAL_ALIGNMENT_LEFT, 380.0, 13, Color("8ceaff"))
	for index: int in range(ROOM_IDS.size()):
		var room_id: String = ROOM_IDS[index]
		var list_room: Dictionary = PrecinctState.get_room(room_id)
		var rect: Rect2 = Rect2(824.0, 140.0 + float(index) * 56.0, 410.0, 48.0)
		room_hits[room_id] = rect
		_panel(rect, Color("173448") if room_id == selected_room_id else Color("102636"), Color("b8f8ff") if room_id == selected_room_id else Color("356f84"), 8)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 20.0), String(list_room.get("name", "Room")), HORIZONTAL_ALIGNMENT_LEFT, 255.0, 10, Color("effdff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(280.0, 20.0), "L%d // %s" % [int(list_room.get("level", 1)), "ONLINE" if bool(list_room.get("repaired", false)) else "DAMAGED"], HORIZONTAL_ALIGNMENT_RIGHT, 116.0, 9, Color("73e5bf") if bool(list_room.get("repaired", false)) else Color("ff8da8"))

func _draw_officers() -> void:
	_panel(Rect2(24.0, 92.0, 370.0, 520.0), Color("0a1e2d"), Color("478ba2"), 14)
	_panel(Rect2(414.0, 92.0, 840.0, 520.0), Color("0a1e2d"), Color("478ba2"), 14)
	draw_string(ThemeDB.fallback_font, Vector2(44.0, 120.0), "OFFICER ROSTER", HORIZONTAL_ALIGNMENT_LEFT, 300.0, 14, Color("8ceaff"))
	for index: int in range(PrecinctState.officers.size()):
		var officer: Dictionary = PrecinctState.officers[index]
		var officer_id: String = String(officer.get("id", ""))
		var rect: Rect2 = Rect2(42.0, 144.0 + float(index) * 108.0, 334.0, 92.0)
		officer_hits[officer_id] = rect
		_panel(rect, Color("173448") if officer_id == selected_officer_id else Color("102636"), Color("b8f8ff") if officer_id == selected_officer_id else Color("356f84"), 10)
		_draw_officer_art(officer, Rect2(rect.position + Vector2(7.0, 7.0), Vector2(78.0, 78.0)))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(96.0, 28.0), String(officer.get("name", "Officer")), HORIZONTAL_ALIGNMENT_LEFT, 210.0, 12, Color("effdff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(96.0, 51.0), "%s // LEVEL %d" % [String(officer.get("class", "")), int(officer.get("level", 1))], HORIZONTAL_ALIGNMENT_LEFT, 210.0, 9, Color("86c5d6"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(96.0, 73.0), _officer_status(officer), HORIZONTAL_ALIGNMENT_LEFT, 210.0, 9, Color("72efbd") if PrecinctState.officer_available(officer) else Color("ff93ad"))
	var selected: Dictionary = PrecinctState.get_officer(selected_officer_id)
	_draw_officer_art(selected, Rect2(448.0, 128.0, 320.0, 320.0))
	draw_string(ThemeDB.fallback_font, Vector2(798.0, 154.0), String(selected.get("name", "OFFICER")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 410.0, 23, Color("effdff"))
	draw_string(ThemeDB.fallback_font, Vector2(798.0, 182.0), "%s // %s // LEVEL %d" % [String(selected.get("rarity", "Common")).to_upper(), String(selected.get("class", "Guard")).to_upper(), int(selected.get("level", 1))], HORIZONTAL_ALIGNMENT_LEFT, 410.0, 11, Color("83e6f7"))
	_stat_bar(Vector2(798.0, 224.0), "HEALTH", int(selected.get("hp", 0)), int(selected.get("max_hp", 100)), Color("62e1b7"))
	_stat_bar(Vector2(798.0, 278.0), "POWER", int(selected.get("power", 0)), 180, Color("ffd17a"))
	_stat_bar(Vector2(798.0, 332.0), "DEFENSE", int(selected.get("defense", 0)), 80, Color("83c8ff"))
	var post_id: String = PrecinctMeta.assigned_room_id(selected_officer_id)
	var post_text: String = "UNASSIGNED"
	if not post_id.is_empty():
		post_text = String(PrecinctState.get_room(post_id).get("name", "Room")).to_upper()
	draw_string(ThemeDB.fallback_font, Vector2(798.0, 404.0), "CURRENT POST // %s" % post_text, HORIZONTAL_ALIGNMENT_LEFT, 410.0, 11, Color("a9c8d3"))
	_button("train", Rect2(448.0, 532.0, 230.0, 52.0), "TRAIN OFFICER", PrecinctState.officer_available(selected))
	_button("heal", Rect2(694.0, 532.0, 230.0, 52.0), "MEDBAY TREATMENT", true)
	_button("post_officer", Rect2(940.0, 532.0, 280.0, 52.0), "ASSIGN TO DIVISION", true)

func _draw_patrol() -> void:
	_panel(Rect2(24.0, 92.0, 366.0, 520.0), Color("0a1e2d"), Color("478ba2"), 14)
	_panel(Rect2(408.0, 92.0, 430.0, 520.0), Color("0a1e2d"), Color("478ba2"), 14)
	_panel(Rect2(856.0, 92.0, 398.0, 520.0), Color("0a1e2d"), Color("478ba2"), 14)
	draw_string(ThemeDB.fallback_font, Vector2(44.0, 120.0), "DISTRESS CALLS", HORIZONTAL_ALIGNMENT_LEFT, 300.0, 14, Color("8ceaff"))
	for index: int in range(PrecinctState.patrol_calls.size()):
		var call: Dictionary = PrecinctState.patrol_calls[index]
		var call_id: String = String(call.get("id", ""))
		var rect: Rect2 = Rect2(42.0, 144.0 + float(index) * 108.0, 330.0, 92.0)
		call_hits[call_id] = rect
		_panel(rect, Color("173448") if call_id == selected_call_id else Color("102636"), Color("f0fcff") if call_id == selected_call_id else _difficulty_color(int(call.get("difficulty", 1))), 10)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 26.0), String(call.get("title", "CALL")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 290.0, 11, Color("effdff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 50.0), String(call.get("sector", "Sector")), HORIZONTAL_ALIGNMENT_LEFT, 290.0, 9, Color("88bdcb"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 74.0), "D%d // %d CR // %ds" % [int(call.get("difficulty", 1)), int(call.get("reward", 0)), PrecinctState.seconds_left(int(call.get("expires_at", 0)))], HORIZONTAL_ALIGNMENT_LEFT, 290.0, 9, Color("ffc27e"))
	if PrecinctState.patrol_calls.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(44.0, 164.0), "Scanner sweep active. Next signal in %ds." % PrecinctState.seconds_left(PrecinctState.next_call_at), HORIZONTAL_ALIGNMENT_LEFT, 310.0, 10, Color("87b7c5"))
	var selected_call: Dictionary = _selected_call()
	if selected_call.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(430.0, 126.0), "SELECT A DISTRESS CALL", HORIZONTAL_ALIGNMENT_LEFT, 370.0, 15, Color("8ceaff"))
		_draw_skin("evidence_cache", Rect2(468.0, 206.0, 310.0, 310.0), Color(0.62, 0.84, 1.0, 0.36))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(430.0, 126.0), String(selected_call.get("title", "PATROL")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 380.0, 15, Color("effdff"))
		_draw_skin("wrecked_shuttle", Rect2(448.0, 160.0, 350.0, 252.0), Color(0.78, 0.90, 1.0, 0.72))
		draw_string(ThemeDB.fallback_font, Vector2(438.0, 452.0), "THREAT D%d // REWARD %d CR" % [int(selected_call.get("difficulty", 1)), int(selected_call.get("reward", 0))], HORIZONTAL_ALIGNMENT_LEFT, 370.0, 11, Color("ffd17a"))
		_button("dispatch", Rect2(438.0, 526.0, 370.0, 52.0), "DISPATCH FORMATION", not selected_team.is_empty())
	draw_string(ThemeDB.fallback_font, Vector2(876.0, 120.0), "FORMATION %d/3" % selected_team.size(), HORIZONTAL_ALIGNMENT_LEFT, 320.0, 14, Color("8ceaff"))
	for index: int in range(PrecinctState.officers.size()):
		var officer: Dictionary = PrecinctState.officers[index]
		var officer_id: String = String(officer.get("id", ""))
		var rect: Rect2 = Rect2(874.0, 144.0 + float(index) * 108.0, 362.0, 92.0)
		officer_hits[officer_id] = rect
		var chosen: bool = selected_team.has(officer_id)
		_panel(rect, Color("173448") if chosen else Color("102636"), Color("a8ffef") if chosen else Color("356f84"), 10)
		_draw_officer_art(officer, Rect2(rect.position + Vector2(7.0, 7.0), Vector2(78.0, 78.0)))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(96.0, 30.0), String(officer.get("name", "Officer")), HORIZONTAL_ALIGNMENT_LEFT, 220.0, 11, Color("effdff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(96.0, 54.0), "%s // PWR %d" % [String(officer.get("class", "")), int(officer.get("power", 0))], HORIZONTAL_ALIGNMENT_LEFT, 220.0, 9, Color("86bdca"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(96.0, 76.0), "SELECTED" if chosen else _officer_status(officer), HORIZONTAL_ALIGNMENT_LEFT, 220.0, 9, Color("72efbd"))

func _draw_custody() -> void:
	_panel(Rect2(24.0, 92.0, 620.0, 520.0), Color("0a1e2d"), Color("478ba2"), 14)
	_panel(Rect2(664.0, 92.0, 590.0, 520.0), Color("0a1e2d"), Color("478ba2"), 14)
	_draw_skin("cargo_wall", Rect2(44.0, 112.0, 580.0, 340.0), Color(0.84, 0.92, 1.0, 0.86))
	_draw_skin("evidence_cache", Rect2(426.0, 310.0, 170.0, 170.0), Color(1.0, 0.78, 0.44, 0.82))
	draw_string(ThemeDB.fallback_font, Vector2(46.0, 492.0), "HOLDING CELLS", HORIZONTAL_ALIGNMENT_LEFT, 420.0, 22, Color("effdff"))
	draw_string(ThemeDB.fallback_font, Vector2(46.0, 526.0), "%d PRISONER(S) AWAITING ACTION" % PrecinctState.prisoners, HORIZONTAL_ALIGNMENT_LEFT, 520.0, 12, Color("ffc77e"))
	draw_string(ThemeDB.fallback_font, Vector2(686.0, 120.0), "CUSTODY ACTIONS", HORIZONTAL_ALIGNMENT_LEFT, 480.0, 14, Color("8ceaff"))
	_custody_card("process", Rect2(686.0, 146.0, 546.0, 116.0), "PROCESS CASE", "Standard booking and evidence review.", "+70 credits // +4 intel", PrecinctState.is_room_repaired("cells"))
	_custody_card("interrogate", Rect2(686.0, 280.0, 546.0, 116.0), "INTERROGATE", "Question the suspect about Syndicate activity.", "+10 intel // +1 evidence", PrecinctState.is_room_repaired("interrogation"))
	_custody_card("transfer", Rect2(686.0, 414.0, 546.0, 116.0), "SECURE TRANSFER", "Move the prisoner to orbital detention.", "+125 credits", PrecinctState.is_room_repaired("transfer"))

func _draw_tasks() -> void:
	_panel(Rect2(18.0, 88.0, 1244.0, 544.0), Color("081a28"), Color("478ba2"), 14)
	draw_string(ThemeDB.fallback_font, Vector2(36.0, 116.0), "CHAPTER & DAILY OBJECTIVES", HORIZONTAL_ALIGNMENT_LEFT, 600.0, 17, Color("effdff"))
	var tasks: Array[Dictionary] = PrecinctMeta.task_catalog()
	for index: int in range(tasks.size()):
		var task: Dictionary = tasks[index]
		var column: int = index % 2
		var row: int = index / 2
		var rect: Rect2 = Rect2(38.0 + float(column) * 608.0, 146.0 + float(row) * 150.0, 588.0, 132.0)
		var task_id: String = String(task.get("id", ""))
		var progress: int = int(task.get("progress", 0))
		var target: int = int(task.get("target", 1))
		var complete: bool = progress >= target
		var claimed: bool = PrecinctMeta.task_claimed(task_id)
		_panel(rect, Color("123043") if complete else Color("0f2535"), Color("71e5bd") if complete else Color("3f7e94"), 12)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 24.0), String(task.get("group", "TASK")), HORIZONTAL_ALIGNMENT_LEFT, 120.0, 9, Color("7ce8fb"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 50.0), String(task.get("title", "Objective")), HORIZONTAL_ALIGNMENT_LEFT, 350.0, 13, Color("effdff"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 74.0), String(task.get("description", "")), HORIZONTAL_ALIGNMENT_LEFT, 380.0, 9, Color("8db9c7"))
		_progress(Rect2(rect.position + Vector2(16.0, 94.0), Vector2(360.0, 12.0)), progress, target, Color("6ce6bd"))
		var claim_rect: Rect2 = Rect2(rect.position + Vector2(410.0, 74.0), Vector2(146.0, 40.0))
		task_hits[task_id] = claim_rect
		_panel(claim_rect, Color("1c5a4a") if complete and not claimed else Color("25313a"), Color("88f6d3") if complete and not claimed else Color("566570"), 8)
		var label: String = "CLAIM" if complete and not claimed else ("CLAIMED" if claimed else "%d/%d" % [min(progress, target), target])
		draw_string(ThemeDB.fallback_font, claim_rect.position + Vector2(5.0, 25.0), label, HORIZONTAL_ALIGNMENT_CENTER, claim_rect.size.x - 10.0, 10, Color("effdff") if complete and not claimed else Color("8799a3"))

func _draw_navigation() -> void:
	draw_rect(Rect2(0.0, 650.0, 1280.0, 70.0), Color("061522"), true)
	draw_line(Vector2(0.0, 650.0), Vector2(1280.0, 650.0), Color("60dfff", 0.42), 2.0)
	for index: int in range(VIEWS.size()):
		var view_id: String = VIEWS[index]
		var rect: Rect2 = Rect2(float(index) * 213.333, 652.0, 213.333, 66.0)
		nav_hits[view_id] = rect
		if view_id == current_view:
			draw_rect(Rect2(rect.position + Vector2(8.0, 5.0), rect.size - Vector2(16.0, 10.0)), Color("163d51"), true)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 39.0), String(VIEW_LABELS.get(view_id, view_id)), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 11, Color("eafcff") if view_id == current_view else Color("7ea4b2"))
		var badge: int = _badge(view_id)
		if badge > 0:
			draw_circle(rect.position + Vector2(182.0, 17.0), 11.0, Color("ff5d80"))
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(172.0, 21.0), "%d" % badge, HORIZONTAL_ALIGNMENT_CENTER, 20.0, 9, Color.WHITE)

func _draw_status() -> void:
	var rect: Rect2 = Rect2(388.0, 614.0, 504.0, 30.0)
	_panel(rect, Color("07131d", 0.94), Color("37788f"), 10)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 20.0), status_message, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 20.0, 9, Color("bcebf4"))

func _draw_assignment_modal() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color(0.0, 0.0, 0.0, 0.66), true)
	var panel_rect: Rect2 = Rect2(290.0, 110.0, 700.0, 480.0)
	_panel(panel_rect, Color("0a1d2c"), Color("8ceaff"), 16)
	modal_hits["close"] = Rect2(920.0, 126.0, 46.0, 38.0)
	_button_visual(modal_hits["close"] as Rect2, "X", true)
	if modal_mode == "assign_officer":
		draw_string(ThemeDB.fallback_font, Vector2(320.0, 152.0), "ASSIGN OFFICER TO %s" % String(PrecinctState.get_room(selected_room_id).get("name", "DIVISION")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 560.0, 16, Color("effdff"))
		for index: int in range(PrecinctState.officers.size()):
			var officer: Dictionary = PrecinctState.officers[index]
			var officer_id: String = String(officer.get("id", ""))
			var rect: Rect2 = Rect2(324.0, 184.0 + float(index) * 90.0, 632.0, 74.0)
			modal_hits["officer:" + officer_id] = rect
			_panel(rect, Color("123044"), Color("4a98b0"), 10)
			_draw_officer_art(officer, Rect2(rect.position + Vector2(6.0, 6.0), Vector2(62.0, 62.0)))
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(82.0, 30.0), String(officer.get("name", "Officer")), HORIZONTAL_ALIGNMENT_LEFT, 300.0, 12, Color("effdff"))
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(82.0, 53.0), "%s // LEVEL %d // %s" % [String(officer.get("class", "")), int(officer.get("level", 1)), _officer_status(officer)], HORIZONTAL_ALIGNMENT_LEFT, 420.0, 9, Color("89bdca"))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(320.0, 152.0), "ASSIGN %s TO A DIVISION" % String(PrecinctState.get_officer(selected_officer_id).get("name", "OFFICER")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 560.0, 16, Color("effdff"))
		for index: int in range(ROOM_IDS.size()):
			var room_id: String = ROOM_IDS[index]
			var room: Dictionary = PrecinctState.get_room(room_id)
			var column: int = index % 2
			var row: int = index / 2
			var rect: Rect2 = Rect2(324.0 + float(column) * 314.0, 184.0 + float(row) * 90.0, 298.0, 74.0)
			modal_hits["room:" + room_id] = rect
			_panel(rect, Color("123044") if bool(room.get("repaired", false)) else Color("241c29"), Color("4a98b0") if bool(room.get("repaired", false)) else Color("795264"), 10)
			_draw_skin(String(ROOM_SKINS.get(room_id, "command_nexus")), Rect2(rect.position + Vector2(6.0, 6.0), Vector2(62.0, 62.0)), _room_tint(room_id, bool(room.get("repaired", false))))
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(78.0, 31.0), String(room.get("name", "Room")), HORIZONTAL_ALIGNMENT_LEFT, 206.0, 10, Color("effdff"))
			draw_string(ThemeDB.fallback_font, rect.position + Vector2(78.0, 53.0), "L%d // %s" % [int(room.get("level", 1)), "ONLINE" if bool(room.get("repaired", false)) else "LOCKED"], HORIZONTAL_ALIGNMENT_LEFT, 206.0, 9, Color("72efbd") if bool(room.get("repaired", false)) else Color("ff8da8"))

func _draw_tutorial() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color(0.0, 0.0, 0.0, 0.52), true)
	var panel_rect: Rect2 = Rect2(260.0, 402.0, 760.0, 196.0)
	_panel(panel_rect, Color("0a1e2e"), Color("8ceaff"), 16)
	var steps: Array[Dictionary] = [
		{"title":"WELCOME, CHIEF", "text":"Restore the lunar precinct, staff its divisions, and answer distress calls."},
		{"title":"PRECINCT CITY", "text":"Every building is clickable and opens a detailed building action window."},
		{"title":"BUILDING ACTIONS", "text":"Repair, upgrade, inspect timers, and assign officers to working divisions."},
		{"title":"OFFICER FILES", "text":"Train, heal, inspect stats, and post officers from the roster view."},
		{"title":"PATROL FORMATION", "text":"Select a call, choose up to three officers, then dispatch into combat."},
		{"title":"CUSTODY & TASKS", "text":"Choose prisoner actions and claim chapter or daily objective rewards."}
	]
	var step_data: Dictionary = steps[clamp(PrecinctMeta.tutorial_step, 0, steps.size() - 1)]
	draw_string(ThemeDB.fallback_font, Vector2(292.0, 446.0), String(step_data.get("title", "TUTORIAL")), HORIZONTAL_ALIGNMENT_LEFT, 680.0, 18, Color("effdff"))
	draw_string(ThemeDB.fallback_font, Vector2(292.0, 484.0), String(step_data.get("text", "")), HORIZONTAL_ALIGNMENT_LEFT, 680.0, 11, Color("a4d0dc"))
	draw_string(ThemeDB.fallback_font, Vector2(292.0, 518.0), "STEP %d OF 6" % (PrecinctMeta.tutorial_step + 1), HORIZONTAL_ALIGNMENT_LEFT, 220.0, 9, Color("70dff2"))
	_button_visual(Rect2(850.0, 535.0, 150.0, 46.0), "NEXT", true)
	_button_visual(Rect2(1014.0, 535.0, 150.0, 46.0), "SKIP", false)

func _queue_card(action: String, rect: Rect2, title: String, detail: String) -> void:
	action_hits[action] = rect
	_panel(rect, Color("10283a"), Color("3d8ca5"), 10)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(12.0, 27.0), title, HORIZONTAL_ALIGNMENT_LEFT, 210.0, 11, Color("effdff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(12.0, 54.0), detail, HORIZONTAL_ALIGNMENT_LEFT, 210.0, 9, Color("82bbcb"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(218.0, 54.0), ">", HORIZONTAL_ALIGNMENT_CENTER, 24.0, 17, Color("7eeaff"))

func _custody_card(action: String, rect: Rect2, title: String, detail: String, reward: String, unlocked: bool) -> void:
	action_hits[action] = rect
	_panel(rect, Color("143044") if unlocked else Color("241c29"), Color("4a9ab4") if unlocked else Color("795264"), 12)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 29.0), title, HORIZONTAL_ALIGNMENT_LEFT, 300.0, 13, Color("effdff") if unlocked else Color("9d8c94"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 58.0), detail, HORIZONTAL_ALIGNMENT_LEFT, 500.0, 10, Color("98c2cf") if unlocked else Color("7b6870"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(16.0, 90.0), reward if unlocked else "DIVISION LOCKED", HORIZONTAL_ALIGNMENT_LEFT, 500.0, 10, Color("ffd17a") if unlocked else Color("ff8da8"))

func _button(action: String, rect: Rect2, label: String, enabled: bool) -> void:
	action_hits[action] = rect
	_button_visual(rect, label, enabled)

func _button_visual(rect: Rect2, label: String, enabled: bool) -> void:
	_panel(rect, Color("174f62") if enabled else Color("252e35"), Color("a6f6ff") if enabled else Color("56636b"), 9)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(6.0, rect.size.y * 0.62), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 12.0, 10, Color("effdff") if enabled else Color("77858c"))

func _draw_chip(position: Vector2, label: String, value: int, accent: Color) -> void:
	var rect: Rect2 = Rect2(position, Vector2(154.0, 44.0))
	_panel(rect, Color("0d293c"), Color(accent.r, accent.g, accent.b, 0.52), 10)
	draw_string(ThemeDB.fallback_font, position + Vector2(10.0, 17.0), label, HORIZONTAL_ALIGNMENT_LEFT, 76.0, 8, Color("91b9c6"))
	draw_string(ThemeDB.fallback_font, position + Vector2(78.0, 29.0), "%d" % value, HORIZONTAL_ALIGNMENT_RIGHT, 64.0, 13, accent)

func _draw_officer_art(officer: Dictionary, rect: Rect2) -> void:
	var role_name: String = String(officer.get("class", "Guard"))
	var skin_name: String = "patrol_deputy"
	var tint: Color = Color.WHITE
	if role_name == "Guard":
		skin_name = "shield_deputy"
	elif role_name == "Biker":
		tint = Color(0.88, 0.65, 1.0, 1.0)
	elif role_name == "Marksman":
		tint = Color(1.0, 0.82, 0.44, 1.0)
	if not PrecinctState.officer_available(officer):
		tint = tint.darkened(0.52)
	_panel(rect, Color("06111b"), Color("66bfd5"), 10)
	_draw_skin(skin_name, rect.grow(-3.0), tint)

func _draw_skin(skin_name: String, rect: Rect2, tint: Color) -> void:
	var texture: Texture2D = MoonGoonsSkins.get_texture(skin_name)
	if texture != null:
		draw_texture_rect(texture, rect, false, tint)

func _stat_bar(position: Vector2, label: String, value: int, maximum: int, accent: Color) -> void:
	draw_string(ThemeDB.fallback_font, position, label, HORIZONTAL_ALIGNMENT_LEFT, 140.0, 9, Color("9bc0cb"))
	_progress(Rect2(position + Vector2(0.0, 13.0), Vector2(360.0, 15.0)), value, maximum, accent)
	draw_string(ThemeDB.fallback_font, position + Vector2(368.0, 24.0), "%d/%d" % [value, maximum], HORIZONTAL_ALIGNMENT_RIGHT, 70.0, 9, Color("eafcff"))

func _progress(rect: Rect2, value: int, maximum: int, accent: Color) -> void:
	draw_rect(rect, Color("06111b"), true)
	var ratio: float = clamp(float(value) / float(max(1, maximum)), 0.0, 1.0)
	draw_rect(Rect2(rect.position + Vector2(1.0, 1.0), Vector2((rect.size.x - 2.0) * ratio, rect.size.y - 2.0)), accent, true)
	draw_rect(rect, Color("7fc7d8", 0.32), false, 1.0)

func _panel(rect: Rect2, fill: Color, border: Color, radius: int) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	draw_style_box(style, rect)

func _room_tint(room_id: String, online: bool) -> Color:
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
	if not online:
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

func _selected_call() -> Dictionary:
	for call: Dictionary in PrecinctState.patrol_calls:
		if String(call.get("id", "")) == selected_call_id:
			return call
	return {}

func _research_text() -> String:
	if PrecinctState.research_end > 0:
		return "LEVEL %d // %ds" % [PrecinctState.research_level + 1, PrecinctState.seconds_left(PrecinctState.research_end)]
	return "LEVEL %d // READY" % PrecinctState.research_level

func _ready_task_count() -> int:
	var total: int = 0
	for task: Dictionary in PrecinctMeta.task_catalog():
		var task_id: String = String(task.get("id", ""))
		if int(task.get("progress", 0)) >= int(task.get("target", 1)) and not PrecinctMeta.task_claimed(task_id):
			total += 1
	return total

func _badge(view_id: String) -> int:
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
