class_name MoonGoonsDataValidator
extends RefCounted
## Lightweight schema checks for local debug builds and CI headless runs.

const REQUIRED_UNIT_FIELDS := ["id", "name", "tier", "class", "cost", "stats", "weapon", "abilities"]
const REQUIRED_BUILDING_FIELDS := ["id", "name", "tier", "cost"]

func validate(game_data: MoonGoonsGameData) -> Array[String]:
	var issues: Array[String] = []
	issues.append_array(game_data.errors)
	_validate_unit_source(game_data.unit_data, "tier_1", issues)
	_validate_unit_source(game_data.unit_tier_2_data, "tier_2", issues)
	_validate_building_source(game_data.building_data, issues)
	_validate_runtime_profiles(game_data.building_runtime_data, game_data.building_data, issues)
	_validate_damage_rules(game_data.rules_data, issues)
	return issues

func _validate_unit_source(source: Dictionary, source_label: String, issues: Array[String]) -> void:
	var factions: Dictionary = source.get("factions", {})
	for faction_id: Variant in factions:
		var faction: Dictionary = factions.get(faction_id, {})
		var units: Array = faction.get("units", [])
		for entry: Variant in units:
			if not (entry is Dictionary):
				issues.append("%s/%s contains a non-dictionary unit profile." % [source_label, faction_id])
				continue
			var unit: Dictionary = entry as Dictionary
			for field: String in REQUIRED_UNIT_FIELDS:
				if not unit.has(field):
					issues.append("Unit %s is missing '%s'." % [String(unit.get("id", "unknown")), field])
			var cost: Dictionary = unit.get("cost", {})
			if cost.is_empty() or not cost.has("credits") or not cost.has("command_capacity"):
				issues.append("Unit %s has incomplete cost data." % String(unit.get("id", "unknown")))

func _validate_building_source(source: Dictionary, issues: Array[String]) -> void:
	var factions: Dictionary = source.get("factions", {})
	for faction_id: Variant in factions:
		var faction: Dictionary = factions.get(faction_id, {})
		var buildings: Array = faction.get("buildings", [])
		for entry: Variant in buildings:
			if not (entry is Dictionary):
				issues.append("Building source %s contains a non-dictionary entry." % faction_id)
				continue
			var building: Dictionary = entry as Dictionary
			for field: String in REQUIRED_BUILDING_FIELDS:
				if not building.has(field):
					issues.append("Building %s is missing '%s'." % [String(building.get("id", "unknown")), field])

func _validate_runtime_profiles(runtime_source: Dictionary, base_source: Dictionary, issues: Array[String]) -> void:
	var factions: Dictionary = runtime_source.get("factions", {})
	for faction_id: Variant in factions:
		var faction: Dictionary = factions.get(faction_id, {})
		var structures: Array = faction.get("structures", [])
		for entry: Variant in structures:
			if not (entry is Dictionary):
				issues.append("Runtime profile in %s is not a dictionary." % faction_id)
				continue
			var structure: Dictionary = entry as Dictionary
			var structure_id := String(structure.get("id", ""))
			if structure_id.is_empty():
				issues.append("Runtime building profile has no id.")
				continue
			if _find_building(base_source, String(faction_id), structure_id).is_empty():
				issues.append("Runtime building profile %s has no matching building_data entry." % structure_id)
			var stats: Dictionary = structure.get("stats", {})
			if not stats.is_empty() and (not stats.has("max_hp") or not stats.has("armor") or not stats.has("construction_time_seconds")):
				issues.append("Runtime building profile %s has incomplete stats." % structure_id)

func _validate_damage_rules(rules: Dictionary, issues: Array[String]) -> void:
	var modifiers: Dictionary = rules.get("damage_modifiers", {})
	for damage_type: String in ["kinetic", "energy", "bio_acid"]:
		var row: Dictionary = modifiers.get(damage_type, {})
		for armor_class: String in ["light_infantry", "heavy_infantry", "heavy_mechanical"]:
			if not row.has(armor_class):
				issues.append("Damage rule %s is missing %s." % [damage_type, armor_class])

func _find_building(source: Dictionary, faction_id: String, building_id: String) -> Dictionary:
	var factions: Dictionary = source.get("factions", {})
	var faction: Dictionary = factions.get(faction_id, {})
	var buildings: Array = faction.get("buildings", [])
	for entry: Variant in buildings:
		if entry is Dictionary:
			var building: Dictionary = entry as Dictionary
			if String(building.get("id", "")) == building_id:
				return building
	return {}
