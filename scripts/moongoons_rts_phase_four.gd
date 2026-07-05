extends "res://scripts/moongoons_rts_phase_three.gd"
## Phase Four: recon, explored terrain, fog of war, and Tactical Scan.

var recon_rules: Dictionary = {}
var explored_cells: Dictionary = {}
var tactical_scan_reveals: Array[Dictionary] = []
var tactical_scan_cooldown: float = 0.0
var scan_button: Rect2 = Rect2(994.0, 610.0, 248.0, 22.0)

func _ready() -> void:
	recon_rules = _load_recon_rules()
	super._ready()
	mission_state = "Expand through the fog, secure Forward Relays, and expose the Syndicate before it exposes you."
	_log_event("Phase Four online: lunar fog, recon radii, and Tactical Scan are active.")
	queue_redraw()

func _reset_match() -> void:
	explored_cells.clear()
	tactical_scan_reveals.clear()
	tactical_scan_cooldown = 0.0
	super._reset_match()

func _process(delta: float) -> void:
	super._process(delta)
	if game_over or victory:
		return
	tactical_scan_cooldown = maxf(0.0, tactical_scan_cooldown - delta)
	_update_tactical_scans(delta)
	queue_redraw()

func _handle_hotkey(keycode: Key) -> void:
	if keycode == KEY_X:
		_activate_tactical_scan(get_global_mouse_position())
		return
	super._handle_hotkey(keycode)

func _handle_left_press(cursor: Vector2) -> void:
	if not game_over and not victory and scan_button.has_point(cursor):
		_activate_tactical_scan(get_global_mouse_position())
		return
	super._handle_left_press(cursor)

func _draw_world() -> void:
	super._draw_world()
	_draw_fog_of_war()
	_draw_tactical_scan_markers()
	_draw_territory_panel()

func _draw_sidebar() -> void:
	super._draw_sidebar()
	_draw_tactical_scan_button()

func _activate_tactical_scan(cursor: Vector2) -> void:
	if game_over or victory:
		return
	if tactical_scan_cooldown > 0.0:
		mission_state = "Tactical Scan recharging: %0.1fs." % tactical_scan_cooldown
		return
	var scan_rules: Dictionary = _tactical_scan_rules()
	var intel_cost: int = int(scan_rules.get("intel_cost", 4))
	if intel < intel_cost:
		mission_state = "Need %d Intel for Tactical Scan. Neutralize Syndicate units to gather more." % intel_cost
		return
	var target: Vector2 = _clamp_to_field(cursor)
	intel -= intel_cost
	tactical_scan_cooldown = float(scan_rules.get("cooldown_seconds", 18.0))
	tactical_scan_reveals.append({
		"center": target,
		"remaining": float(scan_rules.get("duration_seconds", 10.0)),
		"radius": float(scan_rules.get("radius", 170.0))
	})
	mission_state = "Tactical Scan deployed. Syndicate movement is exposed in the target sector."
	_log_event("Tactical Scan spent %d Intel at the lunar coordinate." % intel_cost)

func _update_tactical_scans(delta: float) -> void:
	for index: int in range(tactical_scan_reveals.size() - 1, -1, -1):
		var reveal: Dictionary = tactical_scan_reveals[index]
		var remaining: float = maxf(0.0, float(reveal.get("remaining", 0.0)) - delta)
		if remaining <= 0.0:
			tactical_scan_reveals.remove_at(index)
		else:
			reveal["remaining"] = remaining
			tactical_scan_reveals[index] = reveal

func _draw_fog_of_war() -> void:
	var tile_size: int = maxi(16, int(_fog_rules().get("tile_size", 32)))
	var columns: int = ceili(FIELD.size.x / float(tile_size))
	var rows: int = ceili(FIELD.size.y / float(tile_size))
	var unexplored_opacity: float = float(_fog_rules().get("unexplored_opacity", 0.92))
	var explored_opacity: float = float(_fog_rules().get("explored_opacity", 0.54))
	for row: int in range(rows):
		for column: int in range(columns):
			var tile_position: Vector2 = FIELD.position + Vector2(float(column * tile_size), float(row * tile_size))
			var tile_rect: Rect2 = Rect2(tile_position, Vector2(float(tile_size + 1), float(tile_size + 1)))
			var tile_center: Vector2 = tile_rect.get_center()
			var cell_key: String = "%d:%d" % [column, row]
			var currently_visible: bool = _is_point_visible(tile_center)
			if currently_visible:
				explored_cells[cell_key] = true
				continue
			var opacity: float = explored_opacity if explored_cells.has(cell_key) else unexplored_opacity
			draw_rect(tile_rect, Color("020814", opacity))

