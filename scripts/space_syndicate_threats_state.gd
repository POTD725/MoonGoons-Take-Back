extends Node
## Named Syndicate Rising criminals command attackable fleets around resource sites.

signal threats_changed
signal battle_changed
signal target_defeated(target_id: String, commander: String)

const SAVE_PATH: String = "user://moongoons_space_threats.json"
const DIFFICULTY_NAMES: Dictionary = {1:"EASY", 2:"STANDARD", 3:"HARD", 4:"SEVERE", 5:"BOSS"}
const TARGET_TEMPLATES: Array[Dictionary] = [
	{"id":"vox_courier_pack", "site_id":"wreck_courier", "commander":"Vox-13", "crew_id":"crew_2", "class":"Runner", "portrait":"res://assets/syndicate/portraits/vox_13.svg", "title":"Ghost Courier Skiff Pack", "ship":"Courier Skiffs", "level":1, "difficulty":1, "unlock_level":1, "hp":82, "power":12, "defense":4, "respawn":55, "credits":85, "intel":2, "resource":"quantum_salvage", "resource_reward":12},
	{"id":"grit_cinder_escort", "site_id":"asteroid_cinder9", "commander":"Grit Mercer", "crew_id":"crew_4", "class":"Enforcer", "portrait":"res://assets/syndicate/portraits/grit_mercer.svg", "title":"Cinder-9 Armored Escort", "ship":"Armored Smuggler Cutters", "level":2, "difficulty":2, "unlock_level":1, "hp":126, "power":18, "defense":7, "respawn":70, "credits":120, "intel":3, "resource":"moonsteel", "resource_reward":18},
	{"id":"cinder_selene_wing", "site_id":"moon_selene", "commander":"Cinder Quell", "crew_id":"crew_3", "class":"Sharpshot", "portrait":"res://assets/syndicate/portraits/cinder_quell.svg", "title":"Selene Sharpshot Ambush", "ship":"Longshot Interceptors", "level":3, "difficulty":2, "unlock_level":2, "hp":154, "power":22, "defense":8, "respawn":80, "credits":145, "intel":4, "resource":"helium3", "resource_reward":20},
	{"id":"nyx_iron_raiders", "site_id":"asteroid_iron_choir", "commander":"Nyx Raze", "crew_id":"crew_1", "class":"Enforcer", "portrait":"res://assets/syndicate/portraits/nyx_raze.svg", "title":"Iron Choir Raider Flight", "ship":"Enforcer Gunships", "level":4, "difficulty":3, "unlock_level":2, "hp":196, "power":29, "defense":11, "respawn":95, "credits":185, "intel":5, "resource":"moonsteel", "resource_reward":28},
	{"id":"vox_relay_ghosts", "site_id":"wreck_relay", "commander":"Vox-13", "crew_id":"crew_2", "class":"Runner", "portrait":"res://assets/syndicate/portraits/vox_13.svg", "title":"Signal Ghost Convoy", "ship":"Signal-Spoofed Corvettes", "level":5, "difficulty":3, "unlock_level":3, "hp":224, "power":33, "defense":13, "respawn":105, "credits":220, "intel":6, "resource":"quantum_salvage", "resource_reward":32},
	{"id":"grit_mare_gunship", "site_id":"moon_mare_vent", "commander":"Grit Mercer", "crew_id":"crew_4", "class":"Enforcer", "portrait":"res://assets/syndicate/portraits/grit_mercer.svg", "title":"Mare Black-Market Gunship", "ship":"Heavy Contraband Frigate", "level":6, "difficulty":4, "unlock_level":4, "hp":276, "power":40, "defense":16, "respawn":120, "credits":270, "intel":7, "resource":"helium3", "resource_reward":38},
	{"id":"cinder_blueglass_killbox", "site_id":"asteroid_blueglass", "commander":"Cinder Quell", "crew_id":"crew_3", "class":"Sharpshot", "portrait":"res://assets/syndicate/portraits/cinder_quell.svg", "title":"Blueglass Longshot Kill Box", "ship":"Rail-Sniper Destroyers", "level":7, "difficulty":4, "unlock_level":5, "hp":318, "power":46, "defense":18, "respawn":135, "credits":320, "intel":8, "resource":"moonsteel", "resource_reward":46},
	{"id":"nyx_carrier_hammer", "site_id":"wreck_carrier", "commander":"Nyx Raze", "crew_id":"crew_1", "class":"Enforcer", "portrait":"res://assets/syndicate/portraits/nyx_raze.svg", "title":"Syndicate Hammer Fleet", "ship":"Raider Carrier Group", "level":8, "difficulty":5, "unlock_level":6, "hp":382, "power":54, "defense":22, "respawn":155, "credits":390, "intel":10, "resource":"quantum_salvage", "resource_reward":55},
	{"id":"crater_crown_command", "site_id":"moon_khepri", "commander":"Nyx Raze, Vox-13, Cinder Quell & Grit Mercer", "crew_id":"crew_all", "class":"Syndicate Command", "portrait":"res://assets/syndicate/portraits/nyx_raze.svg", "title":"Crater Crown Command Carrier", "ship":"Syndicate Flagship and Escort Fleet", "level":10, "difficulty":5, "unlock_level":8, "hp":540, "power":70, "defense":28, "respawn":240, "credits":650, "intel":18, "resource":"helium3", "resource_reward":80}
]

