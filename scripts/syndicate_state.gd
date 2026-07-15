extends Node
## Persistent state for the criminal-side Syndicate Rising campaign.
## Mirrors the precinct slice's dependable timer/save structure while using a distinct underworld economy.

signal state_changed
signal job_added(job_id: String)

const SAVE_PATH: String = "user://moongoons_syndicate_save.json"
const JOB_LIMIT: int = 3

var credits: int = 520
var contraband: int = 18
var intel: int = 12
var heat: int = 10
var notoriety: int = 1
var black_tech_level: int = 1
var black_tech_end: int = 0
var rooms: Array[Dictionary] = []
var crew: Array[Dictionary] = []
var jobs: Array[Dictionary] = []
var active_job: Dictionary = {}
var active_crew_ids: Array[String] = []
var next_job_at: int = 0
var next_heat_decay_at: int = 0
var job_serial: int = 1
var last_event: String = "SYNDICATE RISING // Rebuild the hideout and take the Moon back from underneath."

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	if rooms.is_empty():
		reset_state()

func reset_state() -> void:
	var now: int = _now()
	credits = 520
	contraband = 18
	intel = 12
	heat = 10
	notoriety = 1
	black_tech_level = 1
	black_tech_end = 0
	job_serial = 1
	active_job = {}
	active_crew_ids = []
	jobs = []
	rooms = [
		_room("backroom", "Backroom Command", "Operations", true, 0, 0),
		_room("chop_shop", "Chop Shop", "Vehicles", false, 125, 0),
		_room("black_market", "Black Market", "Income", false, 145, 0),
		_room("bunks", "Safehouse Bunks", "Recovery", false, 105, 0),
		_room("clinic", "Street Clinic", "Healing", false, 175, 0),
		_room("boss_office", "Boss's Office", "Crew Capacity", false, 215, 0),
		_room("signal_den", "Signal Den", "Counter-Intel", false, 165, 0),
		_room("tunnel", "Smuggler Tunnel", "Fence Contraband", false, 155, 0)
	]
	crew = [
		_crew_member("crew_1", "Nyx Raze", "Enforcer", 74, 108, 18),
		_crew_member("crew_2", "Vox-13", "Runner", 87, 91, 13),
		_crew_member("crew_3", "Cinder Quell", "Sharpshot", 91, 84, 15),
		_crew_member("crew_4", "Grit Mercer", "Enforcer", 70, 112, 20)
	]
	next_job_at = now + 4
	next_heat_decay_at = now + 12
	last_event = "HIDEOUT ONLINE // Backroom Command survived the raid. Seven rooms need rebuilding."
	state_changed.emit()

func tick() -> void:
	var now: int = _now()
	var changed: bool = false
	for room: Dictionary in rooms:
		var repair_end: int = int(room.get("repair_end", 0))
		if not bool(room.get("repaired", false)) and repair_end > 0 and now >= repair_end:
			room["repaired"] = true
			room["repair_end"] = 0
			last_event = "%s rebuilt. The underworld has another heartbeat." % String(room.get("name", "Room"))
			changed = true
	if black_tech_end > 0 and now >= black_tech_end:
		black_tech_level += 1
		black_tech_end = 0
		last_event = "BLACK TECH COMPLETE // Network level %d unlocked." % black_tech_level
		changed = true
	for member: Dictionary in crew:
		var injured_until: int = int(member.get("injured_until", 0))
		if injured_until > 0 and now >= injured_until:
			member["injured_until"] = 0
			member["hp"] = int(member.get("max_hp", 100))
			last_event = "%s is patched up and back on the roster." % String(member.get("name", "Crew"))
			changed = true
	var retained_jobs: Array[Dictionary] = []
	for job: Dictionary in jobs:
		if now < int(job.get("expires_at", 0)):
			retained_jobs.append(job)
		else:
			heat = clampi(heat + 2, 0, 100)
			last_event = "A job window closed. Rivals claimed the score and Heat climbed."
			changed = true
	if retained_jobs.size() != jobs.size():
		jobs = retained_jobs
	if active_job.is_empty() and jobs.size() < JOB_LIMIT and now >= next_job_at:
		_generate_job()
		changed = true
	if now >= next_heat_decay_at:
		next_heat_decay_at = now + 12
		if heat > 0:
			heat = max(0, heat - (2 if is_room_repaired("signal_den") else 1))
			last_event = "Signal spoofers cooled the district. Heat dropped to %d." % heat
			changed = true
	if changed:
		state_changed.emit()

func repair_room(room_id: String) -> Dictionary:
	var room: Dictionary = get_room(room_id)
	if room.is_empty():
		return {"ok": false, "message": "Hideout room not found."}
	if bool(room.get("repaired", false)):
		return {"ok": false, "message": "That room is already running."}
	if int(room.get("repair_end", 0)) > 0:
		return {"ok": false, "message": "A salvage crew is already rebuilding it."}
	var cost: int = int(room.get("repair_cost", 0))
	if credits < cost:
		return {"ok": false, "message": "The rebuild needs %d credits." % cost}
	credits -= cost
	room["repair_end"] = _now() + 12
	last_event = "Salvage drones slipped into %s." % String(room.get("name", "room"))
	state_changed.emit()
	return {"ok": true, "message": last_event}

