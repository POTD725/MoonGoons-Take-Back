extends Node
## Shared state for the MoonGoons precinct vertical slice.
## Keeps timers, patrol calls, officers, repairs, research, prisoners, and saves independent from either scene.

signal state_changed
signal patrol_call_added(call_id: String)

const SAVE_PATH: String = "user://moongoons_precinct_save.json"
const CALL_LIMIT: int = 3

var credits: int = 650
var intel: int = 25
var evidence: int = 0
var prisoners: int = 0
var research_level: int = 1
var research_end: int = 0
var rooms: Array[Dictionary] = []
var officers: Array[Dictionary] = []
var patrol_calls: Array[Dictionary] = []
var active_call: Dictionary = {}
var active_officer_ids: Array[String] = []
var next_call_at: int = 0
var call_serial: int = 1
var last_event: String = "PRECINCT ONLINE // Restore the station and answer the first distress call."

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	if rooms.is_empty():
		reset_state()

func reset_state() -> void:
	var now: int = _now()
	credits = 650
	intel = 25
	evidence = 0
	prisoners = 0
	research_level = 1
	research_end = 0
	call_serial = 1
	active_call = {}
	active_officer_ids = []
	patrol_calls = []
	rooms = [
		_room("ops", "Operations Center", "Command", true, 0, 0),
		_room("armory", "Tactical Armory", "Equipment", false, 120, 0),
		_room("cells", "Holding Cells", "Custody", false, 150, 0),
		_room("quarters", "Crew Quarters", "Recovery", false, 100, 0),
		_room("medbay", "Field Medbay", "Healing", false, 180, 0),
		_room("chief", "Chief's Office", "Capacity", false, 220, 0),
		_room("interrogation", "Interrogation", "Intel", false, 160, 0),
		_room("transfer", "Secure Transfer Hall", "Prisoner Transfer", false, 140, 0)
	]
	officers = [
		_officer("officer_1", "Kira Vale", "Guard", 72, 100, 16),
		_officer("officer_2", "Brakk-9", "Biker", 84, 92, 18),
		_officer("officer_3", "Milo Venn", "Marksman", 88, 86, 21),
		_officer("officer_4", "Sable Orr", "Guard", 68, 108, 15)
	]
	next_call_at = now + 5
	last_event = "PRECINCT ONLINE // Operations Center restored. Seven rooms still need field repairs."
	state_changed.emit()

func tick() -> void:
	var now: int = _now()
	var changed: bool = false
	for room: Dictionary in rooms:
		var repair_end: int = int(room.get("repair_end", 0))
		if not bool(room.get("repaired", false)) and repair_end > 0 and now >= repair_end:
			room["repaired"] = true
			room["repair_end"] = 0
			last_event = "%s restored and ready for duty." % String(room.get("name", "Room"))
			changed = true
	if research_end > 0 and now >= research_end:
		research_level += 1
		research_end = 0
		last_event = "Research completed. Precinct systems advanced to level %d." % research_level
		changed = true
	for officer: Dictionary in officers:
		var injured_until: int = int(officer.get("injured_until", 0))
		if injured_until > 0 and now >= injured_until:
			officer["injured_until"] = 0
			officer["hp"] = int(officer.get("max_hp", 100))
			last_event = "%s cleared by the med team." % String(officer.get("name", "Officer"))
			changed = true
	var retained_calls: Array[Dictionary] = []
	for call: Dictionary in patrol_calls:
		if now < int(call.get("expires_at", 0)):
			retained_calls.append(call)
		else:
			last_event = "A distress call expired. Syndicate influence increased in that sector."
			changed = true
	if retained_calls.size() != patrol_calls.size():
		patrol_calls = retained_calls
	if active_call.is_empty() and patrol_calls.size() < CALL_LIMIT and now >= next_call_at:
		_generate_call()
		changed = true
	if changed:
		state_changed.emit()

func repair_room(room_id: String) -> Dictionary:
	var room: Dictionary = get_room(room_id)
	if room.is_empty():
		return {"ok": false, "message": "Room not found."}
	if bool(room.get("repaired", false)):
		return {"ok": false, "message": "That room is already operational."}
	if int(room.get("repair_end", 0)) > 0:
		return {"ok": false, "message": "Repair crew is already working there."}
	var cost: int = int(room.get("repair_cost", 0))
	if credits < cost:
		return {"ok": false, "message": "Not enough credits for that repair."}
	credits -= cost
	room["repair_end"] = _now() + 12
	last_event = "Repair drones deployed to %s." % String(room.get("name", "room"))
	state_changed.emit()
	return {"ok": true, "message": last_event}

