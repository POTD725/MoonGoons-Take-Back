class_name MoonGoonsAudioDirector
extends Node
## Audio routing layer. It does not require audio assets to exist yet.
## When asset banks are added, connect the emitted event names to AudioStreamPlayers or FMOD events.

enum MusicState {
	UNDERWORLD_AMBIENCE,
	TACTICAL_ESCALATION,
	SYNDICATE_TURF_WAR
}

signal music_state_requested(state_id: String)
signal audio_event_requested(event_id: String, payload: Dictionary)

var current_state: MusicState = MusicState.UNDERWORLD_AMBIENCE
var active_combatants := 0
var in_contested_sector := false
var headquarters_damaged := false

func update_mix(combatant_count: int, contested_sector_active: bool, headquarters_is_damaged: bool) -> void:
	active_combatants = maxi(0, combatant_count)
	in_contested_sector = contested_sector_active
	headquarters_damaged = headquarters_is_damaged
	var desired_state := _resolve_music_state()
	if desired_state != current_state:
		current_state = desired_state
		music_state_requested.emit(music_state_name())

func music_state_name() -> String:
	match current_state:
		MusicState.UNDERWORLD_AMBIENCE:
			return "music_ambient"
		MusicState.TACTICAL_ESCALATION:
			return "music_escalation"
		MusicState.SYNDICATE_TURF_WAR:
			return "music_war"
	return "music_ambient"

func request_unit_voice(faction_id: String, trigger_id: String, unit_id: String = "") -> void:
	var prefix := _faction_prefix(faction_id)
	var event_id := "%s_voice_%s" % [prefix, trigger_id]
	audio_event_requested.emit(event_id, {"faction_id": faction_id, "unit_id": unit_id})

func request_weapon_sound(faction_id: String, weapon_id: String, position: Vector2 = Vector2.ZERO) -> void:
	var prefix := _faction_prefix(faction_id)
	audio_event_requested.emit("%s_weapon_%s" % [prefix, weapon_id], {"position": position})

func request_ui_sound(event_id: String) -> void:
	audio_event_requested.emit("ui_%s" % event_id, {})

func request_world_sound(event_id: String, position: Vector2 = Vector2.ZERO) -> void:
	audio_event_requested.emit("world_%s" % event_id, {"position": position})

func _resolve_music_state() -> MusicState:
	if headquarters_damaged or active_combatants > 10:
		return MusicState.SYNDICATE_TURF_WAR
	if in_contested_sector or active_combatants > 0:
		return MusicState.TACTICAL_ESCALATION
	return MusicState.UNDERWORLD_AMBIENCE

func _faction_prefix(faction_id: String) -> String:
	match faction_id:
		"lunar_peacekeepers":
			return "pk"
		"the_syndicate":
			return "syn"
		"the_nullborn":
			return "nb"
	return "world"
