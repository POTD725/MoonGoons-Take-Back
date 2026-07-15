extends Node2D
## Full-screen origin, patrol, assault, and victory cinematic player using the
## approved isometric orbital-station art direction.

const VIEW := Vector2(1280.0, 720.0)
const CINEMATIC_PATHS: Dictionary = {
	"blackout":"res://assets/generated/cinematics/crater_market_blackout.svg",
	"ghost_key":"res://assets/generated/cinematics/ghost_key_heist.svg",
	"station":"res://assets/generated/cinematics/station_reactivation.svg",
	"patrol":"res://assets/generated/cinematics/patrol_launch.svg",
	"assault":"res://assets/generated/cinematics/syndicate_assault.svg",
	"victory":"res://assets/generated/cinematics/victory_reclaim.svg"
}
const PORTRAIT_PATHS: Dictionary = {
	"nyx":"res://assets/syndicate/portraits/nyx_raze.svg",
	"vox":"res://assets/syndicate/portraits/vox_13.svg",
	"cinder":"res://assets/syndicate/portraits/cinder_quell.svg",
	"grit":"res://assets/syndicate/portraits/grit_mercer.svg"
}

var slides: Array[Dictionary] = []
var elapsed: float = 0.0
var slide_elapsed: float = 0.0
var transition: float = 1.0
var last_slide_index: int = -1
var textures: Dictionary = {}
var portraits: Dictionary = {}
var next_rect := Rect2(1030.0, 642.0, 220.0, 56.0)
var back_rect := Rect2(790.0, 642.0, 220.0, 56.0)
var skip_rect := Rect2(30.0, 642.0, 170.0, 56.0)

func _ready() -> void:
	slides = TakeBackCampaign.cinematic_slides()
	if slides.is_empty():
		TakeBackCampaign.finish_cinematic()
		return
	_load_art()
	last_slide_index = TakeBackCampaign.cinematic_slide_index
	MoonGoonsAudio.play("alert" if TakeBackCampaign.cinematic_kind != "origin" else "dispatch")
	queue_redraw()

func _load_art() -> void:
	for key_value: Variant in CINEMATIC_PATHS.keys():
		var key := String(key_value)
		textures[key] = load(String(CINEMATIC_PATHS[key])) as Texture2D
	for key_value: Variant in PORTRAIT_PATHS.keys():
		var key := String(key_value)
		portraits[key] = load(String(PORTRAIT_PATHS[key])) as Texture2D

func _process(delta: float) -> void:
	elapsed += delta
	slide_elapsed += delta
	transition = minf(1.0, transition + delta * 1.7)
	var current_index: int = TakeBackCampaign.cinematic_slide_index
	if current_index != last_slide_index:
		last_slide_index = current_index
		slide_elapsed = 0.0
		transition = 0.0
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key := event as InputEventKey
		if key.keycode in [KEY_ENTER, KEY_SPACE, KEY_RIGHT]:
			_next()
		elif key.keycode in [KEY_LEFT, KEY_BACKSPACE]:
			_previous()
		elif key.keycode == KEY_ESCAPE:
			TakeBackCampaign.finish_cinematic()
		return
	var pos := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		pos = mouse.position
		pressed = mouse.button_index == MOUSE_BUTTON_LEFT and mouse.pressed
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
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
	MoonGoonsAudio.play("confirm")
	TakeBackCampaign.advance_cinematic()
	transition = 0.0
	slide_elapsed = 0.0
	queue_redraw()

func _previous() -> void:
	if TakeBackCampaign.previous_cinematic():
		MoonGoonsAudio.play("click")
		transition = 0.0
		slide_elapsed = 0.0
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("02060d"), true)
	_draw_starfield()
	if slides.is_empty():
		return
	var index := clampi(TakeBackCampaign.cinematic_slide_index, 0, slides.size() - 1)
	var slide: Dictionary = slides[index]
	var art_key := _art_key_for_slide(index, slide)
	_draw_cinematic_art(art_key)
	_draw_scene_animation(art_key)
	_draw_scanlines()
	_draw_story_panel(index, slide)
	if transition < 1.0:
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.01, 0.025, 0.045, 1.0 - transition), true)

