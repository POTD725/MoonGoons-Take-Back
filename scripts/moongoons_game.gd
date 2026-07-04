extends Node2D

const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const FIELD := Rect2(18.0, 92.0, 938.0, 608.0)
const SIDEBAR := Rect2(974.0, 18.0, 288.0, 684.0)
const FONT_SIZE_SMALL := 15
const FONT_SIZE_MEDIUM := 20
const FONT_SIZE_LARGE := 34

class Deputy:
	var pos: Vector2
	var target: Vector2
	var hp: float = 100.0
	var cooldown: float = 0.0
	var selected: bool = false
	var callsign: String

	func _init(start_pos: Vector2, label: String) -> void:
		pos = start_pos
		target = start_pos
		callsign = label

class Raider:
	var pos: Vector2
	var hp: float = 58.0
	var cooldown: float = 0.0
	var speed: float = 34.0
	var tint: Color

	func _init(start_pos: Vector2, color: Color, raid_speed: float) -> void:
		pos = start_pos
		tint = color
		speed = raid_speed

class Relay:
	var pos: Vector2
	var secured: bool = false
	var pulse: float = 0.0
	var name: String

	func _init(start_pos: Vector2, label: String) -> void:
		pos = start_pos
		name = label

class Beacon:
	var pos: Vector2
	var pulse: float = 0.0

	func _init(start_pos: Vector2) -> void:
		pos = start_pos

var rng := RandomNumberGenerator.new()
var deputies: Array[Deputy] = []
var raiders: Array[Raider] = []
var relays: Array[Relay] = []
var beacons: Array[Beacon] = []
var crater_positions: Array[Vector2] = []
var crater_radii: Array[float] = []
var star_positions: Array[Vector2] = []

var credits: int = 140
var intel: int = 0
var nexus_integrity: float = 100.0
var wave: int = 0
var raid_clock: float = 10.0
var income_clock: float = 0.0
var message_clock: float = 0.0
var build_mode: bool = false
var mission_state: String = "Secure the three Syndicate relays before the Command Nexus falls."
var battle_log: Array[String] = []
var game_over: bool = false
var victory: bool = false
var next_deputy_id: int = 3

var recruit_button := Rect2(994.0, 325.0, 248.0, 50.0)
var beacon_button := Rect2(994.0, 386.0, 248.0, 50.0)
var restart_button := Rect2(994.0, 548.0, 248.0, 50.0)

func _ready() -> void:
	rng.seed = 7252026
	_build_lunar_backdrop()
	deputies.append(Deputy.new(Vector2(470.0, 390.0), "D-01"))
	deputies.append(Deputy.new(Vector2(520.0, 430.0), "D-02"))
	relays.append(Relay.new(Vector2(210.0, 210.0), "RELAY // AURORA"))
	relays.append(Relay.new(Vector2(770.0, 205.0), "RELAY // GRAVITY"))
	relays.append(Relay.new(Vector2(770.0, 565.0), "RELAY // ECLIPSE"))
	battle_log.append("Command Nexus online. Territory scan complete.")
	battle_log.append("Raiders detected beyond crater perimeter.")
	queue_redraw()

func _process(delta: float) -> void:
	if game_over or victory:
		queue_redraw()
		return

	raid_clock -= delta
	income_clock += delta
	message_clock += delta
	if raid_clock <= 0.0:
		_start_raid()
	if income_clock >= 4.0:
		income_clock = 0.0
		var income: int = 6 + beacons.size() * 5
		credits += income
		_log_event("Supply drones delivered +%d credits." % income)

	_update_deputies(delta)
	_update_raiders(delta)
	_update_relays(delta)
	for beacon: Beacon in beacons:
		beacon.pulse += delta

	if nexus_integrity <= 0.0:
		nexus_integrity = 0.0
		game_over = true
		mission_state = "COMMAND NEXUS LOST // THE UNDERWORLD HOLDS THE MOON"
		_log_event("Nexus breach. Redeployment required.")
	elif _secured_relay_count() == relays.size():
		victory = true
		mission_state = "SECTOR SECURED // THE MOON IS TAKING ITS BREATH BACK"
		_log_event("All relays secured. Syndicate signal collapsed.")

	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_event := event as InputEventMouseButton
		var cursor: Vector2 = get_global_mouse_position()
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(cursor)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click(cursor)

