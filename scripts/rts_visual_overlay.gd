extends Node2D
## Production art layer for the RTS route.
## Replaces the prototype circle-and-box look with the established MoonGoons skin pack
## while preserving the underlying deterministic RTS simulation and controls.

const VIEW: Vector2 = Vector2(1280.0, 720.0)
const FIELD: Rect2 = Rect2(18.0, 92.0, 938.0, 608.0)
const NEXUS_POSITION: Vector2 = Vector2(490.0, 430.0)
const HIDEOUT_POSITION: Vector2 = Vector2(835.0, 180.0)
const HUB_BUTTON: Rect2 = Rect2(790.0, 20.0, 150.0, 38.0)

var rts: Node2D
var pulse: float = 0.0

func _ready() -> void:
	rts = get_parent() as Node2D
	mouse_filter = Control.MOUSE_FILTER_IGNORE if self is Control else 0
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _input(event: InputEvent) -> void:
	var position: Vector2 = Vector2.ZERO
	var pressed: bool = false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		position = mouse_event.position
		pressed = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		position = touch_event.position
		pressed = touch_event.pressed
	if pressed and HUB_BUTTON.has_point(position):
		get_viewport().set_input_as_handled()
		MoonGoonsAudio.play("confirm")
		get_tree().change_scene_to_file("res://scenes/CampaignRouter.tscn")

func _draw() -> void:
	if rts == null:
		return
	_draw_crater_art()
	_draw_environment_props()
	_draw_resource_art()
	_draw_structure_art()
	_draw_unit_art()
	_draw_enemy_art()
	_draw_clean_header()

func _draw_crater_art() -> void:
	var texture: Texture2D = MoonGoonsSkins.get_texture("crater")
	if texture == null:
		return
	var positions_value: Variant = rts.get("crater_positions")
	var radii_value: Variant = rts.get("crater_radii")
	if not positions_value is Array or not radii_value is Array:
		return
	var positions: Array = positions_value as Array
	var radii: Array = radii_value as Array
	for index: int in range(0, positions.size(), 3):
		if index >= radii.size():
			break
		var center: Vector2 = positions[index] as Vector2
		var radius: float = float(radii[index]) * 1.45
		draw_texture_rect(texture, Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)), false, Color(0.72, 0.80, 0.88, 0.34))

func _draw_environment_props() -> void:
	_draw_skin("cargo_wall", Rect2(96.0, 126.0, 152.0, 100.0), Color(0.72, 0.88, 1.0, 0.54))
	_draw_skin("wrecked_shuttle", Rect2(702.0, 476.0, 170.0, 112.0), Color(0.88, 0.94, 1.0, 0.66))
	_draw_skin("cargo_crate", Rect2(584.0, 286.0, 64.0, 64.0), Color(1.0, 0.88, 0.58, 0.78))
	_draw_skin("command_nexus", Rect2(NEXUS_POSITION - Vector2(78.0, 78.0), Vector2(156.0, 156.0)), Color.WHITE)
	_draw_skin("wrecked_shuttle", Rect2(HIDEOUT_POSITION - Vector2(72.0, 60.0), Vector2(144.0, 120.0)), Color(1.0, 0.42, 0.62, 0.86))

func _draw_resource_art() -> void:
	var resources_value: Variant = rts.get("resource_nodes")
	if not resources_value is Array:
		return
	for resource_value: Variant in resources_value as Array:
		if not resource_value is Object:
			continue
		var resource := resource_value as Object
		var amount: int = int(resource.get("amount"))
		if amount <= 0:
			continue
		var center: Vector2 = resource.get("pos") as Vector2
		var resource_id: String = str(resource.get("resource_id"))
		var skin_name: String = "evidence_cache" if resource_id == "credits" else "ore_deposit"
		var tint: Color = Color(1.0, 0.87, 0.54, 0.96) if resource_id == "credits" else Color(0.76, 0.66, 1.0, 0.96)
		_draw_skin(skin_name, Rect2(center - Vector2(31.0, 31.0), Vector2(62.0, 62.0)), tint)

