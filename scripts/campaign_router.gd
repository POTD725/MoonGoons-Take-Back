extends Node2D
## Optional campaign selector. The game now starts in the living precinct,
## while this screen uses real MoonGoons art instead of procedural emblems.

const VIEWPORT_SIZE: Vector2 = Vector2(1280.0, 720.0)
const SYNDICATE_EMBLEM: Texture2D = preload("res://assets/syndicate/syndicate_emblem.svg")

var card_rects: Dictionary = {
	"syndicate": Rect2(40.0, 164.0, 380.0, 470.0),
	"precinct": Rect2(450.0, 164.0, 380.0, 470.0),
	"rts": Rect2(860.0, 164.0, 380.0, 470.0)
}
var sound_rect: Rect2 = Rect2(1090.0, 105.0, 132.0, 34.0)
var pulse: float = 0.0
var status_message: String = "Choose a MoonGoons campaign."
var art: Dictionary = {}

func _ready() -> void:
	_load_campaign_art()
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
		MoonGoonsAudio.set_ambience_enabled(not muted)
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
			get_tree().change_scene_to_file("res://scenes/LivingPrecinct.tscn")
		"rts":
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
		_:
			status_message = "That route is not wired yet."

func _draw() -> void:
	_draw_backdrop()
	_draw_header()
	_draw_card("syndicate", "SYNDICATE RISING", "CRIMINAL CAMPAIGN", ["Illustrated story cutscenes", "Rebuild and upgrade eight rooms", "Run scores, level crew, manage Heat"], Color("ff5d8f"), Color("9f46ff"))
	_draw_card("precinct", "PRECINCT DUTY", "PEACEKEEPER CAMPAIGN", ["Explore a living 3D lunar precinct", "Post walking officers to working rooms", "Patrol districts and arrest operators"], Color("5fe5ff"), Color("2779ff"))
	_draw_card("rts", "TAKE BACK FRONT", "STORY RTS", ["Build a Command Nexus", "Capture lunar territories", "Fight the fixed Act I campaign"], Color("ffd36a"), Color("ff7a3d"))
	draw_style_box(_panel_style(Color("171326"), Color("7d7095"), 1, 7), sound_rect)
	var audio_label: String = "AUDIO OFF" if SyndicateAudio.muted else "AUDIO ON"
	draw_string(ThemeDB.fallback_font, sound_rect.position + Vector2(3.0, 22.0), audio_label, HORIZONTAL_ALIGNMENT_CENTER, sound_rect.size.x - 6.0, 10, Color("eef8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(46.0, 684.0), status_message, HORIZONTAL_ALIGNMENT_LEFT, 760.0, 13, Color("aebdca"))
	draw_string(ThemeDB.fallback_font, Vector2(930.0, 684.0), "TAP A CAMPAIGN IMAGE TO PLAY", HORIZONTAL_ALIGNMENT_RIGHT, 300.0, 12, Color("eef8ff"))

func _draw_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("030711"))
	var crater: Texture2D = art.get("crater") as Texture2D
	if crater != null:
		for x_index: int in range(5):
			for y_index: int in range(3):
				var tile_rect := Rect2(float(x_index) * 290.0 - 70.0, float(y_index) * 250.0 + 40.0, 310.0, 260.0)
				draw_texture_rect(crater, tile_rect, false, Color(0.28, 0.34, 0.45, 0.16))
	for index: int in range(90):
		var x: float = fmod(float(index * 113 + 31), VIEWPORT_SIZE.x)
		var y: float = fmod(float(index * 67 + 19), VIEWPORT_SIZE.y)
		draw_circle(Vector2(x, y), 0.8 + float(index % 3) * 0.45, Color("9ab9ff", 0.18))

func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, VIEWPORT_SIZE.x, 144.0), Color("081322", 0.96), true)
	var nexus: Texture2D = art.get("command_nexus") as Texture2D
	if nexus != null:
		draw_texture_rect(nexus, Rect2(905.0, -34.0, 260.0, 210.0), false, Color(0.55, 0.82, 1.0, 0.22))
	draw_string(ThemeDB.fallback_font, Vector2(42.0, 48.0), "MOONGOONS TAKE BACK", HORIZONTAL_ALIGNMENT_LEFT, 650.0, 31, Color("f4fbff"))
	draw_string(ThemeDB.fallback_font, Vector2(44.0, 83.0), "THE MOON HAS TWO SIDES. ORDER OWNS ONE. THE UNDERWORLD WANTS THE OTHER.", HORIZONTAL_ALIGNMENT_LEFT, 830.0, 14, Color("c3a9ff"))
	draw_string(ThemeDB.fallback_font, Vector2(44.0, 116.0), "FULL MOONGOONS ART • LIVING PRECINCT • SYNDICATE HIDEOUT • STORY RTS", HORIZONTAL_ALIGNMENT_LEFT, 850.0, 11, Color("76b8d2"))
	draw_line(Vector2(0.0, 143.0), Vector2(VIEWPORT_SIZE.x, 143.0), Color("65dcff", 0.52), 2.0)

