extends Node2D
## Criminal-side hideout management scene with textured room skins, portraits, audio, and chapter progression.

const VIEW: Vector2 = Vector2(1280.0, 720.0)
const EMBLEM: Texture2D = preload("res://assets/syndicate/syndicate_emblem.svg")
const ROOM_TEXTURES: Dictionary = {
	"backroom": preload("res://assets/syndicate/rooms/backroom_command.svg"),
	"chop_shop": preload("res://assets/syndicate/rooms/chop_shop.svg"),
	"black_market": preload("res://assets/syndicate/rooms/black_market.svg"),
	"bunks": preload("res://assets/syndicate/rooms/safehouse_bunks.svg"),
	"clinic": preload("res://assets/syndicate/rooms/street_clinic.svg"),
	"boss_office": preload("res://assets/syndicate/rooms/boss_office.svg"),
	"signal_den": preload("res://assets/syndicate/rooms/signal_den.svg"),
	"tunnel": preload("res://assets/syndicate/rooms/smuggler_tunnel.svg")
}
const PORTRAITS: Dictionary = {
	"crew_1": preload("res://assets/syndicate/portraits/nyx_raze.svg"),
	"crew_2": preload("res://assets/syndicate/portraits/vox_13.svg"),
	"crew_3": preload("res://assets/syndicate/portraits/cinder_quell.svg"),
	"crew_4": preload("res://assets/syndicate/portraits/grit_mercer.svg")
}
const BASE_RECT: Rect2 = Rect2(24.0, 104.0, 858.0, 500.0)
const SIDE_RECT: Rect2 = Rect2(898.0, 104.0, 358.0, 500.0)

var room_rects: Dictionary = {}
var crew_rects: Dictionary = {}
var job_rects: Dictionary = {}
var buttons: Dictionary = {}
var selected_room: String = "backroom"
var selected_job: String = ""
var selected_crew: Array[String] = []
var message: String = "Rebuild the den, pick a score, and choose a crew."
var pulse: float = 0.0
var tick_clock: float = 0.0

func _ready() -> void:
	var ids: Array[String] = ["backroom", "chop_shop", "black_market", "bunks", "clinic", "boss_office", "signal_den", "tunnel"]
	for index: int in range(ids.size()):
		room_rects[ids[index]] = Rect2(38.0 + float(index % 4) * 208.0, 132.0 + float(index / 4) * 224.0, 194.0, 206.0)
	var names: Array[String] = ["run", "rebuild", "tech", "fence", "save", "load", "reset", "routes"]
	for index: int in range(names.size()):
		buttons[names[index]] = Rect2(36.0 + float(index) * 150.0, 636.0, 140.0 if index < 7 else 156.0, 44.0)
	SyndicateState.tick()
	if not SyndicateState.state_changed.is_connected(_on_state_changed):
		SyndicateState.state_changed.connect(_on_state_changed)
	SyndicateAudio.play_music("hideout")
	queue_redraw()

func _on_state_changed() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	tick_clock += delta
	if tick_clock >= 0.25:
		tick_clock = 0.0
		SyndicateState.tick()
	queue_redraw()

func _input(event: InputEvent) -> void:
	var pos: Vector2 = Vector2.ZERO
	var pressed: bool = false
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		pos = mouse_event.position
		pressed = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		pos = touch_event.position
		pressed = touch_event.pressed
	if not pressed:
		return
	for key: Variant in room_rects:
		if (room_rects[key] as Rect2).has_point(pos):
			selected_room = String(key)
			var room: Dictionary = SyndicateState.get_room(selected_room)
			message = "%s // Level %d // %s" % [room.get("name", "Room"), room.get("level", 1), room.get("function", "Unknown")]
			SyndicateAudio.play_sfx("click")
			return
	for key: Variant in job_rects:
		if (job_rects[key] as Rect2).has_point(pos):
			selected_job = String(key)
			message = "Score selected. Pick crew and tap RUN JOB."
			SyndicateAudio.play_sfx("click")
			return
	for key: Variant in crew_rects:
		if (crew_rects[key] as Rect2).has_point(pos):
			_toggle_crew(String(key))
			return
	for key: Variant in buttons:
		if (buttons[key] as Rect2).has_point(pos):
			_action(String(key))
			return