func _handle_left_click(cursor: Vector2) -> void:
	if restart_button.has_point(cursor) and (game_over or victory):
		_restart_mission()
		return
	if game_over or victory:
		return
	if recruit_button.has_point(cursor):
		_recruit_deputy()
		return
	if beacon_button.has_point(cursor):
		build_mode = not build_mode
		mission_state = "PLACE A LUNAR BEACON IN THE FIELD." if build_mode else "Beacon construction cancelled."
		return
	if not FIELD.has_point(cursor):
		return
	if build_mode:
		_place_beacon(cursor)
		return

	var found: Deputy = null
	for deputy: Deputy in deputies:
		if deputy.pos.distance_to(cursor) <= 24.0:
			found = deputy
	for deputy: Deputy in deputies:
		deputy.selected = deputy == found
	if found != null:
		mission_state = "%s selected. Right-click in the field to deploy." % found.callsign
	else:
		mission_state = "Select a deputy or command a selected deputy with right-click."

func _handle_right_click(cursor: Vector2) -> void:
	if game_over or victory or not FIELD.has_point(cursor):
		return
	var ordered: int = 0
	for deputy: Deputy in deputies:
		if deputy.selected:
			deputy.target = cursor + Vector2(float(ordered * 18), float((ordered % 2) * 15))
			ordered += 1
	if ordered > 0:
		mission_state = "Deployment route confirmed. Hold the line."

func _recruit_deputy() -> void:
	const COST := 45
	if credits < COST:
		mission_state = "Insufficient credits. A deputy costs %d credits." % COST
		return
	credits -= COST
	var offset := Vector2(rng.randf_range(-38.0, 38.0), rng.randf_range(-38.0, 38.0))
	var label := "D-%02d" % next_deputy_id
	next_deputy_id += 1
	deputies.append(Deputy.new(Vector2(495.0, 408.0) + offset, label))
	_log_event("%s deployed from the Tactical Armory." % label)
	mission_state = "%s joined the lunar watch." % label

func _place_beacon(cursor: Vector2) -> void:
	const COST := 60
	if credits < COST:
		mission_state = "Insufficient credits. A beacon costs %d credits." % COST
		return
	if cursor.distance_to(Vector2(495.0, 408.0)) < 80.0:
		mission_state = "Keep the Command Nexus clear. Build farther into the field."
		return
	credits -= COST
	beacons.append(Beacon.new(cursor))
	build_mode = false
	mission_state = "Lunar Beacon anchored. Credit uplink increased."
	_log_event("Beacon online. Passive income has increased.")

func _update_deputies(delta: float) -> void:
	for deputy: Deputy in deputies:
		deputy.cooldown = maxf(0.0, deputy.cooldown - delta)
		var closest: Raider = _closest_raider(deputy.pos)
		if closest != null and deputy.pos.distance_to(closest.pos) < 145.0:
			if deputy.cooldown <= 0.0:
				closest.hp -= 20.0
				deputy.cooldown = 0.55
				if closest.hp <= 0.0:
					raiders.erase(closest)
					credits += 8
					intel += 1
					_log_event("Raider neutralized. Evidence cache recovered.")
		else:
			var delta_pos: Vector2 = deputy.target - deputy.pos
			if delta_pos.length() > 3.0:
				deputy.pos += delta_pos.normalized() * minf(130.0 * delta, delta_pos.length())

func _update_raiders(delta: float) -> void:
	var nexus_pos := Vector2(495.0, 408.0)
	for raider: Raider in raiders.duplicate():
		raider.cooldown = maxf(0.0, raider.cooldown - delta)
		var nearest_deputy: Deputy = _closest_deputy(raider.pos)
		if nearest_deputy != null and nearest_deputy.pos.distance_to(raider.pos) < 92.0:
			if raider.cooldown <= 0.0:
				nearest_deputy.hp -= 10.0
				raider.cooldown = 1.1
				if nearest_deputy.hp <= 0.0:
					deputies.erase(nearest_deputy)
					_log_event("Deputy down. Tactical Armory requests reinforcements.")
		else:
			var direction := nexus_pos - raider.pos
			if direction.length() > 50.0:
				raider.pos += direction.normalized() * raider.speed * delta
			elif raider.cooldown <= 0.0:
				nexus_integrity -= 5.0
				raider.cooldown = 0.8
				_log_event("Command Nexus struck by a Syndicate raider.")