func begin_research() -> Dictionary:
	if research_end > 0:
		return {"ok": false, "message": "Research is already in progress."}
	var credit_cost: int = 100 + research_level * 40
	var intel_cost: int = 5 + research_level * 2
	if credits < credit_cost or intel < intel_cost:
		return {"ok": false, "message": "Research needs %d credits and %d intel." % [credit_cost, intel_cost]}
	credits -= credit_cost
	intel -= intel_cost
	research_end = _now() + 18
	last_event = "Technology Division started precinct research level %d." % (research_level + 1)
	state_changed.emit()
	return {"ok": true, "message": last_event}

func process_prisoner() -> Dictionary:
	if prisoners <= 0:
		return {"ok": false, "message": "No prisoners are awaiting processing."}
	if not is_room_repaired("cells"):
		return {"ok": false, "message": "Restore Holding Cells before processing prisoners."}
	prisoners -= 1
	credits += 70
	intel += 4
	last_event = "Prisoner processed. Evidence review produced 70 credits and 4 intel."
	state_changed.emit()
	return {"ok": true, "message": last_event}

func begin_patrol(call_id: String, officer_ids: Array[String]) -> Dictionary:
	if not active_call.is_empty():
		return {"ok": false, "message": "A patrol battle is already active."}
	var call_index: int = -1
	for index: int in range(patrol_calls.size()):
		if String(patrol_calls[index].get("id", "")) == call_id:
			call_index = index
			break
	if call_index < 0:
		return {"ok": false, "message": "That distress call is no longer active."}
	var valid_ids: Array[String] = []
	for officer_id: String in officer_ids:
		var officer: Dictionary = get_officer(officer_id)
		if not officer.is_empty() and officer_available(officer):
			valid_ids.append(officer_id)
	if valid_ids.is_empty():
		return {"ok": false, "message": "Select at least one available officer."}
	if valid_ids.size() > 3:
		valid_ids.resize(3)
	active_call = patrol_calls[call_index].duplicate(true)
	active_officer_ids = valid_ids
	patrol_calls.remove_at(call_index)
	for officer_id: String in active_officer_ids:
		var officer: Dictionary = get_officer(officer_id)
		officer["busy_until"] = _now() + 45
	last_event = "Patrol dispatched to %s." % String(active_call.get("title", "distress call"))
	state_changed.emit()
	return {"ok": true, "message": last_event}

func finish_patrol(victory: bool, surviving_hp: Dictionary) -> void:
	var now: int = _now()
	for officer_id: String in active_officer_ids:
		var officer: Dictionary = get_officer(officer_id)
		if officer.is_empty():
			continue
		var hp_value: int = int(surviving_hp.get(officer_id, officer.get("hp", 1)))
		officer["hp"] = max(1, hp_value)
		officer["busy_until"] = now + 8
		if hp_value <= int(float(officer.get("max_hp", 100)) * 0.25):
			officer["injured_until"] = now + 30
	if victory and not active_call.is_empty():
		var reward: int = int(active_call.get("reward", 0))
		credits += reward
		evidence += 1
		intel += int(active_call.get("difficulty", 1)) * 2
		if bool(active_call.get("arrestable", true)):
			prisoners += 1
		for officer_id: String in active_officer_ids:
			var officer: Dictionary = get_officer(officer_id)
			officer["xp"] = int(officer.get("xp", 0)) + 12 * int(active_call.get("difficulty", 1))
		last_event = "PATROL SECURED // +%d credits, evidence recovered, suspect detained." % reward
	else:
		last_event = "Patrol withdrew. Officers are recovering and the suspect escaped."
	active_call = {}
	active_officer_ids = []
	next_call_at = min(next_call_at, now + 6)
	save_game()
	state_changed.emit()

