extends Node
## Shared MoonGoons canon linking Take Back to Syndicate Rising.

signal campaign_changed
signal cinematic_requested(kind: String)

const SAVE_PATH: String = "user://moongoons_take_back_campaign.json"
const HOME_SCENE: String = "res://scenes/LivingPrecinct.tscn"
const CINEMATIC_SCENE: String = "res://scenes/TakeBackCinematic.tscn"

const ORIGIN_SLIDES: Array[Dictionary] = [
	{
		"title":"THE NIGHT CRATER MARKET WENT DARK",
		"kicker":"ORIGIN // 00.01",
		"body":"A coordinated blackout cut the market, transit relays, and precinct telemetry at the same instant. While civilians fought for air and light, Nyx Raze moved a Syndicate crew through the blind zone.",
		"art":"surface",
		"speaker":"AUTHORITY ARCHIVE"
	},
	{
		"title":"THE GHOST KEY",
		"kicker":"ORIGIN // 00.02",
		"body":"Vox-13 stole a relay cipher called the Ghost Key. It could open patrol routes, station maintenance locks, and dormant Authority systems across the Moon.",
		"art":"vox",
		"speaker":"INTELLIGENCE DIVISION"
	},
	{
		"title":"A STATION LEFT TO ROT",
		"kicker":"ORIGIN // 00.03",
		"body":"The nearest Peacekeeper station had been abandoned room by room. Its hull still held, but its weapons, engines, medbay, cells, and command systems were broken or stripped.",
		"art":"station",
		"speaker":"RECOVERY LOG"
	},
	{
		"title":"THE TAKE BACK DIRECTIVE",
		"kicker":"ORIGIN // 00.04",
		"body":"You are ordered to restore the station, rebuild its crew, protect the lunar settlements, and reclaim every route the Syndicate converted into a private kingdom.",
		"art":"response",
		"speaker":"LUNAR AUTHORITY"
	},
	{
		"title":"TWO SIDES OF THE SAME WAR",
		"kicker":"ORIGIN // 00.05",
		"body":"In Syndicate Rising, Nyx and her crew exploit the blackout. In Take Back, your station answers it. Victories, raids, stolen resources, and named commanders belong to one shared MoonGoons timeline.",
		"art":"nyx",
		"speaker":"MOONGOONS CANON"
	}
]

const CHAPTERS: Array[Dictionary] = [
	{"id":"origin", "title":"The Crater Market Blackout", "target":"", "reward":"Station command restored"},
	{"id":"ghost_route", "title":"Ghosts in the Courier Lane", "target":"vox_courier_pack", "reward":"Ghost Key fragments recovered"},
	{"id":"cinder_line", "title":"The Cinder Escort", "target":"grit_cinder_escort", "reward":"Cinder-9 supply route secured"},
	{"id":"longshot", "title":"Sharpshot Over Selene", "target":"cinder_selene_wing", "reward":"Selene patrol grid restored"},
	{"id":"iron_choir", "title":"Nyx at the Iron Choir", "target":"nyx_iron_raiders", "reward":"Syndicate command trail exposed"},
	{"id":"crater_crown", "title":"The Crater Crown", "target":"crater_crown_command", "reward":"Act I complete"}
]

var intro_seen: bool = false
var current_chapter: int = 0
var completed_chapters: Array[String] = []
var cinematic_kind: String = ""
var cinematic_target_id: String = ""
var cinematic_slide_index: int = 0
var return_scene: String = HOME_SCENE
var last_event: String = "The Take Back directive is waiting for command authorization."
var _launching: bool = false

func _ready() -> void:
	load_state()
	get_tree().scene_changed.connect(_on_scene_changed)
	if SpaceThreats != null:
		if SpaceThreats.has_signal("battle_started"):
			SpaceThreats.connect("battle_started", _on_space_battle_started)
		if SpaceThreats.has_signal("target_defeated"):
			SpaceThreats.connect("target_defeated", _on_target_defeated)
	if StationProgression != null and StationProgression.has_signal("marauder_alert"):
		StationProgression.connect("marauder_alert", _on_marauder_alert)
	call_deferred("_offer_origin")

func _on_scene_changed(scene: Node) -> void:
	if scene == null or _launching:
		return
	if not intro_seen and scene.name == "LivingPrecinct":
		call_deferred("launch_origin")

func _offer_origin() -> void:
	if not intro_seen and get_tree().current_scene != null and get_tree().current_scene.name == "LivingPrecinct":
		launch_origin()

func launch_origin() -> void:
	if not _can_show_cinematics() or _launching:
		return
	cinematic_kind = "origin"
	cinematic_target_id = ""
	cinematic_slide_index = 0
	return_scene = HOME_SCENE
	_launch_cinematic()

func launch_space_attack(target_id: String) -> void:
	if not _can_show_cinematics() or _launching:
		return
	cinematic_kind = "space_attack"
	cinematic_target_id = target_id
	cinematic_slide_index = 0
	return_scene = HOME_SCENE
	_launch_cinematic()

func launch_marauder_attack() -> void:
	if not _can_show_cinematics() or _launching:
		return
	cinematic_kind = "marauder_attack"
	cinematic_target_id = ""
	cinematic_slide_index = 0
	return_scene = HOME_SCENE
	_launch_cinematic()

func _launch_cinematic() -> void:
	_launching = true
	cinematic_requested.emit(cinematic_kind)
	get_tree().change_scene_to_file(CINEMATIC_SCENE)
	call_deferred("_clear_launch_lock")