func _update_relays(delta: float) -> void:
	for relay: Relay in relays:
		relay.pulse += delta
		if relay.secured:
			continue
		for deputy: Deputy in deputies:
			if deputy.pos.distance_to(relay.pos) < 58.0:
				relay.secured = true
				intel += 5
				credits += 25
				mission_state = "%s secured. Intel network restored." % relay.name
				_log_event("%s retaken. +25 credits, +5 intel." % relay.name)
				break

func _start_raid() -> void:
	wave += 1
	raid_clock = maxf(12.0, 24.0 - float(wave) * 1.2)
	var raider_count: int = 2 + wave
	for index: int in range(raider_count):
		var spawn := _raid_spawn_point(index)
		var tint := Color("ff5b93") if index % 2 == 0 else Color("ff934f")
		var speed := 28.0 + float(wave) * 2.5 + rng.randf_range(-3.0, 4.0)
		raiders.append(Raider.new(spawn, tint, speed))
	mission_state = "SYNDICATE RAID %02d INBOUND // Defend the Command Nexus." % wave
	_log_event("Raid %02d crossed the crater perimeter." % wave)

func _raid_spawn_point(index: int) -> Vector2:
	var side: int = (wave + index) % 4
	match side:
		0:
			return Vector2(rng.randf_range(FIELD.position.x + 30.0, FIELD.end.x - 30.0), FIELD.position.y + 15.0)
		1:
			return Vector2(FIELD.end.x - 15.0, rng.randf_range(FIELD.position.y + 30.0, FIELD.end.y - 30.0))
		2:
			return Vector2(rng.randf_range(FIELD.position.x + 30.0, FIELD.end.x - 30.0), FIELD.end.y - 15.0)
		_:
			return Vector2(FIELD.position.x + 15.0, rng.randf_range(FIELD.position.y + 30.0, FIELD.end.y - 30.0))

func _closest_raider(origin: Vector2) -> Raider:
	var result: Raider = null
	var closest_distance := INF
	for raider: Raider in raiders:
		var distance := origin.distance_squared_to(raider.pos)
		if distance < closest_distance:
			closest_distance = distance
			result = raider
	return result

func _closest_deputy(origin: Vector2) -> Deputy:
	var result: Deputy = null
	var closest_distance := INF
	for deputy: Deputy in deputies:
		var distance := origin.distance_squared_to(deputy.pos)
		if distance < closest_distance:
			closest_distance = distance
			result = deputy
	return result

func _secured_relay_count() -> int:
	var count: int = 0
	for relay: Relay in relays:
		if relay.secured:
			count += 1
	return count

func _restart_mission() -> void:
	deputies.clear()
	raiders.clear()
	relays.clear()
	beacons.clear()
	credits = 140
	intel = 0
	nexus_integrity = 100.0
	wave = 0
	raid_clock = 10.0
	income_clock = 0.0
	game_over = false
	victory = false
	build_mode = false
	next_deputy_id = 3
	mission_state = "Secure the three Syndicate relays before the Command Nexus falls."
	deputies.append(Deputy.new(Vector2(470.0, 390.0), "D-01"))
	deputies.append(Deputy.new(Vector2(520.0, 430.0), "D-02"))
	relays.append(Relay.new(Vector2(210.0, 210.0), "RELAY // AURORA"))
	relays.append(Relay.new(Vector2(770.0, 205.0), "RELAY // GRAVITY"))
	relays.append(Relay.new(Vector2(770.0, 565.0), "RELAY // ECLIPSE"))
	battle_log.clear()
	_log_event("Fresh deployment initiated. Command Nexus online.")