func begin_black_tech() -> Dictionary:
	if black_tech_end > 0:
		return {"ok": false, "message": "A black-tech project is already cooking."}
	if not is_room_repaired("signal_den"):
		return {"ok": false, "message": "Rebuild the Signal Den before advancing black tech."}
	var credit_cost: int = 90 + black_tech_level * 45
	var intel_cost: int = 4 + black_tech_level * 2
	if credits < credit_cost or intel < intel_cost:
		return {"ok": false, "message": "Black tech needs %d credits and %d intel." % [credit_cost, intel_cost]}
	credits -= credit_cost
	intel -= intel_cost
	black_tech_end = _now() + 18
	last_event = "Signal Den started black-tech level %d." % (black_tech_level + 1)
	state_changed.emit()
	return {"ok": true, "message": last_event}

func fence_contraband() -> Dictionary:
	if contraband <= 0:
		return {"ok": false, "message": "No contraband is ready to fence."}
	if not is_room_repaired("tunnel"):
		return {"ok": false, "message": "Rebuild the Smuggler Tunnel before fencing cargo."}
	var moved: int = mini(contraband, 5 + black_tech_level)
	var payout: int = moved * (22 + black_tech_level * 3)
	contraband -= moved
	credits += payout
	heat = clampi(heat + 1, 0, 100)
	last_event = "FENCE COMPLETE // %d contraband became %d credits." % [moved, payout]
	state_changed.emit()
	return {"ok": true, "message": last_event}

func begin_job(job_id: String, crew_ids: Array[String]) -> Dictionary:
	if not active_job.is_empty():
		return {"ok": false, "message": "Another crew is already on a live job."}
	var job_index: int = -1
	for index: int in range(jobs.size()):
		if String(jobs[index].get("id", "")) == job_id:
			job_index = index
			break
	if job_index < 0:
		return {"ok": false, "message": "That job window has closed."}
	var valid_ids: Array[String] = []
	for crew_id: String in crew_ids:
		var member: Dictionary = get_crew_member(crew_id)
		if not member.is_empty() and crew_available(member):
			valid_ids.append(crew_id)
	if valid_ids.is_empty():
		return {"ok": false, "message": "Select at least one available crew member."}
	if valid_ids.size() > 3:
		valid_ids.resize(3)
	active_job = jobs[job_index].duplicate(true)
	active_crew_ids = valid_ids
	jobs.remove_at(job_index)
	for crew_id: String in active_crew_ids:
		var member: Dictionary = get_crew_member(crew_id)
		member["busy_until"] = _now() + 45
	heat = clampi(heat + int(active_job.get("heat_gain", 4)), 0, 100)
	last_event = "CREW DEPLOYED // %s." % String(active_job.get("title", "Underworld job"))
	state_changed.emit()
	return {"ok": true, "message": last_event}

func finish_job(victory: bool, surviving_hp: Dictionary) -> void:
	var now: int = _now()
	for crew_id: String in active_crew_ids:
		var member: Dictionary = get_crew_member(crew_id)
		if member.is_empty():
			continue
		var hp_value: int = int(surviving_hp.get(crew_id, member.get("hp", 1)))
		member["hp"] = max(1, hp_value)
		member["busy_until"] = now + 8
		if hp_value <= int(float(member.get("max_hp", 100)) * 0.25):
			member["injured_until"] = now + 30
	if victory and not active_job.is_empty():
		var reward: int = int(active_job.get("reward", 0))
		var cargo: int = int(active_job.get("contraband", 1))
		var difficulty: int = int(active_job.get("difficulty", 1))
		credits += reward
		contraband += cargo
		intel += difficulty
		notoriety += difficulty
		for crew_id: String in active_crew_ids:
			var member: Dictionary = get_crew_member(crew_id)
			member["xp"] = int(member.get("xp", 0)) + 12 * difficulty
		last_event = "JOB CLEAN // +%d credits, +%d contraband, Notoriety %d." % [reward, cargo, notoriety]
	else:
		heat = clampi(heat + 8, 0, 100)
		last_event = "JOB BURNED // The crew escaped, but Heat spiked to %d." % heat
	active_job = {}
	active_crew_ids = []
	next_job_at = min(next_job_at, now + 6)
	save_game()
	state_changed.emit()

