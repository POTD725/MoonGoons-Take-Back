extends "res://scripts/moongoons_rts_phase_five.gd"
## Phase Six: command interface and debug-only developer console.
## F1 opens the console in debug/editor builds. Release builds keep it disabled by default.

const DEV_CONSOLE_RECT := Rect2(106.0, 112.0, 824.0, 322.0)

var devtool_rules: Dictionary = {}
var developer_console_enabled: bool = false
var developer_console_open: bool = false
var developer_console_buffer: String = ""
var developer_console_history: Array[String] = []

func _ready() -> void:
	devtool_rules = _load_devtool_rules()
	developer_console_enabled = _developer_console_allowed()
	super._ready()
	if developer_console_enabled:
		_console_write("Developer console ready. Press F1 to open. Type help for commands.")
	queue_redraw()

func _reset_match() -> void:
	super._reset_match()
	if developer_console_enabled:
		_console_write("Simulation reset.")

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_F1 and developer_console_enabled:
				_toggle_developer_console()
				return
			if developer_console_open:
				_handle_developer_console_key(key_event)
				return
	if developer_console_open:
		return
	super._input(event)

func _draw() -> void:
	super._draw()
	if developer_console_open:
		_draw_developer_console()

func _toggle_developer_console() -> void:
	developer_console_open = not developer_console_open
	if developer_console_open:
		_console_write("Developer console opened. Cheats are active only in this debug-enabled session.")
	else:
		_console_write("Developer console closed.")
	queue_redraw()

func _handle_developer_console_key(key_event: InputEventKey) -> void:
	if key_event.keycode == KEY_ESCAPE:
		developer_console_open = false
		queue_redraw()
		return
	if key_event.keycode == KEY_ENTER:
		_execute_developer_command()
		return
	if key_event.keycode == KEY_BACKSPACE:
		if not developer_console_buffer.is_empty():
			developer_console_buffer = developer_console_buffer.substr(0, developer_console_buffer.length() - 1)
		queue_redraw()
		return
	if key_event.unicode >= 32 and key_event.unicode <= 126:
		var character: String = String.chr(key_event.unicode)
		if developer_console_buffer.length() < _max_command_length():
			developer_console_buffer += character
		queue_redraw()

func _execute_developer_command() -> void:
	var entered_command: String = developer_console_buffer.strip_edges()
	developer_console_buffer = ""
	if entered_command.is_empty():
		queue_redraw()
		return
	_console_write("> %s" % entered_command)
	var tokens: PackedStringArray = entered_command.to_lower().split(" ", false)
	if tokens.is_empty():
		return
	var command: String = tokens[0]
	match command:
		"help":
			_console_help()
		"status":
			_console_status()
		"credits":
			credits = maxi(0, credits + _integer_argument(tokens, 1, 0))
			_console_write("Credits set to %d." % credits)
		"alloy":
			lunar_alloy = maxi(0, lunar_alloy + _integer_argument(tokens, 1, 0))
			_console_write("Lunar Alloy set to %d." % lunar_alloy)
		"intel":
			intel = maxi(0, intel + _integer_argument(tokens, 1, 0))
			_console_write("Intel set to %d." % intel)
		"capacity":
			command_max = maxi(1, command_max + _integer_argument(tokens, 1, 0))
			_console_write("Command Capacity is now %d." % command_max)
		"spawn":
			_console_spawn(tokens)
		"wave":
			super._spawn_enemy_wave()
			_console_write("Syndicate wave forced.")
		"siphon":
			_deploy_siphon_raid()
			_console_write("Siphon Raid deployment requested.")
		"capture":
			_console_capture(tokens)
		"reveal":
			_console_reveal(tokens)
		"heal":
			_console_heal()
		"clear":
			_console_clear_enemies()
		"win":
			syndicate_hideout_hp = 0.0
			_console_write("Syndicate Hideout integrity set to zero.")
		"lose":
			nexus_integrity = 0.0
			_console_write("Command Nexus integrity set to zero.")
		"restart":
			_reset_match()
			_console_write("RTS match restarted.")
		"close":
			developer_console_open = false
			_console_write("Developer console closed.")
		_:
			_console_write("Unknown command: %s. Type help." % command)
	queue_redraw()

func _console_help() -> void:
	_console_write("help | status | credits <amount> | alloy <amount> | intel <amount> | capacity <amount>")
	_console_write("spawn <worker|deputy|vanguard> [count] | wave | siphon | capture all | reveal [seconds]")
	_console_write("heal | clear | win | lose | restart | close")

func _console_status() -> void:
	_console_write("Credits %d | Alloy %d | Intel %d | Capacity %d/%d" % [credits, lunar_alloy, intel, command_used, command_max])
	_console_write("Workers %d | Army %d | Enemies %d | Sectors %d/%d | Siphons %d" % [workers.size(), combat_units.size(), enemy_units.size(), captured_sector_count, territory_sectors.size(), siphon_operations.size()])

