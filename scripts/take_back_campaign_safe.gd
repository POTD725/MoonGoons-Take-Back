extends "res://scripts/take_back_campaign_state.gd"
## Godot 4.3-compatible scene polling for the shared campaign.

var _last_scene_name: String = ""
var _scene_poll_clock: float = 0.0

func _ready() -> void:
	load_state()
	if SpaceThreats != null:
		if SpaceThreats.has_signal("battle_started") and not SpaceThreats.is_connected("battle_started", _on_space_battle_started):
			SpaceThreats.connect("battle_started", _on_space_battle_started)
		if SpaceThreats.has_signal("target_defeated") and not SpaceThreats.is_connected("target_defeated", _on_target_defeated):
			SpaceThreats.connect("target_defeated", _on_target_defeated)
	if StationProgression != null and StationProgression.has_signal("marauder_alert") and not StationProgression.is_connected("marauder_alert", _on_marauder_alert):
		StationProgression.connect("marauder_alert", _on_marauder_alert)
	set_process(true)
	call_deferred("_offer_origin")

func _process(delta: float) -> void:
	_scene_poll_clock += delta
	if _scene_poll_clock < 0.25:
		return
	_scene_poll_clock = 0.0
	var scene: Node = get_tree().current_scene
	var scene_name: String = scene.name if scene != null else ""
	if scene_name == _last_scene_name:
		return
	_last_scene_name = scene_name
	if not intro_seen and scene_name == "LivingPrecinct":
		call_deferred("launch_origin")
