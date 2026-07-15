extends Node
## Alliance-wide research for Construction, Technology, and Weapons.
## Every node starts at Level 1 and advances to Level 100 with exact timed costs.

signal research_changed
signal research_started(node_id: String, target_level: int)
signal research_completed(node_id: String, new_level: int)

const SAVE_PATH: String = "user://moongoons_alliance_research.json"
const MAX_LEVEL: int = 100
const BRANCHES: Array[String] = ["construction", "technology", "weapons"]

const NODES: Dictionary = {
	"modular_foundry": {
		"name":"Modular Foundry", "branch":"construction", "parent":"", "gap":0,
		"benefit":"Reduces every station, room, equipment, and defense construction timer.",
		"base_time":45, "time_scale":28.0,
		"base_credit":180, "credit_scale":42.0,
		"base_costs":{"moonsteel":8, "helium3":3, "quantum_salvage":2},
		"cost_scales":{"moonsteel":1.10, "helium3":0.36, "quantum_salvage":0.22}
	},
	"rapid_assembly": {
		"name":"Rapid Assembly Lines", "branch":"construction", "parent":"modular_foundry", "gap":3,
		"benefit":"Adds a second construction-time reduction for rooms and equipment.",
		"base_time":60, "time_scale":31.0,
		"base_credit":220, "credit_scale":47.0,
		"base_costs":{"moonsteel":12, "helium3":4, "quantum_salvage":3},
		"cost_scales":{"moonsteel":1.25, "helium3":0.44, "quantum_salvage":0.28}
	},
	"orbital_logistics": {
		"name":"Orbital Logistics", "branch":"construction", "parent":"rapid_assembly", "gap":5,
		"benefit":"Improves harvesting yield and resource delivery across alliance lanes.",
		"base_time":75, "time_scale":35.0,
		"base_credit":260, "credit_scale":52.0,
		"base_costs":{"moonsteel":14, "helium3":7, "quantum_salvage":4},
		"cost_scales":{"moonsteel":1.34, "helium3":0.58, "quantum_salvage":0.33}
	},
	"reinforced_superstructure": {
		"name":"Reinforced Superstructure", "branch":"construction", "parent":"modular_foundry", "gap":5,
		"benefit":"Adds alliance defense rating and hardens the station perimeter.",
		"base_time":78, "time_scale":38.0,
		"base_credit":280, "credit_scale":55.0,
		"base_costs":{"moonsteel":18, "helium3":5, "quantum_salvage":4},
		"cost_scales":{"moonsteel":1.52, "helium3":0.46, "quantum_salvage":0.32}
	},
	"autonomous_builders": {
		"name":"Autonomous Builder Swarms", "branch":"construction", "parent":"reinforced_superstructure", "gap":3,
		"benefit":"Provides the final construction-speed layer and emergency repair support.",
		"base_time":95, "time_scale":42.0,
		"base_credit":340, "credit_scale":61.0,
		"base_costs":{"moonsteel":20, "helium3":8, "quantum_salvage":7},
		"cost_scales":{"moonsteel":1.68, "helium3":0.62, "quantum_salvage":0.51}
	},

	"quantum_computing": {
		"name":"Quantum Computing", "branch":"technology", "parent":"", "gap":0,
		"benefit":"Reduces future alliance research timers.",
		"base_time":55, "time_scale":32.0,
		"base_credit":210, "credit_scale":46.0,
		"base_costs":{"moonsteel":4, "helium3":8, "quantum_salvage":7},
		"cost_scales":{"moonsteel":0.38, "helium3":0.92, "quantum_salvage":0.78}
	},
	"fusion_grid": {
		"name":"Fusion Grid", "branch":"technology", "parent":"quantum_computing", "gap":3,
		"benefit":"Adds shield capacity to interceptors and the orbital station.",
		"base_time":68, "time_scale":36.0,
		"base_credit":250, "credit_scale":52.0,
		"base_costs":{"moonsteel":6, "helium3":12, "quantum_salvage":8},
		"cost_scales":{"moonsteel":0.52, "helium3":1.18, "quantum_salvage":0.84}
	},
	"deep_scan_network": {
		"name":"Deep Scan Network", "branch":"technology", "parent":"quantum_computing", "gap":5,
		"benefit":"Strengthens tactical scans and exposes Syndicate weak points.",
		"base_time":74, "time_scale":39.0,
		"base_credit":270, "credit_scale":56.0,
		"base_costs":{"moonsteel":5, "helium3":10, "quantum_salvage":11},
		"cost_scales":{"moonsteel":0.46, "helium3":0.98, "quantum_salvage":1.12}
	},
	"medical_nanites": {
		"name":"Medical Nanites", "branch":"technology", "parent":"fusion_grid", "gap":5,
		"benefit":"Reduces officer recovery and medical operation time.",
		"base_time":88, "time_scale":43.0,
		"base_credit":315, "credit_scale":61.0,
		"base_costs":{"moonsteel":7, "helium3":13, "quantum_salvage":13},
		"cost_scales":{"moonsteel":0.58, "helium3":1.22, "quantum_salvage":1.18}
	},
	"relay_encryption": {
		"name":"Relay Encryption", "branch":"technology", "parent":"deep_scan_network", "gap":3,
		"benefit":"Reduces hostile cyber pressure and adds a final research-speed bonus.",
		"base_time":102, "time_scale":47.0,
		"base_credit":360, "credit_scale":67.0,
		"base_costs":{"moonsteel":8, "helium3":15, "quantum_salvage":16},
		"cost_scales":{"moonsteel":0.66, "helium3":1.34, "quantum_salvage":1.42}
	},

	"pulse_harmonization": {
		"name":"Pulse Harmonization", "branch":"weapons", "parent":"", "gap":0,
		"benefit":"Raises pulse-cannon and interceptor attack power.",
		"base_time":65, "time_scale":36.0,
		"base_credit":240, "credit_scale":52.0,
		"base_costs":{"moonsteel":8, "helium3":7, "quantum_salvage":9},
		"cost_scales":{"moonsteel":0.82, "helium3":0.72, "quantum_salvage":1.02}
	},
	"rail_capacitors": {
		"name":"Rail Capacitors", "branch":"weapons", "parent":"pulse_harmonization", "gap":3,
		"benefit":"Adds direct damage to rail strikes against Syndicate fleets.",
		"base_time":78, "time_scale":41.0,
		"base_credit":285, "credit_scale":59.0,
		"base_costs":{"moonsteel":11, "helium3":9, "quantum_salvage":12},
		"cost_scales":{"moonsteel":1.02, "helium3":0.86, "quantum_salvage":1.24}
	},
	"targeting_ai": {
		"name":"Targeting AI", "branch":"weapons", "parent":"pulse_harmonization", "gap":5,
		"benefit":"Improves tactical scan damage and weapon accuracy.",
		"base_time":84, "time_scale":44.0,
		"base_credit":310, "credit_scale":63.0,
		"base_costs":{"moonsteel":9, "helium3":11, "quantum_salvage":14},
		"cost_scales":{"moonsteel":0.88, "helium3":1.02, "quantum_salvage":1.38}
	},
	"interceptor_doctrine": {
		"name":"Interceptor Doctrine", "branch":"weapons", "parent":"targeting_ai", "gap":3,
		"benefit":"Adds interceptor shields and improves evade recovery.",
		"base_time":96, "time_scale":49.0,
		"base_credit":350, "credit_scale":69.0,
		"base_costs":{"moonsteel":12, "helium3":14, "quantum_salvage":15},
		"cost_scales":{"moonsteel":1.08, "helium3":1.28, "quantum_salvage":1.44}
	},
	"siege_network": {
		"name":"Alliance Siege Network", "branch":"weapons", "parent":"rail_capacitors", "gap":5,
		"benefit":"Adds station defense rating and late-game fleet firepower.",
		"base_time":115, "time_scale":55.0,
		"base_credit":420, "credit_scale":77.0,
		"base_costs":{"moonsteel":18, "helium3":16, "quantum_salvage":20},
		"cost_scales":{"moonsteel":1.46, "helium3":1.38, "quantum_salvage":1.72}
	}
}

