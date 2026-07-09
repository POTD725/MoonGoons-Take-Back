extends "res://scripts/moongoons_rts_phase_nine_campaign.gd"
## Android testbed shell for the Phase Nine RTS.
## Adds finger-first controls and a brighter code-drawn visual pass without requiring binary art imports.

const TOUCH_SELECT_RADIUS: float = 34.0
const TOUCH_DRAG_THRESHOLD: float = 18.0
const TOUCH_BUTTON_SIZE := Vector2(110.0, 38.0)
const TOUCH_BUTTON_Y: float = 642.0

var touch_buttons: Dictionary = {}
var touch_active: bool = false
var touch_index: int = -1
var touch_start: Vector2 = Vector2.ZERO
var touch_current: Vector2 = Vector2.ZERO
var touch_dragging: bool = false
var touch_order_mode: String = ""

func _ready() -> void:
	_configure_touch_buttons()
	super._ready()
	mission_state = "ANDROID TEST BUILD // Tap a unit, then tap the field to move. Use the touch command deck for attack, scan, story, and cancel."
	_log_event("Android touch command deck loaded. Tap ALL to select squads, GATHER to mine, or ATTACK before tapping a target.")
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
		return
	if event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)
		return
	super._input(event)

func _draw() -> void:
	super._draw()
	_draw_touch_command_deck()
	if touch_dragging:
		_draw_touch_selection_preview()

func _configure_touch_buttons() -> void:
	touch_buttons = {
		"select_all": Rect2(34.0, TOUCH_BUTTON_Y, TOUCH_BUTTON_SIZE.x, TOUCH_BUTTON_SIZE.y),
		"gather": Rect2(150.0, TOUCH_BUTTON_Y, TOUCH_BUTTON_SIZE.x, TOUCH_BUTTON_SIZE.y),
		"move": Rect2(266.0, TOUCH_BUTTON_Y, TOUCH_BUTTON_SIZE.x, TOUCH_BUTTON_SIZE.y),
		"attack": Rect2(382.0, TOUCH_BUTTON_Y, TOUCH_BUTTON_SIZE.x, TOUCH_BUTTON_SIZE.y),
		"shield": Rect2(498.0, TOUCH_BUTTON_Y, TOUCH_BUTTON_SIZE.x, TOUCH_BUTTON_SIZE.y),
		"scan": Rect2(614.0, TOUCH_BUTTON_Y, TOUCH_BUTTON_SIZE.x, TOUCH_BUTTON_SIZE.y),
		"story": Rect2(730.0, TOUCH_BUTTON_Y, TOUCH_BUTTON_SIZE.x, TOUCH_BUTTON_SIZE.y),
		"cancel": Rect2(846.0, TOUCH_BUTTON_Y, TOUCH_BUTTON_SIZE.x, TOUCH_BUTTON_SIZE.y)
	}

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_active = true
		touch_index = event.index
		touch_start = event.position
		touch_current = event.position
		touch_dragging = false
		return
	if not touch_active or event.index != touch_index:
		return
	touch_current = event.position
	if touch_dragging and FIELD.has_point(touch_start) and FIELD.has_point(touch_current):
		_select_in_rectangle(Rect2(touch_start, touch_current - touch_start).abs())
	else:
		_handle_touch_tap(touch_current)
	touch_active = false
	touch_index = -1
	touch_dragging = false
	queue_redraw()

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not touch_active or event.index != touch_index:
		return
	touch_current = event.position
	if touch_start.distance_to(touch_current) >= TOUCH_DRAG_THRESHOLD:
		touch_dragging = true
		queue_redraw()

func _handle_touch_tap(position: Vector2) -> void:
	var button_action: String = _touch_button_at(position)
	if not button_action.is_empty():
		_handle_touch_button(button_action)
		return
	if campaign_board_open:
		_handle_left_press(position)
		return
	if not FIELD.has_point(position):
		_handle_left_press(position)
		return
	if not build_mode.is_empty():
		_place_structure(position)
		return
	if touch_order_mode == "scan":
		_activate_tactical_scan(position)
		touch_order_mode = ""
		return
	if touch_order_mode == "attack":
		_issue_touch_order(position, true)
		touch_order_mode = ""
		return
	if touch_order_mode == "move":
		_issue_touch_order(position, false)
		touch_order_mode = ""
		return
	if _friendly_at(position):
		_select_single_at(position)
		return
	if _selected_touch_unit_count() > 0:
		_issue_touch_order(position, false)
		return
	_select_single_at(position)