func _art_key_for_slide(index: int, slide: Dictionary) -> String:
	match TakeBackCampaign.cinematic_kind:
		"origin":
			var sequence: Array[String] = ["blackout", "ghost_key", "station", "patrol", "victory"]
			return sequence[clampi(index, 0, sequence.size() - 1)]
		"space_attack":
			return "patrol" if index == 0 else "assault"
		"marauder_attack":
			return "assault" if index == 0 else "station"
	var requested := String(slide.get("art", "station"))
	if requested in ["nyx", "vox", "cinder", "grit"]:
		return "assault"
	return requested if textures.has(requested) else "station"

func _draw_cinematic_art(art_key: String) -> void:
	var texture: Texture2D = textures.get(art_key) as Texture2D
	if texture == null:
		_draw_fallback_station()
		return
	var drift_x := sin(slide_elapsed * 0.21) * 18.0
	var drift_y := cos(slide_elapsed * 0.17) * 8.0
	var zoom := 1.035 + sin(slide_elapsed * 0.13) * 0.012
	if art_key == "assault":
		drift_x += sin(slide_elapsed * 8.0) * 4.0
		drift_y += cos(slide_elapsed * 7.0) * 3.0
	var render_size := VIEW * zoom
	var rect := Rect2((VIEW - render_size) * 0.5 + Vector2(drift_x, drift_y), render_size)
	draw_texture_rect(texture, rect, false, Color.WHITE)

func _draw_scene_animation(art_key: String) -> void:
	match art_key:
		"blackout":
			var alarm := 0.08 + 0.08 * maxf(0.0, sin(elapsed * 5.5))
			draw_rect(Rect2(0.0, 0.0, VIEW.x, 506.0), Color(0.65, 0.01, 0.08, alarm), true)
			for index in range(7):
				var x := fmod(elapsed * (22.0 + index * 3.0) + index * 181.0, VIEW.x)
				draw_circle(Vector2(x, 135.0 + index * 41.0), 2.5, Color("ff6b7d", 0.7))
		"ghost_key":
			for ring in range(4):
				var radius := 50.0 + ring * 34.0 + fmod(elapsed * 18.0, 34.0)
				draw_arc(Vector2(640.0, 330.0), radius, 0.0, TAU, 56, Color(0.36, 0.93, 1.0, 0.26), 2.0)
		"station":
			var pulse := 0.25 + 0.20 * sin(elapsed * 2.4)
			for radius in [76.0, 108.0, 142.0]:
				draw_arc(Vector2(640.0, 278.0), radius, 0.0, TAU, 72, Color(0.35, 0.95, 1.0, pulse), 3.0)
		"patrol":
			for index in range(8):
				var x := fmod(elapsed * (180.0 + index * 11.0) + index * 197.0, 1500.0) - 120.0
				var y := 110.0 + index * 48.0
				draw_line(Vector2(x - 80.0, y), Vector2(x, y - 12.0), Color(0.35, 0.92, 1.0, 0.34), 4.0)
		"assault":
			var flash := maxf(0.0, sin(elapsed * 4.2)) * 0.12
			draw_rect(Rect2(0.0, 0.0, VIEW.x, 510.0), Color(1.0, 0.16, 0.10, flash), true)
			for index in range(14):
				var angle := elapsed * (0.7 + index * 0.03) + index
				var center := Vector2(760.0, 335.0)
				var p := center + Vector2(cos(angle), sin(angle)) * (40.0 + index * 8.0)
				draw_circle(p, 2.0 + index % 3, Color("ffbd69", 0.52))
		"victory":
			for index in range(24):
				var x := 90.0 + fmod(index * 137.0 + elapsed * 8.0, 1100.0)
				var y := 80.0 + fmod(index * 79.0 + elapsed * 4.0, 460.0)
				draw_circle(Vector2(x, y), 1.2 + index % 2, Color("ffd77d", 0.42))
	_draw_commander_portrait()

