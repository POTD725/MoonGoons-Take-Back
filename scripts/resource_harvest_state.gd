extends Node
## Persistent harvesting economy for asteroid, moon, and drifting-space sites.

signal resources_changed
signal site_changed(site_id: String)
signal harvest_completed(site_id: String, resource_id: String, amount: int)

const SAVE_PATH: String = "user://moongoons_resource_harvesting.json"
const RESOURCE_IDS: Array[String] = ["moonsteel", "helium3", "quantum_salvage"]
const RESOURCE_DEFS: Dictionary = {
	"moonsteel": {"name":"Moonsteel Ore", "short":"ORE", "use":"Hull plating, rooms, armor, and heavy defenses", "color":"#E29A58"},
	"helium3": {"name":"Helium-3", "short":"HE-3", "use":"Power, engines, shields, and operation acceleration", "color":"#6DEBFF"},
	"quantum_salvage": {"name":"Quantum Salvage", "short":"Q-SALV", "use":"Research, weapons, targeting, and advanced equipment", "color":"#C984FF"}
}

const SITE_TEMPLATES: Array[Dictionary] = [
	{"id":"asteroid_cinder9", "name":"Cinder-9 Excavation", "location":"Asteroid Belt", "kind":"asteroid", "resource":"moonsteel", "base_yield":28, "base_duration":18, "max_reserve":150, "risk":1, "unlock_level":1},
	{"id":"asteroid_iron_choir", "name":"Iron Choir Cluster", "location":"Broken Halo Belt", "kind":"asteroid", "resource":"moonsteel", "base_yield":38, "base_duration":26, "max_reserve":210, "risk":2, "unlock_level":2},
	{"id":"asteroid_blueglass", "name":"Blueglass Deep Core", "location":"Tycho Outer Belt", "kind":"asteroid", "resource":"moonsteel", "base_yield":52, "base_duration":36, "max_reserve":280, "risk":3, "unlock_level":4},
	{"id":"moon_selene", "name":"Selene Regolith Well", "location":"Selene Moon", "kind":"moon", "resource":"helium3", "base_yield":24, "base_duration":20, "max_reserve":135, "risk":1, "unlock_level":1},
	{"id":"moon_mare_vent", "name":"Mare Tranquility Vent", "location":"Tranquility Moonworks", "kind":"moon", "resource":"helium3", "base_yield":34, "base_duration":29, "max_reserve":190, "risk":2, "unlock_level":2},
	{"id":"moon_khepri", "name":"Khepri Ice-Moon Bore", "location":"Khepri Minor", "kind":"moon", "resource":"helium3", "base_yield":46, "base_duration":40, "max_reserve":250, "risk":3, "unlock_level":5},
	{"id":"wreck_courier", "name":"Courier Wreck Drift", "location":"Open Space", "kind":"wreck", "resource":"quantum_salvage", "base_yield":18, "base_duration":22, "max_reserve":100, "risk":1, "unlock_level":1},
	{"id":"wreck_relay", "name":"Derelict Relay Graveyard", "location":"Signal Canyon Orbit", "kind":"wreck", "resource":"quantum_salvage", "base_yield":27, "base_duration":32, "max_reserve":150, "risk":2, "unlock_level":3},
	{"id":"wreck_carrier", "name":"Marauder Carrier Remains", "location":"Blackglass Expanse", "kind":"wreck", "resource":"quantum_salvage", "base_yield":41, "base_duration":44, "max_reserve":220, "risk":4, "unlock_level":6}
]

var resources: Dictionary = {"moonsteel":120, "helium3":80, "quantum_salvage":30}
var sites: Array[Dictionary] = []
var total_harvests: int = 0
var total_collected: Dictionary = {"moonsteel":0, "helium3":0, "quantum_salvage":0}
var last_event: String = "Resource scanners online. Asteroids, moons, and drifting wrecks marked."

func _ready() -> void:
	_initialize_sites()
	load_state()

func reset_state() -> void:
	resources = {"moonsteel":120, "helium3":80, "quantum_salvage":30}
	total_harvests = 0
	total_collected = {"moonsteel":0, "helium3":0, "quantum_salvage":0}
	sites = []
	_initialize_sites()
	last_event = "Resource economy reset."
	save_state()
	resources_changed.emit()

func tick() -> void:
	var now: int = _now()
	var changed: bool = false
	for site: Dictionary in sites:
		var site_id: String = String(site.get("id", ""))
		var recovery_end: int = int(site.get("recovery_end", 0))
		if recovery_end > 0 and now >= recovery_end:
			site["reserve"] = int(site.get("max_reserve", 100))
			site["recovery_end"] = 0
			last_event = "%s resource field has recovered." % String(site.get("name", "Harvest site"))
			site_changed.emit(site_id)
			changed = true
		var harvest_end: int = int(site.get("harvest_end", 0))
		if harvest_end > 0 and now >= harvest_end:
			_complete_harvest(site)
			changed = true
	if changed:
		save_state()
		resources_changed.emit()