func _toggle_crew(id: String) -> void:
	var member: Dictionary = SyndicateState.get_crew_member(id)
	if member.is_empty() or not SyndicateState.crew_available(member):
		message = "%s is unavailable." % member.get("name", "Crew")
		SyndicateAudio.play_sfx("warning")
	elif selected_crew.has(id):
		selected_crew.erase(id)
		message = "%s removed." % member.get("name", "Crew")
		SyndicateAudio.play_sfx("click")
	else:
		var crew_limit: int = 3
		if SyndicateState.is_room_repaired("boss_office"):
			crew_limit = mini(4, 2 + SyndicateState.get_room_level("boss_office"))
		if selected_crew.size() >= crew_limit:
			message = "Current crew capacity is %d." % crew_limit
			SyndicateAudio.play_sfx("warning")
		else:
			selected_crew.append(id)
			message = "%s added." % member.get("name", "Crew")
			SyndicateAudio.play_sfx("accept")

func _action(name: String) -> void:
	var result: Dictionary = {}
	match name:
		"run":
			result = SyndicateState.begin_job(selected_job, selected_crew)
			if bool(result.get("ok", false)):
				SyndicateAudio.play_sfx("accept")
				get_tree().change_scene_to_file("res://scenes/SyndicateRaid.tscn")
				return
		"rebuild":
			result = SyndicateState.repair_or_upgrade_room(selected_room)
			if bool(result.get("ok", false)):
				SyndicateAudio.play_sfx("repair")
		"tech":
			result = SyndicateState.begin_black_tech()
			if bool(result.get("ok", false)):
				SyndicateAudio.play_sfx("special")
		"fence":
			result = SyndicateState.fence_contraband()
			if bool(result.get("ok", false)):
				SyndicateAudio.play_sfx("accept")
		"save":
			result = SyndicateState.save_game()
			SyndicateAudio.play_sfx("click")
		"load":
			result = SyndicateState.load_game()
			selected_job = ""
			selected_crew.clear()
			SyndicateAudio.play_sfx("click")
		"reset":
			SyndicateState.reset_state()
			selected_room = "backroom"
			selected_job = ""
			selected_crew.clear()
			message = "Syndicate route reset."
			SyndicateAudio.play_sfx("warning")
			get_tree().change_scene_to_file("res://scenes/SyndicateCutscene.tscn")
			return
		"routes":
			SyndicateAudio.play_sfx("click")
			get_tree().change_scene_to_file("res://scenes/CampaignRouter.tscn")
			return
	if not bool(result.get("ok", false)) and not result.is_empty():
		SyndicateAudio.play_sfx("warning")
	message = String(result.get("message", "Action failed."))

func _draw() -> void:
	_draw_background()
	_draw_header()
	draw_style_box(_box(Color("130b19"), Color("9d4bb7"), 2, 14), BASE_RECT)
	draw_style_box(_box(Color("130b19"), Color("9d4bb7"), 2, 14), SIDE_RECT)
	draw_string(ThemeDB.fallback_font, Vector2(40.0, 124.0), "HIDEOUT CUTAWAY // TAP A ROOM", HORIZONTAL_ALIGNMENT_LEFT, 390.0, 11, Color("ef88c6"))
	_draw_rooms()
	_draw_jobs()
	_draw_crew()
	_draw_buttons()
	draw_string(ThemeDB.fallback_font, Vector2(38.0, 711.0), message, HORIZONTAL_ALIGNMENT_LEFT, 1180.0, 10, Color("ddbad0"))

func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("07030d"))
	draw_rect(Rect2(0.0, 0.0, VIEW.x, 92.0), Color("1d0d24"))
	for i: int in range(86):
		draw_circle(Vector2(fmod(float(i * 101 + 37), VIEW.x), fmod(float(i * 59 + 23), VIEW.y)), 1.0 + float(i % 3) * 0.42, Color("d9a9ff", 0.20))
	for line_index: int in range(9):
		var offset: float = fmod(pulse * 18.0 + float(line_index) * 160.0, VIEW.x + 200.0) - 100.0
		draw_line(Vector2(offset, 92.0), Vector2(offset + 210.0, 620.0), Color("d66cff", 0.025), 2.0)

