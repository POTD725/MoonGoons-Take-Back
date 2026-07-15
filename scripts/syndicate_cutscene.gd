extends Node2D
## Illustrated story cutscenes for Syndicate Rising.

const VIEW: Vector2 = Vector2(1280.0, 720.0)
const PANELS: Array[Texture2D] = [
	preload("res://assets/syndicate/cutscenes/crater_market_falls.svg"),
	preload("res://assets/syndicate/cutscenes/ghost_key_network.svg"),
	preload("res://assets/syndicate/cutscenes/take_back_dark.svg")
]

var cutscene_id: String = "prologue"
var frames: Array[Dictionary] = []
var frame_index: int = 0
var frame_clock: float = 0.0
var transition: float = 1.0
var button_next: Rect2 = Rect2(1018.0, 636.0, 218.0, 48.0)
var button_skip: Rect2 = Rect2(42.0, 636.0, 150.0, 48.0)

func _ready() -> void:
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
	var panel_index: int = int(frame.get("panel", 0))
	draw_texture_rect(PANELS[clampi(panel_index, 0, PANELS.size() - 1)], Rect2(Vector2.ZERO, VIEW), false)
	draw_rect(Rect2(0.0, 0.0, VIEW.x, 150.0), Color("05030a", 0.62), true)
	draw_rect(Rect2(0.0, 508.0, VIEW.x, 212.0), Color("05030a", 0.88), true)
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("05030a", 1.0 - transition), true)
	var chapter: String = String(frame.get("chapter", "SYNDICATE RISING"))
	var title: String = String(frame.get("title", "THE DARK SIDE"))
	var speaker: String = String(frame.get("speaker", "NYX RAZE"))
	var text: String = String(frame.get("text", ""))
	draw_string(ThemeDB.fallback_font, Vector2(48.0, 52.0), chapter, HORIZONTAL_ALIGNMENT_LEFT, 700.0, 14, Color("ff8dc3"))
	draw_string(ThemeDB.fallback_font, Vector2(48.0, 103.0), title, HORIZONTAL_ALIGNMENT_LEFT, 1040.0, 36, Color("fff4fb"))
	draw_string(ThemeDB.fallback_font, Vector2(48.0, 555.0), speaker, HORIZONTAL_ALIGNMENT_LEFT, 300.0, 15, Color("ffbe68"))
	_draw_wrapped_text(text, Vector2(48.0, 590.0), 890.0, 19, Color("f4dce9"))
	var progress: String = "%d / %d" % [frame_index + 1, frames.size()]
	draw_string(ThemeDB.fallback_font, Vector2(913.0, 555.0), progress, HORIZONTAL_ALIGNMENT_RIGHT, 300.0, 12, Color("b38ca7"))
	_draw_button(button_skip, "SKIP")
	_draw_button(button_next, "CONTINUE" if frame_index < frames.size() - 1 else "ENTER HIDEOUT")

func _draw_wrapped_text(text: String, origin: Vector2, width: float, font_size: int, color: Color) -> void:
	var words: PackedStringArray = text.split(" ")
	var line: String = ""
	var y: float = origin.y
	for word: String in words:
		var candidate: String = word if line.is_empty() else line + " " + word
		var size: Vector2 = ThemeDB.fallback_font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
		if size.x > width and not line.is_empty():
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
				{"panel": 2, "chapter": "ACT I FINALE", "title": "TAKE BACK THE DARK", "speaker": "NYX RAZE", "text": "Eclipse Tower carries our signal now. The law still owns the daylight shifts. The night belongs to everyone they tried to erase."},
				{"panel": 1, "chapter": "ACT II TEASER", "title": "SOMETHING ANSWERS BELOW", "speaker": "VOX-13", "text": "Boss, the tower is receiving a transmission from beneath the oldest crater. It is not Peacekeeper. It is not Syndicate either."}
			]
		_:
			return [
				{"panel": 0, "chapter": "PROLOGUE", "title": "THE NIGHT AFTER THE RAID", "speaker": "NYX RAZE", "text": "The Peacekeepers called Crater Market secured. They counted bodies, sealed doors, and left before the dust settled."},
				{"panel": 1, "chapter": "PROLOGUE", "title": "THE NETWORK REMEMBERS", "speaker": "VOX-13", "text": "Backroom Command survived. Seven rooms are wrecked, our routes are burned, and every fixer with a pulse is waiting for a signal."},
				{"panel": 2, "chapter": "PROLOGUE", "title": "TAKE BACK THE DARK", "speaker": "NYX RAZE", "text": "Rebuild the den. Gather the crew. We take the Moon back from underneath, one stolen key at a time."}
			]

func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