func resource_amount(resource_id: String) -> int:
	return int(resources.get(resource_id, 0))

func resource_name(resource_id: String) -> String:
	var data: Variant = RESOURCE_DEFS.get(resource_id, {})
	return String((data as Dictionary).get("name", resource_id.capitalize())) if data is Dictionary else resource_id.capitalize()

func resource_color(resource_id: String) -> Color:
	var data: Variant = RESOURCE_DEFS.get(resource_id, {})
	var color_text: String = String((data as Dictionary).get("color", "#FFFFFF")) if data is Dictionary else "#FFFFFF"
	return Color(color_text)

func add_resource(resource_id: String, amount: int) -> void:
	if not RESOURCE_IDS.has(resource_id) or amount <= 0:
		return
	resources[resource_id] = resource_amount(resource_id) + amount
	total_collected[resource_id] = int(total_collected.get(resource_id, 0)) + amount
	save_state()
	resources_changed.emit()

func can_afford(costs: Dictionary) -> bool:
	for key_value: Variant in costs.keys():
		var resource_id: String = String(key_value)
		if resource_amount(resource_id) < int(costs.get(resource_id, 0)):
			return false
	return true

func spend(costs: Dictionary) -> bool:
	if not can_afford(costs):
		return false
	for key_value: Variant in costs.keys():
		var resource_id: String = String(key_value)
		resources[resource_id] = resource_amount(resource_id) - int(costs.get(resource_id, 0))
	save_state()
	resources_changed.emit()
	return true

func refund(costs: Dictionary) -> void:
	for key_value: Variant in costs.keys():
		add_resource(String(key_value), int(costs.get(key_value, 0)))

func harvest_slots() -> int:
	var station_level: int = 1
	if get_node_or_null("/root/StationProgression") != null:
		station_level = int(get_node("/root/StationProgression").get("station_level"))
	return mini(3, 1 + int((station_level - 1) / 4))

func active_harvest_count() -> int:
	var count: int = 0
	for site: Dictionary in sites:
		if int(site.get("harvest_end", 0)) > 0:
			count += 1
	return count

func site_catalog() -> Array[Dictionary]:
	tick()
	var result: Array[Dictionary] = []
	var station_level: int = 1
	if get_node_or_null("/root/StationProgression") != null:
		station_level = int(get_node("/root/StationProgression").get("station_level"))
	for site: Dictionary in sites:
		var entry: Dictionary = site.duplicate(true)
		entry["locked"] = station_level < int(site.get("unlock_level", 1))
		entry["time_left"] = seconds_left(int(site.get("harvest_end", 0)))
		entry["recovery_left"] = seconds_left(int(site.get("recovery_end", 0)))
		entry["yield"] = projected_yield(site)
		result.append(entry)
	return result

func get_site(site_id: String) -> Dictionary:
	for site: Dictionary in sites:
		if String(site.get("id", "")) == site_id:
			return site
	return {}

func begin_harvest(site_id: String) -> Dictionary:
	tick()
	var site: Dictionary = get_site(site_id)
	if site.is_empty():
		return _result(false, "Harvest site not found.")
	var station_level: int = 1
	if get_node_or_null("/root/StationProgression") != null:
		station_level = int(get_node("/root/StationProgression").get("station_level"))
	var unlock_level: int = int(site.get("unlock_level", 1))
	if station_level < unlock_level:
		return _result(false, "%s unlocks at station level %d." % [String(site.get("name", "Site")), unlock_level])
	if int(site.get("harvest_end", 0)) > 0:
		return _result(false, "A harvester is already working this site.")
	if int(site.get("recovery_end", 0)) > 0:
		return _result(false, "This resource field is recovering.")
	if int(site.get("reserve", 0)) <= 0:
		_start_recovery(site)
		return _result(false, "This site is depleted and recovering.")
	if active_harvest_count() >= harvest_slots():
		return _result(false, "All harvesting crews are deployed.")
	var duration: int = harvest_duration(site)
	var amount: int = projected_yield(site)
	site["harvest_end"] = _now() + duration
	site["pending_yield"] = amount
	site["runs"] = int(site.get("runs", 0)) + 1
	last_event = "Harvester dispatched to %s for %d seconds." % [String(site.get("name", "site")), duration]
	save_state()
	site_changed.emit(site_id)
	return _result(true, last_event)

