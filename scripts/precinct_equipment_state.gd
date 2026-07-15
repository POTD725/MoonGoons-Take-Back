extends Node
## Individual room equipment upgrades. Upgrade requests are delegated to
## StationProgression so every item obeys station, Chief, and room caps.

signal equipment_changed

const SAVE_PATH: String = "user://moongoons_precinct_equipment.json"

const EQUIPMENT_CATALOG: Dictionary = {
	"ops": [
		{"id":"command_table","icon":"command_table","name":"Command Table","effect":"Patrol planning speed","description":"Projects patrol routes, active calls, officer positions, and command priorities above the Operations deck.","base_cost":70},
		{"id":"dispatch_console","icon":"dispatch_console","name":"Dispatch Console","effect":"Distress-call response","description":"Coordinates distress calls and shortens the time between an alert, officer assignment, and launch clearance.","base_cost":65},
		{"id":"holo_map","icon":"holo_map","name":"Lunar Holo-Map","effect":"District intelligence","description":"Builds a live three-dimensional map of lunar districts, orbital lanes, criminal activity, and mission routes.","base_cost":80}
	],
	"armory": [
		{"id":"weapon_racks","icon":"weapon_racks","name":"Weapon Racks","effect":"Officer attack power","description":"Stores calibrated Peacekeeper weapons and improves the attack readiness of officers posted to the Armory.","base_cost":75},
		{"id":"armor_forge","icon":"armor_forge","name":"Armor Forge","effect":"Officer defense","description":"Fabricates and repairs pressure-rated armor plates, helmets, seals, and defensive field components.","base_cost":85},
		{"id":"ammo_loader","icon":"ammo_loader","name":"Ammo Loader","effect":"Patrol readiness","description":"Loads patrol craft and response teams with ammunition, power cells, and mission-specific equipment.","base_cost":65}
	],
	"cells": [
		{"id":"cell_locks","icon":"cell_locks","name":"Cell Door Locks","effect":"Prisoner capacity","description":"Controls reinforced detention doors, emergency lockdowns, prisoner capacity, and escape resistance.","base_cost":70},
		{"id":"security_scanner","icon":"security_scanner","name":"Security Scanner","effect":"Contraband detection","description":"Searches detainees and cargo for contraband, hidden weapons, trackers, and Syndicate devices.","base_cost":75},
		{"id":"intake_terminal","icon":"intake_terminal","name":"Intake Terminal","effect":"Prisoner processing","description":"Processes arrests, identity records, evidence links, charges, and secure prisoner assignments.","base_cost":60}
	],
	"quarters": [
		{"id":"bunks","icon":"bunks","name":"Crew Bunks","effect":"Officer recovery","description":"Provides pressure-safe crew rest quarters that improve recovery between patrols and station emergencies.","base_cost":60},
		{"id":"mess_station","icon":"mess_station","name":"Mess Station","effect":"Crew stamina","description":"Produces crew meals and hydration packs, improving stamina during long duty rotations.","base_cost":65},
		{"id":"morale_console","icon":"morale_console","name":"Morale Console","effect":"Training efficiency","description":"Tracks fatigue, commendations, team cohesion, and training efficiency across the station crew.","base_cost":70}
	],
	"medbay": [
		{"id":"med_pods","icon":"med_pods","name":"Medical Pods","effect":"Healing speed","description":"Stabilizes injured officers and civilians inside automated recovery capsules with life-support monitoring.","base_cost":85},
		{"id":"diagnostic_scanner","icon":"diagnostic_scanner","name":"Diagnostic Scanner","effect":"Injury detection","description":"Detects internal injuries, toxins, radiation exposure, alien pathogens, and suit-seal failures.","base_cost":75},
		{"id":"trauma_console","icon":"trauma_console","name":"Trauma Console","effect":"Critical recovery","description":"Coordinates critical treatment, surgical tools, emergency medication, and medical side operations.","base_cost":90}
	],
	"chief": [
		{"id":"command_desk","icon":"command_desk","name":"Chief's Command Desk","effect":"Station authority","description":"Sets the maximum level for station rooms and equipment while coordinating precinct-wide authority.","base_cost":90},
		{"id":"strategy_wall","icon":"strategy_wall","name":"Strategy Wall","effect":"Mission rewards","description":"Combines mission intelligence, fleet movements, evidence, and district control into command plans.","base_cost":95},
		{"id":"authority_uplink","icon":"authority_uplink","name":"Authority Uplink","effect":"District command range","description":"Maintains encrypted contact with regional Peacekeeper command and expands station command range.","base_cost":100}
	],
	"interrogation": [
		{"id":"truth_scanner","icon":"truth_scanner","name":"Truth Scanner","effect":"Interrogation intel","description":"Compares stress, voice, bio-signals, evidence, and testimony during interrogation operations.","base_cost":85},
		{"id":"evidence_console","icon":"evidence_console","name":"Evidence Console","effect":"Evidence recovery","description":"Catalogs recovered evidence and links suspects, locations, ships, crimes, and Syndicate networks.","base_cost":75},
		{"id":"restraint_table","icon":"restraint_table","name":"Restraint Table","effect":"Suspect compliance","description":"Secures dangerous suspects while preserving monitored, controlled interrogation conditions.","base_cost":70}
	],
	"transfer": [
		{"id":"airlock_gate","icon":"airlock_gate","name":"Transfer Airlock","effect":"Transfer security","description":"Seals prisoner-transfer corridors and prevents decompression, escape, or hostile boarding.","base_cost":90},
		{"id":"prisoner_scanner","icon":"prisoner_scanner","name":"Prisoner Scanner","effect":"Transfer inspection","description":"Performs final identity, health, contraband, and tracking checks before secure transport.","base_cost":75},
		{"id":"transport_console","icon":"transport_console","name":"Transport Console","effect":"Transfer rewards","description":"Schedules prisoner shuttles, escort teams, docking windows, routes, and transfer rewards.","base_cost":80}
	]
}

