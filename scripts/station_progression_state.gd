extends Node
## Timed hierarchy: station -> Chief's Office -> room -> equipment.
## Also manages station weapons, shields, hull integrity, and marauder waves.

signal progression_changed
signal marauder_alert

const SAVE_PATH: String = "user://moongoons_station_progression.json"
const MAX_LEVEL: int = 100

const DEFENSE_CATALOG: Dictionary = {
	"point_defense": {"name":"Point-Defense Turrets", "base_cost":180, "rating":12},
	"rail_battery": {"name":"Rail-Cannon Battery", "base_cost":240, "rating":18},
	"shield_grid": {"name":"Station Shield Grid", "base_cost":220, "rating":14},
	"interceptor_bay": {"name":"Interceptor Bay", "base_cost":260, "rating":16}
}

var station_level: int = 1
var station_hull: int = 100
var station_shield: int = 100
var defense_levels: Dictionary = {
	"point_defense":1, "rail_battery":1, "shield_grid":1, "interceptor_bay":1
}
var upgrade_jobs: Array[Dictionary] = []
var active_marauder_wave: Dictionary = {}
var next_marauder_attack_at: int = 0
var attacks_survived: int = 0
var attacks_failed: int = 0
var marauders_defeated: int = 0
var job_serial: int = 1
var wave_serial: int = 1
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	if not load_state():
		next_marauder_attack_at = _now() + 150

func reset_state() -> void:
	station_level = 1
	station_hull = 100
	station_shield = 100
	defense_levels = {"point_defense":1, "rail_battery":1, "shield_grid":1, "interceptor_bay":1}
	upgrade_jobs = []
	active_marauder_wave = {}
	next_marauder_attack_at = _now() + 150
	attacks_survived = 0
	attacks_failed = 0
	marauders_defeated = 0
	job_serial = 1
	wave_serial = 1
	save_state()
	progression_changed.emit()

func tick() -> void:
	var now: int = _now()
	var changed: bool = false
	var remaining_jobs: Array[Dictionary] = []
	for job: Dictionary in upgrade_jobs:
		if now >= int(job.get("finish_at", 0)):
			_complete_upgrade(job)
			changed = true
		else:
			remaining_jobs.append(job)
	upgrade_jobs = remaining_jobs
	if active_marauder_wave.is_empty() and now >= next_marauder_attack_at:
		_start_marauder_wave()
		changed = true
	if not active_marauder_wave.is_empty() and now >= int(active_marauder_wave.get("resolve_at", now + 1)):
		resolve_marauder_wave()
		changed = true
	if changed:
		save_state()
		progression_changed.emit()

func construction_slots() -> int:
	return mini(4, 1 + int((station_level - 1) / 3))

func available_slots() -> int:
	return maxi(0, construction_slots() - upgrade_jobs.size())

func station_upgrade_duration() -> int:
	return 45 + station_level * station_level * 30

func room_upgrade_duration(room_id: String) -> int:
	var room: Dictionary = PrecinctState.get_room(room_id)
	var level: int = int(room.get("level", 1))
	return 25 + level * level * 18

func item_upgrade_duration(room_id: String, item_id: String) -> int:
	var level: int = PrecinctEquipment.item_level(room_id, item_id)
	return 12 + level * level * 10

func defense_upgrade_duration(defense_id: String) -> int:
	var level: int = defense_level(defense_id)
	return 30 + level * level * 22

func begin_station_upgrade() -> Dictionary:
	if station_level >= MAX_LEVEL:
		return _result(false, "The station has reached maximum level.")
	if available_slots() <= 0:
		return _result(false, "All construction slots are occupied.")
	if _has_job("station", "station"):
		return _result(false, "A station expansion is already underway.")
	var cost: int = 500 + station_level * 280
	if PrecinctState.credits < cost:
		return _result(false, "Station expansion requires %d credits." % cost)
	PrecinctState.credits -= cost
	_queue_job("station", "station", "Orbital Station", station_level + 1, station_upgrade_duration())
	return _result(true, "Station level %d expansion started." % (station_level + 1))

func begin_room_upgrade(room_id: String) -> Dictionary:
	var room: Dictionary = PrecinctState.get_room(room_id)
	if room.is_empty():
		return _result(false, "Room not found.")
	if not bool(room.get("repaired", false)):
		return _result(false, "Restore this room before upgrading it.")
	if available_slots() <= 0:
		return _result(false, "All construction slots are occupied.")
	if _has_job("room", room_id):
		return _result(false, "That room is already upgrading.")
	var level: int = int(room.get("level", 1))
	var cap: int = station_level if room_id == "chief" else int(PrecinctState.get_room("chief").get("level", 1))
	if level >= cap:
		var cap_name: String = "Station" if room_id == "chief" else "Chief's Office"
		return _result(false, "%s is capped at level %d. Upgrade the %s first." % [String(room.get("name", "Room")), cap, cap_name])
	var cost: int = 90 + level * 55
	if PrecinctState.credits < cost:
		return _result(false, "Room upgrade requires %d credits." % cost)
	PrecinctState.credits -= cost
	_queue_job("room", room_id, String(room.get("name", "Room")), level + 1, room_upgrade_duration(room_id))
	return _result(true, "%s level %d upgrade started." % [String(room.get("name", "Room")), level + 1])