func _log_event(entry: String) -> void:
	battle_log.push_front(entry)
	if battle_log.size() > 5:
		battle_log.pop_back()

func _build_lunar_backdrop() -> void:
	for index: int in range(48):
		star_positions.append(Vector2(rng.randf_range(0.0, VIEWPORT_SIZE.x), rng.randf_range(0.0, 90.0)))
	for index: int in range(32):
		crater_positions.append(Vector2(rng.randf_range(FIELD.position.x + 10.0, FIELD.end.x - 10.0), rng.randf_range(FIELD.position.y + 10.0, FIELD.end.y - 10.0)))
		crater_radii.append(rng.randf_range(9.0, 37.0))

func _draw() -> void:
	_draw_space()
	_draw_field()
	_draw_world_objects()
	_draw_sidebar()
	_draw_top_banner()
	if game_over or victory:
		_draw_end_overlay()

func _draw_space() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("07101d"))
	draw_rect(Rect2(0.0, 0.0, VIEWPORT_SIZE.x, 92.0), Color("0b1830"))
	for star: Vector2 in star_positions:
		draw_circle(star, 1.3, Color("afcafc", 0.72))

func _draw_field() -> void:
	draw_style_box(_panel_style(Color("14233a"), Color("38567c"), 2, 14), FIELD)
	draw_rect(FIELD.grow(-3.0), Color("1a2934"))
	for index: int in range(crater_positions.size()):
		var crater_pos := crater_positions[index]
		var radius := crater_radii[index]
		draw_circle(crater_pos, radius, Color("0e1821", 0.55))
		draw_arc(crater_pos, radius * 0.82, 0.0, TAU, 28, Color("42505a", 0.25), 1.0)
	for x: float in range(FIELD.position.x + 24.0, FIELD.end.x, 48.0):
		draw_line(Vector2(x, FIELD.position.y + 8.0), Vector2(x, FIELD.end.y - 8.0), Color("75a2bb", 0.07), 1.0)
	for y: float in range(FIELD.position.y + 24.0, FIELD.end.y, 48.0):
		draw_line(Vector2(FIELD.position.x + 8.0, y), Vector2(FIELD.end.x - 8.0, y), Color("75a2bb", 0.07), 1.0)

func _draw_world_objects() -> void:
	var nexus := Vector2(495.0, 408.0)
	_draw_nexus(nexus)
	for relay: Relay in relays:
		_draw_relay(relay)
	for beacon: Beacon in beacons:
		_draw_beacon(beacon)
	for raider: Raider in raiders:
		_draw_raider(raider)
	for deputy: Deputy in deputies:
		_draw_deputy(deputy)
	if build_mode:
		var cursor := get_global_mouse_position()
		if FIELD.has_point(cursor):
			draw_circle(cursor, 26.0, Color("7ef5d0", 0.12))
			draw_arc(cursor, 26.0, 0.0, TAU, 32, Color("7ef5d0", 0.9), 1.5)

func _draw_nexus(pos: Vector2) -> void:
	draw_circle(pos, 55.0, Color("193451"))
	draw_circle(pos, 47.0, Color("0d202f"))
	for angle: float in [0.0, PI * 0.5, PI, PI * 1.5]:
		var endpoint := pos + Vector2(cos(angle), sin(angle)) * 42.0
		draw_line(pos, endpoint, Color("56dcff", 0.65), 5.0)
	draw_circle(pos, 23.0, Color("65e9ff", 0.92))
	draw_circle(pos, 12.0, Color("ecffff"))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-66.0, 82.0), "COMMAND NEXUS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE_SMALL, Color("bee8ff"))

func _draw_relay(relay: Relay) -> void:
	var pulse_size := 24.0 + sin(relay.pulse * 3.0) * 2.0
	var color := Color("7ef5d0") if relay.secured else Color("ffb15f")
	draw_circle(relay.pos, pulse_size + 7.0, Color(color, 0.10))
	draw_arc(relay.pos, pulse_size, relay.pulse, relay.pulse + PI * 1.35, 20, color, 2.0)
	draw_rect(Rect2(relay.pos - Vector2(12.0, 12.0), Vector2(24.0, 24.0)), color.darkened(0.38), true)
	draw_line(relay.pos + Vector2(-17.0, 0.0), relay.pos + Vector2(17.0, 0.0), color, 2.0)
	draw_line(relay.pos + Vector2(0.0, -17.0), relay.pos + Vector2(0.0, 17.0), color, 2.0)
	var state := "SECURED" if relay.secured else "HOSTILE"
	draw_string(ThemeDB.fallback_font, relay.pos + Vector2(-56.0, 48.0), "%s // %s" % [relay.name, state], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, color)