var levels: Dictionary = {}
var active_jobs: Dictionary = {}
var completed_research: int = 0
var last_event: String = "Alliance research network online. Three branches are ready."

func _ready() -> void:
	_initialize_levels()
	load_state()

func reset_state() -> void:
	levels.clear()
	active_jobs.clear()
	completed_research = 0
	last_event = "Alliance research reset to Level 1."
	_initialize_levels()
	save_state()
	research_changed.emit()

func _initialize_levels() -> void:
	for node_value: Variant in NODES.keys():
		var node_id: String = String(node_value)
		if not levels.has(node_id):
			levels[node_id] = 1

func node_catalog(branch: String = "") -> Array[Dictionary]:
	tick()
	var result: Array[Dictionary] = []
	for node_value: Variant in NODES.keys():
		var node_id: String = String(node_value)
		var definition: Dictionary = NODES[node_id] as Dictionary
		if not branch.is_empty() and String(definition.get("branch", "")) != branch:
			continue
		var entry: Dictionary = definition.duplicate(true)
		entry["id"] = node_id
		entry["level"] = level(node_id)
		entry["max_level"] = MAX_LEVEL
		entry["active"] = has_active_job(node_id)
		entry["next_quote"] = level_quote(node_id, mini(MAX_LEVEL, level(node_id) + 1))
		result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _node_order(String(a.get("id", ""))) < _node_order(String(b.get("id", "")))
	)
	return result

