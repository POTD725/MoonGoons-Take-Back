extends Node
## Data-driven Police Headquarters and standalone facility progression.
## Headquarters departments contain twelve individually leveled systems. All
## costs use credits plus harvested Moonsteel, Helium-3, and Quantum Salvage.

signal complex_changed
signal job_completed(job_id: String, label: String)

const SAVE_PATH := "user://moongoons_police_complex.json"
const MAX_LEVEL := 100

const DEPARTMENTS: Dictionary = {
	"reception": {
		"name":"Reception & Public Intake", "function":"Civilian assistance, reports, screening, and case intake", "accent":"#66F0FF",
		"items":[
			{"id":"intake_counter","name":"Intake Counter","effect":"Civilian report speed","profile":"structure","base":65},
			{"id":"visitor_scanner","name":"Visitor Scanner","effect":"Entrance threat detection","profile":"security","base":75},
			{"id":"report_kiosk","name":"Public Report Kiosk","effect":"Self-service case intake","profile":"tech","base":70},
			{"id":"emergency_intercom","name":"Emergency Intercom","effect":"Priority-call routing","profile":"power","base":68},
			{"id":"waiting_area","name":"Waiting Area","effect":"Public service capacity","profile":"structure","base":60},
			{"id":"identity_terminal","name":"Identity Terminal","effect":"Visitor verification","profile":"tech","base":74},
			{"id":"evidence_drop","name":"Secure Evidence Drop","effect":"Citizen evidence intake","profile":"security","base":78},
			{"id":"records_terminal","name":"Public Records Terminal","effect":"Records request speed","profile":"tech","base":72},
			{"id":"translation_console","name":"Translation Console","effect":"Multilingual assistance","profile":"tech","base":70},
			{"id":"complaint_desk","name":"Complaint Desk","effect":"Internal complaint processing","profile":"balanced","base":66},
			{"id":"dispatch_handoff","name":"Dispatch Handoff Console","effect":"Case-to-patrol response speed","profile":"power","base":82},
			{"id":"security_shutters","name":"Entrance Security Shutters","effect":"Headquarters breach resistance","profile":"security","base":88}
		]
	},
	"operations": {
		"name":"Operations & Dispatch", "function":"Precinct command, calls, patrol tracking, and emergency coordination", "accent":"#48D7FF",
		"items":[
			{"id":"dispatch_console","name":"Dispatch Console","effect":"Patrol response speed","profile":"tech","base":70},
			{"id":"command_table","name":"Command Table","effect":"Mission planning","profile":"balanced","base":78},
			{"id":"lunar_holo_map","name":"Lunar Holo-Map","effect":"District intelligence","profile":"power","base":82},
			{"id":"communications_array","name":"Communications Array","effect":"Signal range","profile":"power","base":84},
			{"id":"incident_wall","name":"Incident Status Wall","effect":"Active-case capacity","profile":"tech","base":76},
			{"id":"patrol_tracker","name":"Patrol Tracker","effect":"Officer deployment control","profile":"tech","base":74},
			{"id":"emergency_router","name":"Emergency Router","effect":"Distress-call priority","profile":"power","base":80},
			{"id":"officer_status_board","name":"Officer Status Board","effect":"Personnel readiness","profile":"balanced","base":72},
			{"id":"threat_analyzer","name":"Threat Analyzer","effect":"Enemy difficulty forecasting","profile":"tech","base":88},
			{"id":"drone_feed_console","name":"Drone Feed Console","effect":"Remote surveillance","profile":"tech","base":86},
			{"id":"backup_power_unit","name":"Backup Power Unit","effect":"Operations uptime","profile":"power","base":90},
			{"id":"command_archive","name":"Command Archive","effect":"Mission reward intelligence","profile":"security","base":84}
		]
	},
	"chief": {
		"name":"Chief's Office", "function":"Authority cap, policy, staffing, and district command", "accent":"#FFE36A",
		"items":[
			{"id":"command_desk","name":"Chief's Command Desk","effect":"Headquarters authority","profile":"structure","base":90},
			{"id":"strategy_wall","name":"Strategy Wall","effect":"Mission reward planning","profile":"tech","base":95},
			{"id":"authority_uplink","name":"Authority Uplink","effect":"District command range","profile":"power","base":100},
			{"id":"secure_comms","name":"Secure Command Comms","effect":"Encrypted leadership traffic","profile":"security","base":96},
			{"id":"policy_archive","name":"Policy Archive","effect":"Department efficiency","profile":"tech","base":88},
			{"id":"briefing_table","name":"Executive Briefing Table","effect":"Command coordination","profile":"balanced","base":92},
			{"id":"personnel_console","name":"Personnel Console","effect":"Officer capacity","profile":"tech","base":94},
			{"id":"district_map","name":"District Command Map","effect":"Territory oversight","profile":"power","base":98},
			{"id":"command_safe","name":"Command Evidence Safe","effect":"High-value evidence security","profile":"security","base":102},
			{"id":"crisis_terminal","name":"Crisis Response Terminal","effect":"Emergency defense response","profile":"power","base":104},
			{"id":"alliance_link","name":"Alliance Command Link","effect":"Alliance coordination","profile":"tech","base":108},
			{"id":"executive_security","name":"Executive Security Grid","effect":"Chief protection and HQ cap stability","profile":"security","base":110}
		]
	},
	"detectives": {
		"name":"Detective Bureau", "function":"Case investigation, warrants, surveillance, and cold-case work", "accent":"#FFB85A",
		"items":[
			{"id":"case_board","name":"Case Evidence Board","effect":"Investigation speed","profile":"structure","base":72},
			{"id":"evidence_terminal","name":"Evidence Review Terminal","effect":"Evidence analysis","profile":"tech","base":78},
			{"id":"interview_desk","name":"Witness Interview Desk","effect":"Witness cooperation","profile":"balanced","base":68},
			{"id":"forensic_viewer","name":"Forensic Viewer","effect":"Clue identification","profile":"tech","base":82},
			{"id":"surveillance_archive","name":"Surveillance Archive","effect":"Suspect tracking","profile":"security","base":80},
			{"id":"suspect_database","name":"Suspect Database","effect":"Identity matching","profile":"tech","base":84},
			{"id":"field_kit_station","name":"Field Kit Station","effect":"Detective readiness","profile":"structure","base":76},
			{"id":"cold_case_vault","name":"Cold Case Vault","effect":"Legacy-case rewards","profile":"security","base":86},
			{"id":"warrant_terminal","name":"Warrant Terminal","effect":"Raid authorization speed","profile":"tech","base":80},
			{"id":"trace_analyzer","name":"Trace Evidence Analyzer","effect":"Scene reconstruction","profile":"tech","base":88},
			{"id":"informant_console","name":"Informant Network Console","effect":"Intel generation","profile":"balanced","base":92},
			{"id":"briefing_table","name":"Detective Briefing Table","effect":"Team investigation power","profile":"structure","base":84}
		]
	},
	"cyber_crimes": {
		"name":"Cyber Crimes Division", "function":"Network forensics, hacking investigations, and digital evidence", "accent":"#8C7CFF",
		"items":[
			{"id":"network_forensics","name":"Network Forensics Rig","effect":"Digital evidence recovery","profile":"tech","base":84},
			{"id":"intrusion_lab","name":"Intrusion Analysis Lab","effect":"Breach investigation","profile":"tech","base":88},
			{"id":"malware_sandbox","name":"Malware Sandbox","effect":"Malware containment","profile":"security","base":90},
			{"id":"signal_tracer","name":"Signal Tracer","effect":"Hacker location accuracy","profile":"power","base":86},
			{"id":"crypto_breaker","name":"Cryptography Breaker","effect":"Encrypted evidence access","profile":"tech","base":94},
			{"id":"darknet_monitor","name":"Darknet Monitor","effect":"Criminal market detection","profile":"tech","base":92},
			{"id":"data_recovery","name":"Data Recovery Array","effect":"Deleted-file restoration","profile":"power","base":90},
			{"id":"firewall_core","name":"Division Firewall Core","effect":"Cyberattack resistance","profile":"security","base":96},
			{"id":"identity_graph","name":"Digital Identity Graph","effect":"Alias matching","profile":"tech","base":88},
			{"id":"drone_hack_console","name":"Drone Hack Console","effect":"Hostile drone capture","profile":"power","base":98},
			{"id":"quantum_decoder","name":"Quantum Decoder","effect":"Advanced codebreaking","profile":"tech","base":106},
			{"id":"evidence_airgap","name":"Evidence Air-Gap Vault","effect":"Digital evidence security","profile":"security","base":102}
		]
	},
	"bio_hacking": {
		"name":"Bio-Hacking Crimes Unit", "function":"Illegal implants, gene crime, pathogens, and nanotech investigations", "accent":"#63F5B4",
		"items":[
			{"id":"gene_scanner","name":"Gene Signature Scanner","effect":"Genetic suspect matching","profile":"bio","base":88},
			{"id":"bio_database","name":"Bio-Signature Database","effect":"Biological evidence matching","profile":"tech","base":84},
			{"id":"mutation_analyzer","name":"Mutation Analyzer","effect":"Illegal enhancement detection","profile":"bio","base":94},
			{"id":"pathogen_filter","name":"Pathogen Isolation Filter","effect":"Contamination control","profile":"bio","base":92},
			{"id":"implant_detector","name":"Implant Detector","effect":"Contraband implant discovery","profile":"tech","base":90},
			{"id":"neural_trace","name":"Neural Trace Rig","effect":"Memory-hack evidence","profile":"bio","base":100},
			{"id":"tissue_archive","name":"Tissue Evidence Archive","effect":"Sample storage capacity","profile":"security","base":86},
			{"id":"biohazard_locker","name":"Biohazard Locker","effect":"Hazardous evidence security","profile":"security","base":92},
			{"id":"forensic_incubator","name":"Forensic Incubator","effect":"Sample analysis speed","profile":"bio","base":96},
			{"id":"nanotech_scanner","name":"Nanotech Scanner","effect":"Microscopic device detection","profile":"tech","base":102},
			{"id":"antidote_synth","name":"Antidote Synthesizer","effect":"Field hazard recovery","profile":"bio","base":106},
			{"id":"clean_room_seal","name":"Clean-Room Seal Grid","effect":"Unit containment rating","profile":"power","base":104}
		]
	},
	"holding": {
		"name":"Booking & Holding", "function":"Suspect intake, booking, detention, and custody security", "accent":"#72A8FF",
		"items":[
			{"id":"cell_locks","name":"Cell Door Locks","effect":"Custody security","profile":"security","base":72},
			{"id":"booking_terminal","name":"Booking Terminal","effect":"Prisoner processing speed","profile":"tech","base":68},
			{"id":"contraband_scanner","name":"Contraband Scanner","effect":"Hidden-item detection","profile":"security","base":76},
			{"id":"biometric_registry","name":"Biometric Registry","effect":"Prisoner identification","profile":"tech","base":78},
			{"id":"restraint_rack","name":"Restraint Equipment Rack","effect":"Custody control","profile":"structure","base":66},
			{"id":"observation_console","name":"Cell Observation Console","effect":"Incident prevention","profile":"tech","base":80},
			{"id":"meal_dispenser","name":"Secure Meal Dispenser","effect":"Holding capacity","profile":"power","base":64},
			{"id":"sanitation_unit","name":"Cell Sanitation Unit","effect":"Recovery and capacity","profile":"power","base":70},
			{"id":"capacity_controller","name":"Population Controller","effect":"Maximum prisoners","profile":"tech","base":82},
			{"id":"legal_call_terminal","name":"Legal Call Terminal","effect":"Processing compliance","profile":"security","base":74},
			{"id":"emergency_barrier","name":"Emergency Cell Barrier","effect":"Riot resistance","profile":"security","base":88},
			{"id":"evidence_locker","name":"Booking Evidence Locker","effect":"Property security","profile":"structure","base":76}
		]
	},
	"interrogation": {
		"name":"Interrogation Department", "function":"Suspect interviews, behavioral analysis, and intelligence recovery", "accent":"#C47BFF",
		"items":[
			{"id":"truth_scanner","name":"Truth Scanner","effect":"Interrogation intel","profile":"tech","base":86},
			{"id":"evidence_console","name":"Evidence Presentation Console","effect":"Suspect pressure","profile":"tech","base":78},
			{"id":"restraint_table","name":"Secure Interview Table","effect":"Interview control","profile":"structure","base":72},
			{"id":"behavior_monitor","name":"Behavior Monitor","effect":"Deception detection","profile":"bio","base":88},
			{"id":"audio_analyzer","name":"Voice Stress Analyzer","effect":"Statement accuracy","profile":"tech","base":84},
			{"id":"microexpression_camera","name":"Microexpression Camera","effect":"Behavioral evidence","profile":"bio","base":90},
			{"id":"statement_archive","name":"Statement Archive","effect":"Case linkage","profile":"security","base":80},
			{"id":"stress_sensor","name":"Contactless Stress Sensor","effect":"Guilt probability","profile":"bio","base":92},
			{"id":"recording_unit","name":"Legal Recording Unit","effect":"Evidence validity","profile":"security","base":82},
			{"id":"light_grid","name":"Interview Light Grid","effect":"Room control","profile":"power","base":76},
			{"id":"observation_window","name":"Secure Observation Window","effect":"Team analysis","profile":"structure","base":88},
			{"id":"confession_verifier","name":"Confession Verifier","effect":"False-confession protection","profile":"tech","base":100}
		]
	},
	"transport": {
		"name":"Secure Prisoner Transport", "function":"Transfer planning, loading, escort, and secure convoy operations", "accent":"#61E1FF",
		"items":[
			{"id":"airlock_gate","name":"Transfer Airlock","effect":"Transfer security","profile":"security","base":90},
			{"id":"prisoner_scanner","name":"Prisoner Scanner","effect":"Transfer inspection","profile":"tech","base":78},
			{"id":"transport_console","name":"Transport Console","effect":"Transfer rewards","profile":"tech","base":82},
			{"id":"route_planner","name":"Secure Route Planner","effect":"Convoy travel safety","profile":"tech","base":84},
			{"id":"shuttle_dock","name":"Prisoner Shuttle Dock","effect":"Transport capacity","profile":"structure","base":94},
			{"id":"restraint_system","name":"Vehicle Restraint System","effect":"Escape prevention","profile":"security","base":86},
			{"id":"escort_loadout","name":"Escort Loadout Rack","effect":"Escort combat power","profile":"structure","base":80},
			{"id":"cargo_manifest","name":"Custody Manifest Terminal","effect":"Transfer processing","profile":"tech","base":76},
			{"id":"transfer_seal","name":"Custody Transfer Seal","effect":"Evidence chain integrity","profile":"security","base":88},
			{"id":"tracking_beacon","name":"Convoy Tracking Beacon","effect":"Shuttle recovery","profile":"power","base":90},
			{"id":"emergency_bulkhead","name":"Emergency Bulkhead","effect":"Ambush resistance","profile":"security","base":96},
			{"id":"convoy_comms","name":"Convoy Communications","effect":"Escort coordination","profile":"power","base":92}
		]
	}
}

