class_name MoonGoonsGameData
extends RefCounted
## Central loader for MoonGoons data-driven content.
## Unit, building, economy, balance, control, map, and campaign values belong in JSON, not scene scripts.

const UNIT_DATA_PATH := "res://data/unit_data.json"
const UNIT_TIER_2_DATA_PATH := "res://data/unit_tier_2.json"
const BUILDING_DATA_PATH := "res://data/building_data.json"
const BUILDING_RUNTIME_DATA_PATH := "res://data/building_runtime_profiles.json"
const RULES_DATA_PATH := "res://data/gameplay_rules.json"

var unit_data: Dictionary = {}
var unit_tier_2_data: Dictionary = {}
var building_data: Dictionary = {}
var building_runtime_data: Dictionary = {}
var rules_data: Dictionary = {}
var errors: Array[String] = []

func load_all() -> bool:
	errors.clear()
	unit_data = _load_json(UNIT_DATA_PATH)
	unit_tier_2_data = _load_json(UNIT_TIER_2_DATA_PATH)
	building_data = _load_json(BUILDING_DATA_PATH)
	building_runtime_data = _load_json(BUILDING_RUNTIME_DATA_PATH)
	rules_data = _load_json(RULES_DATA_PATH)
	return errors.is_empty()

func get_unit(faction_id: String, unit_id: String) -> Dictionary:
	var unit := _find_profile(unit_data, faction_id, "units", unit_id)
	if not unit.is_empty():
		return unit
	return _find_profile(unit_tier_2_data, faction_id, "units", unit_id)

func get_units_for_faction(faction_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for source: Dictionary in [unit_data, unit_tier_2_data]:
		var factions: Dictionary = source.get("factions", {})
		var faction: Dictionary = factions.get(faction_id, {})
		var units: Array = faction.get("units", [])
		for entry: Variant in units:
			if entry is Dictionary:
				result.append((entry as Dictionary).duplicate(true))
	return result

func get_building(faction_id: String, building_id: String) -> Dictionary:
	var base_building := _find_profile(building_data, faction_id, "buildings", building_id)
	var runtime_profile := _find_profile(building_runtime_data, faction_id, "structures", building_id)
	if base_building.is_empty():
		return runtime_profile
	return _deep_merge(base_building, runtime_profile)

func get_building_runtime(faction_id: String, building_id: String) -> Dictionary:
	return _find_profile(building_runtime_data, faction_id, "structures", building_id)

func get_resource(resource_id: String) -> Dictionary:
	var resources: Dictionary = rules_data.get("resources", {})
	var resource: Dictionary = resources.get(resource_id, {})
	return resource.duplicate(true)

func get_damage_multiplier(damage_type: String, armor_class: String) -> float:
	var modifiers: Dictionary = rules_data.get("damage_modifiers", {})
	var damage_row: Dictionary = modifiers.get(damage_type, {})
	return float(damage_row.get(armor_class, 1.0))

func get_grid_hotkey(key: String) -> String:
	var controls: Dictionary = rules_data.get("controls", {})
	var grid: Dictionary = controls.get("grid", {})
	return String(grid.get(key.to_upper(), ""))

func get_campaign_act(act_id: String) -> Dictionary:
	var campaign: Dictionary = rules_data.get("campaign", {})
	var acts: Array = campaign.get("acts", [])
	for entry: Variant in acts:
		if entry is Dictionary:
			var act: Dictionary = entry
			if String(act.get("id", "")) == act_id:
				return act.duplicate(true)
	return {}

func _find_profile(source: Dictionary, faction_id: String, collection_key: String, profile_id: String) -> Dictionary:
	var factions: Dictionary = source.get("factions", {})
	var faction: Dictionary = factions.get(faction_id, {})
	var entries: Array = faction.get(collection_key, [])
	for entry: Variant in entries:
		if entry is Dictionary:
			var profile: Dictionary = entry
			if String(profile.get("id", "")) == profile_id:
				return profile.duplicate(true)
	return {}

func _deep_merge(base: Dictionary, overlay: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key: Variant in overlay:
		var overlay_value: Variant = overlay[key]
		if result.has(key) and result[key] is Dictionary and overlay_value is Dictionary:
			result[key] = _deep_merge(result[key], overlay_value)
		else:
			result[key] = overlay_value
	return result

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("Missing data file: %s" % path)
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Could not open data file: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		errors.append("Invalid JSON object in: %s" % path)
		return {}
	return parsed as Dictionary
