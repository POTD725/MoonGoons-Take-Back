extends Node
## Station assignments, custody work, missions, and command progression.

signal meta_changed

const SAVE_PATH: String = "user://moongoons_precinct_meta.json"

var room_assignments: Dictionary = {}
var task_claims: Dictionary = {}
var tutorial_step: int = 0
var chapter: int = 1
var reputation: int = 0
var prisoners_interrogated: int = 0
var prisoners_transferred: int = 0

func _ready() -> void:
	load_meta()

func reset_meta() -> void:
	room_assignments = {}
	task_claims = {}
	tutorial_step = 0
	chapter = 1
	reputation = 0
	prisoners_interrogated = 0
	prisoners_transferred = 0
	save_meta()
	meta_changed.emit()

func upgrade_room(room_id: String) -> Dictionary:
	var progression: Node = get_node_or_null("/root/StationProgression")
	if progression != null and progression.has_method("begin_room_upgrade"):
		return progression.call("begin_room_upgrade", room_id) as Dictionary
	return _result(false, "Station progression service is unavailable.")

func chief_level() -> int:
	return maxi(1, int(PrecinctState.get_room("chief").get("level", 1)))

func train_officer(officer_id: String) -> Dictionary:
	var officer: Dictionary = PrecinctState.get_officer(officer_id)
	if officer.is_empty():
		return _result(false, "Officer not found.")
	if not PrecinctState.officer_available(officer):
		return _result(false, "That officer is currently unavailable.")
	var level: int = int(officer.get("level", 1))
	if level >= 100:
		return _result(false, "That officer has reached level 100.")
	var cost: int = 70 + level * 35
	if PrecinctState.credits < cost:
		return _result(false, "Training requires %d credits." % cost)
	PrecinctState.credits -= cost
	officer["level"] = level + 1
	officer["power"] = int(officer.get("power", 50)) + 7
	officer["defense"] = int(officer.get("defense", 10)) + 2
	officer["max_hp"] = int(officer.get("max_hp", 100)) + 8
	officer["hp"] = int(officer.get("max_hp", 100))
	officer["xp"] = 0
	reputation += 1
	PrecinctState.last_event = "%s completed level %d training." % [String(officer.get("name", "Officer")), level + 1]
	PrecinctState.state_changed.emit()
	save_meta()
	meta_changed.emit()
	return _result(true, PrecinctState.last_event)

func heal_officer(officer_id: String) -> Dictionary:
	var officer: Dictionary = PrecinctState.get_officer(officer_id)
	if officer.is_empty():
		return _result(false, "Officer not found.")
	if int(officer.get("hp", 0)) >= int(officer.get("max_hp", 100)) and int(officer.get("injured_until", 0)) <= 0:
		return _result(false, "That officer is already at full health.")
	var cost: int = 45
	if PrecinctState.credits < cost:
		return _result(false, "Treatment requires %d credits." % cost)
	if not PrecinctState.is_room_repaired("medbay"):
		return _result(false, "Restore the Field Medbay first.")
	PrecinctState.credits -= cost
	officer["hp"] = int(officer.get("max_hp", 100))
	officer["injured_until"] = 0
	PrecinctState.last_event = "%s returned to full duty." % String(officer.get("name", "Officer"))
	PrecinctState.state_changed.emit()
	meta_changed.emit()
	return _result(true, PrecinctState.last_event)

func assign_officer(officer_id: String, room_id: String) -> Dictionary:
	var officer: Dictionary = PrecinctState.get_officer(officer_id)
	var room: Dictionary = PrecinctState.get_room(room_id)
	if officer.is_empty() or room.is_empty():
		return _result(false, "Officer or room not found.")
	if not bool(room.get("repaired", false)):
		return _result(false, "Restore the room before assigning staff.")
	for assigned_room_value: Variant in room_assignments.keys():
		var assigned_room: String = String(assigned_room_value)
		if String(room_assignments.get(assigned_room, "")) == officer_id:
			room_assignments.erase(assigned_room)
	room_assignments[room_id] = officer_id
	reputation += 1
	PrecinctState.last_event = "%s assigned to %s." % [String(officer.get("name", "Officer")), String(room.get("name", "Room"))]
	save_meta()
	PrecinctState.state_changed.emit()
	meta_changed.emit()
	return _result(true, PrecinctState.last_event)

func unassign_room(room_id: String) -> Dictionary:
	if not room_assignments.has(room_id):
		return _result(false, "No officer is assigned there.")
	room_assignments.erase(room_id)
	save_meta()
	meta_changed.emit()
	return _result(true, "Room assignment cleared.")

func assigned_officer_id(room_id: String) -> String:
	return String(room_assignments.get(room_id, ""))