const FACILITIES: Dictionary = {
	"research_center":{"name":"Research Center","role":"Technology and station research","accent":"#9D8CFF","profile":"tech","modules":["Theory Core","Prototype Bench","Data Library","Materials Lab","Simulation Array","Secure Patent Vault"]},
	"guard_academy":{"name":"Guard Academy","role":"Guard troop training","accent":"#5AA8FF","profile":"security","modules":["Drill Floor","Shield Course","Custody Simulator","Armor Lockers","Tactics Classroom","Qualification Range"]},
	"biker_garage":{"name":"Biker Garage","role":"Rapid-response biker training","accent":"#FF9C4A","profile":"power","modules":["Bike Bays","Engine Bench","Pursuit Course","Rider Armor Rack","Navigation Simulator","Rapid Launch Gate"]},
	"marksman_range":{"name":"Marksman Range","role":"Long-range troop training","accent":"#FFD35A","profile":"security","modules":["Target Lane","Ballistics Computer","Spotter Deck","Weapon Calibration","Wind Simulator","Sniper Certification Booth"]},
	"robotics_bay":{"name":"Robotics Bay","role":"Police robots, drones, and autonomous support","accent":"#5EF0E0","profile":"tech","modules":["Robot Assembly Line","Drone Rack","AI Training Core","Repair Gantry","Battery Foundry","Remote Command Pod"]},
	"hospital":{"name":"Police Hospital","role":"Officer healing, trauma care, and recovery","accent":"#5DF2B0","profile":"bio","modules":["Trauma Ward","Medical Pods","Surgery Suite","Diagnostic Scanner","Recovery Wing","Pharmacy Synthesizer"]},
	"crime_lab":{"name":"Crime Laboratory","role":"Forensics, evidence science, and laboratory analysis","accent":"#D18CFF","profile":"bio","modules":["DNA Lab","Ballistics Lab","Chemical Analysis","Trace Evidence Bench","Autopsy Scanner","Evidence Cold Storage"]},
	"storage_depot":{"name":"Secure Storage Depot","role":"Resources, evidence, weapons, and emergency supplies","accent":"#B5C3CE","profile":"structure","modules":["Moonsteel Vault","Helium-3 Tanks","Salvage Lockers","Evidence Warehouse","Emergency Supply Racks","Automated Inventory Grid"]},
	"tactical_armory":{"name":"Tactical Armory","role":"Weapons, armor, ammunition, and tactical equipment","accent":"#FFAA43","profile":"security","modules":["Weapon Racks","Armor Forge","Ammo Loader","Shield Locker","Heavy Weapons Cage","Loadout Terminal"]}
}

