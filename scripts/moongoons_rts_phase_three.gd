extends "res://scripts/moongoons_rts_phase_two.gd"
## Phase Three: territory capture, forward relay operations, and expansion pressure.

class TerritorySector:
	var id: String
	var display_name: String
	var description: String
	var pos: Vector2
	var resource_id: String
	var income_amount: int
	var income_interval_seconds: float
	var control: float = 0.0
	var income_clock: float = 0.0
	var capture_announced: bool = false

	func _init(definition: Dictionary) -> void:
		id = String(definition.get("id", "unknown_sector"))
		display_name = String(definition.get("display_name", id))
		description = String(definition.get("description", ""))
		var position_values: Array = definition.get("position", [0.0, 0.0]) as Array
		var x_position: float = float(position_values[0]) if position_values.size() > 0 else 0.0
		var y_position: float = float(position_values[1]) if position_values.size() > 1 else 0.0
		pos = Vector2(x_position, y_position)
		resource_id = String(definition.get("resource", "credits"))
		income_amount = int(definition.get("income_amount", 0))
		income_interval_seconds = float(definition.get("income_interval_seconds", 5.0))

var territory_rules: Dictionary = {}
var territory_sectors: Array[TerritorySector] = []
var captured_sector_count: int = 0
var outpost_count: int = 0

func _ready() -> void:
	territory_rules = _load_territory_rules()
	super._ready()
	_initialize_territories()
	mission_state = "Secure hostile sectors, establish forward relays, and dismantle the Syndicate hideout."
	_log_event("Phase Three online: territorial relays can now be captured and fortified.")
	queue_redraw()

func _reset_match() -> void:
	super._reset_match()
	if not territory_rules.is_empty():
		_initialize_territories()

func _process(delta: float) -> void:
	super._process(delta)
	if game_over or victory:
		return
	_update_territories(delta)
	queue_redraw()

func _draw_world() -> void:
	_draw_territory_zones()
	super._draw_world()
	_draw_territory_panel()

func _initialize_territories() -> void:
	territory_sectors.clear()
	captured_sector_count = 0
	outpost_count = 0
	var definitions: Array = territory_rules.get("territories", []) as Array
	for entry: Variant in definitions:
		if entry is Dictionary:
			territory_sectors.append(TerritorySector.new(entry as Dictionary))

func _update_territories(delta: float) -> void:
	captured_sector_count = 0
	outpost_count = 0
	for sector: TerritorySector in territory_sectors:
		var owner_before: String = _sector_owner(sector)
		var friendly_count: int = _friendly_units_in_sector(sector)
		var hostile_count: int = _hostile_units_in_sector(sector)
		var capture_delta: float = _capture_rate_per_unit() * delta
		if friendly_count > 0 and hostile_count == 0:
			sector.control = clampf(sector.control + capture_delta * float(friendly_count), 0.0, 1.0)
		elif hostile_count > 0 and friendly_count == 0:
			sector.control = clampf(sector.control - capture_delta * float(hostile_count), 0.0, 1.0)
		var owner_after: String = _sector_owner(sector)
		if owner_before != owner_after:
			_handle_sector_owner_change(sector, owner_before, owner_after)
		if owner_after == "peacekeeper":
			captured_sector_count += 1
			var outpost_online: bool = _is_outpost_online(sector)
			if outpost_online:
				outpost_count += 1
			_update_sector_income(sector, outpost_online, delta)

func _handle_sector_owner_change(sector: TerritorySector, previous_owner: String, new_owner: String) -> void:
	if new_owner == "peacekeeper":
		sector.capture_announced = true
		mission_state = "%s secured. A forward relay here will double its sector income." % sector.display_name
		_log_event("%s secured for the Lunar Peacekeepers." % sector.display_name)
		_schedule_counter_raid()
	elif previous_owner == "peacekeeper":
		mission_state = "%s has fallen back under Syndicate influence." % sector.display_name
		_log_event("Territory lost: %s." % sector.display_name)

func _update_sector_income(sector: TerritorySector, outpost_online: bool, delta: float) -> void:
	sector.income_clock += delta
	if sector.income_clock < sector.income_interval_seconds:
		return
	sector.income_clock = 0.0
	var multiplier: float = _outpost_income_multiplier() if outpost_online else 1.0
	var income: int = int(float(sector.income_amount) * multiplier)
	if sector.resource_id == "lunar_alloy":
		lunar_alloy += income
	else:
		credits += income
	var outpost_label: String = " with Forward Relay bonus" if outpost_online else ""
	_log_event("%s delivered +%d %s%s." % [sector.display_name, income, _sector_resource_label(sector.resource_id), outpost_label])