func level(node_id: String) -> int:
	return clampi(int(levels.get(node_id, 1)), 1, MAX_LEVEL)

func level_quote(node_id: String, target_level: int) -> Dictionary:
	if not NODES.has(node_id):
		return {}
	var definition: Dictionary = NODES[node_id] as Dictionary
	var target: int = clampi(target_level, 1, MAX_LEVEL)
	if target <= 1:
		return {
			"node_id":node_id, "target_level":1, "seconds":0, "credits":0,
			"costs":{"moonsteel":0, "helium3":0, "quantum_salvage":0},
			"parent_required":0, "parent":"", "gap":int(definition.get("gap", 0))
		}
	var time_seconds: int = int(round(float(definition.get("base_time", 45)) + pow(float(target), 2.0) * float(definition.get("time_scale", 30.0))))
	time_seconds = int(round(float(time_seconds) * technology_time_multiplier()))
	var credit_cost: int = int(ceil(float(definition.get("base_credit", 200)) + pow(float(target), 1.8) * float(definition.get("credit_scale", 45.0))))
	var base_costs: Dictionary = definition.get("base_costs", {}) as Dictionary
	var scales: Dictionary = definition.get("cost_scales", {}) as Dictionary
	var costs: Dictionary = {}
	for resource_id: String in ["moonsteel", "helium3", "quantum_salvage"]:
		var base_value: int = int(base_costs.get(resource_id, 0))
		var scale_value: float = float(scales.get(resource_id, 0.5))
		costs[resource_id] = base_value + int(ceil(pow(float(target), 1.6) * scale_value))
	var parent_id: String = String(definition.get("parent", ""))
	var gap: int = int(definition.get("gap", 0))
	var parent_required: int = 0 if parent_id.is_empty() else maxi(1, target - gap)
	return {
		"node_id":node_id,
		"target_level":target,
		"seconds":time_seconds,
		"credits":credit_cost,
		"costs":costs,
		"parent":parent_id,
		"parent_required":parent_required,
		"gap":gap
	}

