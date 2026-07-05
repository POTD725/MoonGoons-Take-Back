class_name MoonGoonsCampaignCatalogValidator
extends RefCounted
## Focused validation for campaign mission catalogs loaded from multiple JSON files.

const REQUIRED_MISSION_FIELDS := ["id", "act", "title", "location", "objectives", "triggers"]

func validate(game_data: MoonGoonsGameData) -> Array[String]:
	var issues: Array[String] = []
	var mission_ids: Dictionary = {}
	for source: Dictionary in [game_data.campaign_missions_data, game_data.campaign_missions_extended_data]:
		var missions: Array = source.get("missions", [])
		for entry: Variant in missions:
			if not (entry is Dictionary):
				issues.append("Campaign mission catalog contains a non-dictionary entry.")
				continue
			var mission: Dictionary = entry as Dictionary
			var mission_id := String(mission.get("id", ""))
			for field: String in REQUIRED_MISSION_FIELDS:
				if not mission.has(field):
					issues.append("Campaign mission %s is missing '%s'." % [mission_id, field])
			if mission_id.is_empty():
				issues.append("Campaign mission has an empty ID.")
			elif mission_ids.has(mission_id):
				issues.append("Duplicate campaign mission ID: %s" % mission_id)
			else:
				mission_ids[mission_id] = true
			_validate_mission_entries(mission, issues)
	if mission_ids.size() != 20:
		issues.append("Expected 20 campaign missions, found %d." % mission_ids.size())
	return issues

func _validate_mission_entries(mission: Dictionary, issues: Array[String]) -> void:
	var mission_id := String(mission.get("id", "unknown"))
	var objectives: Array = mission.get("objectives", [])
	for objective_entry: Variant in objectives:
		if not (objective_entry is Dictionary):
			issues.append("Mission %s has a non-dictionary objective." % mission_id)
			continue
		var objective: Dictionary = objective_entry as Dictionary
		for field: String in ["id", "completion_event", "completion_conditions"]:
			if not objective.has(field):
				issues.append("Mission %s objective is missing '%s'." % [mission_id, field])
	var triggers: Array = mission.get("triggers", [])
	for trigger_entry: Variant in triggers:
		if not (trigger_entry is Dictionary):
			issues.append("Mission %s has a non-dictionary trigger." % mission_id)
			continue
		var trigger: Dictionary = trigger_entry as Dictionary
		for field: String in ["id", "event", "effects"]:
			if not trigger.has(field):
				issues.append("Mission %s trigger is missing '%s'." % [mission_id, field])
