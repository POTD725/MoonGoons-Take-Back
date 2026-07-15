extends Node2D
## Front door for the current MoonGoons Take Back play surfaces.

const VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)
const SYNDICATE_EMBLEM: Texture2D = preload("res://assets/syndicate/syndicate_emblem.svg")

var card_rects: Dictionary = {
	"syndicate": Rect2(58.0, 190.0, 360.0, 420.0),
	"precinct": Rect2(460.0, 190.0, 360.0, 420.0),
	"rts": Rect2(862.0, 190.0, 360.0, 420.0)
}
var sound_rect: Rect2 = Rect2(1090.0, 105.0, 132.0, 34.0)
var pulse: float = 0.0
var status_message: String = "Choose whose boots hit the lunar dust first."

func _ready() -> void:
	SyndicateAudio.play_music("hideout")

func _process(delta: float) -> void:
	pulse += delta
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
	if not pressed:
		return
	if sound_rect.has_point(position):
		var muted: bool = SyndicateAudio.toggle_muted()
		status_message = "Audio muted." if muted else "Audio restored."
		queue_redraw()
		return
	for route_value: Variant in card_rects.keys():
		var route: String = String(route_value)
		var rect: Rect2 = card_rects[route] as Rect2
		if rect.has_point(position):
			SyndicateAudio.play_sfx("accept")
			_open_route(route)
			return

func _open_route(route: String) -> void:
	match route:
		"syndicate":
			if not SyndicateState.intro_seen or not SyndicateState.pending_cutscene.is_empty():
				get_tree().change_scene_to_file("res://scenes/SyndicateCutscene.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/SyndicateHideout.tscn")
		"precinct":
			get_tree().change_scene_to_file("res://scenes/PrecinctVerticalSlice.tscn")
		"rts":
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
		_:
			status_message = "That route is not wired yet."