func _is_point_visible(point: Vector2) -> bool:
	if point.distance_to(NEXUS_POSITION) <= _fog_radius("command_nexus_vision_radius", 220.0):
		return true
	for worker: Variant in workers:
		if point.distance_to(worker.pos) <= _fog_radius("worker_vision_radius", 100.0):
			return true
	for unit: Variant in combat_units:
		var unit_radius: float = _fog_radius("vanguard_vision_radius", 140.0) if String(unit.unit_type) == "vanguard" else _fog_radius("deputy_vision_radius", 165.0)
		if point.distance_to(unit.pos) <= unit_radius:
			return true
	for structure: Variant in structures:
		if not bool(structure.complete):
			continue
		var structure_radius: float = _structure_vision_radius(String(structure.structure_type))
		if point.distance_to(structure.pos) <= structure_radius:
			return true
	for sector: Variant in territory_sectors:
		if _sector_owner(sector) != "peacekeeper":
			continue
		var sector_radius: float = _fog_radius("secured_sector_vision_radius", 96.0)
		if _is_outpost_online(sector):
			sector_radius += _fog_radius("forward_relay_bonus_vision_radius", 72.0)
		if point.distance_to(sector.pos) <= sector_radius:
			return true
	for reveal: Dictionary in tactical_scan_reveals:
		var scan_center: Vector2 = reveal.get("center", Vector2.ZERO)
		var scan_radius: float = float(reveal.get("radius", 170.0))
		if point.distance_to(scan_center) <= scan_radius:
			return true
	return false

func _structure_vision_radius(structure_type: String) -> float:
	match structure_type:
		"relay":
			return _fog_radius("relay_vision_radius", 185.0)
		"armory":
			return _fog_radius("armory_vision_radius", 125.0)
		"turret":
			return _fog_radius("turret_vision_radius", 150.0)
		_:
			return 80.0

func _draw_tactical_scan_markers() -> void:
	for reveal: Dictionary in tactical_scan_reveals:
		var scan_center: Vector2 = reveal.get("center", Vector2.ZERO)
		var scan_radius: float = float(reveal.get("radius", 170.0))
		var remaining: float = float(reveal.get("remaining", 0.0))
		draw_circle(scan_center, scan_radius, Color("77e7ff", 0.07))
		draw_arc(scan_center, scan_radius, 0.0, TAU, 36, Color("77e7ff", 0.82), 2.0)
		draw_line(scan_center + Vector2(-14.0, 0.0), scan_center + Vector2(14.0, 0.0), Color("dffbff"), 2.0)
		draw_line(scan_center + Vector2(0.0, -14.0), scan_center + Vector2(0.0, 14.0), Color("dffbff"), 2.0)
		draw_string(ThemeDB.fallback_font, scan_center + Vector2(-36.0, -scan_radius - 8.0), "TACTICAL SCAN %0.1fs" % remaining, HORIZONTAL_ALIGNMENT_CENTER, 72.0, 9, Color("9cefff"))

func _draw_tactical_scan_button() -> void:
	var scan_rules: Dictionary = _tactical_scan_rules()
	var intel_cost: int = int(scan_rules.get("intel_cost", 4))
	var ready: bool = tactical_scan_cooldown <= 0.0 and intel >= intel_cost and not game_over and not victory
	var fill: Color = Color("17506a") if ready else Color("132c42")
	var border: Color = Color("76eaff") if ready else Color("476b85")
	draw_style_box(_panel_style(fill, border, 1, 6), scan_button)
	var detail: String = "X  TACTICAL SCAN // %d Intel" % intel_cost
	if tactical_scan_cooldown > 0.0:
		detail = "TACTICAL SCAN RECHARGING // %0.1fs" % tactical_scan_cooldown
	elif intel < intel_cost:
		detail = "X  TACTICAL SCAN // NEED %d INTEL" % intel_cost
	draw_string(ThemeDB.fallback_font, scan_button.position + Vector2(10.0, 15.0), detail, HORIZONTAL_ALIGNMENT_LEFT, 228.0, 10, Color("e6f9ff") if ready else Color("a6c1d2"))

func _fog_radius(key: String, fallback: float) -> float:
	return float(_fog_rules().get(key, fallback))

func _fog_rules() -> Dictionary:
	return recon_rules.get("fog", {}) as Dictionary

func _tactical_scan_rules() -> Dictionary:
	return recon_rules.get("tactical_scan", {}) as Dictionary

func _clamp_to_field(position: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, FIELD.position.x + 1.0, FIELD.end.x - 1.0),
		clampf(position.y, FIELD.position.y + 1.0, FIELD.end.y - 1.0)
	)

func _load_recon_rules() -> Dictionary:
	var path: String = "res://data/rts_phase_four_recon.json"
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
