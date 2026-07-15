extends Node
## Repeatable station side operations: engine repair, weapon fitting,
## medical triage, and evidence-driven interrogation.

signal operation_changed

const SAVE_PATH: String = "user://moongoons_side_operations.json"

var active_operation: Dictionary = {}
var engine_repairs: int = 0
var weapon_upgrades: int = 0
var medical_cases: int = 0
var interrogations: int = 0
var confessions: int = 0
var unreliable_statements: int = 0
var defense_bonus: int = 0
var operation_serial: int = 1
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	load_state()

func reset_state() -> void:
	active_operation = {}
	engine_repairs = 0
	weapon_upgrades = 0
	medical_cases = 0
	interrogations = 0
	confessions = 0
	unreliable_statements = 0
	defense_bonus = 0
	operation_serial = 1
	save_state()
	operation_changed.emit()

func start_operation(operation_id: String) -> Dictionary:
	if not active_operation.is_empty() and not bool(active_operation.get("finished", false)):
		return _result(false, "Finish or abandon the current side operation first.")
	match operation_id:
		"engine": active_operation = _new_engine_operation()
		"weapons": active_operation = _new_weapon_operation()
		"medical": active_operation = _new_medical_operation()
		"interrogation": active_operation = _new_interrogation_operation()
		_: return _result(false, "Unknown side operation.")
	operation_serial += 1
	save_state()
	operation_changed.emit()
	return _result(true, String(active_operation.get("briefing", "Operation started.")))

func abandon_operation() -> Dictionary:
	if active_operation.is_empty():
		return _result(false, "No side operation is active.")
	active_operation = {}
	save_state()
	operation_changed.emit()
	return _result(true, "Side operation abandoned.")

func engine_action(action: String) -> Dictionary:
	if String(active_operation.get("type", "")) != "engine" or bool(active_operation.get("finished", false)):
		return _result(false, "No active engine-repair operation.")
	var stage: int = int(active_operation.get("stage", 0))
	var integrity: int = int(active_operation.get("integrity", 100))
	var message: String = ""
	match action:
		"isolate_power":
			if stage == 0:
				active_operation["power_isolated"] = true
				active_operation["stage"] = 1
				message = "Power isolated. Replace the highlighted damaged part."
			else:
				integrity -= 4
				message = "Power routing was disturbed at the wrong stage."
		"replace_coupler", "replace_pump", "replace_fuse":
			var requested_part: String = action.trim_prefix("replace_")
			if stage == 1 and requested_part == String(active_operation.get("fault_part", "")):
				active_operation["part_replaced"] = true
				active_operation["stage"] = 2
				message = "Correct component installed. Balance coolant between 45 and 55 percent."
			else:
				integrity -= 9
				message = "Wrong replacement part. Engine integrity dropped."
		"coolant_down":
			active_operation["coolant"] = maxi(0, int(active_operation.get("coolant", 50)) - 7)
			message = "Coolant flow reduced."
		"coolant_up":
			active_operation["coolant"] = mini(100, int(active_operation.get("coolant", 50)) + 7)
			message = "Coolant flow increased."
		"lock_coolant":
			var coolant: int = int(active_operation.get("coolant", 0))
			if stage == 2 and coolant >= 45 and coolant <= 55:
				active_operation["stage"] = 3
				message = "Coolant stabilized. Restart the engine."
			else:
				integrity -= 8
				message = "Coolant is outside the safe band."
		"restart":
			if stage == 3:
				return _complete_engine()
			integrity -= 12
			message = "Premature restart caused a violent power surge."
		_:
			return _result(false, "Unknown engine action.")
	active_operation["integrity"] = maxi(0, integrity)
	if int(active_operation.get("integrity", 0)) <= 0:
		return _fail_operation("Engine repair failed. The damaged drive section has been isolated.")
	active_operation["message"] = message
	save_state()
	operation_changed.emit()
	return _result(true, message)