var hq_level: int = 1
var department_levels: Dictionary = {}
var department_item_levels: Dictionary = {}
var facility_levels: Dictionary = {}
var facility_item_levels: Dictionary = {}
var jobs: Array[Dictionary] = []
var job_serial: int = 1
var last_event: String = "Police Headquarters planning grid online."
var _tick_clock: float = 0.0

func _ready() -> void:
	_initialize_state()
	load_state()

func _process(delta: float) -> void:
	_tick_clock += delta
	if _tick_clock >= 0.5:
		_tick_clock = 0.0
		tick()

func department_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id_value: Variant in DEPARTMENTS.keys():
		var department_id := String(id_value)
		var data := (DEPARTMENTS[department_id] as Dictionary).duplicate(true)
		data["id"] = department_id
		data["level"] = department_level(department_id)
		data["cap"] = department_cap(department_id)
		data["item_count"] = (data.get("items", []) as Array).size()
		result.append(data)
	return result

func department_items(department_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var data: Variant = DEPARTMENTS.get(department_id, {})
	if not data is Dictionary:
		return result
	for raw_item: Variant in (data as Dictionary).get("items", []):
		if not raw_item is Dictionary:
			continue
		var item := (raw_item as Dictionary).duplicate(true)
		var item_id := String(item.get("id", ""))
		var level := department_item_level(department_id, item_id)
		var target := level + 1
		item["level"] = level
		item["cap"] = department_level(department_id)
		item["costs"] = item_costs(String(item.get("profile", "balanced")), target, int(item.get("base", 70)))
		item["duration"] = item_duration(target)
		item["upgrading"] = _has_job("department_item", "%s:%s" % [department_id, item_id])
		result.append(item)
	return result

func facility_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id_value: Variant in FACILITIES.keys():
		var facility_id := String(id_value)
		var data := (FACILITIES[facility_id] as Dictionary).duplicate(true)
		data["id"] = facility_id
		data["level"] = facility_level(facility_id)
		data["cap"] = station_level()
		result.append(data)
	return result

func facility_items(facility_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var data: Variant = FACILITIES.get(facility_id, {})
	if not data is Dictionary:
		return result
	var index := 0
	for module_value: Variant in (data as Dictionary).get("modules", []):
		var module_name := String(module_value)
		var module_id := module_name.to_snake_case()
		var level := facility_item_level(facility_id, module_id)
		var target := level + 1
		result.append({
			"id":module_id, "name":module_name, "level":level, "cap":facility_level(facility_id),
			"effect":"%s module performance" % String((data as Dictionary).get("role", "Facility")),
			"costs":item_costs(String((data as Dictionary).get("profile", "balanced")), target, 72 + index * 4),
			"duration":item_duration(target),
			"upgrading":_has_job("facility_item", "%s:%s" % [facility_id, module_id])
		})
		index += 1
	return result

func begin_hq_upgrade() -> Dictionary:
	var target := hq_level + 1
	if target > MAX_LEVEL:
		return _result(false, "Police Headquarters is already level 100.")
	if target > station_level():
		return _result(false, "Upgrade the overall station to level %d first." % target)
	if _has_job("hq", "police_hq"):
		return _result(false, "Headquarters is already upgrading.")
	return _begin_job("hq", "police_hq", "Police Headquarters", target, level_costs("balanced", target, 420), level_duration(target, 90))

func begin_department_upgrade(department_id: String) -> Dictionary:
	if not DEPARTMENTS.has(department_id):
		return _result(false, "Department not found.")
	var level := department_level(department_id)
	var target := level + 1
	if target > department_cap(department_id):
		return _result(false, "%s is capped at level %d." % [department_name(department_id), department_cap(department_id)])
	if _has_job("department", department_id):
		return _result(false, "That department is already upgrading.")
	var profile := "balanced" if department_id in ["reception", "operations", "chief", "detectives"] else ("bio" if department_id == "bio_hacking" else "security")
	return _begin_job("department", department_id, department_name(department_id), target, level_costs(profile, target, 180), level_duration(target, 55))

func begin_department_item_upgrade(department_id: String, item_id: String) -> Dictionary:
	var item := _department_item(department_id, item_id)
	if item.is_empty():
		return _result(false, "Department item not found.")
	var level := department_item_level(department_id, item_id)
	var target := level + 1
	if target > department_level(department_id):
		return _result(false, "Upgrade %s to level %d first." % [department_name(department_id), target])
	var key := "%s:%s" % [department_id, item_id]
	if _has_job("department_item", key):
		return _result(false, "That item is already upgrading.")
	return _begin_job("department_item", key, String(item.get("name", "Department Item")), target, item_costs(String(item.get("profile", "balanced")), target, int(item.get("base", 70))), item_duration(target), {"department_id":department_id, "item_id":item_id})

func begin_facility_upgrade(facility_id: String) -> Dictionary:
	if not FACILITIES.has(facility_id):
		return _result(false, "Facility not found.")
	var level := facility_level(facility_id)
	var target := level + 1
	if target > station_level():
		return _result(false, "%s is capped at station level %d." % [facility_name(facility_id), station_level()])
	if _has_job("facility", facility_id):
		return _result(false, "That facility is already upgrading.")
	var data := FACILITIES[facility_id] as Dictionary
	return _begin_job("facility", facility_id, facility_name(facility_id), target, level_costs(String(data.get("profile", "balanced")), target, 220), level_duration(target, 65))

func begin_facility_item_upgrade(facility_id: String, item_id: String) -> Dictionary:
	var item := _facility_item(facility_id, item_id)
	if item.is_empty():
		return _result(false, "Facility module not found.")
	var level := facility_item_level(facility_id, item_id)
	var target := level + 1
	if target > facility_level(facility_id):
		return _result(false, "Upgrade %s to level %d first." % [facility_name(facility_id), target])
	var key := "%s:%s" % [facility_id, item_id]
	if _has_job("facility_item", key):
		return _result(false, "That facility module is already upgrading.")
	return _begin_job("facility_item", key, String(item.get("name", "Facility Module")), target, item.get("costs", {}) as Dictionary, int(item.get("duration", 30)), {"facility_id":facility_id, "item_id":item_id})

func tick() -> void:
	var now := _now()
	var retained: Array[Dictionary] = []
	var changed := false
	for job: Dictionary in jobs:
		if now >= int(job.get("finish_at", 0)):
			_complete_job(job)
			changed = true
		else:
			retained.append(job)
	jobs = retained
	if changed:
		save_state()
		complex_changed.emit()

func active_job_count() -> int:
	return jobs.size()

func work_slots() -> int:
	return mini(5, 2 + int((hq_level - 1) / 20))

func job_time_left(job: Dictionary) -> int:
	return maxi(0, int(job.get("finish_at", 0)) - _now())

func department_level(department_id: String) -> int:
	return int(department_levels.get(department_id, 1))

func department_item_level(department_id: String, item_id: String) -> int:
	return int(department_item_levels.get("%s:%s" % [department_id, item_id], 1))

func facility_level(facility_id: String) -> int:
	return int(facility_levels.get(facility_id, 1))

func facility_item_level(facility_id: String, item_id: String) -> int:
	return int(facility_item_levels.get("%s:%s" % [facility_id, item_id], 1))

func department_cap(department_id: String) -> int:
	if department_id == "chief":
		return hq_level
	return department_level("chief")

func station_level() -> int:
	var progression := get_node_or_null("/root/StationProgression")
	return int(progression.get("station_level")) if progression != null else 1

func department_name(department_id: String) -> String:
	var data: Variant = DEPARTMENTS.get(department_id, {})
	return String((data as Dictionary).get("name", department_id.capitalize())) if data is Dictionary else department_id.capitalize()

func facility_name(facility_id: String) -> String:
	var data: Variant = FACILITIES.get(facility_id, {})
	return String((data as Dictionary).get("name", facility_id.capitalize())) if data is Dictionary else facility_id.capitalize()

func level_costs(profile: String, target_level: int, base_credits: int) -> Dictionary:
	return _cost_formula(profile, target_level, base_credits, 2.1)

func item_costs(profile: String, target_level: int, base_credits: int) -> Dictionary:
	return _cost_formula(profile, target_level, base_credits, 1.0)

func item_duration(target_level: int) -> int:
	return 18 + target_level * 7 + target_level * target_level

func level_duration(target_level: int, base_seconds: int) -> int:
	return base_seconds + target_level * 14 + target_level * target_level * 2

func save_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"hq_level":hq_level,
		"department_levels":department_levels,
		"department_item_levels":department_item_levels,
		"facility_levels":facility_levels,
		"facility_item_levels":facility_item_levels,
		"jobs":jobs,
		"job_serial":job_serial,
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
	var data := parsed as Dictionary
	hq_level = clampi(int(data.get("hq_level", 1)), 1, MAX_LEVEL)
	department_levels = Dictionary(data.get("department_levels", {}))
	department_item_levels = Dictionary(data.get("department_item_levels", {}))
	facility_levels = Dictionary(data.get("facility_levels", {}))
	facility_item_levels = Dictionary(data.get("facility_item_levels", {}))
	jobs = _dictionary_array(data.get("jobs", []))
	job_serial = int(data.get("job_serial", 1))
	last_event = String(data.get("last_event", last_event))
	_initialize_state()
	tick()
	complex_changed.emit()
	return true

func _initialize_state() -> void:
	for id_value: Variant in DEPARTMENTS.keys():
		var department_id := String(id_value)
		if not department_levels.has(department_id):
			department_levels[department_id] = 1
		for item: Dictionary in department_items_raw(department_id):
			var key := "%s:%s" % [department_id, String(item.get("id", ""))]
			if not department_item_levels.has(key):
				department_item_levels[key] = 1
	for id_value: Variant in FACILITIES.keys():
		var facility_id := String(id_value)
		if not facility_levels.has(facility_id):
			facility_levels[facility_id] = 1
		var modules: Array = (FACILITIES[facility_id] as Dictionary).get("modules", []) as Array
		for module_value: Variant in modules:
			var key := "%s:%s" % [facility_id, String(module_value).to_snake_case()]
			if not facility_item_levels.has(key):
				facility_item_levels[key] = 1

func department_items_raw(department_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var data: Variant = DEPARTMENTS.get(department_id, {})
	if data is Dictionary:
		for raw_item: Variant in (data as Dictionary).get("items", []):
			if raw_item is Dictionary:
				result.append(raw_item as Dictionary)
	return result

func _begin_job(kind: String, target_id: String, label: String, target_level: int, costs: Dictionary, duration: int, extra: Dictionary = {}) -> Dictionary:
	if active_job_count() >= work_slots():
		return _result(false, "All Headquarters work crews are occupied.")
	if not _can_pay(costs):
		return _result(false, "%s requires %s." % [label, format_costs(costs)])
	_spend(costs)
	var job := {
		"id":"complex_%04d" % job_serial,
		"kind":kind,
		"target_id":target_id,
		"label":label,
		"target_level":target_level,
		"costs":costs,
		"finish_at":_now() + duration
	}
	for key_value: Variant in extra.keys():
		job[String(key_value)] = extra[key_value]
	job_serial += 1
	jobs.append(job)
	last_event = "%s level %d upgrade started. Time: %s." % [label, target_level, format_duration(duration)]
	save_state()
	complex_changed.emit()
	return _result(true, last_event)

func _complete_job(job: Dictionary) -> void:
	var kind := String(job.get("kind", ""))
	var target_level := int(job.get("target_level", 1))
	match kind:
		"hq": hq_level = maxi(hq_level, target_level)
		"department": department_levels[String(job.get("target_id", ""))] = target_level
		"department_item": department_item_levels["%s:%s" % [String(job.get("department_id", "")), String(job.get("item_id", ""))]] = target_level
		"facility": facility_levels[String(job.get("target_id", ""))] = target_level
		"facility_item": facility_item_levels["%s:%s" % [String(job.get("facility_id", "")), String(job.get("item_id", ""))]] = target_level
	last_event = "%s reached level %d." % [String(job.get("label", "Upgrade")), target_level]
	job_completed.emit(String(job.get("id", "")), String(job.get("label", "Upgrade")))

func _department_item(department_id: String, item_id: String) -> Dictionary:
	for item: Dictionary in department_items_raw(department_id):
		if String(item.get("id", "")) == item_id:
			return item
	return {}

func _facility_item(facility_id: String, item_id: String) -> Dictionary:
	for item: Dictionary in facility_items(facility_id):
		if String(item.get("id", "")) == item_id:
			return item
	return {}

func _cost_formula(profile: String, target_level: int, base_credits: int, scale: float) -> Dictionary:
	var weights: Dictionary = {
		"structure":Vector3(3.0, 1.0, 1.0), "power":Vector3(2.0, 3.0, 1.0),
		"tech":Vector3(1.0, 2.0, 4.0), "bio":Vector3(1.0, 3.0, 4.0),
		"security":Vector3(3.0, 1.0, 2.0), "balanced":Vector3(2.0, 2.0, 2.0)
	}
	var weight: Vector3 = weights.get(profile, weights["balanced"]) as Vector3
	var resource_base := maxf(1.0, scale * (1.0 + float(target_level) + float(target_level * target_level) / 35.0))
	return {
		"credits":int(round(float(base_credits) * scale + target_level * 42.0 * scale + target_level * target_level * 3.0 * scale)),
		"moonsteel":int(ceil(resource_base * weight.x)),
		"helium3":int(ceil(resource_base * weight.y)),
		"quantum_salvage":int(ceil(resource_base * weight.z))
	}

func _can_pay(costs: Dictionary) -> bool:
	if PrecinctState.credits < int(costs.get("credits", 0)):
		return false
	return ResourceHarvest.can_afford(_resource_costs(costs))

func _spend(costs: Dictionary) -> void:
	PrecinctState.credits -= int(costs.get("credits", 0))
	ResourceHarvest.spend(_resource_costs(costs))
	PrecinctState.state_changed.emit()

func _resource_costs(costs: Dictionary) -> Dictionary:
	return {
		"moonsteel":int(costs.get("moonsteel", 0)),
		"helium3":int(costs.get("helium3", 0)),
		"quantum_salvage":int(costs.get("quantum_salvage", 0))
	}

func _has_job(kind: String, target_id: String) -> bool:
	for job: Dictionary in jobs:
		if String(job.get("kind", "")) == kind and String(job.get("target_id", "")) == target_id:
			return true
	return false

func format_costs(costs: Dictionary) -> String:
	return "%d credits, %d Moonsteel, %d Helium-3, %d Quantum Salvage" % [
		int(costs.get("credits", 0)), int(costs.get("moonsteel", 0)),
		int(costs.get("helium3", 0)), int(costs.get("quantum_salvage", 0))
	]

func format_duration(seconds: int) -> String:
	if seconds >= 3600:
		return "%dh %02dm" % [int(seconds / 3600), int((seconds % 3600) / 60)]
	if seconds >= 60:
		return "%dm %02ds" % [int(seconds / 60), seconds % 60]
	return "%ds" % seconds

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