var targets: Array[Dictionary] = []
var active_battle: Dictionary = {}
var targets_defeated: int = 0
var boss_fleets_defeated: int = 0
var total_space_wins: int = 0
var last_event: String = "Syndicate fleets detected around lunar resource lanes."
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_initialize_targets()
	load_state()

func reset_state() -> void:
	targets = []
	active_battle = {}
	targets_defeated = 0
	boss_fleets_defeated = 0
	total_space_wins = 0
	last_event = "Space-threat network reset."
	_initialize_targets()
	save_state()
	threats_changed.emit()

func tick() -> void:
	var now: int = _now()
	var changed: bool = false
	for target: Dictionary in targets:
		var defeated_until: int = int(target.get("defeated_until", 0))
		if defeated_until > 0 and now >= defeated_until:
			target["defeated_until"] = 0
			target["hp"] = int(target.get("max_hp", 100))
			last_event = "%s has returned to the resource lanes." % String(target.get("title", "Syndicate fleet"))
			changed = true
	if changed:
		save_state()
		threats_changed.emit()

func target_catalog() -> Array[Dictionary]:
	tick()
	var result: Array[Dictionary] = []
	var station_level: int = _station_level()
	for target: Dictionary in targets:
		var entry: Dictionary = target.duplicate(true)
		entry["locked"] = station_level < int(target.get("unlock_level", 1))
		entry["defeated"] = int(target.get("defeated_until", 0)) > _now()
		entry["respawn_left"] = maxi(0, int(target.get("defeated_until", 0)) - _now())
		entry["difficulty_name"] = difficulty_name(int(target.get("difficulty", 1)))
		result.append(entry)
	return result

func get_target(target_id: String) -> Dictionary:
	for target: Dictionary in targets:
		if String(target.get("id", "")) == target_id:
			return target
	return {}

func target_for_site(site_id: String) -> Dictionary:
	for target: Dictionary in targets:
		if String(target.get("site_id", "")) == site_id:
			return target
	return {}

func site_is_threatened(site_id: String) -> bool:
	tick()
	var target: Dictionary = target_for_site(site_id)
	if target.is_empty():
		return false
	return int(target.get("defeated_until", 0)) <= _now() and _station_level() >= int(target.get("unlock_level", 1))

func difficulty_name(value: int) -> String:
	return String(DIFFICULTY_NAMES.get(clampi(value, 1, 5), "UNKNOWN"))

func begin_battle(target_id: String) -> Dictionary:
	tick()
	if not active_battle.is_empty():
		return _result(false, "Another space engagement is already active.")
	var target: Dictionary = get_target(target_id)
	if target.is_empty():
		return _result(false, "Syndicate target not found.")
	if _station_level() < int(target.get("unlock_level", 1)):
		return _result(false, "This target unlocks at station level %d." % int(target.get("unlock_level", 1)))
	if int(target.get("defeated_until", 0)) > _now():
		return _result(false, "That fleet has already been driven off for now.")
	var defense_rating: int = _defense_rating()
	var station_level: int = _station_level()
	active_battle = {
		"target_id":target_id,
		"enemy_hp":int(target.get("max_hp", target.get("hp", 100))),
		"enemy_max_hp":int(target.get("max_hp", target.get("hp", 100))),
		"player_hull":120 + station_level * 18,
		"player_max_hull":120 + station_level * 18,
		"player_shield":55 + station_level * 8,
		"player_max_shield":55 + station_level * 8,
		"player_attack":14 + int(defense_rating / 5),
		"player_defense":6 + int(defense_rating / 8),
		"scan_bonus":0,
		"evading":false,
		"rail_cooldown":0,
		"turn":1,
		"log":"Authority interceptors have engaged %s." % String(target.get("title", "Syndicate fleet"))
	}
	last_event = String(active_battle.get("log", "Space engagement started."))
	save_state()
	battle_changed.emit()
	return _result(true, last_event)