var item_levels: Dictionary = {}
var total_upgrades: int = 0

func _ready() -> void:
	_initialize_levels()
	load_state()

func reset_state() -> void:
	item_levels = {}
	total_upgrades = 0
	_initialize_levels()
	save_state()
	equipment_changed.emit()

func room_items(room_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var source: Variant = EQUIPMENT_CATALOG.get(room_id, [])
	if source is Array:
		for raw_item: Variant in source:
			if not raw_item is Dictionary:
				continue
			var item: Dictionary = (raw_item as Dictionary).duplicate(true)
			var item_id: String = String(item.get("id", ""))
			var level: int = item_level(room_id, item_id)
			item["level"] = level
			item["cap"] = int(PrecinctState.get_room(room_id).get("level", 1))
			item["upgrade_cost"] = upgrade_cost(room_id, item_id)
			result.append(item)
	return result

func item_level(room_id: String, item_id: String) -> int:
	return int(item_levels.get(_key(room_id, item_id), 1))

func chief_level() -> int:
	return maxi(1, int(PrecinctState.get_room("chief").get("level", 1)))

func upgrade_cost(room_id: String, item_id: String) -> int:
	var item: Dictionary = _catalog_item(room_id, item_id)
	if item.is_empty():
		return 0
	var current_level: int = item_level(room_id, item_id)
	return int(item.get("base_cost", 70)) + current_level * 40

func upgrade_item(room_id: String, item_id: String) -> Dictionary:
	var progression: Node = get_node_or_null("/root/StationProgression")
	if progression != null and progression.has_method("begin_item_upgrade"):
		return progression.call("begin_item_upgrade", room_id, item_id) as Dictionary
	return _result(false, "Station progression service is unavailable.")

func complete_item_upgrade(room_id: String, item_id: String, target_level: int) -> void:
	var item: Dictionary = _catalog_item(room_id, item_id)
	if item.is_empty():
		return
	var current_level: int = item_level(room_id, item_id)
	var resolved_level: int = maxi(current_level, target_level)
	item_levels[_key(room_id, item_id)] = resolved_level
	total_upgrades += 1
	PrecinctState.last_event = "%s reached level %d." % [String(item.get("name", "Equipment")), resolved_level]
	save_state()
	equipment_changed.emit()

func total_item_count() -> int:
	var total: int = 0
	for room_value: Variant in EQUIPMENT_CATALOG.values():
		if room_value is Array:
			total += (room_value as Array).size()
	return total

func upgraded_item_count() -> int:
	var count: int = 0
	for level_value: Variant in item_levels.values():
		if int(level_value) > 1:
			count += 1
	return count

func room_operational_rating(room_id: String) -> int:
	var items: Array[Dictionary] = room_items(room_id)
	if items.is_empty():
		return 0
	var level_total: int = 0
	for item: Dictionary in items:
		level_total += int(item.get("level", 1))
	return int(round(float(level_total) / float(items.size())))

func save_state() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"item_levels": item_levels,
		"total_upgrades": total_upgrades
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
	item_levels = Dictionary(data.get("item_levels", {}))
	total_upgrades = int(data.get("total_upgrades", 0))
	_initialize_levels()
	equipment_changed.emit()
	return true

func _initialize_levels() -> void:
	for room_value: Variant in EQUIPMENT_CATALOG.keys():
		var room_id: String = String(room_value)
		var source: Variant = EQUIPMENT_CATALOG.get(room_id, [])
		if not source is Array:
			continue
		for raw_item: Variant in source:
			if raw_item is Dictionary:
				var item_id: String = String((raw_item as Dictionary).get("id", ""))
				var item_key: String = _key(room_id, item_id)
				if not item_levels.has(item_key):
					item_levels[item_key] = 1

func _catalog_item(room_id: String, item_id: String) -> Dictionary:
	var source: Variant = EQUIPMENT_CATALOG.get(room_id, [])
	if source is Array:
		for raw_item: Variant in source:
			if raw_item is Dictionary and String((raw_item as Dictionary).get("id", "")) == item_id:
				return raw_item as Dictionary
	return {}

func _key(room_id: String, item_id: String) -> String:
	return "%s:%s" % [room_id, item_id]

func _result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message}