func _schedule_counter_raid() -> void:
	var controlled_count: int = _count_controlled_sectors()
	var configured_delay: float = 5.0
	match controlled_count:
		1:
			configured_delay = float(_capture_rules().get("first_capture_enemy_wave_delay", 5.0))
		2:
			configured_delay = float(_capture_rules().get("second_capture_enemy_wave_delay", 4.0))
		_:
			configured_delay = float(_capture_rules().get("third_capture_enemy_wave_delay", 3.0))
	enemy_spawn_clock = minf(enemy_spawn_clock, configured_delay)
	_log_event("Syndicate counter-raid detected. Hold the new sector.")

func _friendly_units_in_sector(sector: TerritorySector) -> int:
	var count: int = 0
	for unit: Variant in combat_units:
		if unit.pos.distance_to(sector.pos) <= _capture_radius():
			count += 1
	return count

func _hostile_units_in_sector(sector: TerritorySector) -> int:
	var count: int = 0
	for enemy: Variant in enemy_units:
		if enemy.pos.distance_to(sector.pos) <= _capture_radius():
			count += 1
	return count

func _is_outpost_online(sector: TerritorySector) -> bool:
	for structure: Variant in structures:
		if String(structure.structure_type) == "relay" and bool(structure.complete):
			if structure.pos.distance_to(sector.pos) <= _relay_outpost_radius():
				return true
	return false

func _sector_owner(sector: TerritorySector) -> String:
	if sector.control >= 0.99:
		return "peacekeeper"
	if sector.control <= 0.01:
		return "syndicate"
	return "contested"

func _count_controlled_sectors() -> int:
	var count: int = 0
	for sector: TerritorySector in territory_sectors:
		if _sector_owner(sector) == "peacekeeper":
			count += 1
	return count

func _capture_radius() -> float:
	return float(_capture_rules().get("radius", 76.0))

func _relay_outpost_radius() -> float:
	return float(_capture_rules().get("relay_outpost_radius", 108.0))

func _capture_rate_per_unit() -> float:
	return float(_capture_rules().get("capture_rate_per_unit", 0.08))

func _outpost_income_multiplier() -> float:
	return float(_capture_rules().get("outpost_income_multiplier", 2.0))

func _capture_rules() -> Dictionary:
	return territory_rules.get("capture_rules", {}) as Dictionary

func _sector_resource_label(resource_id: String) -> String:
	return "Lunar Alloy" if resource_id == "lunar_alloy" else "Credits"

func _draw_territory_zones() -> void:
	for sector: TerritorySector in territory_sectors:
		var control_color: Color = _territory_color(sector)
		var radius: float = _capture_radius()
		draw_circle(sector.pos, radius, Color(control_color, 0.08))
		draw_arc(sector.pos, radius, 0.0, TAU, 32, Color(control_color, 0.54), 1.5)
		if sector.control > 0.0:
			draw_arc(sector.pos, radius + 4.0, -PI * 0.5, -PI * 0.5 + TAU * sector.control, 32, control_color, 3.0)
		var owner_label: String = _sector_owner(sector).to_upper()
		draw_string(ThemeDB.fallback_font, sector.pos + Vector2(-56.0, -radius - 14.0), sector.display_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 112.0, 10, control_color)
		draw_string(ThemeDB.fallback_font, sector.pos + Vector2(-50.0, radius + 20.0), "%s // %s" % [owner_label, _sector_resource_label(sector.resource_id)], HORIZONTAL_ALIGNMENT_CENTER, 100.0, 9, Color("d7ebf8"))
		if _is_outpost_online(sector):
			draw_circle(sector.pos + Vector2(0.0, -12.0), 7.0, Color("7ef5d0"))
			draw_string(ThemeDB.fallback_font, sector.pos + Vector2(-38.0, radius + 34.0), "FORWARD RELAY x2", HORIZONTAL_ALIGNMENT_CENTER, 76.0, 8, Color("7ef5d0"))

func _draw_territory_panel() -> void:
	var panel: Rect2 = Rect2(34.0, 612.0, 402.0, 68.0)
	draw_style_box(_panel_style(Color("0e2338", 0.93), Color("4b789a"), 1, 8), panel)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12.0, 19.0), "TERRITORY CONTROL", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("a8cae2"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12.0, 39.0), "Sectors %d/%d    Forward Relays %d    Capture with combat units" % [captured_sector_count, territory_sectors.size(), outpost_count], HORIZONTAL_ALIGNMENT_LEFT, 376.0, 11, Color("e3f4ff"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(12.0, 57.0), "A completed Communications Relay inside a secured sector doubles its income.", HORIZONTAL_ALIGNMENT_LEFT, 376.0, 9, Color("86a9c2"))

func _territory_color(sector: TerritorySector) -> Color:
	match _sector_owner(sector):
		"peacekeeper":
			return Color("7ef5d0")
		"contested":
			return Color("ffd470")
		_:
			return Color("ff7094")

func _load_territory_rules() -> Dictionary:
	var path: String = "res://data/rts_phase_three_territories.json"
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