func begin_item_upgrade(room_id: String, item_id: String) -> Dictionary:
	var room: Dictionary = PrecinctState.get_room(room_id)
	if room.is_empty() or not bool(room.get("repaired", false)):
		return _result(false, "Restore the room before upgrading its equipment.")
	if available_slots() <= 0:
		return _result(false, "All construction slots are occupied.")
	var target_key: String = "%s:%s" % [room_id, item_id]
	if _has_job("item", target_key):
		return _result(false, "That equipment item is already upgrading.")
	var items: Array[Dictionary] = PrecinctEquipment.room_items(room_id)
	var item: Dictionary = {}
	for candidate: Dictionary in items:
		if String(candidate.get("id", "")) == item_id:
			item = candidate
			break
	if item.is_empty():
		return _result(false, "Equipment item not found.")
	var level: int = int(item.get("level", 1))
	var room_level: int = int(room.get("level", 1))
	if level >= room_level:
		return _result(false, "%s is capped at room level %d. Upgrade the room first." % [String(item.get("name", "Equipment")), room_level])
	var cost: int = PrecinctEquipment.upgrade_cost(room_id, item_id)
	if PrecinctState.credits < cost:
		return _result(false, "Equipment upgrade requires %d credits." % cost)
	PrecinctState.credits -= cost
	_queue_job("item", target_key, String(item.get("name", "Equipment")), level + 1, item_upgrade_duration(room_id, item_id), {"room_id":room_id, "item_id":item_id})
	return _result(true, "%s level %d upgrade started." % [String(item.get("name", "Equipment")), level + 1])

func begin_defense_upgrade(defense_id: String) -> Dictionary:
	if not DEFENSE_CATALOG.has(defense_id):
		return _result(false, "Defense system not found.")
	if available_slots() <= 0:
		return _result(false, "All construction slots are occupied.")
	if _has_job("defense", defense_id):
		return _result(false, "That defense system is already upgrading.")
	var level: int = defense_level(defense_id)
	if level >= station_level:
		return _result(false, "%s is capped at station level %d." % [defense_name(defense_id), station_level])
	var data: Dictionary = DEFENSE_CATALOG[defense_id] as Dictionary
	var cost: int = int(data.get("base_cost", 200)) + level * 110
	if PrecinctState.credits < cost:
		return _result(false, "Defense upgrade requires %d credits." % cost)
	PrecinctState.credits -= cost
	_queue_job("defense", defense_id, defense_name(defense_id), level + 1, defense_upgrade_duration(defense_id))
	return _result(true, "%s level %d upgrade started." % [defense_name(defense_id), level + 1])

func job_time_left(job: Dictionary) -> int:
	return maxi(0, int(job.get("finish_at", 0)) - _now())

func defense_level(defense_id: String) -> int:
	return int(defense_levels.get(defense_id, 1))

func defense_name(defense_id: String) -> String:
	var data: Variant = DEFENSE_CATALOG.get(defense_id, {})
	return String((data as Dictionary).get("name", defense_id.capitalize())) if data is Dictionary else defense_id.capitalize()

func defense_rating() -> int:
	var total: int = SideOperations.defense_bonus
	for defense_value: Variant in DEFENSE_CATALOG.keys():
		var defense_id: String = String(defense_value)
		var data: Dictionary = DEFENSE_CATALOG[defense_id] as Dictionary
		total += defense_level(defense_id) * int(data.get("rating", 10))
	return total

func trigger_marauder_wave() -> Dictionary:
	if not active_marauder_wave.is_empty():
		return _result(false, "A marauder wave is already approaching.")
	_start_marauder_wave()
	save_state()
	progression_changed.emit()
	return _result(true, "Marauder attack detected. Defensive engagement begins in 30 seconds.")

func resolve_marauder_wave() -> Dictionary:
	if active_marauder_wave.is_empty():
		return _result(false, "No marauder wave is active.")
	var attack_power: int = int(active_marauder_wave.get("power", 50))
	var station_power: int = defense_rating() + _rng.randi_range(-8, 12)
	var message: String
	if station_power >= attack_power:
		attacks_survived += 1
		marauders_defeated += int(active_marauder_wave.get("ships", 1))
		PrecinctState.credits += 100 + int(active_marauder_wave.get("tier", 1)) * 45
		PrecinctState.intel += 3
		station_shield = mini(100, station_shield + 8)
		message = "Marauder wave destroyed. Station defenses held."
	else:
		attacks_failed += 1
		var damage: int = maxi(8, attack_power - station_power)
		var shield_absorb: int = mini(station_shield, damage)
		station_shield -= shield_absorb
		damage -= shield_absorb
		station_hull = maxi(0, station_hull - damage)
		message = "Marauders breached the defense perimeter. Hull integrity is %d%%." % station_hull
	active_marauder_wave = {}
	next_marauder_attack_at = _now() + 180 + _rng.randi_range(0, 90)
	save_state()
	progression_changed.emit()
	return _result(station_power >= attack_power, message)

