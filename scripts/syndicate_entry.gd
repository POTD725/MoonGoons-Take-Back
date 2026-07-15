extends Node2D
## Web-facing entry point for the requested criminal-side campaign.
## Fresh players see the illustrated prologue; returning players resume the hideout.

const VIEW: Vector2 = Vector2(1280.0, 720.0)
const EMBLEM: Texture2D = preload("res://assets/syndicate/syndicate_emblem.svg")

var routed: bool = false
var pulse: float = 0.0

func _ready() -> void:
	SyndicateAudio.play_music("hideout")
	call_deferred("_route_to_criminal_campaign")

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _route_to_criminal_campaign() -> void:
	if routed:
		return
	routed = true
	await get_tree().process_frame
	if not SyndicateState.intro_seen or not SyndicateState.pending_cutscene.is_empty():
		get_tree().change_scene_to_file("res://scenes/SyndicateCutscene.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/SyndicateHideout.tscn")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("05030b"))
	for index: int in range(90):
		var x: float = fmod(float(index * 109 + 31), VIEW.x)
		var y: float = fmod(float(index * 61 + 17), VIEW.y)
		draw_circle(Vector2(x, y), 1.0 + float(index % 3) * 0.4, Color("c68dff", 0.18))
	var emblem_rect := Rect2(520.0, 152.0, 240.0, 240.0)
	draw_texture_rect(EMBLEM, emblem_rect, false)
	draw_string(ThemeDB.fallback_font, Vector2(120.0, 462.0), "SYNDICATE RISING", HORIZONTAL_ALIGNMENT_CENTER, 1040.0, 38, Color("fff4fb"))
	draw_string(ThemeDB.fallback_font, Vector2(180.0, 510.0), "RESUMING THE CRIMINAL CAMPAIGN BENEATH CRATER MARKET", HORIZONTAL_ALIGNMENT_CENTER, 920.0, 15, Color("ff91c5"))
	var width: float = 360.0 + sin(pulse * 3.0) * 26.0
	draw_rect(Rect2(460.0, 556.0, 360.0, 8.0), Color("3d183e"), true)
	draw_rect(Rect2(460.0, 556.0, width, 8.0), Color("ff6fab"), true)