func level_schedule(node_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for target_level: int in range(1, MAX_LEVEL + 1):
		result.append(level_quote(node_id, target_level))
	return result

func begin_research(node_id: String) -> Dictionary:
	tick()
	if not NODES.has(node_id):
		return _result(false, "Alliance research node not found.")
	var current_level: int = level(node_id)
	if current_level >= MAX_LEVEL:
		return _result(false, "%s has reached Level 100." % node_name(node_id))
	var branch: String = node_branch(node_id)
	if active_jobs.has(branch):
		return _result(false, "%s research already has an active project." % branch.capitalize())
	var quote: Dictionary = level_quote(node_id, current_level + 1)
	var requirement: Dictionary = prerequisite_status(node_id, current_level + 1)
	if not bool(requirement.get("ok", false)):
		return _result(false, String(requirement.get("message", "Prerequisite not met.")))
	var credit_cost: int = int(quote.get("credits", 0))
	var resource_costs: Dictionary = quote.get("costs", {}) as Dictionary
	if PrecinctState.credits < credit_cost or not ResourceHarvest.can_afford(resource_costs):
		return _result(false, _cost_failure_text(quote))
	PrecinctState.credits -= credit_cost
	PrecinctState.state_changed.emit()
	if not ResourceHarvest.spend(resource_costs):
		PrecinctState.credits += credit_cost
		PrecinctState.state_changed.emit()
		return _result(false, "Alliance resources changed before research could begin.")
	var now: int = _now()
	active_jobs[branch] = {
		"node_id":node_id,
		"branch":branch,
		"target_level":current_level + 1,
		"started_at":now,
		"finish_at":now + int(quote.get("seconds", 1)),
		"duration":int(quote.get("seconds", 1)),
		"credits":credit_cost,
		"costs":resource_costs
	}
	last_event = "%s Level %d research started for the alliance." % [node_name(node_id), current_level + 1]
	save_state()
	research_started.emit(node_id, current_level + 1)
	research_changed.emit()
	return _result(true, last_event)

func tick() -> void:
	var now: int = _now()
	var completed_branches: Array[String] = []
	for branch_value: Variant in active_jobs.keys():
		var branch: String = String(branch_value)
		var job: Dictionary = active_jobs[branch] as Dictionary
		if now >= int(job.get("finish_at", now + 1)):
			_complete_job(job)
			completed_branches.append(branch)
	for branch: String in completed_branches:
		active_jobs.erase(branch)
	if not completed_branches.is_empty():
		save_state()
		research_changed.emit()

func complete_job_now(branch: String) -> Dictionary:
	if not active_jobs.has(branch):
		return _result(false, "No active %s research job." % branch)
	var job: Dictionary = active_jobs[branch] as Dictionary
	_complete_job(job)
	active_jobs.erase(branch)
	save_state()
	research_changed.emit()
	return _result(true, last_event)

func _complete_job(job: Dictionary) -> void:
	var node_id: String = String(job.get("node_id", ""))
	var target_level: int = clampi(int(job.get("target_level", level(node_id) + 1)), 1, MAX_LEVEL)
	levels[node_id] = target_level
	completed_research += 1
	last_event = "%s reached Alliance Level %d." % [node_name(node_id), target_level]
	research_completed.emit(node_id, target_level)

func prerequisite_status(node_id: String, target_level: int) -> Dictionary:
	if not NODES.has(node_id):
		return _result(false, "Research node not found.")
	var definition: Dictionary = NODES[node_id] as Dictionary
	var parent_id: String = String(definition.get("parent", ""))
	if parent_id.is_empty():
		return _result(true, "Root research has no prerequisite.")
	var gap: int = int(definition.get("gap", 0))
	var required_level: int = maxi(1, clampi(target_level, 1, MAX_LEVEL) - gap)
	var parent_level: int = level(parent_id)
	if parent_level < required_level:
		return _result(false, "%s must reach Level %d first. This branch uses a %d-level prerequisite gap." % [node_name(parent_id), required_level, gap])
	return _result(true, "%s Level %d satisfies the %d-level gap." % [node_name(parent_id), parent_level, gap])

func has_active_job(node_id: String) -> bool:
	for job_value: Variant in active_jobs.values():
		var job: Dictionary = job_value as Dictionary
		if String(job.get("node_id", "")) == node_id:
			return true
	return false

func active_job(branch: String) -> Dictionary:
	return (active_jobs[branch] as Dictionary).duplicate(true) if active_jobs.has(branch) else {}

func seconds_left(branch: String) -> int:
	if not active_jobs.has(branch):
		return 0
	return maxi(0, int((active_jobs[branch] as Dictionary).get("finish_at", 0)) - _now())

func node_name(node_id: String) -> String:
	return String((NODES.get(node_id, {}) as Dictionary).get("name", node_id.capitalize()))

func node_branch(node_id: String) -> String:
	return String((NODES.get(node_id, {}) as Dictionary).get("branch", "construction"))

func construction_time_multiplier() -> float:
	var reduction: float = float(level("modular_foundry") - 1) * 0.0025
	reduction += float(level("rapid_assembly") - 1) * 0.0015
	reduction += float(level("autonomous_builders") - 1) * 0.0010
	return clampf(1.0 - reduction, 0.50, 1.0)

func technology_time_multiplier() -> float:
	var reduction: float = float(level("quantum_computing") - 1) * 0.0022
	reduction += float(level("relay_encryption") - 1) * 0.0014
	return clampf(1.0 - reduction, 0.58, 1.0)

func adjust_construction_time(seconds: int) -> int:
	return maxi(1, int(round(float(seconds) * construction_time_multiplier())))

func harvest_yield_multiplier() -> float:
	return 1.0 + float(level("orbital_logistics") - 1) * 0.004

func defense_rating_bonus() -> int:
	return int(round(float(level("reinforced_superstructure") - 1) * 0.8 + float(level("siege_network") - 1) * 1.2))

func shield_bonus() -> int:
	return int(round(float(level("fusion_grid") - 1) * 1.5))

func weapon_attack_bonus() -> int:
	return int(round(float(level("pulse_harmonization") - 1) * 0.8 + float(level("siege_network") - 1) * 0.7))

func rail_damage_bonus() -> int:
	return int(round(float(level("rail_capacitors") - 1) * 1.1))

func scan_damage_bonus() -> int:
	return int(round(float(level("deep_scan_network") - 1) * 0.6 + float(level("targeting_ai") - 1) * 0.9))

func interceptor_shield_bonus() -> int:
	return int(round(float(level("interceptor_doctrine") - 1) * 1.2))

func healing_time_multiplier() -> float:
	return clampf(1.0 - float(level("medical_nanites") - 1) * 0.0035, 0.65, 1.0)

func quote_text(quote: Dictionary) -> String:
	if quote.is_empty():
		return "No quote available."
	var costs: Dictionary = quote.get("costs", {}) as Dictionary
	return "Level %d • %s • %d credits • %d Moonsteel • %d Helium-3 • %d Quantum Salvage" % [
		int(quote.get("target_level", 1)),
		format_duration(int(quote.get("seconds", 0))),
		int(quote.get("credits", 0)),
		int(costs.get("moonsteel", 0)),
		int(costs.get("helium3", 0)),
		int(costs.get("quantum_salvage", 0))
	]

func format_duration(total_seconds: int) -> String:
	var seconds: int = maxi(0, total_seconds)
	var days: int = int(seconds / 86400)
	seconds %= 86400
	var hours: int = int(seconds / 3600)
	seconds %= 3600
	var minutes: int = int(seconds / 60)
	seconds %= 60
	if days > 0:
		return "%dd %02dh %02dm" % [days, hours, minutes]
	if hours > 0:
		return "%dh %02dm %02ds" % [hours, minutes, seconds]
	return "%dm %02ds" % [minutes, seconds]

func save_state() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"levels":levels,
		"active_jobs":active_jobs,
		"completed_research":completed_research,
		"last_event":last_event
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
	levels = Dictionary(data.get("levels", levels))
	active_jobs = Dictionary(data.get("active_jobs", {}))
	completed_research = int(data.get("completed_research", 0))
	last_event = String(data.get("last_event", last_event))
	_initialize_levels()
	tick()
	return true

func _node_order(node_id: String) -> int:
	var ordered: Array[String] = [
		"modular_foundry", "rapid_assembly", "orbital_logistics", "reinforced_superstructure", "autonomous_builders",
		"quantum_computing", "fusion_grid", "deep_scan_network", "medical_nanites", "relay_encryption",
		"pulse_harmonization", "rail_capacitors", "targeting_ai", "interceptor_doctrine", "siege_network"
	]
	return ordered.find(node_id)

func _cost_failure_text(quote: Dictionary) -> String:
	var costs: Dictionary = quote.get("costs", {}) as Dictionary
	return "Needs %d credits, %d Moonsteel, %d Helium-3, and %d Quantum Salvage." % [
		int(quote.get("credits", 0)), int(costs.get("moonsteel", 0)),
		int(costs.get("helium3", 0)), int(costs.get("quantum_salvage", 0))
	]

func _now() -> int:
	return int(Time.get_unix_time_from_system())

func _result(ok: bool, message: String) -> Dictionary:
	return {"ok":ok, "message":message}