func _draw_commander_portrait() -> void:
	if slides.is_empty():
		return
	var index := clampi(TakeBackCampaign.cinematic_slide_index, 0, slides.size() - 1)
	var requested := String(slides[index].get("art", ""))
	if not portraits.has(requested):
		return
	var portrait: Texture2D = portraits.get(requested) as Texture2D
	if portrait == null:
		return
	var rect := Rect2(930.0, 46.0, 270.0, 270.0)
	draw_style_box(_panel(Color("07101a", 0.90), Color("ff6fae"), 4, 22), rect)
	draw_texture_rect(portrait, rect.grow(-16.0), false)
	var scan_y := rect.position.y + fmod(elapsed * 70.0, rect.size.y)
	draw_line(Vector2(rect.position.x + 8.0, scan_y), Vector2(rect.end.x - 8.0, scan_y), Color(1.0, 0.42, 0.70, 0.42), 2.0)

func _draw_story_panel(index: int, slide: Dictionary) -> void:
	draw_rect(Rect2(0.0, 488.0, 1280.0, 232.0), Color(0.015, 0.03, 0.055, 0.97), true)
	draw_line(Vector2(0.0, 488.0), Vector2(1280.0, 488.0), Color("62e8ff", 0.72), 3.0)
	draw_string(ThemeDB.fallback_font, Vector2(38.0, 524.0), String(slide.get("kicker", "CLASSIFIED")), HORIZONTAL_ALIGNMENT_LEFT, 760.0, 15, Color("76eaff"))
	draw_string(ThemeDB.fallback_font, Vector2(38.0, 568.0), String(slide.get("title", "TAKE BACK")), HORIZONTAL_ALIGNMENT_LEFT, 1160.0, 28, Color("f4fbff"))
	_draw_wrapped(String(slide.get("body", "")), Vector2(40.0, 604.0), 920.0, 15, Color("c9d9e5"))
	draw_string(ThemeDB.fallback_font, Vector2(40.0, 631.0), "SOURCE // %s" % String(slide.get("speaker", "AUTHORITY")), HORIZONTAL_ALIGNMENT_LEFT, 680.0, 11, Color("ffca72"))
	draw_string(ThemeDB.fallback_font, Vector2(1010.0, 631.0), "%d / %d" % [index + 1, slides.size()], HORIZONTAL_ALIGNMENT_RIGHT, 240.0, 12, Color("8fa8ba"))
	_draw_button(skip_rect, "SKIP", false)
	_draw_button(back_rect, "PREVIOUS", index > 0)
	_draw_button(next_rect, "CONTINUE" if index + 1 < slides.size() else "ENTER GAME", true)

func _draw_fallback_station() -> void:
	draw_rect(Rect2(0.0, 0.0, VIEW.x, 490.0), Color("071522"), true)
	for index in range(8):
		var center := Vector2(190.0 + index % 4 * 300.0, 160.0 + index / 4 * 190.0)
		draw_circle(center, 72.0, Color("20394a"))
		draw_arc(center, 72.0, 0.0, TAU, 48, Color("5ee8ff"), 3.0)

func _draw_starfield() -> void:
	for index in range(120):
		var x := fmod(float(index * 109 + 31) + elapsed * (2.0 + index % 4), VIEW.x)
		var y := fmod(float(index * 67 + 19), 490.0)
		var pulse := 0.22 + 0.18 * sin(elapsed * 1.6 + float(index))
		draw_circle(Vector2(x, y), 0.8 + float(index % 3) * 0.5, Color(0.75, 0.90, 1.0, pulse))

func _draw_scanlines() -> void:
	for index in range(24):
		var y := fmod(float(index * 22) + elapsed * 18.0, 488.0)
		draw_line(Vector2(0.0, y), Vector2(1280.0, y), Color(0.25, 0.75, 1.0, 0.028), 1.0)

func _draw_button(rect: Rect2, label: String, active: bool) -> void:
	var fill := Color("1d4d63") if active else Color("101a25")
	var border := Color("6fead9") if active else Color("526474")
	draw_style_box(_panel(fill, border, 2, 9), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 36.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16.0, 13, Color("f2f8fc") if active else Color("8395a3"))

func _draw_wrapped(text: String, origin: Vector2, width: float, font_size: int, color: Color) -> void:
	var words := text.split(" ")
	var line := ""
	var y := origin.y
	for word: String in words:
		var candidate := word if line.is_empty() else line + " " + word
		if ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > width and not line.is_empty():
			draw_string(ThemeDB.fallback_font, Vector2(origin.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)
			line = word
			y += float(font_size + 7)
		else:
			line = candidate
	if not line.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(origin.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _panel(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
