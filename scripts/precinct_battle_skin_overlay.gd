extends Node2D
## Imported MoonGoons art layer for the tactical patrol scene.

var pulse: float = 0.0

func _ready() -> void:
	z_index = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	_draw_environment()
	_draw_patrol()
	_draw_enemy_art()

func _draw_environment() -> void:
	_draw_skin("crater", Rect2(332.0, 154.0, 170.0, 170.0), Color(0.70, 0.86, 1.0, 0.24))
	_draw_skin("wrecked_shuttle", Rect2(468.0, 358.0, 220.0, 190.0), Color(0.78, 0.86, 1.0, 0.32))
	_draw_skin("cargo_crate", Rect2(338.0, 424.0, 92.0, 92.0), Color(0.95, 0.82, 0.60, 0.38))
	_draw_skin("cargo_wall", Rect2(780.0, 178.0, 128.0, 224.0), Color(1.0, 0.42, 0.58, 0.22))

func _draw_patrol() -> void:
	var battle: Node = get_parent()
	if battle == null:
		return
	var units_value: Variant = battle.get("officer_units")
	if not units_value is Array:
		return
	for unit_value: Variant in units_value as Array:
		if not unit_value is Dictionary:
			continue
		var unit: Dictionary = unit_value as Dictionary
		var center: Vector2 = unit.get("position", Vector2.ZERO) as Vector2
		var hp: int = int(unit.get("hp", 0))
		var role_name: String = String(unit.get("class", "Guard"))
		var skin_name: String = "patrol_deputy"
		var tint: Color = Color.WHITE
		if role_name == "Guard":
			skin_name = "shield_deputy"
		elif role_name == "Biker":
			tint = Color(0.88, 0.64, 1.0, 1.0)
		elif role_name == "Marksman":
			tint = Color(1.0, 0.82, 0.42, 1.0)
		if hp <= 0:
			tint = tint.darkened(0.72)
		if bool(unit.get("covering", false)) and hp > 0:
			draw_circle(center, 52.0 + sin(pulse * 4.0) * 2.0, Color(0.36, 0.92, 1.0, 0.16))
			draw_arc(center, 51.0, -2.6, 0.55, 30, Color(0.65, 0.97, 1.0, 0.84), 4.0)
		_draw_skin(skin_name, Rect2(center + Vector2(-48.0, -52.0), Vector2(96.0, 96.0)), tint)

func _draw_enemy_art() -> void:
	var battle: Node = get_parent()
	if battle == null:
		return
	var hp: int = int(battle.get("enemy_hp"))
	var center: Vector2 = Vector2(717.0, 322.0)
	var alpha: float = 1.0 if hp > 0 else 0.30
	draw_circle(center, 64.0 + sin(pulse * 3.2) * 4.0, Color(1.0, 0.12, 0.32, 0.12 if hp > 0 else 0.03))
	_draw_skin("pulse_cannon", Rect2(center + Vector2(-70.0, -66.0), Vector2(140.0, 140.0)), Color(1.0, 0.22, 0.38, 0.48 * alpha))
	_draw_skin("patrol_deputy", Rect2(center + Vector2(-55.0, -58.0), Vector2(110.0, 110.0)), Color(1.0, 0.22, 0.43, alpha))

func _draw_skin(skin_name: String, rect: Rect2, tint: Color) -> void:
	var texture: Texture2D = MoonGoonsSkins.get_texture(skin_name)
	if texture != null:
		draw_texture_rect(texture, rect, false, tint)
