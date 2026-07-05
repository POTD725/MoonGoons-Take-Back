class_name MoonGoonsAchievementTracker
extends RefCounted
## Event-driven achievement tracker with local profile persistence.
## Achievement evaluation occurs only when relevant game events are reported.

signal achievement_unlocked(achievement_id: String, reward: Dictionary)

const DEFAULT_CATALOG_PATH := "res://data/achievements.json"
const DEFAULT_PROFILE_PATH := "user://profile_save.json"

var _catalog: Dictionary = {}
var _profile: Dictionary = {}
var _session_counters: Dictionary = {}
var errors: Array[String] = []

func load(catalog_path: String = DEFAULT_CATALOG_PATH, profile_path: String = DEFAULT_PROFILE_PATH) -> bool:
	errors.clear()
	_catalog = _load_json(catalog_path)
	if _catalog.is_empty():
		return false
	_profile = _load_json(profile_path)
	if _profile.is_empty():
		_profile = (_catalog.get("default_profile", {}) as Dictionary).duplicate(true)
	return true

func record_event(event_id: String, payload: Dictionary = {}) -> Array[String]:
	var unlocked: Array[String] = []
	match event_id:
		"on_unit_arrest":
			_session_counters["current_match_arrests"] = int(_session_counters.get("current_match_arrests", 0)) + 1
		"on_siphon_tick":
			_add_persistent_counter("total_credits_siphoned", int(payload.get("credits", 0)))
		"on_mission_complete", "on_match_end":
			pass
		_:
			return unlocked
	for achievement: Dictionary in _achievements_for_event(event_id):
		if _is_unlocked(String(achievement.get("id", ""))):
			continue
		if _criteria_met(achievement, payload):
			_unlock(achievement)
			unlocked.append(String(achievement.get("id", "")))
	return unlocked

func save_profile(profile_path: String = DEFAULT_PROFILE_PATH) -> bool:
	var file := FileAccess.open(profile_path, FileAccess.WRITE)
	if file == null:
		errors.append("Could not write player profile: %s" % profile_path)
		return false
	file.store_string(JSON.stringify(_profile, "  "))
	return true

func get_profile() -> Dictionary:
	return _profile.duplicate(true)

func reset_match_session() -> void:
	_session_counters.clear()

func _achievements_for_event(event_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var achievements: Array = _catalog.get("achievements", [])
	for entry: Variant in achievements:
		if entry is Dictionary:
			var achievement: Dictionary = entry as Dictionary
			if String(achievement.get("tracking_event", "")) == event_id:
				result.append(achievement)
	return result

func _criteria_met(achievement: Dictionary, payload: Dictionary) -> bool:
	var criteria: Dictionary = achievement.get("criteria", {})
	if criteria.has("mission_id"):
		return String(payload.get("mission_id", "")) == String(criteria["mission_id"]) and String(payload.get("outcome", "completed")) == "completed"
	if criteria.has("session_counter"):
		return int(_session_counters.get(String(criteria["session_counter"]), 0)) >= int(criteria.get("minimum", 0))
	if criteria.has("persistent_counter"):
		return _persistent_counter(String(criteria["persistent_counter"])) >= int(criteria.get("minimum", 0))
	if criteria.has("faction"):
		return String(payload.get("faction", "")) == String(criteria["faction"]) and String(payload.get("outcome", "")) == String(criteria.get("outcome", "victory")) and float(payload.get("corrupted_cells_pct", 0.0)) >= float(criteria.get("corrupted_cells_pct_minimum", 1.0))
	if criteria.has("evidence_collected_count_equals"):
		return int(payload.get("evidence_collected_count", -1)) == int(payload.get("max_campaign_evidence", -2))
	return false

func _unlock(achievement: Dictionary) -> void:
	var achievement_id := String(achievement.get("id", ""))
	var progression := _progression()
	var unlocked: Array = progression.get("unlocked_achievements", [])
	if not unlocked.has(achievement_id):
		unlocked.append(achievement_id)
		progression["unlocked_achievements"] = unlocked
	var reward: Dictionary = achievement.get("reward", {})
	var cosmetics: Array = progression.get("unlocked_cosmetics", [])
	if String(reward.get("type", "")) == "cosmetic" and not cosmetics.has(String(reward.get("id", ""))):
		cosmetics.append(String(reward.get("id", "")))
		progression["unlocked_cosmetics"] = cosmetics
	_profile["persistent_progression"] = progression
	achievement_unlocked.emit(achievement_id, reward.duplicate(true))

func _is_unlocked(achievement_id: String) -> bool:
	return (_progression().get("unlocked_achievements", []) as Array).has(achievement_id)

func _add_persistent_counter(counter_id: String, amount: int) -> void:
	var progression := _progression()
	progression[counter_id] = int(progression.get(counter_id, 0)) + amount
	_profile["persistent_progression"] = progression

func _persistent_counter(counter_id: String) -> int:
	return int(_progression().get(counter_id, 0))

func _progression() -> Dictionary:
	var progression: Dictionary = _profile.get("persistent_progression", {})
	_profile["persistent_progression"] = progression
	return progression

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}
