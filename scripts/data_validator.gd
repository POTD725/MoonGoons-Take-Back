class_name MoonGoonsDataValidator
extends RefCounted
## Lightweight schema checks for local debug builds and CI headless runs.

const REQUIRED_UNIT_FIELDS := ["id", "name", "tier", "class", "cost", "stats", "weapon", "abilities"]
const REQUIRED_BUILDING_FIELDS := ["id", "name", "tier", "cost"]
const REQUIRED_LOCALIZATION_KEYS := [
	"ui_menu.start_game",
	"resources.credits_label",
	"system_alerts.game_desynced"
]

func validate(game_data: MoonGoonsGameData) -> Array[String]:
	var issues: Array[String] = []
	issues.append_array(game_data.errors)
	_validate_unit_source(game_data.unit_data, "tier_1", issues)
	_validate_unit_source(game_data.unit_tier_2_data, "tier_2", issues)
	_validate_unit_source(game_data.unit_tier_3_data, "tier_3", issues)
	_validate_building_source(game_data.building_data, issues)
	_validate_runtime_profiles(game_data.building_runtime_data, game_data.building_data, issues)
	_validate_damage_rules(game_data.rules_data, issues)
	_validate_localization(game_data.localization_data, issues)
	_validate_achievements(game_data.achievements_data, issues)
	_validate_fx_profiles(game_data.fx_profiles_data, issues)
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

func _validate_localization(localization: Dictionary, issues: Array[String]) -> void:
	var meta: Dictionary = localization.get("meta", {})
	var languages: Dictionary = localization.get("languages", {})
	var supported_languages: Array = meta.get("supported_languages", [])
	for language_id: Variant in supported_languages:
		var language := String(language_id)
		if not languages.has(language):
			issues.append("Localization metadata lists missing language: %s" % language)
			continue
		for key_path: String in REQUIRED_LOCALIZATION_KEYS:
			if _lookup_path(languages[language] as Dictionary, key_path).is_empty():
				issues.append("Localization %s is missing %s." % [language, key_path])

func _validate_achievements(achievements_data: Dictionary, issues: Array[String]) -> void:
	var seen_ids: Dictionary = {}
	var achievements: Array = achievements_data.get("achievements", [])
	for entry: Variant in achievements:
		if not (entry is Dictionary):
			issues.append("Achievement list contains a non-dictionary entry.")
			continue
		var achievement: Dictionary = entry as Dictionary
		var achievement_id := String(achievement.get("id", ""))
		if achievement_id.is_empty() or not achievement.has("tracking_event") or not achievement.has("criteria"):
			issues.append("Achievement has incomplete schema: %s" % achievement_id)
		elif seen_ids.has(achievement_id):
			issues.append("Duplicate achievement id: %s" % achievement_id)
		seen_ids[achievement_id] = true

func _validate_fx_profiles(fx_data: Dictionary, issues: Array[String]) -> void:
	var profiles: Dictionary = fx_data.get("profiles", {})
	for profile_id: Variant in profiles:
		var profile: Variant = profiles[profile_id]
		if not (profile is Dictionary):
			issues.append("FX profile %s is not a dictionary." % String(profile_id))
			continue
		if not bool((profile as Dictionary).get("simulation_decoupled", false)):
			issues.append("FX profile %s must declare simulation_decoupled=true." % String(profile_id))

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

func _lookup_path(root: Dictionary, key_path: String) -> String:
	var node: Variant = root
	for segment: String in key_path.split(".", false):
		if not (node is Dictionary):
			return ""
		node = (node as Dictionary).get(segment)
	return String(node) if node is String else ""
