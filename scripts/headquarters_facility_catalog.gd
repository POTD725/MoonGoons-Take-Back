class_name HeadquartersFacilityCatalog
extends RefCounted
## Canonical architecture for the Take Back precinct vertical slice.
## One Police Headquarters contains nine departments. Each department owns exactly
## twelve upgradeable systems. Nine standalone facilities surround Headquarters.

const STYLE_NAMES: Array[String] = [
	"Authority Standard", "Lunar Industrial", "Peacekeeper Tactical",
	"Orbital Civic", "Prototype Neon"
]

const DEPARTMENTS: Array[Dictionary] = [
	{"id":"reception", "name":"Reception & Public Intake", "function":"Civilian reports, visitors, emergency intake", "accent":"#65ECFF"},
	{"id":"operations", "name":"Operations & Dispatch", "function":"Mission control and officer deployment", "accent":"#4BD8FF"},
	{"id":"chief", "name":"Chief's Office", "function":"Headquarters and department level cap", "accent":"#FFE16A"},
	{"id":"detectives", "name":"Detectives Office", "function":"Cases, witnesses, evidence boards, warrants", "accent":"#FFB75A"},
	{"id":"cyber_crimes", "name":"Cyber Crimes Division", "function":"Network crime, digital evidence, signal tracing", "accent":"#7DDCFF"},
	{"id":"bio_hacking", "name":"Bio-Hacking Division", "function":"Illegal augmentation and genetic crime", "accent":"#67F0B2"},
	{"id":"holding", "name":"Holding & Booking", "function":"Booking, cells, contraband and custody", "accent":"#82A9FF"},
	{"id":"interrogation", "name":"Interrogation Division", "function":"Interview, guilt analysis and intelligence", "accent":"#C780FF"},
	{"id":"prisoner_transport", "name":"Prisoner Transport", "function":"Secure transfer routes and escort control", "accent":"#5FE5FF"}
]

const FACILITIES: Array[Dictionary] = [
	{"id":"research_center", "name":"Research Center", "function":"Technology and alliance research", "accent":"#8CEAFF", "position":Vector2(-20,-15)},
	{"id":"guard_academy", "name":"Guard Academy", "function":"Train defensive peacekeepers", "accent":"#6CB4FF", "position":Vector2(-8,-18)},
	{"id":"biker_garage", "name":"Biker Response Garage", "function":"Train rapid-response riders", "accent":"#FFB15D", "position":Vector2(8,-18)},
	{"id":"marksman_range", "name":"Marksman Range", "function":"Train long-range officers", "accent":"#FF6F89", "position":Vector2(20,-15)},
	{"id":"robotics_bay", "name":"Robotics Bay", "function":"Build drones and robotic deputies", "accent":"#B58CFF", "position":Vector2(-23,3)},
	{"id":"hospital", "name":"Peacekeeper Hospital", "function":"Heal officers and perform medical operations", "accent":"#58F0C0", "position":Vector2(23,3)},
	{"id":"crime_lab", "name":"Forensic Crime Lab", "function":"Analyze evidence and bio-digital traces", "accent":"#77E4FF", "position":Vector2(-18,18)},
	{"id":"storage_depot", "name":"Secure Storage Depot", "function":"Store equipment, evidence and seized cargo", "accent":"#F5CE72", "position":Vector2(0,21)},
	{"id":"vehicle_depot", "name":"Vehicle & Transport Depot", "function":"Patrol vehicles, shuttles and prisoner carriers", "accent":"#62DFFF", "position":Vector2(18,18)}
]