func _handle_touch_button(action: String) -> void:
	if action == "cancel":
		touch_order_mode = ""
		build_mode = ""
		attack_move_armed = false
		campaign_board_open = false
		mission_state = "Touch command cancelled."
		queue_redraw()
		return
	if action == "story":
		campaign_board_open = not campaign_board_open
		mission_state = "Story Dispatch %s." % ("opened" if campaign_board_open else "closed")
		queue_redraw()
		return
	if game_over or victory:
		return
	match action:
		"select_all":
			_select_all_playable_units()
		"gather":
			_touch_gather()
		"move":
			touch_order_mode = "move"
			attack_move_armed = false
			mission_state = "MOVE READY // Tap the battlefield to send selected units."
		"attack":
			touch_order_mode = "attack"
			attack_move_armed = true
			mission_state = "ATTACK-MOVE READY // Tap a target, empty ground, or hostile marker."
		"shield":
			_activate_shield_wall()
		"scan":
			touch_order_mode = "scan"
			mission_state = "TACTICAL SCAN READY // Tap a fogged or suspicious sector."
		_:
			pass
	queue_redraw()

func _issue_touch_order(destination: Vector2, attack_move: bool) -> void:
	if _selected_touch_unit_count() <= 0:
		mission_state = "Select units before issuing a touch order."
		return
	var target_enemy: Variant = _enemy_at(destination)
	if target_enemy != null:
		_command_selected_combat(target_enemy.pos, String(target_enemy.id), true)
		return
	_command_selected_combat(destination, "", attack_move)
	if not attack_move:
		_command_selected_workers_move(destination)

func _select_all_playable_units() -> void:
	var selected_count: int = 0
	for worker: Variant in workers:
		worker.selected = true
		selected_count += 1
	for unit: Variant in combat_units:
		unit.selected = true
		selected_count += 1
	mission_state = "Android squad select: %d lunar unit(s) ready." % selected_count

func _touch_gather() -> void:
	if _selected_worker_count() <= 0:
		for worker: Variant in workers:
			worker.selected = true
	var gather_origin: Vector2 = _selected_unit_centroid()
	_assign_selected_workers_to_nearest_resource(gather_origin)
	if _selected_worker_count() > 0:
		mission_state = "Touch gather order sent to selected Survey Drone(s)."

func _selected_touch_unit_count() -> int:
	var selected_count: int = 0
	for worker: Variant in workers:
		if bool(worker.selected):
			selected_count += 1
	for unit: Variant in combat_units:
		if bool(unit.selected):
			selected_count += 1
	return selected_count

func _selected_unit_centroid() -> Vector2:
	var total: Vector2 = Vector2.ZERO
	var count: int = 0
	for worker: Variant in workers:
		if bool(worker.selected):
			total += worker.pos
			count += 1
	for unit: Variant in combat_units:
		if bool(unit.selected):
			total += unit.pos
			count += 1
	if count <= 0:
		return NEXUS_POSITION
	return total / float(count)

func _friendly_at(position: Vector2) -> bool:
	var nearest_worker: Variant = _closest_worker(position)
	if nearest_worker != null and nearest_worker.pos.distance_to(position) <= TOUCH_SELECT_RADIUS:
		return true
	var nearest_unit: Variant = _closest_combat_unit(position)
	if nearest_unit != null and nearest_unit.pos.distance_to(position) <= TOUCH_SELECT_RADIUS:
		return true
	return false

func _touch_button_at(position: Vector2) -> String:
	for action_value: Variant in touch_buttons.keys():
		var action: String = String(action_value)
		var rect_value: Variant = touch_buttons.get(action, Rect2())
		if rect_value is Rect2 and (rect_value as Rect2).has_point(position):
			return action
	return ""

func _draw_touch_command_deck() -> void:
	var deck_rect: Rect2 = Rect2(24.0, 632.0, 936.0, 62.0)
	draw_style_box(_panel_style(Color("071522", 0.86), Color("6ddfff", 0.42), 1, 12), deck_rect)
	draw_string(ThemeDB.fallback_font, deck_rect.position + Vector2(10.0, 12.0), "ANDROID TOUCH COMMAND DECK", HORIZONTAL_ALIGNMENT_LEFT, 230.0, 8, Color("9eefff"))
	for action_value: Variant in touch_buttons.keys():
		var action: String = String(action_value)
		var rect: Rect2 = touch_buttons[action] as Rect2
		var active: bool = action == touch_order_mode or (action == "story" and campaign_board_open)
		var fill: Color = Color("205a6d", 0.96) if active else Color("122c42", 0.96)
		var border: Color = Color("b9f6ff") if active else Color("4c819b")
		draw_style_box(_panel_style(fill, border, 1, 8), rect)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(5.0, 23.0), _touch_button_label(action), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10.0, 10, Color("eafdff"))
	var help_text: String = "Tap unit to select. Tap ground to move. Drag box to select squads. Use side panel to train/build, then tap field to place."
	draw_string(ThemeDB.fallback_font, Vector2(40.0, 692.0), help_text, HORIZONTAL_ALIGNMENT_LEFT, 880.0, 9, Color("a8cadd"))

