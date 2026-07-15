extends Node2D
## Full-screen origin and attack cinematic player.

const VIEW: Vector2 = Vector2(1280.0, 720.0)
const SURFACE: Texture2D = preload("res://assets/shared/syndicate_rising/lunar_surface_panorama.svg")
const STATION: Texture2D = preload("res://assets/shared/syndicate_rising/peacekeeper_orbital_station.svg")
const RESPONSE: Texture2D = preload("res://assets/shared/syndicate_rising/take_back_response.svg")
const PORTRAITS: Dictionary = {
	"nyx": preload("res://assets/syndicate/portraits/nyx_raze.svg"),
	"vox": preload("res://assets/syndicate/portraits/vox_13.svg"),
	"cinder": preload("res://assets/syndicate/portraits/cinder_quell.svg"),
	"grit": preload("res://assets/syndicate/portraits/grit_mercer.svg")
}

var slides: Array[Dictionary] = []
var elapsed: float = 0.0
var next_rect: Rect2 = Rect2(1030.0, 642.0, 220.0, 56.0)
var back_rect: Rect2 = Rect2(790.0, 642.0, 220.0, 56.0)
var skip_rect: Rect2 = Rect2(30.0, 642.0, 170.0, 56.0)

func _ready() -> void:
	slides = TakeBackCampaign.cinematic_slides()
	if slides.is_empty():
		TakeBackCampaign.finish_cinematic()
		return
	MoonGoonsAudio.play_music("combat" if TakeBackCampaign.cinematic_kind != "origin" else "precinct")
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key: InputEventKey = event as InputEventKey
		if key.keycode in [KEY_ENTER, KEY_SPACE, KEY_RIGHT]:
			_next()
		elif key.keycode in [KEY_LEFT, KEY_BACKSPACE]:
			_previous()
		elif key.keycode == KEY_ESCAPE:
			TakeBackCampaign.finish_cinematic()
		return
	var pos: Vector2 = Vector2.ZERO
	var pressed: bool = false
	if event is InputEventMouseButton:
		var mouse: InputEventMouseButton = event as InputEventMouseButton
		pos = mouse.position
		pressed = mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		pos = touch.position
		pressed = touch.pressed
	if not pressed:
		return
	if next_rect.has_point(pos):
		_next()
	elif back_rect.has_point(pos):
		_previous()
	elif skip_rect.has_point(pos):
		TakeBackCampaign.finish_cinematic()

func _next() -> void:
	MoonGoonsAudio.play_sfx("accept")
	TakeBackCampaign.advance_cinematic()
	queue_redraw()

func _previous() -> void:
	if TakeBackCampaign.previous_cinematic():
		MoonGoonsAudio.play_sfx("click")
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("02060d"), true)
	_draw_starfield()
	if slides.is_empty():
		return
	var index: int = clampi(TakeBackCampaign.cinematic_slide_index, 0, slides.size() - 1)
	var slide: Dictionary = slides[index]
	_draw_art(String(slide.get("art", "surface")))
	_draw_scanlines()
	draw_rect(Rect2(0.0, 420.0, 1280.0, 300.0), Color(0.015, 0.03, 0.055, 0.97), true)
	draw_line(Vector2(0.0, 420.0), Vector2(1280.0, 420.0), Color("62e8ff", 0.62), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(38.0, 458.0), String(slide.get("kicker", "CLASSIFIED")), HORIZONTAL_ALIGNMENT_LEFT, 760.0, 15, Color("76eaff"))
	draw_string(ThemeDB.fallback_font, Vector2(38.0, 506.0), String(slide.get("title", "TAKE BACK")), HORIZONTAL_ALIGNMENT_LEFT, 1160.0, 32, Color("f4fbff"))
	_draw_wrapped(String(slide.get("body", "")), Vector2(40.0, 548.0), 1160.0, 17, Color("c9d9e5"))
	draw_string(ThemeDB.fallback_font, Vector2(40.0, 626.0), "SOURCE // %s" % String(slide.get("speaker", "AUTHORITY")), HORIZONTAL_ALIGNMENT_LEFT, 680.0, 12, Color("ffca72"))
	draw_string(ThemeDB.fallback_font, Vector2(1010.0, 626.0), "%d / %d" % [index + 1, slides.size()], HORIZONTAL_ALIGNMENT_RIGHT, 240.0, 12, Color("8fa8ba"))
	_draw_button(skip_rect, "SKIP", false)
	_draw_button(back_rect, "PREVIOUS", index > 0)
	_draw_button(next_rect, "CONTINUE" if index + 1 < slides.size() else "ENTER GAME", true)

func _draw_art(art_key: String) -> void:
	match art_key:
		"station":
			draw_texture_rect(SURFACE, Rect2(0.0, 0.0, 1280.0, 420.0), false)
			draw_texture_rect(STATION, Rect2(280.0, 45.0, 720.0, 320.0), false)
		"response":
			draw_texture_rect(RESPONSE, Rect2(190.0, 15.0, 900.0, 420.0), false)
		"nyx", "vox", "cinder", "grit":
			draw_texture_rect(SURFACE, Rect2(0.0, 0.0, 1280.0, 420.0), false)
			var portrait: Texture2D = PORTRAITS[art_key] as Texture2D
			draw_style_box(_panel(Color("07101a", 0.90), Color("ff6fae"), 4, 22), Rect2(472.0, 34.0, 336.0, 336.0))
			draw_texture_rect(portrait, Rect2(490.0, 52.0, 300.0, 300.0), false)
		_:
			draw_texture_rect(SURFACE, Rect2(0.0, 0.0, 1280.0, 420.0), false)
			var station_x: float = 790.0 + sin(elapsed * 0.45) * 25.0
			draw_texture_rect(STATION, Rect2(station_x, 24.0, 420.0, 187.0), false)

func _draw_starfield() -> void:
	for index: int in range(120):
		var x: float = fmod(float(index * 109 + 31), VIEW.x)
		var y: float = fmod(float(index * 67 + 19), 420.0)
		var pulse: float = 0.22 + 0.18 * sin(elapsed * 1.6 + float(index))
		draw_circle(Vector2(x, y), 0.8 + float(index % 3) * 0.5, Color(0.75, 0.90, 1.0, pulse))

func _draw_scanlines() -> void:
	for index: int in range(22):
		var y: float = fmod(float(index * 22) + elapsed * 18.0, 420.0)
		draw_line(Vector2(0.0, y), Vector2(1280.0, y), Color(0.25, 0.75, 1.0, 0.035), 1.0)

func _draw_button(rect: Rect2, label: String, active: bool) -> void:
	var fill: Color = Color("1d4d63") if active else Color("101a25")
	var border: Color = Color("6fead9") if active else Color("526474")
	draw_style_box(_panel(fill, border, 2, 9), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 36.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 13, Color("f2f8fc") if active else Color("8395a3"))

func _draw_wrapped(text: String, origin: Vector2, width: float, font_size: int, color: Color) -> void:
	var words: PackedStringArray = text.split(" ")
	var line: String = ""
	var y: float = origin.y
	for word: String in words:
		var candidate: String = word if line.is_empty() else line + " " + word
		if ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > width and not line.is_empty():
			draw_string(ThemeDB.fallback_font, Vector2(origin.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)
			line = word
			y += float(font_size + 8)
		else:
			line = candidate
	if not line.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(origin.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _panel(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