const DEPARTMENT_ITEMS: Dictionary = {
	"reception":["Intake Desk","Visitor Scanner","Emergency Kiosk","Case Filing Terminal","Public Holo-Board","Language Translator","Civilian Shield Gate","Waiting Area","Report Recorder","Identity Verifier","Accessibility Station","Dispatch Handoff Console"],
	"operations":["Command Table","Dispatch Console","Lunar Holo-Map","Patrol Router","Distress Receiver","Officer Tracker","Mission Archive","Fleet Uplink","Sector Scanner","Emergency Beacon","Shift Scheduler","Operations AI"],
	"chief":["Command Desk","Strategy Wall","Authority Uplink","Department Cap Server","Alliance Console","Budget Terminal","Promotion Board","Directive Archive","Secure Communicator","Crisis Table","Station Charter","Executive AI"],
	"detectives":["Evidence Board","Case Database","Witness Booth","Warrant Terminal","Crime Pattern AI","Field Kit Locker","Suspect Archive","Interview Recorder","Cold Case Vault","Surveillance Desk","Detective Lab Bench","Lead Assignment Console"],
	"cyber_crimes":["Network Trace Array","Malware Sandbox","Signal Decoder","Digital Evidence Vault","Quantum Firewall","Drone Forensics Bench","Darknet Monitor","Identity Graph","Encryption Cracker","Data Recovery Rig","Cyber Range","Counter-Hack AI"],
	"bio_hacking":["Gene Scanner","Augmentation Reader","Bio-Sample Locker","Nanite Detector","Clone Registry","Contamination Hood","Illegal Implant Bench","Tissue Analyzer","Mutation Archive","Biohazard Seal","Medical Evidence AI","Genome Trace Array"],
	"holding":["Cell Door Locks","Booking Terminal","Contraband Scanner","Restraint Rack","Custody Camera Grid","Prisoner Property Vault","Fingerprint Station","Breath Analyzer","Cell Climate Control","Meal Dispenser","Emergency Suppression","Custody AI"],
	"interrogation":["Truth Scanner","Evidence Console","Restraint Table","Guilt Meter","Voice Stress Array","Memory Playback","Interview Recorder","Observation Glass","Legal Rights Terminal","Behavior AI","Room Climate Control","Intelligence Extractor"],
	"prisoner_transport":["Transfer Airlock","Prisoner Scanner","Transport Console","Escort Scheduler","Route Encryptor","Vehicle Restraints","Docking Clamp","Transfer Manifest","Emergency Lockdown","Shuttle Tracker","Medical Restraint Kit","Convoy Command AI"]
}

const RESOURCE_ROTATION: Array[String] = ["credits", "moonsteel", "helium3", "quantum_salvage"]

static func department_ids() -> Array[String]:
	var result: Array[String] = []
	for entry: Dictionary in DEPARTMENTS:
		result.append(String(entry.get("id", "")))
	return result

static func facility_ids() -> Array[String]:
	var result: Array[String] = []
	for entry: Dictionary in FACILITIES:
		result.append(String(entry.get("id", "")))
	return result

static func department(department_id: String) -> Dictionary:
	for entry: Dictionary in DEPARTMENTS:
		if String(entry.get("id", "")) == department_id:
			return entry
	return {}

static func facility(facility_id: String) -> Dictionary:
	for entry: Dictionary in FACILITIES:
		if String(entry.get("id", "")) == facility_id:
			return entry
	return {}

static func department_items(department_id: String) -> Array[Dictionary]:
	var names_value: Variant = DEPARTMENT_ITEMS.get(department_id, [])
	var result: Array[Dictionary] = []
	if not names_value is Array:
		return result
	var names := names_value as Array
	for index: int in range(names.size()):
		var name: String = String(names[index])
		var resource_a: String = RESOURCE_ROTATION[index % RESOURCE_ROTATION.size()]
		var resource_b: String = RESOURCE_ROTATION[(index + 2) % RESOURCE_ROTATION.size()]
		result.append({
			"id": _slug(name), "name": name,
			"resource_a": resource_a, "resource_b": resource_b,
			"base_cost": 45 + index * 9, "base_time": 18 + index * 4
		})
	return result

static func item_cost(item: Dictionary, current_level: int) -> Dictionary:
	var base: int = int(item.get("base_cost", 50))
	var primary: int = base + current_level * 18 + int(pow(float(current_level), 1.42) * 3.0)
	var secondary: int = maxi(4, int(round(float(primary) * 0.34)))
	return {
		String(item.get("resource_a", "credits")): primary,
		String(item.get("resource_b", "moonsteel")): secondary
	}

static func item_time(item: Dictionary, current_level: int) -> int:
	return int(item.get("base_time", 20)) + current_level * 11 + int(pow(float(current_level), 1.28) * 4.0)

static func department_upgrade_cost(department_id: String, current_level: int) -> Dictionary:
	var index: int = maxi(0, department_ids().find(department_id))
	return {
		"credits": 120 + current_level * 80 + index * 15,
		"moonsteel": 20 + current_level * 13,
		"helium3": 12 + current_level * 8
	}

static func department_upgrade_time(current_level: int) -> int:
	return 45 + current_level * 24 + int(pow(float(current_level), 1.35) * 8.0)

static func facility_upgrade_cost(facility_id: String, current_level: int) -> Dictionary:
	var index: int = maxi(0, facility_ids().find(facility_id))
	return {
		"credits": 180 + current_level * 105 + index * 20,
		"moonsteel": 32 + current_level * 17,
		"helium3": 18 + current_level * 11,
		"quantum_salvage": 8 + current_level * 7
	}

static func facility_upgrade_time(current_level: int) -> int:
	return 70 + current_level * 36 + int(pow(float(current_level), 1.38) * 10.0)

static func _slug(value: String) -> String:
	return value.to_lower().replace("'", "").replace("-", "_").replace(" ", "_").replace("/", "_")