func assigned_room_id(officer_id: String) -> String:
	for room_value: Variant in room_assignments.keys():
		var room_id: String = String(room_value)
		if String(room_assignments.get(room_id, "")) == officer_id:
			return room_id
	return ""

func custody_action(action: String) -> Dictionary:
	if PrecinctState.prisoners <= 0:
		return _result(false, "No prisoners are awaiting action.")
	match action:
		"process":
			return PrecinctState.process_prisoner()
		"interrogate":
			if not PrecinctState.is_room_repaired("interrogation"):
				return _result(false, "Restore Interrogation first.")
			PrecinctState.prisoners -= 1
			PrecinctState.intel += 10
			PrecinctState.evidence += 1
			prisoners_interrogated += 1
			reputation += 2
			PrecinctState.last_event = "Interrogation produced 10 intel and one evidence item."
		"transfer":
			if not PrecinctState.is_room_repaired("transfer"):
				return _result(false, "Restore the Secure Transfer Hall first.")
			PrecinctState.prisoners -= 1
			PrecinctState.credits += 125
			prisoners_transferred += 1
			reputation += 2
			PrecinctState.last_event = "Secure transfer completed. +125 credits."
		_:
			return _result(false, "Unknown custody action.")
	PrecinctState.state_changed.emit()
	save_meta()
	meta_changed.emit()
	return _result(true, PrecinctState.last_event)

func task_catalog() -> Array[Dictionary]:
	return [
		_mission("chapter_restore", "CHAPTER 1", "Restore the Precinct", "Bring four station divisions online.", 4, _repaired_count(), 180, 5),
		_mission("chapter_station", "CHAPTER 1", "Expand the Station", "Raise the orbital station to level 2 so the Chief's Office can advance.", 2, StationProgression.station_level, 260, 8),
		_mission("chapter_command", "CHAPTER 1", "Establish Command Authority", "Raise the Chief's Office to level 2. It unlocks level 2 rooms.", 2, chief_level(), 220, 8),
		_mission("chapter_equipment", "CHAPTER 1", "Equip the Precinct", "Complete three individual room-equipment upgrades.", 3, PrecinctEquipment.total_upgrades, 240, 8),
		_mission("chapter_patrol", "CHAPTER 1", "First Arrests", "Hold or process two Syndicate suspects.", 2, PrecinctState.prisoners + prisoners_interrogated + prisoners_transferred, 250, 10),
		_mission("chapter_hideout", "CHAPTER 2", "Expose a Hideout", "Investigate a district until one Syndicate hideout is exposed.", 1, CounterSyndicate.hideouts_exposed, 300, 12),
		_mission("chapter_scores", "CHAPTER 2", "Break Their Momentum", "Stop three Syndicate scores through successful patrols or raids.", 3, CounterSyndicate.intercepted_scores, 320, 12),
		_mission("chapter_arrest", "CHAPTER 2", "Major Arrest", "Capture one major Syndicate operator.", 1, CounterSyndicate.major_arrests, 350, 15),
		_mission("chapter_control", "CHAPTER 2", "Reclaim Lunar Ground", "Raise overall Authority control to 35 percent.", 35, CounterSyndicate.authority_control, 420, 18),
		_mission("daily_upgrade", "DAILY", "Calibrate Equipment", "Complete one individual item upgrade.", 1, PrecinctEquipment.upgraded_item_count(), 100, 3),
		_mission("daily_training", "DAILY", "Officer Development", "Train any officer to level 2.", 1, _trained_officer_count(), 100, 2),
		_mission("daily_assignment", "DAILY", "Staff the Station", "Assign two officers to active divisions.", 2, room_assignments.size(), 90, 3),
		_mission("daily_custody", "DAILY", "Work the Case", "Interrogate or transfer one prisoner.", 1, prisoners_interrogated + prisoners_transferred, 120, 4),
		_mission("daily_intel", "DAILY", "Build an Intelligence File", "Accumulate 30 intel for active investigations.", 30, PrecinctState.intel, 120, 4),
		_mission("patrol_response", "PATROL", "Answer the Call", "Stop one Syndicate score in a lunar district.", 1, CounterSyndicate.intercepted_scores, 130, 4),
		_mission("patrol_veteran", "PATROL", "District Sweep", "Stop five Syndicate scores.", 5, CounterSyndicate.intercepted_scores, 280, 10),
		_mission("investigation_network", "INVESTIGATION", "Map the Network", "Expose three Syndicate hideouts.", 3, CounterSyndicate.hideouts_exposed, 360, 14),
		_mission("district_foothold", "DISTRICT", "Secure a Foothold", "Raise one district to 40 percent Authority control.", 40, _highest_district_control(), 260, 10),
		_mission("station_mastery", "STATION", "Command-Grade Precinct", "Raise six individual equipment items above level 1.", 6, PrecinctEquipment.upgraded_item_count(), 400, 15),
		_mission("side_engine", "SIDE OPS", "Drive Section Emergency", "Complete one engine-repair puzzle.", 1, SideOperations.engine_repairs, 140, 4),
		_mission("side_weapons", "SIDE OPS", "Arm the Station", "Complete one weapons-fitting and calibration puzzle.", 1, SideOperations.weapon_upgrades, 160, 4),
		_mission("side_medical", "SIDE OPS", "Emergency Medicine", "Stabilize one patient in Medical Ops.", 1, SideOperations.medical_cases, 140, 5),
		_mission("side_interrogation", "SIDE OPS", "Reliable Confession", "Obtain one reliable confession without excessive stress.", 1, SideOperations.confessions, 180, 8),
		_mission("defense_upgrade", "DEFENSE", "Harden the Perimeter", "Raise any station defense system to level 2.", 2, _highest_defense_level(), 240, 8),
		_mission("defense_wave", "DEFENSE", "Repel Marauders", "Survive one marauder attack.", 1, StationProgression.attacks_survived, 260, 10),
		_mission("defense_veteran", "DEFENSE", "Hold the Line", "Destroy ten marauder ships.", 10, StationProgression.marauders_defeated, 420, 16)
	]