func _draw_header() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 34.0), "MOONGOONS TAKE BACK", HORIZONTAL_ALIGNMENT_LEFT, 420.0, 24, Color("fff3fb"))
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 61.0), "SYNDICATE RISING // CHAPTER %d" % SyndicateState.story_chapter, HORIZONTAL_ALIGNMENT_LEFT, 490.0, 13, Color("ff7eaa"))
	draw_texture_rect(EMBLEM, Rect2(500.0, 10.0, 62.0, 62.0), false)
	var stats: String = "CREDITS %04d   CARGO %03d   INTEL %03d   HEAT %03d   NOTORIETY %02d" % [SyndicateState.credits, SyndicateState.contraband, SyndicateState.intel, SyndicateState.heat, SyndicateState.notoriety]
	draw_string(ThemeDB.fallback_font, Vector2(574.0, 39.0), stats, HORIZONTAL_ALIGNMENT_LEFT, 660.0, 14, Color("f8d9ff"))
	var tech: String = "READY" if SyndicateState.black_tech_end <= 0 else "%ds" % SyndicateState.seconds_left(SyndicateState.black_tech_end)
	draw_string(ThemeDB.fallback_font, Vector2(574.0, 66.0), "BLACK TECH L%d // %s // JOBS %d" % [SyndicateState.black_tech_level, tech, SyndicateState.jobs_completed], HORIZONTAL_ALIGNMENT_LEFT, 420.0, 11, Color("b98bd4"))
	var heat_rect: Rect2 = Rect2(1015.0, 58.0, 205.0, 10.0)
	draw_rect(heat_rect, Color("2b162d"), true)
	draw_rect(Rect2(heat_rect.position, Vector2(heat_rect.size.x * clampf(float(SyndicateState.heat) / 100.0, 0.0, 1.0), 10.0)), Color("ffbd66") if SyndicateState.heat < 50 else Color("ff4d6d"), true)
	draw_line(Vector2(0.0, 91.0), Vector2(VIEW.x, 91.0), Color("ff5d8f", 0.48), 2.0)

func _draw_rooms() -> void:
	for room: Dictionary in SyndicateState.rooms:
		var id: String = String(room.get("id", ""))
		var rect: Rect2 = room_rects[id] as Rect2
		var repaired: bool = bool(room.get("repaired", false))
		var selected: bool = id == selected_room
		draw_style_box(_box(Color("24122c") if repaired else Color("1d121d"), Color("fff2fb") if selected else (Color("c45cf0") if repaired else Color("843e59")), 2 if selected else 1, 10), rect)
		var inside: Rect2 = Rect2(rect.position + Vector2(7.0, 7.0), Vector2(rect.size.x - 14.0, 137.0))
		var texture: Texture2D = ROOM_TEXTURES[id] as Texture2D
		draw_texture_rect(texture, inside, false)
		if not repaired:
			draw_rect(inside, Color("160711", 0.58 + sin(pulse * 2.0) * 0.04), true)
			draw_line(inside.position + Vector2(14.0, 14.0), inside.position + Vector2(68.0, 68.0), Color("ff4f78"), 3.0)
			draw_line(inside.position + Vector2(137.0, 15.0), inside.position + Vector2(109.0, 74.0), Color("ff9b6e"), 2.0)
		draw_rect(Rect2(rect.position + Vector2(0.0, 150.0), Vector2(rect.size.x, 56.0)), Color("0b0710", 0.92), true)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 169.0), String(room.get("name", "ROOM")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 178.0, 11, Color("fff5fb"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 188.0), "L%d // %s" % [room.get("level", 1), room.get("function", "")], HORIZONTAL_ALIGNMENT_LEFT, 178.0, 9, Color("c79bb9"))
		var state_text: String
		if repaired:
			state_text = "RUNNING // TAP UPGRADE"
		elif int(room.get("repair_end", 0)) > 0:
			state_text = "REBUILDING %ds" % SyndicateState.seconds_left(int(room.get("repair_end", 0)))
		else:
			state_text = "WRECKED // %d CR" % room.get("repair_cost", 0)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 202.0), state_text, HORIZONTAL_ALIGNMENT_LEFT, 178.0, 8, Color("72f0c1") if repaired else Color("ff9a7c"))