func weapon_action(action: String) -> Dictionary:
	if String(active_operation.get("type", "")) != "weapons" or bool(active_operation.get("finished", false)):
		return _result(false, "No active weapons-fitting operation.")
	var sequence: Array = active_operation.get("sequence", []) as Array
	var installed: Array = active_operation.get("installed", []) as Array
	var message: String = ""
	if action in ["capacitor", "cooling_jacket", "targeting_chip", "ammo_feed"]:
		var expected: String = String(sequence[installed.size()]) if installed.size() < sequence.size() else ""
		if action == expected:
			installed.append(action)
			active_operation["installed"] = installed
			message = "%s installed correctly." % _part_name(action)
		else:
			active_operation["stability"] = maxi(0, int(active_operation.get("stability", 100)) - 12)
			message = "%s was fitted out of sequence. Weapon stability dropped." % _part_name(action)
	elif action == "align_left":
		active_operation["alignment"] = maxi(0, int(active_operation.get("alignment", 50)) - 6)
		message = "Emitter alignment moved left."
	elif action == "align_right":
		active_operation["alignment"] = mini(100, int(active_operation.get("alignment", 50)) + 6)
		message = "Emitter alignment moved right."
	elif action == "calibrate":
		if installed.size() < sequence.size():
			active_operation["stability"] = maxi(0, int(active_operation.get("stability", 100)) - 10)
			message = "Calibration failed. Not all parts are installed."
		else:
			var alignment: int = int(active_operation.get("alignment", 0))
			var target: int = int(active_operation.get("target_alignment", 50))
			if absi(alignment - target) <= 5:
				return _complete_weapons()
			active_operation["stability"] = maxi(0, int(active_operation.get("stability", 100)) - 10)
			message = "Calibration missed the target band."
	else:
		return _result(false, "Unknown weapons action.")
	if int(active_operation.get("stability", 0)) <= 0:
		return _fail_operation("Weapons fitting failed. The assembly has been locked for inspection.")
	active_operation["message"] = message
	save_state()
	operation_changed.emit()
	return _result(true, message)

func medical_action(action: String) -> Dictionary:
	if String(active_operation.get("type", "")) != "medical" or bool(active_operation.get("finished", false)):
		return _result(false, "No active medical operation.")
	if operation_time_left() <= 0:
		return _fail_operation("Medical operation timed out. The patient was transferred to intensive care.")
	var sequence: Array = active_operation.get("sequence", []) as Array
	var completed: Array = active_operation.get("completed", []) as Array
	var expected: String = String(sequence[completed.size()]) if completed.size() < sequence.size() else ""
	var vitals: int = int(active_operation.get("vitals", 70))
	var message: String = ""
	if action == expected:
		completed.append(action)
		active_operation["completed"] = completed
		vitals = mini(100, vitals + 11)
		message = "%s applied. Patient vitals improved." % _treatment_name(action)
	else:
		vitals -= 14
		message = "%s was not appropriate for the current condition." % _treatment_name(action)
	active_operation["vitals"] = maxi(0, vitals)
	if vitals <= 0:
		return _fail_operation("Medical operation failed. The patient entered critical status.")
	if completed.size() >= sequence.size():
		return _complete_medical()
	active_operation["message"] = message
	save_state()
	operation_changed.emit()
	return _result(true, message)

func interrogation_action(action: String) -> Dictionary:
	if String(active_operation.get("type", "")) != "interrogation" or bool(active_operation.get("finished", false)):
		return _result(false, "No active interrogation.")
	if operation_time_left() <= 0:
		return _fail_operation("Interview window expired. The suspect requested legal review.")
	var guilt: int = int(active_operation.get("guilt", 12))
	var stress: int = int(active_operation.get("stress", 18))
	var cooperation: int = int(active_operation.get("cooperation", 35))
	var credibility: int = int(active_operation.get("credibility", 50))
	var message: String = ""
	match action:
		"ask":
			cooperation += 8
			stress += 2
			credibility += 3
			guilt += 4 if int(active_operation.get("actual_guilt", 50)) >= 50 else 1
			message = "The suspect answered a controlled question."
		"present_evidence":
			if PrecinctState.evidence <= 0:
				return _result(false, "No evidence is available to present.")
			guilt += 16
			stress += 10
			credibility += 8
			message = "Evidence presented. The suspect's story is under pressure."
		"reassure":
			stress -= 15
			cooperation += 12
			message = "The suspect relaxed and became more cooperative."
		"confront":
			stress += 19
			cooperation -= 7
			guilt += 8
			credibility -= 3
			message = "Direct confrontation increased pressure."
		"verify_statement":
			credibility += 12 if stress < 70 else -8
			guilt += 5
			message = "The statement was checked against the case file."
		"seek_confession":
			active_operation["guilt"] = clampi(guilt, 0, 100)
			active_operation["stress"] = clampi(stress, 0, 100)
			active_operation["cooperation"] = clampi(cooperation, 0, 100)
			active_operation["credibility"] = clampi(credibility, 0, 100)
			return _resolve_interrogation()
		_:
			return _result(false, "Unknown interrogation action.")
	active_operation["guilt"] = clampi(guilt, 0, 100)
	active_operation["stress"] = clampi(stress, 0, 100)
	active_operation["cooperation"] = clampi(cooperation, 0, 100)
	active_operation["credibility"] = clampi(credibility, 0, 100)
	if int(active_operation.get("stress", 0)) >= 95:
		return _fail_operation("The suspect shut down under excessive pressure. No reliable statement was obtained.")
	active_operation["message"] = message
	save_state()
	operation_changed.emit()
	return _result(true, message)