func _console_spawn(tokens: PackedStringArray) -> void:
	if tokens.size() < 2:
		_console_write("Usage: spawn <worker|deputy|vanguard> [count]")
		return
	var unit_type: String = tokens[1]
	var requested_count: int = clampi(_integer_argument(tokens, 2, 1), 1, 20)
	match unit_type:
		"worker", "deputy", "vanguard":
			for index: int in range(requested_count):
				var spawn_position: Vector2 = NEXUS_POSITION + Vector2(64.0 + float(index % 5) * 14.0, 52.0 + float(index / 5) * 14.0)
				_dev_spawn_unit(unit_type, spawn_position)
			_console_write("Spawned %d %s unit(s)." % [requested_count, unit_type])
		_:
			_console_write("Unknown spawn unit: %s." % unit_type)

func _dev_spawn_unit(unit_type: String, spawn_position: Vector2) -> void:
	match unit_type:
		"worker":
			command_max = maxi(command_max, command_used + WORKER_CAPACITY)
			command_used += WORKER_CAPACITY
			_spawn_worker(spawn_position)
		"vanguard":
			command_max = maxi(command_max, command_used + VANGUARD_CAPACITY)
			command_used += VANGUARD_CAPACITY
			_spawn_combat_unit("vanguard", spawn_position)
		_:
			command_max = maxi(command_max, command_used + DEPUTY_CAPACITY)
			command_used += DEPUTY_CAPACITY
			_spawn_combat_unit("deputy", spawn_position)

func _console_capture(tokens: PackedStringArray) -> void:
	if tokens.size() < 2 or tokens[1] != "all":
		_console_write("Usage: capture all")
		return
	var captured_count: int = 0
	for sector: Variant in territory_sectors:
		var previous_owner: String = _sector_owner(sector)
		sector.control = 1.0
		if previous_owner != "peacekeeper":
			_handle_sector_owner_change(sector, previous_owner, "peacekeeper")
			captured_count += 1
	_console_write("Captured %d sector(s) for the Peacekeepers." % captured_count)

func _console_reveal(tokens: PackedStringArray) -> void:
	var duration: float = clampf(float(_integer_argument(tokens, 1, 20)), 1.0, 600.0)
	tactical_scan_reveals.append({
		"center": FIELD.get_center(),
		"remaining": duration,
		"radius": 1200.0
	})
	_console_write("Full battlefield reveal enabled for %0.0f seconds." % duration)

func _console_heal() -> void:
	nexus_integrity = 1500.0
	for worker: Variant in workers:
		worker.hp = 55.0
	for unit: Variant in combat_units:
		unit.hp = unit.max_hp
	for structure: Variant in structures:
		structure.hp = structure.max_hp
	_console_write("Command Nexus, units, workers, and structures restored.")

func _console_clear_enemies() -> void:
	var cleared_count: int = enemy_units.size()
	for enemy: Variant in enemy_units.duplicate():
		_remove_enemy(enemy)
	_console_write("Cleared %d Syndicate unit(s)." % cleared_count)

func _integer_argument(tokens: PackedStringArray, index: int, fallback: int) -> int:
	if index >= tokens.size():
		return fallback
	var text: String = tokens[index]
	return text.to_int() if text.is_valid_int() else fallback

func _console_write(message: String) -> void:
	developer_console_history.append(message)
	while developer_console_history.size() > _max_history_lines():
		developer_console_history.pop_front()

func _max_history_lines() -> int:
	return maxi(4, int(_developer_console_config().get("max_history_lines", 8)))

func _max_command_length() -> int:
	return maxi(32, int(_developer_console_config().get("max_command_length", 96)))

func _draw_developer_console() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("00040b", 0.46))
	draw_style_box(_panel_style(Color("071827", 0.97), Color("73e9ff"), 2, 10), DEV_CONSOLE_RECT)
	draw_string(ThemeDB.fallback_font, DEV_CONSOLE_RECT.position + Vector2(18.0, 29.0), "MOONGOONS TAKE BACK // DEVELOPER CONSOLE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color("a6f4ff"))
	draw_string(ThemeDB.fallback_font, DEV_CONSOLE_RECT.position + Vector2(18.0, 49.0), "DEBUG SESSION // F1 or ESC closes // commands affect only this running match", HORIZONTAL_ALIGNMENT_LEFT, 780.0, 10, Color("79aac4"))
	var line_y: float = DEV_CONSOLE_RECT.position.y + 77.0
	for line: String in developer_console_history:
		draw_string(ThemeDB.fallback_font, Vector2(DEV_CONSOLE_RECT.position.x + 18.0, line_y), line, HORIZONTAL_ALIGNMENT_LEFT, 780.0, 12, Color("d9f6ff"))
		line_y += 22.0
	draw_rect(Rect2(DEV_CONSOLE_RECT.position + Vector2(16.0, DEV_CONSOLE_RECT.size.y - 48.0), Vector2(792.0, 31.0)), Color("0c2940"))
	draw_string(ThemeDB.fallback_font, DEV_CONSOLE_RECT.position + Vector2(25.0, DEV_CONSOLE_RECT.size.y - 27.0), "> " + developer_console_buffer + "_", HORIZONTAL_ALIGNMENT_LEFT, 770.0, 14, Color("f1ffff"))

func _developer_console_allowed() -> bool:
	var config: Dictionary = _developer_console_config()
	if not bool(config.get("enabled", true)):
		return false
	return OS.is_debug_build() or bool(config.get("allow_release", false))

func _developer_console_config() -> Dictionary:
	return devtool_rules.get("developer_console", {}) as Dictionary

func _load_devtool_rules() -> Dictionary:
	var path: String = "res://data/rts_phase_six_devtools.json"
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
