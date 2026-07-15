extends Node2D
## Shared MoonGoons story cutscenes using the same approved orbital-station
## artwork, lighting, parallax, and transition language as Take Back.

const VIEW := Vector2(1280.0, 720.0)
const PANEL_PATHS: Array[String] = [
	"res://assets/generated/cinematics/crater_market_blackout.svg",
	"res://assets/generated/cinematics/ghost_key_heist.svg",
	"res://assets/generated/cinematics/syndicate_assault.svg",
	"res://assets/generated/cinematics/victory_reclaim.svg"
]

var panels: Array[Texture2D] = []
var cutscene_id: String = "prologue"
var frames: Array[Dictionary] = []
var frame_index: int = 0
var frame_clock: float = 0.0
var transition: float = 1.0
var button_next := Rect2(1018.0, 636.0, 218.0, 48.0)
var button_skip := Rect2(42.0, 636.0, 150.0, 48.0)

func _ready() -> void:
	for path: String in PANEL_PATHS:
		panels.append(load(path) as Texture2D)
	cutscene_id = SyndicateState.pending_cutscene
	if cutscene_id.is_empty():
		cutscene_id = "prologue" if not SyndicateState.intro_seen else "ghost_key"
	frames = _frames_for(cutscene_id)
	SyndicateAudio.play_music("cutscene")
	SyndicateAudio.play_sfx("accept")
	queue_redraw()

func _process(delta: float) -> void:
	frame_clock += delta
	transition = minf(1.0, transition + delta * 1.8)
	if frame_clock >= 6.5:
		_advance()
	queue_redraw()

func _input(event: InputEvent) -> void:
	var position := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		position = mouse_event.position
		pressed = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		position = touch_event.position
		pressed = touch_event.pressed
	if not pressed:
		return
	if button_skip.has_point(position):
		SyndicateAudio.play_sfx("click")
		_finish()
	elif button_next.has_point(position):
		SyndicateAudio.play_sfx("click")
		_advance()
	else:
		_advance()

func _advance() -> void:
	frame_index += 1
	frame_clock = 0.0
	transition = 0.0
	if frame_index >= frames.size():
		_finish()
	else:
		SyndicateAudio.play_sfx("accept")
		queue_redraw()

func _finish() -> void:
	SyndicateState.consume_cutscene()
	SyndicateAudio.play_music("hideout")
	get_tree().change_scene_to_file("res://scenes/SyndicateHideout.tscn")

func _draw() -> void:
	if frames.is_empty():
		return
	var frame: Dictionary = frames[clampi(frame_index, 0, frames.size() - 1)]
	var panel_index := clampi(int(frame.get("panel", 0)), 0, panels.size() - 1)
	_draw_panel_art(panel_index)
	_draw_motion(panel_index)
	draw_rect(Rect2(0.0, 0.0, VIEW.x, 150.0), Color("05030a", 0.54), true)
	draw_rect(Rect2(0.0, 508.0, VIEW.x, 212.0), Color("05030a", 0.91), true)
	if transition < 1.0:
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color("05030a", 1.0 - transition), true)
	var chapter := String(frame.get("chapter", "SYNDICATE RISING"))
	var title := String(frame.get("title", "THE DARK SIDE"))
	var speaker := String(frame.get("speaker", "NYX RAZE"))
	var text := String(frame.get("text", ""))
	draw_string(ThemeDB.fallback_font, Vector2(48.0, 52.0), chapter, HORIZONTAL_ALIGNMENT_LEFT, 700.0, 14, Color("ff8dc3"))
	draw_string(ThemeDB.fallback_font, Vector2(48.0, 103.0), title, HORIZONTAL_ALIGNMENT_LEFT, 1040.0, 36, Color("fff4fb"))
	draw_string(ThemeDB.fallback_font, Vector2(48.0, 555.0), speaker, HORIZONTAL_ALIGNMENT_LEFT, 300.0, 15, Color("ffbe68"))
	_draw_wrapped_text(text, Vector2(48.0, 590.0), 890.0, 19, Color("f4dce9"))
	var progress := "%d / %d" % [frame_index + 1, frames.size()]
	draw_string(ThemeDB.fallback_font, Vector2(913.0, 555.0), progress, HORIZONTAL_ALIGNMENT_RIGHT, 300.0, 12, Color("b38ca7"))
	_draw_button(button_skip, "SKIP")
	_draw_button(button_next, "CONTINUE" if frame_index < frames.size() - 1 else "ENTER HIDEOUT")

func _draw_panel_art(panel_index: int) -> void:
	var texture: Texture2D = panels[panel_index] if panel_index < panels.size() else null
	if texture == null:
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color("071522"), true)
		return
	var zoom := 1.03 + sin(frame_clock * 0.14) * 0.012
	var render_size := VIEW * zoom
	var drift := Vector2(sin(frame_clock * 0.22) * 18.0, cos(frame_clock * 0.16) * 8.0)
	if panel_index == 2:
		drift += Vector2(sin(frame_clock * 8.0) * 4.0, cos(frame_clock * 7.0) * 3.0)
	draw_texture_rect(texture, Rect2((VIEW - render_size) * 0.5 + drift, render_size), false)