func _touch_button_label(action: String) -> String:
	match action:
		"select_all":
			return "ALL"
		"gather":
			return "GATHER"
		"move":
			return "MOVE"
		"attack":
			return "ATTACK"
		"shield":
			return "SHIELD"
		"scan":
			return "SCAN"
		"story":
			return "STORY"
		"cancel":
			return "CANCEL"
		_:
			return action.to_upper()

func _draw_touch_selection_preview() -> void:
	var selection_rect: Rect2 = Rect2(touch_start, touch_current - touch_start).abs()
	draw_rect(selection_rect, Color("b6f7ff", 0.16), true)
	draw_rect(selection_rect, Color("b6f7ff", 0.92), false, 2.0)

func _draw_space() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("030916"))
	draw_rect(Rect2(0.0, 0.0, VIEWPORT_SIZE.x, 92.0), Color("0b1f3a"))
	draw_circle(Vector2(1102.0, 64.0), 66.0, Color("d8f5ff", 0.06))
	draw_circle(Vector2(1102.0, 64.0), 42.0, Color("d8f5ff", 0.05))
	for star: Vector2 in star_positions:
		var star_size: float = 1.0 + fmod(star.x + star.y, 2.0)
		draw_circle(star, star_size, Color("b9d6ff", 0.78))
	draw_line(Vector2(0.0, 91.0), Vector2(VIEWPORT_SIZE.x, 91.0), Color("6edfff", 0.28), 1.0)

func _draw_field() -> void:
	super._draw_field()
	draw_rect(FIELD.grow(-8.0), Color("76d9ff", 0.035), false, 2.0)
	for index: int in range(5):
		var x: float = FIELD.position.x + 120.0 + float(index) * 156.0
		draw_line(Vector2(x, FIELD.position.y + 12.0), Vector2(x + 66.0, FIELD.end.y - 18.0), Color("a3eaff", 0.035), 2.0)
	draw_string(ThemeDB.fallback_font, FIELD.position + Vector2(18.0, 24.0), "LUNAR DISTRICT // TOUCH TEST RANGE", HORIZONTAL_ALIGNMENT_LEFT, 360.0, 10, Color("86bad2", 0.78))

func _draw_command_nexus() -> void:
	super._draw_command_nexus()
	draw_arc(NEXUS_POSITION, 68.0, 0.0, TAU, 48, Color("8ff6ff", 0.35), 2.0)
	draw_arc(NEXUS_POSITION, 77.0, -match_clock * 0.35, TAU - match_clock * 0.35, 48, Color("7ef5d0", 0.18), 1.5)

func _draw_syndicate_hideout() -> void:
	super._draw_syndicate_hideout()
	draw_arc(SYNDICATE_HIDEOUT_POSITION, 68.0, match_clock * 0.28, TAU + match_clock * 0.28, 42, Color("ff78b0", 0.30), 2.0)
	draw_circle(SYNDICATE_HIDEOUT_POSITION + Vector2(34.0, -34.0), 7.0, Color("ffbdd1", 0.75))

func _draw_resource_node(node: Variant) -> void:
	super._draw_resource_node(node)
	if int(node.amount) > 0:
		var resource_color: Color = Color("ffd46e") if String(node.resource_id) == "credits" else Color("ad95ff")
		draw_arc(node.pos, 34.0, match_clock, TAU + match_clock, 28, Color(resource_color, 0.35), 1.5)

func _draw_worker(worker: Variant) -> void:
	super._draw_worker(worker)
	draw_arc(worker.pos, 17.0, -PI * 0.2, PI * 0.85, 14, Color("eaffff", 0.42), 1.2)

func _draw_combat_unit(unit: Variant) -> void:
	super._draw_combat_unit(unit)
	var badge_color: Color = Color("68e4ff") if String(unit.unit_type) == "deputy" else Color("7ef5d0")
	draw_circle(unit.pos + Vector2(10.0, -10.0), 3.8, Color(badge_color, 0.95))

func _draw_enemy(enemy: Variant) -> void:
	super._draw_enemy(enemy)
	draw_arc(enemy.pos, 20.0, match_clock * 0.6, TAU + match_clock * 0.6, 16, Color(enemy.tint, 0.38), 1.3)

func _draw_banner() -> void:
	super._draw_banner()
	draw_string(ThemeDB.fallback_font, Vector2(1012.0, 28.0), "ANDROID TESTABLE", HORIZONTAL_ALIGNMENT_LEFT, 220.0, 10, Color("9ef6ff"))