func battle_action(action: String) -> Dictionary:
	if active_battle.is_empty():
		return _result(false, "No active space battle.")
	var target: Dictionary = get_target(String(active_battle.get("target_id", "")))
	if target.is_empty():
		active_battle = {}
		return _result(false, "The target signal was lost.")
	var message: String = ""
	var enemy_retaliates: bool = false
	match action:
		"cannons":
			var damage: int = maxi(4, int(active_battle.get("player_attack", 14)) + _rng.randi_range(0, 8) + int(active_battle.get("scan_bonus", 0)) - int(target.get("defense", 4)))
			active_battle["enemy_hp"] = maxi(0, int(active_battle.get("enemy_hp", 0)) - damage)
			active_battle["scan_bonus"] = 0
			message = "Pulse cannons hit for %d damage." % damage
			enemy_retaliates = true
		"rail_strike":
			if int(active_battle.get("rail_cooldown", 0)) > 0:
				return _result(false, "Rail capacitors need %d more turn(s)." % int(active_battle.get("rail_cooldown", 0)))
			var rail_level: int = _defense_level("rail_battery")
			var damage: int = maxi(12, 25 + rail_level * 7 + _rng.randi_range(0, 12) + int(active_battle.get("scan_bonus", 0)) - int(target.get("defense", 4)))
			active_battle["enemy_hp"] = maxi(0, int(active_battle.get("enemy_hp", 0)) - damage)
			active_battle["rail_cooldown"] = 2
			active_battle["scan_bonus"] = 0
			message = "Rail strike tears through the fleet for %d damage." % damage
			enemy_retaliates = true
		"scan":
			if PrecinctState.intel < 2:
				return _result(false, "Tactical scan needs 2 intel.")
			PrecinctState.intel -= 2
			active_battle["scan_bonus"] = 14 + _station_level() * 2
			message = "Tactical scan exposed weak armor. The next attack gains bonus damage."
			enemy_retaliates = true
		"evade":
			active_battle["evading"] = true
			var shield_gain: int = 6 + _defense_level("interceptor_bay") * 2
			active_battle["player_shield"] = mini(int(active_battle.get("player_max_shield", 100)), int(active_battle.get("player_shield", 0)) + shield_gain)
			message = "Interceptor wing evades and recovers %d shield." % shield_gain
			enemy_retaliates = true
		"retreat":
			last_event = "Authority wing disengaged from %s." % String(target.get("title", "the fleet"))
			active_battle = {}
			save_state()
			battle_changed.emit()
			return _result(true, last_event)
		_:
			return _result(false, "Unknown space-combat action.")
	if int(active_battle.get("enemy_hp", 0)) <= 0:
		return _finish_victory(target, message)
	if enemy_retaliates:
		message += "\n" + _enemy_turn(target)
	if int(active_battle.get("player_hull", 0)) <= 0:
		last_event = "Authority interceptors were disabled by %s. The crew escaped in recovery pods." % String(target.get("commander", "Syndicate forces"))
		active_battle = {}
		save_state()
		battle_changed.emit()
		return _result(false, last_event)
	active_battle["turn"] = int(active_battle.get("turn", 1)) + 1
	active_battle["rail_cooldown"] = maxi(0, int(active_battle.get("rail_cooldown", 0)) - 1)
	active_battle["log"] = message
	last_event = message
	save_state()
	battle_changed.emit()
	return _result(true, message)