func _draw_jobs() -> void:
	job_rects.clear()
	draw_string(ThemeDB.fallback_font, Vector2(914.0, 128.0), "SCORE BOARD", HORIZONTAL_ALIGNMENT_LEFT, 190.0, 13, Color("ff88c0"))
	if SyndicateState.jobs.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(916.0, 172.0), "Fixers scanning... next window %ds" % SyndicateState.seconds_left(SyndicateState.next_job_at), HORIZONTAL_ALIGNMENT_LEFT, 320.0, 10, Color("9f7895"))
	for i: int in range(SyndicateState.jobs.size()):
		var job: Dictionary = SyndicateState.jobs[i]
		var id: String = String(job.get("id", ""))
		var rect: Rect2 = Rect2(914.0, 145.0 + float(i) * 57.0, 326.0, 50.0)
		job_rects[id] = rect
		var story: bool = bool(job.get("story", false))
		var border: Color = Color("fff4fb") if id == selected_job else (Color("ffbe68") if story else _difficulty(int(job.get("difficulty", 1))))
		draw_style_box(_box(Color("24112c"), border, 1 if id != selected_job else 2, 8), rect)
		var prefix: String = "STORY // " if story else ""
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 17.0), prefix + String(job.get("title", "JOB")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 245.0, 9, Color("fff4fb"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(8.0, 36.0), "%s // D%d // %d CR" % [job.get("sector", "Sector"), job.get("difficulty", 1), job.get("reward", 0)], HORIZONTAL_ALIGNMENT_LEFT, 260.0, 8, Color("c89bb9"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(274.0, 29.0), "%02ds" % SyndicateState.seconds_left(int(job.get("expires_at", 0))), HORIZONTAL_ALIGNMENT_CENTER, 42.0, 10, Color("ffb16f"))

func _draw_crew() -> void:
	crew_rects.clear()
	draw_line(Vector2(912.0, 324.0), Vector2(1240.0, 324.0), Color("e16cff", 0.24), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(914.0, 347.0), "CREW ROSTER // SELECT FOR JOB", HORIZONTAL_ALIGNMENT_LEFT, 290.0, 11, Color("ff88c0"))
	for i: int in range(SyndicateState.crew.size()):
		var member: Dictionary = SyndicateState.crew[i]
		var id: String = String(member.get("id", ""))
		var rect: Rect2 = Rect2(914.0, 360.0 + float(i) * 56.0, 326.0, 49.0)
		crew_rects[id] = rect
		var ready: bool = SyndicateState.crew_available(member)
		draw_style_box(_box(Color("211127"), Color("fff0f9") if selected_crew.has(id) else (Color("b553cc") if ready else Color("67444f")), 1, 8), rect)
		var portrait: Texture2D = PORTRAITS[id] as Texture2D
		draw_texture_rect(portrait, Rect2(rect.position + Vector2(4.0, 3.0), Vector2(43.0, 43.0)), false)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(52.0, 17.0), "%s  L%d" % [member.get("name", "Crew"), member.get("level", 1)], HORIZONTAL_ALIGNMENT_LEFT, 150.0, 10, Color("fff4fb"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(52.0, 35.0), "%s PWR %d HP %d/%d" % [member.get("class", ""), member.get("power", 0), member.get("hp", 0), member.get("max_hp", 0)], HORIZONTAL_ALIGNMENT_LEFT, 220.0, 8, Color("c195b1"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(270.0, 29.0), "READY" if ready else "BUSY", HORIZONTAL_ALIGNMENT_CENTER, 45.0, 8, Color("72f0c1") if ready else Color("ff91ad"))

func _draw_buttons() -> void:
	var selected_data: Dictionary = SyndicateState.get_room(selected_room)
	var room_action: String = "UPGRADE" if bool(selected_data.get("repaired", false)) else "REBUILD"
	var labels: Dictionary = {"run":"RUN JOB", "rebuild":room_action, "tech":"BLACK TECH", "fence":"FENCE CARGO", "save":"SAVE", "load":"LOAD", "reset":"RESET", "routes":"CAMPAIGNS"}
	for key: Variant in buttons:
		var rect: Rect2 = buttons[key] as Rect2
		var active: bool = (key == "run" and not selected_job.is_empty() and not selected_crew.is_empty()) or key == "rebuild"
		draw_style_box(_box(Color("582048") if active else Color("3b183d"), Color("ff8fbc") if active else Color("8e478f"), 1, 8), rect)
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(5.0, 27.0), labels[key], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 10.0, 9, Color("fff5fb"))

func _difficulty(level: int) -> Color:
	return Color("72f0c1") if level <= 1 else (Color("ffbd67") if level == 2 else Color("ff5f7f"))

func _box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style
