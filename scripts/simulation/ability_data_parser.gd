class_name MoonGoonsAbilityDataParser
extends RefCounted
## Converts unit JSON profiles into deterministic simulation spawn configurations.
## Read raw data once at mission load; do not parse files inside a simulation tick.

var _profiles_by_id: Dictionary = {}
var errors: Array[String] = []

func initialize_from_paths(data_paths: Array[String]) -> bool:
	errors.clear()
	_profiles_by_id.clear()
	for data_path: String in data_paths:
		var source := _load_json(data_path)
		if source.is_empty():
			continue
		_cache_unit_profiles(source, data_path)
	return errors.is_empty()

func initialize_from_game_data(game_data: MoonGoonsGameData) -> bool:
	return initialize_from_paths([
		MoonGoonsGameData.UNIT_DATA_PATH,
		MoonGoonsGameData.UNIT_TIER_2_DATA_PATH,
		MoonGoonsGameData.UNIT_TIER_3_DATA_PATH
	])

func get_profile(unit_id: String) -> Dictionary:
	var profile: Dictionary = _profiles_by_id.get(unit_id, {})
	return profile.duplicate(true)

func get_ability(unit_id: String, ability_id: String) -> Dictionary:
	var profile := get_profile(unit_id)
	var abilities: Array = profile.get("abilities", [])
	for entry: Variant in abilities:
		if entry is Dictionary:
			var ability: Dictionary = entry as Dictionary
			if String(ability.get("id", "")) == ability_id:
				return ability.duplicate(true)
	return {}

func spawn_unit_from_catalog(
	unit_id: String,
	faction_id: String,
	start_x_fp: int,
	start_z_fp: int,
	instance_id: String
) -> MoonGoonsSimulationUnit:
	var profile := get_profile(unit_id)
	if profile.is_empty():
		errors.append("Cannot spawn unknown unit profile: %s" % unit_id)
		return null
	var stats: Dictionary = profile.get("stats", {})
	var speed_fp := MoonGoonsFixedMath.from_float(float(stats.get("movement_speed", 0.0)))
	return MoonGoonsSimulationUnit.new(instance_id, faction_id, start_x_fp, start_z_fp, speed_fp)

func profile_count() -> int:
	return _profiles_by_id.size()

func _cache_unit_profiles(source: Dictionary, source_label: String) -> void:
	var factions: Dictionary = source.get("factions", {})
	for faction_id: Variant in factions:
		var faction: Dictionary = factions.get(faction_id, {})
		var units: Array = faction.get("units", [])
		for entry: Variant in units:
			if not (entry is Dictionary):
				errors.append("Non-dictionary unit profile in %s/%s." % [source_label, faction_id])
				continue
			var profile: Dictionary = entry as Dictionary
			var profile_id := String(profile.get("id", ""))
			if profile_id.is_empty():
				errors.append("Unit profile in %s has no id." % source_label)
				continue
			if _profiles_by_id.has(profile_id):
				errors.append("Duplicate unit profile id: %s" % profile_id)
				continue
			_profiles_by_id[profile_id] = profile.duplicate(true)

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("Missing unit data source: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Could not open unit data source: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		errors.append("Invalid JSON object in unit data source: %s" % path)
		return {}
	return parsed as Dictionary