func save_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"targets":targets,
		"active_battle":active_battle,
		"targets_defeated":targets_defeated,
		"boss_fleets_defeated":boss_fleets_defeated,
		"total_space_wins":total_space_wins,
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
	targets = _dictionary_array(data.get("targets", []))
	active_battle = Dictionary(data.get("active_battle", {}))
	targets_defeated = int(data.get("targets_defeated", 0))
	boss_fleets_defeated = int(data.get("boss_fleets_defeated", 0))
	total_space_wins = int(data.get("total_space_wins", 0))
	last_event = String(data.get("last_event", last_event))
	_initialize_targets()
	return true

func _initialize_targets() -> void:
	var existing: Dictionary = {}
	for target: Dictionary in targets:
		existing[String(target.get("id", ""))] = target
	var rebuilt: Array[Dictionary] = []
	for template: Dictionary in TARGET_TEMPLATES:
		var target_id: String = String(template.get("id", ""))
		var target: Dictionary = template.duplicate(true)
		target["max_hp"] = int(template.get("hp", 100))
		if existing.has(target_id):
			var saved: Dictionary = existing[target_id] as Dictionary
			for key_value: Variant in saved.keys():
				target[key_value] = saved[key_value]
		if not target.has("hp"):
			target["hp"] = int(target.get("max_hp", 100))
		if not target.has("defeated_until"):
			target["defeated_until"] = 0
		if not target.has("wins"):
			target["wins"] = 0
		rebuilt.append(target)
	targets = rebuilt

func _enemy_turn(target: Dictionary) -> String:
	var damage: int = maxi(3, int(target.get("power", 10)) + _rng.randi_range(-3, 7) - int(active_battle.get("player_defense", 5)))
	if bool(active_battle.get("evading", false)):
		damage = maxi(1, int(ceil(float(damage) * 0.45)))
		active_battle["evading"] = false
	var shield: int = int(active_battle.get("player_shield", 0))
	var absorbed: int = mini(shield, damage)
	active_battle["player_shield"] = shield - absorbed
	damage -= absorbed
	if damage > 0:
		active_battle["player_hull"] = maxi(0, int(active_battle.get("player_hull", 0)) - damage)
	return "%s retaliates: %d shield absorbed, %d hull damage." % [String(target.get("commander", "Syndicate")), absorbed, damage]

func _finish_victory(target: Dictionary, opening_message: String) -> Dictionary:
	var target_id: String = String(target.get("id", ""))
	var resource_id: String = String(target.get("resource", "moonsteel"))
	var resource_reward: int = int(target.get("resource_reward", 10))
	target["defeated_until"] = _now() + int(target.get("respawn", 60))
	target["hp"] = int(target.get("max_hp", 100))
	target["wins"] = int(target.get("wins", 0)) + 1
	targets_defeated += 1
	total_space_wins += 1
	if int(target.get("difficulty", 1)) >= 5:
		boss_fleets_defeated += 1
	PrecinctState.credits += int(target.get("credits", 80))
	PrecinctState.intel += int(target.get("intel", 2))
	var harvest: Node = get_node_or_null("/root/ResourceHarvest")
	if harvest != null and harvest.has_method("add_resource"):
		harvest.call("add_resource", resource_id, resource_reward)
	var message: String = "%s\nTARGET DEFEATED // %s driven from the lane. +%d credits, +%d intel, +%d %s." % [opening_message, String(target.get("commander", "Syndicate fleet")), int(target.get("credits", 80)), int(target.get("intel", 2)), resource_reward, _resource_name(resource_id)]
	last_event = message
	active_battle = {}
	save_state()
	target_defeated.emit(target_id, String(target.get("commander", "Syndicate")))
	threats_changed.emit()
	battle_changed.emit()
	return _result(true, message)

func _station_level() -> int:
	var progression: Node = get_node_or_null("/root/StationProgression")
	return int(progression.get("station_level")) if progression != null else 1

func _defense_rating() -> int:
	var progression: Node = get_node_or_null("/root/StationProgression")
	return int(progression.call("defense_rating")) if progression != null and progression.has_method("defense_rating") else 40

func _defense_level(defense_id: String) -> int:
	var progression: Node = get_node_or_null("/root/StationProgression")
	return int(progression.call("defense_level", defense_id)) if progression != null and progression.has_method("defense_level") else 1

func _resource_name(resource_id: String) -> String:
	var harvest: Node = get_node_or_null("/root/ResourceHarvest")
	return String(harvest.call("resource_name", resource_id)) if harvest != null and harvest.has_method("resource_name") else resource_id.capitalize()

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
