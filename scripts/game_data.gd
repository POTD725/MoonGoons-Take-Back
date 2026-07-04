class_name MoonGoonsGameData
extends RefCounted
## Central loader for MoonGoons data-driven content.
## Unit, building, economy, balance, control, map, and campaign values belong in JSON, not scene scripts.

const UNIT_DATA_PATH := "res://data/unit_data.json"
const BUILDING_DATA_PATH := "res://data/building_data.json"
const RULES_DATA_PATH := "res://data/gameplay_rules.json"

var unit_data: Dictionary = {}
var building_data: Dictionary = {}
var rules_data: Dictionary = {}
var errors: Array[String] = []

func load_all() -> bool:
	errors.clear()
	unit_data = _load_json(UNIT_DATA_PATH)
	building_data = _load_json(BUILDING_DATA_PATH)
	rules_data = _load_json(RULES_DATA_PATH)
	return errors.is_empty()

func get_unit(faction_id: String, unit_id: String) -> Dictionary:
	var factions: Dictionary = unit_data.get("factions", {})
	var faction: Dictionary = factions.get(faction_id, {})
	var units: Array = faction.get("units", [])
	for entry: Variant in units:
		var unit: Dictionary = entry as Dictionary
		if String(unit.get("id", "")) == unit_id:
			return unit.duplicate(true)
	return {}

func get_building(faction_id: String, building_id: String) -> Dictionary:
	var factions: Dictionary = building_data.get("factions", {})
	var faction: Dictionary = factions.get(faction_id, {})
	var buildings: Array = faction.get("buildings", [])
	for entry: Variant in buildings:
		var building: Dictionary = entry as Dictionary
		if String(building.get("id", "")) == building_id:
			return building.duplicate(true)
	return {}

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
		var act: Dictionary = entry as Dictionary
		if String(act.get("id", "")) == act_id:
			return act.duplicate(true)
	return {}

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