func _clear_launch_lock() -> void:
	_launching = false

func cinematic_slides() -> Array[Dictionary]:
	if cinematic_kind == "origin":
		return ORIGIN_SLIDES.duplicate(true)
	if cinematic_kind == "space_attack":
		var target: Dictionary = SpaceThreats.get_target(cinematic_target_id) if SpaceThreats != null else {}
		var commander: String = String(target.get("commander", "Syndicate Fleet"))
		var title: String = String(target.get("title", "Syndicate Intercept"))
		var ship: String = String(target.get("ship", "Unknown raiders"))
		var portrait_key: String = _portrait_key(String(target.get("crew_id", "crew_1")))
		return [
			{"kicker":"ATTACK ALERT", "title":title.to_upper(), "body":"%s has moved %s into an Authority resource lane. Interceptors are launching now." % [commander, ship], "art":"response", "speaker":"TACTICAL CONTROL"},
			{"kicker":"COMMANDER IDENTIFIED", "title":commander.to_upper(), "body":"This commander also appears in Syndicate Rising. Defeating the fleet advances the same shared conflict from the Peacekeeper side.", "art":portrait_key, "speaker":"INTELLIGENCE DIVISION"}
		]
	return [
		{"kicker":"STATION ATTACK", "title":"MARAUDERS INBOUND", "body":"Unknown ships are crossing the defense perimeter. Point-defense turrets, rail batteries, shields, and interceptors will determine whether the station holds.", "art":"response", "speaker":"DEFENSE CONTROL"},
		{"kicker":"BATTLE STATIONS", "title":"PROTECT THE PRECINCT", "body":"Keep the command chain alive. If the perimeter fails, repair the hull, reinforce the rooms, and upgrade every defense to the station level cap.", "art":"station", "speaker":"CHIEF'S OFFICE"}
	]

func advance_cinematic() -> bool:
	var slides: Array[Dictionary] = cinematic_slides()
	if cinematic_slide_index + 1 < slides.size():
		cinematic_slide_index += 1
		campaign_changed.emit()
		return true
	finish_cinematic()
	return false

func previous_cinematic() -> bool:
	if cinematic_slide_index <= 0:
		return false
	cinematic_slide_index -= 1
	campaign_changed.emit()
	return true

func finish_cinematic() -> void:
	if cinematic_kind == "origin":
		intro_seen = true
		if not completed_chapters.has("origin"):
			completed_chapters.append("origin")
		current_chapter = maxi(current_chapter, 1)
		last_event = "Origin complete. The station has accepted the Take Back directive."
	cinematic_kind = ""
	cinematic_target_id = ""
	cinematic_slide_index = 0
	save_state()
	campaign_changed.emit()
	get_tree().change_scene_to_file(return_scene)

func chapter_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index: int in range(CHAPTERS.size()):
		var entry: Dictionary = CHAPTERS[index].duplicate(true)
		entry["index"] = index
		entry["completed"] = completed_chapters.has(String(entry.get("id", "")))
		entry["active"] = index == current_chapter
		entry["locked"] = index > current_chapter
		result.append(entry)
	return result

func current_chapter_data() -> Dictionary:
	return CHAPTERS[clampi(current_chapter, 0, CHAPTERS.size() - 1)].duplicate(true)

func reset_campaign() -> void:
	intro_seen = false
	current_chapter = 0
	completed_chapters = []
	cinematic_kind = ""
	cinematic_target_id = ""
	cinematic_slide_index = 0
	last_event = "The Take Back directive is waiting for command authorization."
	save_state()
	campaign_changed.emit()

func save_state() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"intro_seen":intro_seen,
		"current_chapter":current_chapter,
		"completed_chapters":completed_chapters,
		"last_event":last_event
	}))

func load_state() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var data: Dictionary = parsed as Dictionary
	intro_seen = bool(data.get("intro_seen", false))
	current_chapter = clampi(int(data.get("current_chapter", 0)), 0, CHAPTERS.size() - 1)
	completed_chapters = []
	var raw_completed: Variant = data.get("completed_chapters", [])
	if raw_completed is Array:
		for value: Variant in raw_completed:
			completed_chapters.append(String(value))
	last_event = String(data.get("last_event", last_event))
	return true

func _on_space_battle_started(target_id: String) -> void:
	call_deferred("launch_space_attack", target_id)

func _on_target_defeated(target_id: String, commander: String) -> void:
	if current_chapter >= CHAPTERS.size():
		return
	var active: Dictionary = current_chapter_data()
	if String(active.get("target", "")) != target_id:
		return
	var chapter_id: String = String(active.get("id", ""))
	if not completed_chapters.has(chapter_id):
		completed_chapters.append(chapter_id)
	last_event = "%s defeated. %s" % [commander, String(active.get("reward", "Chapter complete."))]
	current_chapter = mini(CHAPTERS.size() - 1, current_chapter + 1)
	save_state()
	campaign_changed.emit()

func _on_marauder_alert() -> void:
	call_deferred("launch_marauder_attack")

func _portrait_key(crew_id: String) -> String:
	match crew_id:
		"crew_2": return "vox"
		"crew_3": return "cinder"
		"crew_4": return "grit"
		_: return "nyx"

func _can_show_cinematics() -> bool:
	return DisplayServer.get_name() != "headless" and get_tree() != null