func operation_time_left() -> int:
	if active_operation.is_empty():
		return 0
	var deadline: int = int(active_operation.get("deadline", 0))
	return maxi(0, deadline - int(Time.get_unix_time_from_system()))

func operation_status() -> String:
	if active_operation.is_empty():
		return "NO ACTIVE SIDE OPERATION"
	return String(active_operation.get("message", active_operation.get("briefing", "Operation active.")))

func save_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"active_operation": active_operation,
		"engine_repairs": engine_repairs,
		"weapon_upgrades": weapon_upgrades,
		"medical_cases": medical_cases,
		"interrogations": interrogations,
		"confessions": confessions,
		"unreliable_statements": unreliable_statements,
		"defense_bonus": defense_bonus,
		"operation_serial": operation_serial
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
	active_operation = Dictionary(data.get("active_operation", {}))
	engine_repairs = int(data.get("engine_repairs", 0))
	weapon_upgrades = int(data.get("weapon_upgrades", 0))
	medical_cases = int(data.get("medical_cases", 0))
	interrogations = int(data.get("interrogations", 0))
	confessions = int(data.get("confessions", 0))
	unreliable_statements = int(data.get("unreliable_statements", 0))
	defense_bonus = int(data.get("defense_bonus", 0))
	operation_serial = int(data.get("operation_serial", 1))
	operation_changed.emit()
	return true

func _new_engine_operation() -> Dictionary:
	var parts: Array[String] = ["coupler", "pump", "fuse"]
	var fault: String = parts[_rng.randi_range(0, parts.size() - 1)]
	return {
		"id": "engine_%04d" % operation_serial, "type": "engine", "finished": false,
		"briefing": "ENGINE FAULT // Isolate power, replace the damaged %s, balance coolant, and restart." % fault,
		"message": "Engine fault diagnosed. Isolate power first.", "stage": 0,
		"fault_part": fault, "power_isolated": false, "part_replaced": false,
		"coolant": _rng.randi_range(20, 82), "integrity": 100
	}

func _new_weapon_operation() -> Dictionary:
	var sequences: Array[Array] = [
		["capacitor", "cooling_jacket", "targeting_chip", "ammo_feed"],
		["cooling_jacket", "capacitor", "ammo_feed", "targeting_chip"],
		["ammo_feed", "capacitor", "cooling_jacket", "targeting_chip"]
	]
	return {
		"id": "weapon_%04d" % operation_serial, "type": "weapons", "finished": false,
		"briefing": "WEAPONS FITTING // Install the components in diagnostic order, then align and calibrate the emitter.",
		"message": "Diagnostic order loaded. Install the first component.",
		"sequence": sequences[_rng.randi_range(0, sequences.size() - 1)], "installed": [],
		"alignment": _rng.randi_range(20, 80), "target_alignment": _rng.randi_range(42, 58), "stability": 100
	}