func _draw_card(route: String, title: String, subtitle: String, bullets: Array[String], primary: Color, secondary: Color) -> void:
	var rect: Rect2 = card_rects[route] as Rect2
	var breathe: float = 0.08 + sin(pulse * 1.7 + rect.position.x * 0.01) * 0.025
	draw_style_box(_panel_style(Color("0c1320", 0.98), primary.lightened(0.08), 2, 18), rect)
	var art_rect := Rect2(rect.position + Vector2(3.0, 3.0), Vector2(rect.size.x - 6.0, 190.0))
	_draw_campaign_art(route, art_rect, primary, secondary)
	draw_rect(art_rect, Color(primary, 0.04 + breathe), true)
	draw_line(rect.position + Vector2(0.0, 193.0), rect.position + Vector2(rect.size.x, 193.0), Color(primary, 0.64), 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(18.0, 226.0), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 36.0, 21, Color("f7fbff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(18.0, 251.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 36.0, 11, primary.lightened(0.18))
	for index: int in range(bullets.size()):
		var y: float = rect.position.y + 294.0 + float(index) * 34.0
		draw_circle(Vector2(rect.position.x + 31.0, y - 4.0), 4.0, primary)
		draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 46.0, y), bullets[index], HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 68.0, 11, Color("c1d4df"))
	var button_rect: Rect2 = Rect2(rect.position + Vector2(24.0, 412.0), Vector2(rect.size.x - 48.0, 40.0))
	draw_style_box(_panel_style(Color(primary, 0.23), primary, 2, 9), button_rect)
	draw_string(ThemeDB.fallback_font, button_rect.position + Vector2(4.0, 26.0), "ENTER CAMPAIGN", HORIZONTAL_ALIGNMENT_CENTER, button_rect.size.x - 8.0, 11, Color("ffffff"))

func _draw_campaign_art(route: String, rect: Rect2, primary: Color, secondary: Color) -> void:
	draw_rect(rect, Color("050912"), true)
	match route:
		"syndicate":
			_draw_art_texture(art.get("wrecked_shuttle") as Texture2D, Rect2(rect.position + Vector2(72.0, 6.0), Vector2(245.0, 176.0)), Color.WHITE)
			_draw_art_texture(art.get("nyx") as Texture2D, Rect2(rect.position + Vector2(-5.0, 8.0), Vector2(145.0, 180.0)), Color.WHITE)
			_draw_art_texture(art.get("cargo_crate") as Texture2D, Rect2(rect.position + Vector2(278.0, 118.0), Vector2(85.0, 64.0)), Color.WHITE)
		"precinct":
			_draw_art_texture(art.get("ops_center") as Texture2D, rect, Color(0.72, 0.92, 1.0, 0.78))
			_draw_art_texture(art.get("patrol_deputy") as Texture2D, Rect2(rect.position + Vector2(12.0, 28.0), Vector2(125.0, 150.0)), Color.WHITE)
			_draw_art_texture(art.get("shield_deputy") as Texture2D, Rect2(rect.position + Vector2(245.0, 26.0), Vector2(125.0, 152.0)), Color.WHITE)
			_draw_art_texture(art.get("command_nexus") as Texture2D, Rect2(rect.position + Vector2(114.0, 12.0), Vector2(160.0, 165.0)), Color(0.9, 1.0, 1.0, 0.92))
		"rts":
			_draw_art_texture(art.get("ore_deposit") as Texture2D, Rect2(rect.position + Vector2(0.0, 26.0), Vector2(130.0, 150.0)), Color.WHITE)
			_draw_art_texture(art.get("command_nexus") as Texture2D, Rect2(rect.position + Vector2(105.0, 8.0), Vector2(175.0, 172.0)), Color.WHITE)
			_draw_art_texture(art.get("sentry_turret") as Texture2D, Rect2(rect.position + Vector2(255.0, 75.0), Vector2(112.0, 108.0)), Color.WHITE)
			_draw_art_texture(art.get("pulse_cannon") as Texture2D, Rect2(rect.position + Vector2(8.0, 98.0), Vector2(104.0, 86.0)), Color.WHITE)
		_:
			_draw_faction_emblem(route, rect.get_center(), primary, secondary)
	draw_rect(rect, Color(primary, 0.05), true)

func _draw_art_texture(texture: Texture2D, rect: Rect2, modulate: Color) -> void:
	if texture == null:
		return
	draw_texture_rect(texture, rect, false, modulate)

func _draw_faction_emblem(route: String, center: Vector2, primary: Color, secondary: Color) -> void:
	if route == "syndicate":
		draw_texture_rect(SYNDICATE_EMBLEM, Rect2(center - Vector2(48.0, 48.0), Vector2(96.0, 96.0)), false)
		return
	draw_circle(center, 48.0, Color("060811", 0.88))
	draw_arc(center, 49.0, 0.0, TAU, 48, primary, 3.0)
	draw_arc(center, 39.0, 0.0, TAU, 48, Color(secondary, 0.68), 2.0)

func _load_campaign_art() -> void:
	var paths: Dictionary = {
		"command_nexus": "res://assets/skins/moongoons/command_nexus.png",
		"patrol_deputy": "res://assets/skins/moongoons/patrol_deputy.png",
		"shield_deputy": "res://assets/skins/moongoons/shield_deputy.png",
		"sentry_turret": "res://assets/skins/moongoons/sentry_turret.png",
		"pulse_cannon": "res://assets/skins/moongoons/pulse_cannon.png",
		"ore_deposit": "res://assets/skins/moongoons/ore_deposit.png",
		"wrecked_shuttle": "res://assets/skins/moongoons/wrecked_shuttle.png",
		"cargo_crate": "res://assets/skins/moongoons/cargo_crate.png",
		"crater": "res://assets/skins/moongoons/crater.png",
		"ops_center": "res://assets/precinct/rooms/ops_center.svg",
		"nyx": "res://assets/syndicate/portraits/nyx_raze.svg"
	}
	for key_value: Variant in paths.keys():
		var key: String = String(key_value)
		var path: String = String(paths[key])
		if ResourceLoader.exists(path):
			art[key] = load(path) as Texture2D

func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
