extends Node
## Extra progression used by the APK-inspired MoonGoons hub.
## This stays separate from PrecinctState so the proven patrol/combat loop remains stable.

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
	var room: Dictionary = PrecinctState.get_room(room_id)
	if room.is_empty():
		return _result(false, "Room not found.")
	if not bool(room.get("repaired", false)):
		return _result(false, "Restore this room before upgrading it.")
	var level: int = int(room.get("level", 1))
	if level >= 100:
		return _result(false, "This room is already level 100.")
	var cost: int = 90 + level * 55
	if PrecinctState.credits < cost:
		return _result(false, "Upgrade requires %d credits." % cost)
	PrecinctState.credits -= cost
	room["level"] = level + 1
	reputation += 2
	PrecinctState.last_event = "%s upgraded to level %d." % [String(room.get("name", "Room")), level + 1]
	PrecinctState.state_changed.emit()
	save_meta()
	meta_changed.emit()
	return _result(true, PrecinctState.last_event)

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
		{"id":"chapter_restore", "group":"CHAPTER", "title":"Restore the Precinct", "description":"Bring four rooms online.", "target":4, "progress":_repaired_count(), "reward_credits":180, "reward_intel":5},
		{"id":"chapter_patrol", "group":"CHAPTER", "title":"First Arrests", "description":"Hold two prisoners at once.", "target":2, "progress":PrecinctState.prisoners, "reward_credits":220, "reward_intel":8},
		{"id":"daily_upgrade", "group":"DAILY", "title":"Improve a Division", "description":"Raise any room to level 2.", "target":1, "progress":_upgraded_room_count(), "reward_credits":90, "reward_intel":2},
		{"id":"daily_training", "group":"DAILY", "title":"Officer Development", "description":"Train any officer to level 2.", "target":1, "progress":_trained_officer_count(), "reward_credits":100, "reward_intel":2},
		{"id":"daily_assignment", "group":"DAILY", "title":"Staff the Station", "description":"Assign two officers to rooms.", "target":2, "progress":room_assignments.size(), "reward_credits":80, "reward_intel":3},
		{"id":"daily_custody", "group":"DAILY", "title":"Work the Case", "description":"Interrogate or transfer one prisoner.", "target":1, "progress":prisoners_interrogated + prisoners_transferred, "reward_credits":110, "reward_intel":4}
	]

func claim_task(task_id: String) -> Dictionary:
	if bool(task_claims.get(task_id, false)):
		return _result(false, "That reward has already been claimed.")
	for task: Dictionary in task_catalog():
		if String(task.get("id", "")) != task_id:
			continue
		if int(task.get("progress", 0)) < int(task.get("target", 1)):
			return _result(false, "Task requirements are not complete.")
		task_claims[task_id] = true
		PrecinctState.credits += int(task.get("reward_credits", 0))
		PrecinctState.intel += int(task.get("reward_intel", 0))
		reputation += 3
		PrecinctState.last_event = "%s reward claimed." % String(task.get("title", "Task"))
		save_meta()
		PrecinctState.state_changed.emit()
		meta_changed.emit()
		return _result(true, PrecinctState.last_event)
	return _result(false, "Task not found.")

func task_claimed(task_id: String) -> bool:
	return bool(task_claims.get(task_id, false))

func advance_tutorial() -> void:
	tutorial_step = min(6, tutorial_step + 1)
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

func _repaired_count() -> int:
	var total: int = 0
	for room: Dictionary in PrecinctState.rooms:
		if bool(room.get("repaired", false)):
			total += 1
	return total

func _upgraded_room_count() -> int:
	var total: int = 0
	for room: Dictionary in PrecinctState.rooms:
		if int(room.get("level", 1)) >= 2:
			total += 1
	return total

func _trained_officer_count() -> int:
	var total: int = 0
	for officer: Dictionary in PrecinctState.officers:
		if int(officer.get("level", 1)) >= 2:
			total += 1
	return total

func _result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message}