func _draw_beacon(beacon: Beacon) -> void:
	var energy := 19.0 + sin(beacon.pulse * 4.0) * 3.0
	draw_circle(beacon.pos, energy + 8.0, Color("8095ff", 0.10))
	draw_polygon(PackedVector2Array([beacon.pos + Vector2(0.0, -16.0), beacon.pos + Vector2(14.0, 14.0), beacon.pos + Vector2(-14.0, 14.0)]), PackedColorArray([Color("8397ff")]))
	draw_circle(beacon.pos, 5.0, Color("f4f5ff"))

func _draw_deputy(deputy: Deputy) -> void:
	if deputy.selected:
		draw_arc(deputy.pos, 23.0, 0.0, TAU, 28, Color("8de9ff"), 2.0)
	draw_circle(deputy.pos, 15.0, Color("244e73"))
	draw_circle(deputy.pos, 10.0, Color("82e6ff"))
	draw_line(deputy.pos + Vector2(-5.0, 0.0), deputy.pos + Vector2(11.0, -6.0), Color("e8ffff"), 2.8)
	_draw_health_bar(deputy.pos + Vector2(-16.0, -26.0), deputy.hp / 100.0, Color("61f6bb"))
	draw_string(ThemeDB.fallback_font, deputy.pos + Vector2(-14.0, 31.0), deputy.callsign, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("cff5ff"))

func _draw_raider(raider: Raider) -> void:
	draw_circle(raider.pos, 16.0, Color(raider.tint, 0.2))
	draw_circle(raider.pos, 11.0, raider.tint.darkened(0.25))
	draw_line(raider.pos + Vector2(-7.0, -5.0), raider.pos + Vector2(8.0, 5.0), Color("fff0f4"), 2.0)
	_draw_health_bar(raider.pos + Vector2(-14.0, -23.0), raider.hp / 58.0, raider.tint)

func _draw_health_bar(top_left: Vector2, fraction: float, color: Color) -> void:
	draw_rect(Rect2(top_left, Vector2(32.0, 4.0)), Color("091018"))
	draw_rect(Rect2(top_left + Vector2(1.0, 1.0), Vector2(30.0 * clampf(fraction, 0.0, 1.0), 2.0)), color)