func _new_medical_operation() -> Dictionary:
	var cases: Array[Dictionary] = [
		{"patient":"Officer with decompression trauma", "diagnosis":"Pressure injury", "sequence":["oxygen", "seal_wound", "pressure_stabilizer"]},
		{"patient":"Dock worker with radiation exposure", "diagnosis":"Radiation poisoning", "sequence":["decon", "anti_rad", "fluids"]},
		{"patient":"Patrol officer with arterial trauma", "diagnosis":"Severe blood loss", "sequence":["tourniquet", "medgel", "transfusion"]}
	]
	var case_data: Dictionary = cases[_rng.randi_range(0, cases.size() - 1)]
	return {
		"id":"medical_%04d" % operation_serial, "type":"medical", "finished":false,
		"briefing":"MEDICAL OPS // %s. Diagnosis: %s." % [String(case_data.get("patient", "Patient")), String(case_data.get("diagnosis", "Unknown"))],
		"message":"Apply treatments in the correct order before the timer expires.",
		"sequence":case_data.get("sequence", []), "completed":[], "vitals":68,
		"deadline":int(Time.get_unix_time_from_system()) + 90
	}

func _new_interrogation_operation() -> Dictionary:
	var actual_guilt: int = _rng.randi_range(30, 96)
	return {
		"id":"interrogation_%04d" % operation_serial, "type":"interrogation", "finished":false,
		"briefing":"INTERROGATION // Determine the suspect's role without producing an unreliable statement.",
		"message":"Begin with controlled questions and evidence review.",
		"actual_guilt":actual_guilt, "guilt":12, "stress":18, "cooperation":35, "credibility":50,
		"deadline":int(Time.get_unix_time_from_system()) + 120
	}

func _complete_engine() -> Dictionary:
	engine_repairs += 1
	PrecinctState.credits += 120
	PrecinctState.intel += 2
	active_operation["finished"] = true
	active_operation["success"] = true
	active_operation["message"] = "Engine section restored. +120 credits and +2 intel."
	save_state()
	operation_changed.emit()
	return _result(true, String(active_operation.get("message", "Engine restored.")))

func _complete_weapons() -> Dictionary:
	weapon_upgrades += 1
	defense_bonus += 8
	PrecinctState.credits += 100
	active_operation["finished"] = true
	active_operation["success"] = true
	active_operation["message"] = "Weapon calibrated. Station defense increased by 8."
	save_state()
	operation_changed.emit()
	return _result(true, String(active_operation.get("message", "Weapon calibrated.")))

func _complete_medical() -> Dictionary:
	medical_cases += 1
	PrecinctState.credits += 90
	PrecinctState.intel += 3
	active_operation["finished"] = true
	active_operation["success"] = true
	active_operation["message"] = "Patient stabilized. +90 credits and +3 intel."
	save_state()
	operation_changed.emit()
	return _result(true, String(active_operation.get("message", "Patient stabilized.")))

func _resolve_interrogation() -> Dictionary:
	interrogations += 1
	var actual_guilt: int = int(active_operation.get("actual_guilt", 0))
	var guilt: int = int(active_operation.get("guilt", 0))
	var cooperation: int = int(active_operation.get("cooperation", 0))
	var credibility: int = int(active_operation.get("credibility", 0))
	var stress: int = int(active_operation.get("stress", 0))
	var reliable: bool = guilt >= 65 and cooperation >= 45 and credibility >= 45 and stress < 85
	if reliable and actual_guilt >= 55:
		confessions += 1
		PrecinctState.intel += 12
		PrecinctState.evidence += 1
		active_operation["success"] = true
		active_operation["message"] = "Reliable confession obtained. +12 intel and +1 evidence."
	elif stress >= 75 or credibility < 35:
		unreliable_statements += 1
		active_operation["success"] = false
		active_operation["message"] = "Statement rejected as unreliable. Pressure or credibility was outside safe limits."
	else:
		active_operation["success"] = false
		active_operation["message"] = "No confession. The evidence threshold or cooperation level was insufficient."
	active_operation["finished"] = true
	save_state()
	operation_changed.emit()
	return _result(bool(active_operation.get("success", false)), String(active_operation.get("message", "Interview complete.")))

func _fail_operation(message: String) -> Dictionary:
	active_operation["finished"] = true
	active_operation["success"] = false
	active_operation["message"] = message
	save_state()
	operation_changed.emit()
	return _result(false, message)

func _part_name(part_id: String) -> String:
	return part_id.replace("_", " ").capitalize()

func _treatment_name(action: String) -> String:
	return action.replace("_", " ").capitalize()

func _result(ok: bool, message: String) -> Dictionary:
	return {"ok": ok, "message": message}