func _draw_structure_art() -> void:
	var structures_value: Variant = rts.get("structures")
	if not structures_value is Array:
		return
	for structure_value: Variant in structures_value as Array:
		if not structure_value is Object:
			continue
		var structure := structure_value as Object
		var center: Vector2 = structure.get("pos") as Vector2
		var structure_type: String = str(structure.get("structure_type"))
		var complete: bool = bool(structure.get("complete"))
		var skin_name: String = "machine_shop"
		var size: Vector2 = Vector2(76.0, 76.0)
		match structure_type:
			"relay":
				skin_name = "machine_shop"
				size = Vector2(78.0, 72.0)
			"armory":
				skin_name = "tactical_armory"
				size = Vector2(102.0, 86.0)
			"turret":
				skin_name = "sentry_turret"
				size = Vector2(68.0, 68.0)
		var tint: Color = Color.WHITE if complete else Color(0.65, 0.75, 0.82, 0.68)
		_draw_skin(skin_name, Rect2(center - size * 0.5, size), tint)

func _draw_unit_art() -> void:
	var workers_value: Variant = rts.get("workers")
	if workers_value is Array:
		for worker_value: Variant in workers_value as Array:
			if worker_value is Object:
				var worker := worker_value as Object
				var center: Vector2 = worker.get("pos") as Vector2
				_draw_skin("builder_drone", Rect2(center - Vector2(23.0, 23.0), Vector2(46.0, 46.0)), Color.WHITE)
	var units_value: Variant = rts.get("combat_units")
	if units_value is Array:
		for unit_value: Variant in units_value as Array:
			if not unit_value is Object:
				continue
			var unit := unit_value as Object
			var center: Vector2 = unit.get("pos") as Vector2
			var unit_type: String = str(unit.get("unit_type"))
			var skin_name: String = "shield_deputy" if unit_type == "vanguard" else "patrol_deputy"
			var size: Vector2 = Vector2(52.0, 52.0) if unit_type == "vanguard" else Vector2(44.0, 44.0)
			_draw_skin(skin_name, Rect2(center - size * 0.5, size), Color.WHITE)

func _draw_enemy_art() -> void:
	var enemies_value: Variant = rts.get("enemy_units")
	if not enemies_value is Array:
		return
	for enemy_value: Variant in enemies_value as Array:
		if not enemy_value is Object:
			continue
		var enemy := enemy_value as Object
		var center: Vector2 = enemy.get("pos") as Vector2
		var enemy_type: String = str(enemy.get("unit_type"))
		var skin_name: String = "pulse_cannon" if enemy_type == "bruiser" else "sentry_turret"
		var size: Vector2 = Vector2(54.0, 54.0) if enemy_type == "bruiser" else Vector2(42.0, 42.0)
		_draw_skin(skin_name, Rect2(center - size * 0.5, size), Color(1.0, 0.32, 0.56, 0.94))

func _draw_clean_header() -> void:
	draw_rect(Rect2(0.0, 0.0, 960.0, 92.0), Color("071827", 0.985), true)
	draw_line(Vector2(0.0, 91.0), Vector2(960.0, 91.0), Color("66dcff", 0.48), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 34.0), "MOONGOONS TAKE BACK // RTS FRONT", HORIZONTAL_ALIGNMENT_LEFT, 520.0, 23, Color("e9fbff"))
	var mission_state: String = str(rts.get("mission_state"))
	draw_string(ThemeDB.fallback_font, Vector2(24.0, 65.0), mission_state, HORIZONTAL_ALIGNMENT_LEFT, 742.0, 12, Color("a9cfe2"))
	draw_style_box(_panel_style(Color("173a4d", 0.98), Color("7ef5d0"), 2, 8), HUB_BUTTON)
	draw_string(ThemeDB.fallback_font, HUB_BUTTON.position + Vector2(5.0, 25.0), "CAMPAIGN HUB", HORIZONTAL_ALIGNMENT_CENTER, HUB_BUTTON.size.x - 10.0, 10, Color("efffff"))
	var art_status: String = MoonGoonsSkins.status_text()
	draw_string(ThemeDB.fallback_font, Vector2(790.0, 76.0), art_status, HORIZONTAL_ALIGNMENT_CENTER, 150.0, 9, Color("7ef5d0"))

func _draw_skin(skin_name: String, rect: Rect2, tint: Color) -> void:
	var texture: Texture2D = MoonGoonsSkins.get_texture(skin_name)
	if texture == null:
		return
	draw_texture_rect(texture, rect, false, tint)

func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