func claim_task(task_id: String) -> Dictionary:
	if bool(task_claims.get(task_id, false)):
		return _result(false, "That mission reward has already been claimed.")
	for task: Dictionary in task_catalog():
		if String(task.get("id", "")) != task_id:
			continue
		if int(task.get("progress", 0)) < int(task.get("target", 1)):
			return _result(false, "Mission requirements are not complete.")
		task_claims[task_id] = true
		PrecinctState.credits += int(task.get("reward_credits", 0))
		PrecinctState.intel += int(task.get("reward_intel", 0))
		reputation += 3
		PrecinctState.last_event = "%s mission reward claimed." % String(task.get("title", "Mission"))
		save_meta()
		PrecinctState.state_changed.emit()
		meta_changed.emit()
		return _result(true, PrecinctState.last_event)
	return _result(false, "Mission not found.")

func task_claimed(task_id: String) -> bool:
	return bool(task_claims.get(task_id, false))

func advance_tutorial() -> void:
	tutorial_step = mini(6, tutorial_step + 1)
	save_meta()
	meta_changed.emit()

func dismiss_tutorial() -> void:
	tutorial_step = 6
	save_meta()
	meta_changed.emit()

func save_meta() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"room_assignments": room_assignments,
		"task_claims": task_claims,
		"tutorial_step": tutorial_step,
		"chapter": chapter,
		"reputation": reputation,
		"prisoners_interrogated": prisoners_interrogated,
		"prisoners_transferred": prisoners_transferred
	}))

func load_meta() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed as Dictionary
	room_assignments = Dictionary(data.get("room_assignments", {}))
	task_claims = Dictionary(data.get("task_claims", {}))
	tutorial_step = int(data.get("tutorial_step", 0))
	chapter = int(data.get("chapter", 1))
	reputation = int(data.get("reputation", 0))
	prisoners_interrogated = int(data.get("prisoners_interrogated", 0))
	prisoners_transferred = int(data.get("prisoners_transferred", 0))

func _mission(id_value: String, group_value: String, title_value: String, description_value: String, target_value: int, progress_value: int, credits_value: int, intel_value: int) -> Dictionary:
	return {
		"id": id_value,
		"group": group_value,
		"title": title_value,
		"description": description_value,
		"target": target_value,
		"progress": mini(target_value, progress_value),
		"reward_credits": credits_value,
		"reward_intel": intel_value
	}

func _repaired_count() -> int:
	var total: int = 0
	for room: Dictionary in PrecinctState.rooms:
		if bool(room.get("repaired", false)):
			total += 1
	return total

func _trained_officer_count() -> int:
	var total: int = 0
	for officer: Dictionary in PrecinctState.officers:
		if int(officer.get("level", 1)) >= 2:
			total += 1
	return total

func _highest_district_control() -> int:
	var highest: int = 0
	for district: Dictionary in CounterSyndicate.district_catalog():
		highest = maxi(highest, int(district.get("control", 0)))
	return highest

func _highest_defense_level() -> int:
	var highest: int = 1
	for defense_value: Variant in StationProgression.DEFENSE_CATALOG.keys():
		highest = maxi(highest, StationProgression.defense_level(String(defense_value)))
	return highest

func _result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message}