func repair_station_hull() -> Dictionary:
	if station_hull >= 100 and station_shield >= 100:
		return _result(false, "Station hull and shields are already at full strength.")
	var missing: int = (100 - station_hull) + (100 - station_shield)
	var cost: int = maxi(40, missing * 3)
	if PrecinctState.credits < cost:
		return _result(false, "Hull and shield repair requires %d credits." % cost)
	PrecinctState.credits -= cost
	station_hull = mini(100, station_hull + 30)
	station_shield = mini(100, station_shield + 40)
	save_state()
	progression_changed.emit()
	return _result(true, "Repair crews restored hull and shield strength.")

func save_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"station_level":station_level, "station_hull":station_hull, "station_shield":station_shield,
		"defense_levels":defense_levels, "upgrade_jobs":upgrade_jobs,
		"active_marauder_wave":active_marauder_wave, "next_marauder_attack_at":next_marauder_attack_at,
		"attacks_survived":attacks_survived, "attacks_failed":attacks_failed,
		"marauders_defeated":marauders_defeated, "job_serial":job_serial, "wave_serial":wave_serial
	}))

func load_state() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	var data := parsed as Dictionary
	station_level = int(data.get("station_level", 1))
	station_hull = int(data.get("station_hull", 100))
	station_shield = int(data.get("station_shield", 100))
	defense_levels = Dictionary(data.get("defense_levels", defense_levels))
	upgrade_jobs = _dictionary_array(data.get("upgrade_jobs", []))
	active_marauder_wave = Dictionary(data.get("active_marauder_wave", {}))
	next_marauder_attack_at = int(data.get("next_marauder_attack_at", _now() + 150))
	attacks_survived = int(data.get("attacks_survived", 0))
	attacks_failed = int(data.get("attacks_failed", 0))
	marauders_defeated = int(data.get("marauders_defeated", 0))
	job_serial = int(data.get("job_serial", 1))
	wave_serial = int(data.get("wave_serial", 1))
	progression_changed.emit()
	return true

func _queue_job(job_type: String, target_id: String, display_name: String, target_level: int, duration: int, extra: Dictionary = {}) -> void:
	var job: Dictionary = {
		"id":"job_%05d" % job_serial, "type":job_type, "target_id":target_id,
		"display_name":display_name, "target_level":target_level,
		"started_at":_now(), "finish_at":_now() + duration, "duration":duration
	}
	for key_value: Variant in extra.keys():
		job[String(key_value)] = extra[key_value]
	job_serial += 1
	upgrade_jobs.append(job)
	save_state()
	progression_changed.emit()

func _complete_upgrade(job: Dictionary) -> void:
	match String(job.get("type", "")):
		"station": station_level = int(job.get("target_level", station_level + 1))
		"room":
			var room: Dictionary = PrecinctState.get_room(String(job.get("target_id", "")))
			if not room.is_empty(): room["level"] = int(job.get("target_level", int(room.get("level", 1)) + 1))
		"item": PrecinctEquipment.complete_item_upgrade(String(job.get("room_id", "")), String(job.get("item_id", "")), int(job.get("target_level", 2)))
		"defense": defense_levels[String(job.get("target_id", ""))] = int(job.get("target_level", 2))
	PrecinctState.last_event = "%s reached level %d." % [String(job.get("display_name", "Upgrade")), int(job.get("target_level", 1))]
	PrecinctState.state_changed.emit()

func _has_job(job_type: String, target_id: String) -> bool:
	for job: Dictionary in upgrade_jobs:
		if String(job.get("type", "")) == job_type and String(job.get("target_id", "")) == target_id:
			return true
	return false

func _start_marauder_wave() -> void:
	var tier: int = maxi(1, station_level)
	active_marauder_wave = {
		"id":"wave_%04d" % wave_serial, "tier":tier,
		"ships":2 + tier, "power":55 + tier * 24 + _rng.randi_range(0, 25),
		"detected_at":_now(), "resolve_at":_now() + 30
	}
	wave_serial += 1
	marauder_alert.emit()

func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item: Variant in value:
			if item is Dictionary: result.append(item as Dictionary)
	return result

func _now() -> int:
	return int(Time.get_unix_time_from_system())

func _result(ok: bool, message: String) -> Dictionary:
	return {"ok":ok, "message":message}