func save_game() -> Dictionary:
	var data: Dictionary = {
		"credits": credits,
		"intel": intel,
		"evidence": evidence,
		"prisoners": prisoners,
		"research_level": research_level,
		"research_end": research_end,
		"rooms": rooms,
		"officers": officers,
		"patrol_calls": patrol_calls,
		"active_call": active_call,
		"active_officer_ids": active_officer_ids,
		"next_call_at": next_call_at,
		"call_serial": call_serial,
		"last_event": last_event
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Save file could not be opened."}
	file.store_string(JSON.stringify(data))
	last_event = "Precinct status saved."
	return {"ok": true, "message": last_event}

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {"ok": false, "message": "No precinct save exists yet."}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "Save file could not be read."}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"ok": false, "message": "The precinct save is invalid."}
	var data: Dictionary = parsed as Dictionary
	credits = int(data.get("credits", 650))
	intel = int(data.get("intel", 25))
	evidence = int(data.get("evidence", 0))
	prisoners = int(data.get("prisoners", 0))
	research_level = int(data.get("research_level", 1))
	research_end = int(data.get("research_end", 0))
	rooms = _dictionary_array(data.get("rooms", []))
	officers = _dictionary_array(data.get("officers", []))
	patrol_calls = _dictionary_array(data.get("patrol_calls", []))
	active_call = Dictionary(data.get("active_call", {}))
	active_officer_ids = _string_array(data.get("active_officer_ids", []))
	next_call_at = int(data.get("next_call_at", _now() + 6))
	call_serial = int(data.get("call_serial", 1))
	last_event = "Precinct save loaded."
	state_changed.emit()
	return {"ok": true, "message": last_event}

func get_room(room_id: String) -> Dictionary:
	for room: Dictionary in rooms:
		if String(room.get("id", "")) == room_id:
			return room
	return {}

func get_officer(officer_id: String) -> Dictionary:
	for officer: Dictionary in officers:
		if String(officer.get("id", "")) == officer_id:
			return officer
	return {}

func active_officers() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for officer_id: String in active_officer_ids:
		var officer: Dictionary = get_officer(officer_id)
		if not officer.is_empty():
			result.append(officer)
	return result

func officer_available(officer: Dictionary) -> bool:
	var now: int = _now()
	return now >= int(officer.get("busy_until", 0)) and now >= int(officer.get("injured_until", 0))

func is_room_repaired(room_id: String) -> bool:
	var room: Dictionary = get_room(room_id)
	return not room.is_empty() and bool(room.get("repaired", false))

func seconds_left(timestamp: int) -> int:
	return max(0, timestamp - _now())

func _generate_call() -> void:
	var templates: Array[Dictionary] = [
		{"title": "Syndicate Relay Raid", "sector": "Crater Market", "difficulty": 1},
		{"title": "Shuttle Jacking", "sector": "Tycho Transit", "difficulty": 2},
		{"title": "Evidence Cache Theft", "sector": "Blueglass Ward", "difficulty": 1},
		{"title": "Smuggler Barricade", "sector": "Dock Seven", "difficulty": 2},
		{"title": "Hacker Cell Breach", "sector": "Signal Canyon", "difficulty": 3},
		{"title": "Lost Survey Pet", "sector": "Habitat Ring", "difficulty": 1},
		{"title": "Armored Convoy Robbery", "sector": "Mare Highway", "difficulty": 3}
	]
	var template: Dictionary = templates[_rng.randi_range(0, templates.size() - 1)]
	var difficulty: int = int(template.get("difficulty", 1))
	var call_id: String = "call_%04d" % call_serial
	call_serial += 1
	var call: Dictionary = {
		"id": call_id,
		"title": String(template.get("title", "Distress Call")),
		"sector": String(template.get("sector", "Unknown Sector")),
		"difficulty": difficulty,
		"reward": 80 + difficulty * 55,
		"expires_at": _now() + 55 + _rng.randi_range(0, 20),
		"enemy_hp": 70 + difficulty * 55,
		"enemy_power": 10 + difficulty * 5,
		"arrestable": true
	}
	patrol_calls.append(call)
	next_call_at = _now() + _rng.randi_range(18, 27)
	last_event = "NEW DISTRESS CALL // %s in %s." % [String(call.get("title", "Call")), String(call.get("sector", "Sector"))]
	patrol_call_added.emit(call_id)

func _room(id_value: String, name_value: String, function_value: String, repaired_value: bool, cost_value: int, repair_end_value: int) -> Dictionary:
	return {
		"id": id_value,
		"name": name_value,
		"function": function_value,
		"level": 1,
		"repaired": repaired_value,
		"repair_cost": cost_value,
		"repair_end": repair_end_value
	}

func _officer(id_value: String, name_value: String, class_value: String, power_value: int, hp_value: int, defense_value: int) -> Dictionary:
	return {
		"id": id_value,
		"name": name_value,
		"class": class_value,
		"rarity": "Common",
		"level": 1,
		"power": power_value,
		"max_hp": hp_value,
		"hp": hp_value,
		"defense": defense_value,
		"xp": 0,
		"busy_until": 0,
		"injured_until": 0
	}

func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item: Variant in value:
			if item is Dictionary:
				result.append(item as Dictionary)
	return result

func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item: Variant in value:
			result.append(String(item))
	return result

func _now() -> int:
	return int(Time.get_unix_time_from_system())