func _draw_sidebar() -> void:
	draw_style_box(_panel_style(Color("101e32"), Color("355777"), 2, 14), SIDEBAR)
	draw_string(ThemeDB.fallback_font, Vector2(994.0, 57.0), "TACTICAL CONSOLE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE_MEDIUM, Color("a7dcff"))
	draw_string(ThemeDB.fallback_font, Vector2(994.0, 80.0), "Operation: TAKE BACK", HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE_SMALL, Color("7494af"))
	_draw_stat_card(Rect2(994.0, 101.0, 118.0, 72.0), "CREDITS", str(credits), Color("ffd47a"))
	_draw_stat_card(Rect2(1124.0, 101.0, 118.0, 72.0), "INTEL", str(intel), Color("a48cff"))
	_draw_stat_card(Rect2(994.0, 184.0, 118.0, 72.0), "DEPUTIES", str(deputies.size()), Color("77e7ff"))
	_draw_stat_card(Rect2(1124.0, 184.0, 118.0, 72.0), "RELAYS", "%d/%d" % [_secured_relay_count(), relays.size()], Color("79f1bf"))
	draw_string(ThemeDB.fallback_font, Vector2(994.0, 283.0), "NEXUS INTEGRITY", HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE_SMALL, Color("99b6cc"))
	draw_rect(Rect2(994.0, 291.0, 248.0, 17.0), Color("07101b"))
	var integrity_color := Color("73f2bd") if nexus_integrity > 45.0 else Color("ff6a7c")
	draw_rect(Rect2(997.0, 294.0, 242.0 * nexus_integrity / 100.0, 11.0), integrity_color)
	_draw_action_button(recruit_button, "RECRUIT DEPUTY", "45 credits", false)
	_draw_action_button(beacon_button, "BUILD LUNAR BEACON", "60 credits", build_mode)
	draw_string(ThemeDB.fallback_font, Vector2(994.0, 466.0), "OPERATION LOG", HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE_SMALL, Color("99b6cc"))
	var log_y := 490.0
	for entry: String in battle_log:
		draw_string(ThemeDB.fallback_font, Vector2(994.0, log_y), "• " + entry, HORIZONTAL_ALIGNMENT_LEFT, 244.0, 12, Color("c4d8e8"))
		log_y += 20.0
	if game_over or victory:
		_draw_action_button(restart_button, "REDEPLOY", "Restart operation", false)
	else:
		draw_string(ThemeDB.fallback_font, Vector2(994.0, 650.0), "Next raid: %0.0fs // Wave %02d" % [raid_clock, wave + 1], HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE_SMALL, Color("8ca7bd"))
		draw_string(ThemeDB.fallback_font, Vector2(994.0, 674.0), "Left-click: select / build   Right-click: move", HORIZONTAL_ALIGNMENT_LEFT, 244.0, 11, Color("66849e"))

func _draw_stat_card(rect: Rect2, label: String, value: String, color: Color) -> void:
	draw_style_box(_panel_style(Color("14283d"), Color(color, 0.36), 1, 8), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 23.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("9fb6c7"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10.0, 56.0), value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26, color)

func _draw_action_button(rect: Rect2, title: String, detail: String, active: bool) -> void:
	var fill := Color("1d5262") if active else Color("162f4a")
	var border := Color("7ef5d0") if active else Color("4e7fa7")
	draw_style_box(_panel_style(fill, border, 2, 8), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(13.0, 22.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("e5f7ff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(13.0, 41.0), detail, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("a5c0d2"))

func _draw_top_banner() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(22.0, 42.0), "MOONGOONS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE_LARGE, Color("e2f6ff"))
	draw_string(ThemeDB.fallback_font, Vector2(22.0, 67.0), "TAKE BACK // LUNAR TERRITORY PROTOTYPE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, Color("7cb1d4"))
	draw_string(ThemeDB.fallback_font, Vector2(392.0, 39.0), "MISSION STATUS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("7ca0be"))
	draw_string(ThemeDB.fallback_font, Vector2(392.0, 63.0), mission_state, HORIZONTAL_ALIGNMENT_LEFT, 540.0, 16, Color("d8eafa"))

func _draw_end_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("020812", 0.75))
	var title := "SECTOR SECURED" if victory else "COMMAND NEXUS LOST"
	var color := Color("7ef5d0") if victory else Color("ff7490")
	draw_style_box(_panel_style(Color("10263b"), color, 3, 16), Rect2(250.0, 230.0, 680.0, 250.0))
	draw_string(ThemeDB.fallback_font, Vector2(360.0, 310.0), title, HORIZONTAL_ALIGNMENT_CENTER, 460.0, 42, color)
	draw_string(ThemeDB.fallback_font, Vector2(340.0, 352.0), mission_state, HORIZONTAL_ALIGNMENT_CENTER, 500.0, 17, Color("e7f4ff"))
	draw_string(ThemeDB.fallback_font, Vector2(340.0, 392.0), "Relays reclaimed: %d/%d     Raiders stopped: %d     Intel: %d" % [_secured_relay_count(), relays.size(), max(0, wave * (wave + 3) / 2 - raiders.size()), intel], HORIZONTAL_ALIGNMENT_CENTER, 500.0, 15, Color("abc5d9"))
	draw_string(ThemeDB.fallback_font, Vector2(340.0, 436.0), "Use the REDEPLOY control to launch another operation.", HORIZONTAL_ALIGNMENT_CENTER, 500.0, 15, Color("8aacbe"))

func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	return box