func _draw_motion(panel_index: int) -> void:
	for index in range(34):
		var x := fmod(float(index * 109 + 31) + frame_clock * (3.0 + index % 5), VIEW.x)
		var y := fmod(float(index * 67 + 19), 500.0)
		draw_circle(Vector2(x, y), 0.8 + index % 3 * 0.45, Color(0.78, 0.92, 1.0, 0.18))
	if panel_index == 0:
		var alarm := maxf(0.0, sin(frame_clock * 5.2)) * 0.13
		draw_rect(Rect2(0.0, 0.0, VIEW.x, 508.0), Color(0.75, 0.02, 0.10, alarm), true)
	elif panel_index == 1:
		for ring in range(5):
			var radius := 50.0 + ring * 32.0 + fmod(frame_clock * 16.0, 32.0)
			draw_arc(Vector2(640.0, 330.0), radius, 0.0, TAU, 56, Color(0.95, 0.34, 0.70, 0.18), 2.0)
	elif panel_index == 2:
		var flash := maxf(0.0, sin(frame_clock * 4.1)) * 0.12
		draw_rect(Rect2(0.0, 0.0, VIEW.x, 508.0), Color(1.0, 0.12, 0.08, flash), true)
	elif panel_index == 3:
		for index in range(18):
			var px := 100.0 + fmod(index * 149.0 + frame_clock * 7.0, 1080.0)
			var py := 80.0 + fmod(index * 83.0, 390.0)
			draw_circle(Vector2(px, py), 1.4, Color("ffd477", 0.42))
	for index in range(23):
		var scan_y := fmod(float(index * 23) + frame_clock * 20.0, 508.0)
		draw_line(Vector2(0.0, scan_y), Vector2(VIEW.x, scan_y), Color(0.35, 0.70, 1.0, 0.025), 1.0)

func _draw_wrapped_text(text: String, origin: Vector2, width: float, font_size: int, color: Color) -> void:
	var words := text.split(" ")
	var line := ""
	var y := origin.y
	for word: String in words:
		var candidate := word if line.is_empty() else line + " " + word
		var text_size := ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
		if text_size.x > width and not line.is_empty():
			draw_string(ThemeDB.fallback_font, Vector2(origin.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)
			line = word
			y += float(font_size + 9)
		else:
			line = candidate
	if not line.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(origin.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, color)

func _draw_button(rect: Rect2, label: String) -> void:
	draw_style_box(_panel_style(Color("37163c", 0.92), Color("ff72b1"), 2, 9), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(4.0, 30.0), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 8.0, 12, Color("fff7fb"))

func _frames_for(id: String) -> Array[Dictionary]:
	match id:
		"ghost_key":
			return [
				{"panel": 1, "chapter": "CHAPTER II", "title": "THE GHOST KEY OPENS", "speaker": "VOX-13", "text": "The relay key is real. Every patrol route, evidence lock, and blind camera on the east rim is whispering into our Signal Den."},
				{"panel": 2, "chapter": "CHAPTER II", "title": "A NETWORK BENEATH THE NETWORK", "speaker": "NYX RAZE", "text": "Then we stop stealing scraps. Blueglass keeps the names of every fixer they ever turned. We take the records and give the Moon its memory back."}
			]
		"war_room":
			return [
				{"panel": 2, "chapter": "CHAPTER IV", "title": "THE PRECINCT BLINKS", "speaker": "CINDER QUELL", "text": "The Dawn Convoy is ours. The Peacekeepers are moving power cells into Grid Seven before their next sweep."},
				{"panel": 0, "chapter": "CHAPTER IV", "title": "CUT THE LIGHTS", "speaker": "GRIT MERCER", "text": "We blackout the precinct, open every tunnel, and let every crew on the Moon decide what freedom costs."}
			]
		"finale":
			return [
				{"panel": 3, "chapter": "ACT I FINALE", "title": "TAKE BACK THE DARK", "speaker": "NYX RAZE", "text": "Eclipse Tower carries our signal now. The law still owns the daylight shifts. The night belongs to everyone they tried to erase."},
				{"panel": 1, "chapter": "ACT II TEASER", "title": "SOMETHING ANSWERS BELOW", "speaker": "VOX-13", "text": "Boss, the tower is receiving a transmission from beneath the oldest crater. It is not Peacekeeper. It is not Syndicate either."}
			]
		_:
			return [
				{"panel": 0, "chapter": "PROLOGUE", "title": "THE NIGHT AFTER THE RAID", "speaker": "NYX RAZE", "text": "The Peacekeepers called Crater Market secured. They counted bodies, sealed doors, and left before the dust settled."},
				{"panel": 1, "chapter": "PROLOGUE", "title": "THE NETWORK REMEMBERS", "speaker": "VOX-13", "text": "Backroom Command survived. Seven rooms are wrecked, our routes are burned, and every fixer with a pulse is waiting for a signal."},
				{"panel": 2, "chapter": "PROLOGUE", "title": "TAKE BACK THE DARK", "speaker": "NYX RAZE", "text": "Rebuild the den. Gather the crew. We take the Moon back from underneath, one stolen key at a time."}
			]

func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
