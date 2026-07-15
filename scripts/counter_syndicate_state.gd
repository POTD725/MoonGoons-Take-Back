extends Node
## Shared cops-side campaign state for MoonGoons Take Back.
## Syndicate Rising remains a separate game; here the Syndicate exists only as
## the hostile faction being investigated, raided, arrested, and pushed out.

signal threat_changed

const SAVE_PATH: String = "user://moongoons_take_back_threat.json"

var districts: Array[Dictionary] = []
var syndicate_heat: int = 38
var authority_control: int = 22
var major_arrests: int = 0
var hideouts_exposed: int = 0
var intercepted_scores: int = 0
var current_target_id: String = "crater_market"
var last_briefing: String = "Syndicate activity detected across six lunar districts."

func _ready() -> void:
	if districts.is_empty():
		reset_state()

func reset_state() -> void:
	districts = [
		_district("crater_market", "Crater Market", "Smuggling and black-market exchange", 74, 18, "Nyx Raze Crew"),
		_district("tycho_transit", "Tycho Transit", "Shuttle theft and convoy ambushes", 66, 24, "Grit Mercer Riders"),
		_district("blueglass", "Blueglass Ward", "Data theft and evidence laundering", 58, 31, "Vox-13 Signal Cell"),
		_district("dock_seven", "Dock Seven", "Contraband freight and weapons traffic", 81, 12, "Cinder Quell Network"),
		_district("signal_canyon", "Signal Canyon", "Hacking relays and ghost communications", 69, 19, "Ghost Key Operators"),
		_district("mare_highway", "Mare Highway", "Armored robberies and mobile hideouts", 61, 27, "Dustline Syndicate")
	]
	syndicate_heat = 38
	authority_control = 22
	major_arrests = 0
	hideouts_exposed = 0
	intercepted_scores = 0
	current_target_id = "crater_market"
	last_briefing = "Syndicate activity detected across six lunar districts."
	_recalculate_campaign_totals()
	threat_changed.emit()

func district_catalog() -> Array[Dictionary]:
	return districts

func get_district(district_id: String) -> Dictionary:
	for district: Dictionary in districts:
		if String(district.get("id", "")) == district_id:
			return district
	return {}

func select_target(district_id: String) -> Dictionary:
	var district: Dictionary = get_district(district_id)
	if district.is_empty():
		return {"ok": false, "message": "District record not found."}
	current_target_id = district_id
	last_briefing = "Target locked: %s. %s" % [String(district.get("name", "District")), String(district.get("activity", "Syndicate activity"))]
	threat_changed.emit()
	return {"ok": true, "message": last_briefing}

func investigate_target() -> Dictionary:
	var district: Dictionary = get_district(current_target_id)
	if district.is_empty():
		return {"ok": false, "message": "Select a district first."}
	if PrecinctState.intel < 5:
		return {"ok": false, "message": "Investigation requires 5 intel."}
	PrecinctState.intel -= 5
	district["intel"] = mini(100, int(district.get("intel", 0)) + 16)
	var exposure: int = int(district.get("intel", 0))
	if exposure >= 55 and not bool(district.get("hideout_exposed", false)):
		district["hideout_exposed"] = true
		hideouts_exposed += 1
		last_briefing = "Hideout exposed in %s. A raid operation can now be generated." % String(district.get("name", "the district"))
	else:
		last_briefing = "Investigation advanced in %s. Exposure is now %d%%." % [String(district.get("name", "the district")), exposure]
	PrecinctState.state_changed.emit()
	threat_changed.emit()
	return {"ok": true, "message": last_briefing}

func record_patrol_result(district_id: String, victory: bool, difficulty: int = 1) -> void:
	var district: Dictionary = get_district(district_id)
	if district.is_empty():
		district = get_district(current_target_id)
	if district.is_empty():
		return
	var pressure: int = maxi(3, difficulty * 5)
	if victory:
		district["threat"] = maxi(0, int(district.get("threat", 50)) - pressure)
		district["control"] = mini(100, int(district.get("control", 20)) + pressure)
		district["intel"] = mini(100, int(district.get("intel", 0)) + difficulty * 4)
		intercepted_scores += 1
		last_briefing = "Peacekeepers disrupted a Syndicate score in %s." % String(district.get("name", "the district"))
	else:
		district["threat"] = mini(100, int(district.get("threat", 50)) + pressure)
		district["control"] = maxi(0, int(district.get("control", 20)) - difficulty * 2)
		last_briefing = "Syndicate control increased in %s after a failed response." % String(district.get("name", "the district"))
	_recalculate_campaign_totals()
	threat_changed.emit()

func record_major_arrest(district_id: String = "") -> void:
	major_arrests += 1
	var target_id: String = district_id if not district_id.is_empty() else current_target_id
	var district: Dictionary = get_district(target_id)
	if not district.is_empty():
		district["threat"] = maxi(0, int(district.get("threat", 50)) - 8)
		district["control"] = mini(100, int(district.get("control", 20)) + 6)
		last_briefing = "Major Syndicate arrest recorded in %s." % String(district.get("name", "the district"))
	_recalculate_campaign_totals()
	threat_changed.emit()

func campaign_complete() -> bool:
	for district: Dictionary in districts:
		if int(district.get("control", 0)) < 75:
			return false
	return true

func campaign_status() -> String:
	return "AUTHORITY %d%%   SYNDICATE HEAT %d%%   SCORES STOPPED %d   HIDEOUTS %d/6" % [authority_control, syndicate_heat, intercepted_scores, hideouts_exposed]

func save_state() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"districts": districts,
		"syndicate_heat": syndicate_heat,
		"authority_control": authority_control,
		"major_arrests": major_arrests,
		"hideouts_exposed": hideouts_exposed,
		"intercepted_scores": intercepted_scores,
		"current_target_id": current_target_id,
		"last_briefing": last_briefing
	}))

func load_state() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var data: Dictionary = parsed as Dictionary
	districts = _dictionary_array(data.get("districts", []))
	syndicate_heat = int(data.get("syndicate_heat", 38))
	authority_control = int(data.get("authority_control", 22))
	major_arrests = int(data.get("major_arrests", 0))
	hideouts_exposed = int(data.get("hideouts_exposed", 0))
	intercepted_scores = int(data.get("intercepted_scores", 0))
	current_target_id = String(data.get("current_target_id", "crater_market"))
	last_briefing = String(data.get("last_briefing", "Threat map restored."))
	_recalculate_campaign_totals()
	threat_changed.emit()
	return true

func _recalculate_campaign_totals() -> void:
	if districts.is_empty():
		authority_control = 0
		syndicate_heat = 100
		return
	var control_total: int = 0
	var threat_total: int = 0
	for district: Dictionary in districts:
		control_total += int(district.get("control", 0))
		threat_total += int(district.get("threat", 0))
	authority_control = int(round(float(control_total) / float(districts.size())))
	syndicate_heat = int(round(float(threat_total) / float(districts.size())))

func _district(id_value: String, name_value: String, activity_value: String, threat_value: int, control_value: int, crew_value: String) -> Dictionary:
	return {
		"id": id_value,
		"name": name_value,
		"activity": activity_value,
		"threat": threat_value,
		"control": control_value,
		"intel": 12,
		"crew": crew_value,
		"hideout_exposed": false
	}

func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item: Variant in value:
			if item is Dictionary:
				result.append(item as Dictionary)
	return result