func _draw() -> void:
	_draw_backdrop()
	_draw_header()
	_draw_card("syndicate", "SYNDICATE RISING", "CRIMINAL CAMPAIGN", ["Illustrated story cutscenes", "Rebuild and upgrade eight rooms", "Run scores, level crew, manage Heat"], Color("ff5d8f"), Color("9f46ff"))
	_draw_card("precinct", "PRECINCT DUTY", "PEACEKEEPER CAMPAIGN", ["Restore the lunar station", "Answer district distress calls", "Arrest Syndicate operators"], Color("5fe5ff"), Color("2779ff"))
	_draw_card("rts", "TAKE BACK FRONT", "STORY RTS", ["Build a Command Nexus", "Capture lunar territories", "Fight the fixed Act I campaign"], Color("ffd36a"), Color("ff7a3d"))
	draw_style_box(_panel_style(Color("171326"), Color("7d7095"), 1, 7), sound_rect)
	var audio_label: String = "AUDIO OFF" if SyndicateAudio.muted else "AUDIO ON"
	draw_string(ThemeDB.fallback_font, sound_rect.position + Vector2(3.0, 22.0), audio_label, HORIZONTAL_ALIGNMENT_CENTER, sound_rect.size.x - 6.0, 10, Color("eef8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(64.0, 677.0), status_message, HORIZONTAL_ALIGNMENT_LEFT, 760.0, 13, Color("aebdca"))
	draw_string(ThemeDB.fallback_font, Vector2(930.0, 677.0), "TAP A CAMPAIGN CARD TO PLAY", HORIZONTAL_ALIGNMENT_RIGHT, 290.0, 12, Color("eef8ff"))

func _draw_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("05040c"))
	for index: int in range(115):
		var x: float = fmod(float(index * 113 + 31), VIEWPORT_SIZE.x)
		var y: float = fmod(float(index * 67 + 19), VIEWPORT_SIZE.y)
		var glow: Color = Color("9ab9ff", 0.15 + float(index % 3) * 0.04)
		draw_circle(Vector2(x, y), 0.8 + float(index % 3) * 0.45, glow)
	draw_circle(Vector2(1108.0, 75.0), 122.0, Color("bea3ff", 0.045))
	draw_circle(Vector2(1108.0, 75.0), 84.0, Color("fff0dc", 0.035))
	for ring: int in range(4):
		draw_arc(Vector2(1108.0, 75.0), 94.0 + float(ring) * 18.0, 0.15, 2.8, 64, Color("a86cff", 0.07), 2.0)

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, VIEWPORT_SIZE.x, 142.0), Color("0d1020", 0.92), true)
	draw_string(ThemeDB.fallback_font, Vector2(52.0, 52.0), "MOONGOONS TAKE BACK", HORIZONTAL_ALIGNMENT_LEFT, 650.0, 31, Color("f4fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(54.0, 86.0), "THE MOON HAS TWO SIDES. ORDER OWNS ONE. THE UNDERWORLD WANTS THE OTHER.", HORIZONTAL_ALIGNMENT_LEFT, 820.0, 14, Color("c3a9ff"))
	draw_string(ThemeDB.fallback_font, Vector2(54.0, 116.0), "CAMPAIGN ROUTER // ORIGINAL MOONGOONS ART, AUDIO, AND GAMEPLAY", HORIZONTAL_ALIGNMENT_LEFT, 760.0, 11, Color("73859a"))
	draw_line(Vector2(0.0, 141.0), Vector2(VIEWPORT_SIZE.x, 141.0), Color("aa72ff", 0.46), 2.0)

func _draw_card(route: String, title: String, subtitle: String, bullets: Array[String], primary: Color, secondary: Color) -> void:
	var rect: Rect2 = card_rects[route] as Rect2
	var breathe: float = 0.08 + sin(pulse * 1.7 + rect.position.x * 0.01) * 0.025
	draw_style_box(_panel_style(Color("101322", 0.97), primary.lightened(0.08), 2, 18), rect)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 128.0)), Color(primary, 0.11 + breathe), true)
	draw_line(rect.position + Vector2(0.0, 128.0), rect.position + Vector2(rect.size.x, 128.0), Color(primary, 0.45), 2.0)
	_draw_faction_emblem(route, rect.position + Vector2(180.0, 72.0), primary, secondary)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(18.0, 167.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 36.0, 22, Color("f7fbff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(18.0, 193.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 36.0, 11, primary.lightened(0.18))
	for index: int in range(bullets.size()):
		var y: float = rect.position.y + 237.0 + float(index) * 39.0
		draw_circle(Vector2(rect.position.x + 31.0, y - 4.0), 4.0, primary)
		draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 46.0, y), bullets[index], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 68.0, 12, Color("b8c7d4"))
	var button_rect: Rect2 = Rect2(rect.position + Vector2(24.0, 360.0), Vector2(rect.size.x - 48.0, 42.0))
	draw_style_box(_panel_style(Color(primary, 0.20), primary, 2, 9), button_rect)
	draw_string(ThemeDB.fallback_font, button_rect.position + Vector2(4.0, 27.0), "ENTER CAMPAIGN", HORIZONTAL_ALIGNMENT_CENTER, button_rect.size.x - 8.0, 11, Color("ffffff"))

func _draw_faction_emblem(route: String, center: Vector2, primary: Color, secondary: Color) -> void:
	if route == "syndicate":
		draw_texture_rect(SYNDICATE_EMBLEM, Rect2(center - Vector2(48.0, 48.0), Vector2(96.0, 96.0)), false)
		return
	draw_circle(center, 48.0, Color("060811", 0.88))
	draw_arc(center, 49.0, 0.0, TAU, 48, primary, 3.0)
	draw_arc(center, 39.0, 0.0, TAU, 48, Color(secondary, 0.68), 2.0)
	if route == "precinct":
		draw_polygon(PackedVector2Array([center + Vector2(0.0, -34.0), center + Vector2(30.0, -18.0), center + Vector2(24.0, 20.0), center + Vector2(0.0, 35.0), center + Vector2(-24.0, 20.0), center + Vector2(-30.0, -18.0)]), PackedColorArray([Color(primary, 0.34)]))
		draw_line(center + Vector2(0.0, -20.0), center + Vector2(0.0, 20.0), primary, 6.0)
		draw_line(center + Vector2(-18.0, 0.0), center + Vector2(18.0, 0.0), primary, 6.0)
	else:
		for angle_index: int in range(8):
			var angle: float = float(angle_index) * TAU / 8.0
			draw_line(center + Vector2.from_angle(angle) * 13.0, center + Vector2.from_angle(angle) * 34.0, primary, 5.0)
		draw_circle(center, 16.0, secondary)

func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