func upgrade_site(site_id: String) -> Dictionary:
	var site: Dictionary = get_site(site_id)
	if site.is_empty():
		return _result(false, "Harvest site not found.")
	if int(site.get("harvest_end", 0)) > 0:
		return _result(false, "Wait for the current harvest to finish.")
	var station_level: int = 1
	if get_node_or_null("/root/StationProgression") != null:
		station_level = int(get_node("/root/StationProgression").get("station_level"))
	var level: int = int(site.get("level", 1))
	if level >= station_level:
		return _result(false, "Site level is capped by station level %d." % station_level)
	var cost: Dictionary = {"moonsteel":10 + level * 6, "helium3":6 + level * 4, "quantum_salvage":4 + level * 3}
	if not spend(cost):
		return _result(false, "Site upgrade needs %d ore, %d Helium-3, and %d salvage." % [cost["moonsteel"], cost["helium3"], cost["quantum_salvage"]])
	site["level"] = level + 1
	site["max_reserve"] = int(site.get("max_reserve", 100)) + 35
	site["reserve"] = mini(int(site.get("max_reserve", 100)), int(site.get("reserve", 0)) + 35)
	last_event = "%s upgraded to extraction level %d." % [String(site.get("name", "Site")), level + 1]
	save_state()
	site_changed.emit(site_id)
	return _result(true, last_event)

func projected_yield(site: Dictionary) -> int:
	var level: int = int(site.get("level", 1))
	var base_yield: int = int(site.get("base_yield", 20))
	var reserve: int = int(site.get("reserve", 0))
	return mini(reserve, base_yield + (level - 1) * 7)

func harvest_duration(site: Dictionary) -> int:
	var level: int = int(site.get("level", 1))
	var base_duration: int = int(site.get("base_duration", 20))
	return maxi(8, base_duration + int(site.get("risk", 1)) * 3 - (level - 1) * 2)

func seconds_left(timestamp: int) -> int:
	return maxi(0, timestamp - _now())

func save_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"resources":resources,
		"sites":sites,
		"total_harvests":total_harvests,
		"total_collected":total_collected,
		"last_event":last_event
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
	var data: Dictionary = parsed as Dictionary
	resources = Dictionary(data.get("resources", resources))
	sites = _dictionary_array(data.get("sites", []))
	total_harvests = int(data.get("total_harvests", 0))
	total_collected = Dictionary(data.get("total_collected", total_collected))
	last_event = String(data.get("last_event", last_event))
	_initialize_sites()
	return true

func _initialize_sites() -> void:
	var existing: Dictionary = {}
	for site: Dictionary in sites:
		existing[String(site.get("id", ""))] = site
	var rebuilt: Array[Dictionary] = []
	for template: Dictionary in SITE_TEMPLATES:
		var site_id: String = String(template.get("id", ""))
		var site: Dictionary = template.duplicate(true)
		if existing.has(site_id):
			var saved: Dictionary = existing[site_id] as Dictionary
			for key_value: Variant in saved.keys():
				site[key_value] = saved[key_value]
		if not site.has("level"):
			site["level"] = 1
		if not site.has("reserve"):
			site["reserve"] = int(site.get("max_reserve", 100))
		if not site.has("harvest_end"):
			site["harvest_end"] = 0
		if not site.has("recovery_end"):
			site["recovery_end"] = 0
		if not site.has("pending_yield"):
			site["pending_yield"] = 0
		if not site.has("runs"):
			site["runs"] = 0
		rebuilt.append(site)
	sites = rebuilt

func _complete_harvest(site: Dictionary) -> void:
	var amount: int = mini(int(site.get("pending_yield", 0)), int(site.get("reserve", 0)))
	var resource_id: String = String(site.get("resource", "moonsteel"))
	site["reserve"] = maxi(0, int(site.get("reserve", 0)) - amount)
	site["harvest_end"] = 0
	site["pending_yield"] = 0
	resources[resource_id] = resource_amount(resource_id) + amount
	total_collected[resource_id] = int(total_collected.get(resource_id, 0)) + amount
	total_harvests += 1
	last_event = "%s delivered %d %s." % [String(site.get("name", "Harvester")), amount, resource_name(resource_id)]
	if int(site.get("reserve", 0)) <= 0:
		_start_recovery(site)
	harvest_completed.emit(String(site.get("id", "")), resource_id, amount)
	site_changed.emit(String(site.get("id", "")))

func _start_recovery(site: Dictionary) -> void:
	var level: int = int(site.get("level", 1))
	site["recovery_end"] = _now() + maxi(30, 70 - level * 5)

func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for item: Variant in value:
			if item is Dictionary:
				result.append(item as Dictionary)
	return result

func _now() -> int:
	return int(Time.get_unix_time_from_system())

func _result(ok: bool, message: String) -> Dictionary:
	return {"ok":ok, "message":message}