func save_game() -> Dictionary:
	var data: Dictionary = {
		"credits": credits,
		"contraband": contraband,
		"intel": intel,
		"heat": heat,
		"notoriety": notoriety,
		"black_tech_level": black_tech_level,
		"black_tech_end": black_tech_end,
		"rooms": rooms,
		"crew": crew,
		"jobs": jobs,
		"active_job": active_job,
		"active_crew_ids": active_crew_ids,
		"next_job_at": next_job_at,
		"next_heat_decay_at": next_heat_decay_at,
		"job_serial": job_serial,
		"last_event": last_event
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Syndicate save could not be opened."}
	file.store_string(JSON.stringify(data))
	last_event = "Syndicate operation saved."
	return {"ok": true, "message": last_event}

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {"ok": false, "message": "No Syndicate save exists yet."}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "Syndicate save could not be read."}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"ok": false, "message": "The Syndicate save is invalid."}
	var data: Dictionary = parsed as Dictionary
	credits = int(data.get("credits", 520))
	contraband = int(data.get("contraband", 18))
	intel = int(data.get("intel", 12))
	heat = int(data.get("heat", 10))
	notoriety = int(data.get("notoriety", 1))
	black_tech_level = int(data.get("black_tech_level", 1))
	black_tech_end = int(data.get("black_tech_end", 0))
	rooms = _dictionary_array(data.get("rooms", []))
	crew = _dictionary_array(data.get("crew", []))
	jobs = _dictionary_array(data.get("jobs", []))
	active_job = Dictionary(data.get("active_job", {}))
	active_crew_ids = _string_array(data.get("active_crew_ids", []))
	next_job_at = int(data.get("next_job_at", _now() + 6))
	next_heat_decay_at = int(data.get("next_heat_decay_at", _now() + 12))
	job_serial = int(data.get("job_serial", 1))
	last_event = "Syndicate operation loaded."
	state_changed.emit()
	return {"ok": true, "message": last_event}

func get_room(room_id: String) -> Dictionary:
	for room: Dictionary in rooms:
		if String(room.get("id", "")) == room_id:
			return room
	return {}

func get_crew_member(crew_id: String) -> Dictionary:
	for member: Dictionary in crew:
		if String(member.get("id", "")) == crew_id:
			return member
	return {}

func active_crew() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for crew_id: String in active_crew_ids:
		var member: Dictionary = get_crew_member(crew_id)
		if not member.is_empty():
			result.append(member)
	return result

func crew_available(member: Dictionary) -> bool:
	var now: int = _now()
	return now >= int(member.get("busy_until", 0)) and now >= int(member.get("injured_until", 0))

func is_room_repaired(room_id: String) -> bool:
	var room: Dictionary = get_room(room_id)
	return not room.is_empty() and bool(room.get("repaired", false))

func seconds_left(timestamp: int) -> int:
	return max(0, timestamp - _now())

func _generate_job() -> void:
	var templates: Array[Dictionary] = [
		{"title": "Hijack Supply Skiff", "sector": "Tycho Freight Spine", "difficulty": 1, "target": "Peacekeepers"},
		{"title": "Crack Evidence Vault", "sector": "Blueglass Ward", "difficulty": 2, "target": "Peacekeepers"},
		{"title": "Siphon Transit Payroll", "sector": "Mare Exchange", "difficulty": 1, "target": "Corporate Security"},
		{"title": "Extract Captured Fixer", "sector": "Dock Seven", "difficulty": 2, "target": "Peacekeepers"},
		{"title": "Sabotage Sensor Grid", "sector": "Signal Canyon", "difficulty": 3, "target": "Peacekeepers"},
		{"title": "Smuggle Reactor Cores", "sector": "Eclipse Foundry", "difficulty": 3, "target": "Customs Patrol"},
		{"title": "Raid Rival Cache", "sector": "Crater Market", "difficulty": 2, "target": "Hollow Fang"}
	]
	var template: Dictionary = templates[_rng.randi_range(0, templates.size() - 1)]
	var difficulty: int = int(template.get("difficulty", 1))
	var job_id: String = "job_%04d" % job_serial
	job_serial += 1
	var response_bonus: int = heat / 12
	var job: Dictionary = {
		"id": job_id,
		"title": String(template.get("title", "Underworld Job")),
		"sector": String(template.get("sector", "Unknown Sector")),
		"target": String(template.get("target", "Peacekeepers")),
		"difficulty": difficulty,
		"reward": 75 + difficulty * 60 + notoriety * 4,
		"contraband": 1 + difficulty,
		"heat_gain": 3 + difficulty * 2,
		"expires_at": _now() + max(32, 62 - heat / 2) + _rng.randi_range(0, 18),
		"enemy_hp": 72 + difficulty * 58 + response_bonus * 5,
		"enemy_power": 10 + difficulty * 5 + response_bonus
	}
	jobs.append(job)
	next_job_at = _now() + _rng.randi_range(17, 25)
	last_event = "NEW SCORE // %s in %s." % [String(job.get("title", "Job")), String(job.get("sector", "Sector"))]
	job_added.emit(job_id)

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

func _crew_member(id_value: String, name_value: String, class_value: String, power_value: int, hp_value: int, defense_value: int) -> Dictionary:
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
