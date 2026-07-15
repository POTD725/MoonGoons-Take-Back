extends "res://scripts/station_progression_state.gd"
## Alliance Construction and Weapons research modifies the existing tested station systems.

func station_upgrade_duration() -> int:
	return AllianceResearch.adjust_construction_time(super.station_upgrade_duration())

func room_upgrade_duration(room_id: String) -> int:
	return AllianceResearch.adjust_construction_time(super.room_upgrade_duration(room_id))

func item_upgrade_duration(room_id: String, item_id: String) -> int:
	return AllianceResearch.adjust_construction_time(super.item_upgrade_duration(room_id, item_id))

func defense_upgrade_duration(defense_id: String) -> int:
	return AllianceResearch.adjust_construction_time(super.defense_upgrade_duration(defense_id))

func defense_rating() -> int:
	return super.defense_rating() + AllianceResearch.defense_rating_bonus()
