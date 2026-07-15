extends Node2D
## Visual skin layer for the precinct management scene.
## It deliberately contains no gameplay input or state mutation.

const ROOM_IDS: Array[String] = ["ops", "armory", "cells", "quarters", "medbay", "chief", "interrogation", "transfer"]
const ROOM_PRIMARY: Dictionary = {
	"ops": "command_nexus",
	"armory": "tactical_armory",
	"cells": "cargo_wall",
	"quarters": "cargo_crate",
	"medbay": "machine_shop",
	"chief": "command_nexus",
	"interrogation": "evidence_cache",
	"transfer": "wrecked_shuttle"
}
const ROOM_SECONDARY: Dictionary = {
	"cells": "evidence_cache",
	"quarters": "cargo_wall",
	"medbay": "builder_drone",
	"chief": "sentry_turret",
	"interrogation": "cargo_wall",
	"transfer": "cargo_wall"
}

var _pulse: float = 0.0

func _ready() -> void:
	z_index = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	if PrecinctState != null and not PrecinctState.state_changed.is_connected(_on_state_changed):
		PrecinctState.state_changed.connect(_on_state_changed)
	queue_redraw()

func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()

func _draw() -> void:
	_draw_room_skins()
	_draw_officer_skins()
	_draw_skin_status()

func _draw_room_skins() -> void:
	for index: int in range(ROOM_IDS.size()):
		var room_id: String = ROOM_IDS[index]
		var column: int = index % 4
		var row: int = index / 4
		var card_position: Vector2 = Vector2(38.0 + float(column) * 208.0, 132.0 + float(row) * 224.0)
		var interior: Rect2 = Rect2(card_position + Vector2(7.0, 7.0), Vector2(180.0, 137.0))
		var room: Dictionary = PrecinctState.get_room(room_id)
		var repaired: bool = bool(room.get("repaired", false))
		var primary_name: String = String(ROOM_PRIMARY.get(room_id, "command_nexus"))
		var tint: Color = _room_tint(room_id, repaired)
		_draw_skin(primary_name, interior, tint)
		if ROOM_SECONDARY.has(room_id):
			var secondary_rect: Rect2 = Rect2(interior.position + Vector2(105.0, 53.0), Vector2(68.0, 76.0))
			_draw_skin(String(ROOM_SECONDARY[room_id]), secondary_rect, Color(1.0, 1.0, 1.0, 0.86 if repaired else 0.48))
		# Add a glass-panel glaze so the imported art feels embedded in the HUD.
		draw_rect(interior, Color(0.02, 0.08, 0.13, 0.10 if repaired else 0.42), true)
		draw_rect(interior, Color(0.38, 0.88, 1.0, 0.22 if repaired else 0.10), false, 1.0)
		if not repaired:
			var warning_alpha: float = 0.10 + (sin(_pulse * 3.0) + 1.0) * 0.035
			draw_rect(interior, Color(0.55, 0.04, 0.13, warning_alpha), true)
			draw_line(interior.position + Vector2(12.0, 14.0), interior.position + Vector2(70.0, 66.0), Color(1.0, 0.38, 0.52, 0.75), 3.0)
			draw_line(interior.position + Vector2(70.0, 66.0), interior.position + Vector2(50.0, 112.0), Color(1.0, 0.38, 0.52, 0.62), 2.0)

func _draw_officer_skins() -> void:
	for index: int in range(PrecinctState.officers.size()):
		var officer: Dictionary = PrecinctState.officers[index]
		var rect: Rect2 = Rect2(914.0, 360.0 + float(index) * 56.0, 326.0, 49.0)
		var portrait_rect: Rect2 = Rect2(rect.position + Vector2(5.0, 5.0), Vector2(40.0, 40.0))
		var class_name: String = String(officer.get("class", "Guard"))
		var skin_name: String = "patrol_deputy"
		var tint: Color = Color.WHITE
		if class_name == "Guard":
			skin_name = "shield_deputy"
		elif class_name == "Biker":
			skin_name = "patrol_deputy"
			tint = Color(0.88, 0.64, 1.0, 1.0)
		elif class_name == "Marksman":
			skin_name = "patrol_deputy"
			tint = Color(1.0, 0.84, 0.48, 1.0)
		if not PrecinctState.officer_available(officer):
			tint = tint.darkened(0.55)
		draw_style_box(_portrait_style(), portrait_rect)
		_draw_skin(skin_name, portrait_rect.grow(-2.0), tint)

func _draw_skin_status() -> void:
	if MoonGoonsSkins == null:
		return
	var text: String = MoonGoonsSkins.status_text()
	var rect: Rect2 = Rect2(1038.0, 64.0, 200.0, 22.0)
	draw_style_box(_badge_style(MoonGoonsSkins.assets_ready()), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(6.0, 15.0), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 12.0, 9, Color("eaffff"))

func _draw_skin(skin_name: String, rect: Rect2, tint: Color) -> void:
	if MoonGoonsSkins == null:
		return
	var texture: Texture2D = MoonGoonsSkins.get_texture(skin_name)
	if texture == null:
		return
	draw_texture_rect(texture, rect, false, tint)

func _room_tint(room_id: String, repaired: bool) -> Color:
	var tint: Color = Color.WHITE
	match room_id:
		"armory": tint = Color(0.88, 0.78, 1.0, 1.0)
		"cells": tint = Color(1.0, 0.78, 0.48, 1.0)
		"quarters": tint = Color(0.72, 0.90, 1.0, 1.0)
		"medbay": tint = Color(0.55, 1.0, 0.82, 1.0)
		"chief": tint = Color(1.0, 0.88, 0.55, 1.0)
		"interrogation": tint = Color(0.75, 0.70, 1.0, 1.0)
		"transfer": tint = Color(0.72, 0.88, 1.0, 1.0)
		_: tint = Color.WHITE
	if not repaired:
		tint = Color(tint.r * 0.48, tint.g * 0.48, tint.b * 0.48, 0.82)
	return tint

func _portrait_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("06111b")
	style.border_color = Color("79dff1", 0.62)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func _badge_style(ready: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("0b2d35") if ready else Color("3a1d27")
	style.border_color = Color("70efcd") if ready else Color("ff8da8")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func _on_state_changed() -> void:
	queue_redraw()
