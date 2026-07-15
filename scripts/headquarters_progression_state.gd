extends Node
## Persistent progression for Headquarters departments, their 108 item upgrades,
## standalone facilities, five visual skins, and timed construction jobs.

signal headquarters_changed
signal job_completed(job: Dictionary)

const SAVE_PATH := "user://moongoons_headquarters_progression.json"
const MAX_LEVEL := 100

var headquarters_level: int = 1
var department_levels: Dictionary = {}
var item_levels: Dictionary = {}
var facility_levels: Dictionary = {}
var department_styles: Dictionary = {}
var facility_styles: Dictionary = {}
var jobs: Array[Dictionary] = []
var job_serial: int = 1
var last_event: String = "Police Headquarters architecture online."

func _ready() -> void:
	_initialize_defaults()
	load_state()

func _process(_delta: float) -> void:
	tick()

func tick() -> void:
	var now := _now()
	var changed := false
	var remaining: Array[Dictionary] = []
	for job: Dictionary in jobs:
		if now >= int(job.get("finish_at", now + 1)):
			_complete_job(job)
			job_completed.emit(job)
			changed = true
		else:
			remaining.append(job)
	if changed:
		jobs = remaining
		save_state()
		headquarters_changed.emit()

func construction_slots() -> int:
	return mini(4, 1 + int((headquarters_level - 1) / 8))

func active_jobs() -> int:
	return jobs.size()

func available_slots() -> int:
	return maxi(0, construction_slots() - active_jobs())

func department_level(department_id: String) -> int:
	return int(department_levels.get(department_id, 1))

func facility_level(facility_id: String) -> int:
	return int(facility_levels.get(facility_id, 1))

func item_level(department_id: String, item_id: String) -> int:
	return int(item_levels.get("%s:%s" % [department_id, item_id], 1))

func department_style(department_id: String) -> int:
	return clampi(int(department_styles.get(department_id, 0)), 0, HeadquartersFacilityCatalog.STYLE_NAMES.size() - 1)

func facility_style(facility_id: String) -> int:
	return clampi(int(facility_styles.get(facility_id, 0)), 0, HeadquartersFacilityCatalog.STYLE_NAMES.size() - 1)

func set_department_style(department_id: String, style_index: int) -> void:
	department_styles[department_id] = clampi(style_index, 0, HeadquartersFacilityCatalog.STYLE_NAMES.size() - 1)
	last_event = "%s skin applied to %s." % [HeadquartersFacilityCatalog.STYLE_NAMES[department_style(department_id)], String(HeadquartersFacilityCatalog.department(department_id).get("name", department_id))]
	save_state()
	headquarters_changed.emit()

func set_facility_style(facility_id: String, style_index: int) -> void:
	facility_styles[facility_id] = clampi(style_index, 0, HeadquartersFacilityCatalog.STYLE_NAMES.size() - 1)
	last_event = "%s skin applied to %s." % [HeadquartersFacilityCatalog.STYLE_NAMES[facility_style(facility_id)], String(HeadquartersFacilityCatalog.facility(facility_id).get("name", facility_id))]
	save_state()
	headquarters_changed.emit()

func begin_headquarters_upgrade() -> Dictionary:
	if headquarters_level >= MAX_LEVEL:
		return _result(false, "Headquarters is at level 100.")
	if available_slots() <= 0:
		return _result(false, "All construction slots are occupied.")
	var cost := HeadquartersFacilityCatalog.facility_upgrade_cost("headquarters", headquarters_level)
	if not _spend(cost):
		return _result(false, _cost_message("Headquarters upgrade", cost))
	_queue_job("headquarters", "headquarters", headquarters_level + 1, HeadquartersFacilityCatalog.facility_upgrade_time(headquarters_level), {})
	return _result(true, last_event)

func begin_department_upgrade(department_id: String) -> Dictionary:
	var current := department_level(department_id)
	if current >= headquarters_level:
		return _result(false, "Department level is capped by Headquarters level %d." % headquarters_level)
	if available_slots() <= 0:
		return _result(false, "All construction slots are occupied.")
	var cost := HeadquartersFacilityCatalog.department_upgrade_cost(department_id, current)
	if not _spend(cost):
		return _result(false, _cost_message("Department upgrade", cost))
	_queue_job("department", department_id, current + 1, HeadquartersFacilityCatalog.department_upgrade_time(current), {"department_id":department_id})
	return _result(true, last_event)

func begin_item_upgrade(department_id: String, item_id: String) -> Dictionary:
	var current := item_level(department_id, item_id)
	var department_cap := department_level(department_id)
	if current >= department_cap:
		return _result(false, "Item level is capped by department level %d." % department_cap)
	if available_slots() <= 0:
		return _result(false, "All construction slots are occupied.")
	if _job_exists("item", "%s:%s" % [department_id, item_id]):
		return _result(false, "That item is already upgrading.")
	var item := _find_item(department_id, item_id)
	if item.is_empty():
		return _result(false, "Department item not found.")
	var cost := HeadquartersFacilityCatalog.item_cost(item, current)
	if not _spend(cost):
		return _result(false, _cost_message(String(item.get("name", "Item")), cost))
	_queue_job("item", "%s:%s" % [department_id, item_id], current + 1, HeadquartersFacilityCatalog.item_time(item, current), {"department_id":department_id, "item_id":item_id})
	return _result(true, last_event)

func begin_facility_upgrade(facility_id: String) -> Dictionary:
	var current := facility_level(facility_id)
	if current >= headquarters_level:
		return _result(false, "Facility level is capped by Headquarters level %d." % headquarters_level)
	if available_slots() <= 0:
		return _result(false, "All construction slots are occupied.")
	var cost := HeadquartersFacilityCatalog.facility_upgrade_cost(facility_id, current)
	if not _spend(cost):
		return _result(false, _cost_message("Facility upgrade", cost))
	_queue_job("facility", facility_id, current + 1, HeadquartersFacilityCatalog.facility_upgrade_time(current), {"facility_id":facility_id})
	return _result(true, last_event)

func job_time_left(job: Dictionary) -> int:
	return maxi(0, int(job.get("finish_at", 0)) - _now())

func active_job_for(kind: String, target: String) -> Dictionary:
	for job: Dictionary in jobs:
		if String(job.get("kind", "")) == kind and String(job.get("target", "")) == target:
			return job
	return {}

func reset_state() -> void:
	headquarters_level = 1
	department_levels = {}
	item_levels = {}
	facility_levels = {}
	department_styles = {}
	facility_styles = {}
	jobs = []
	job_serial = 1
	_initialize_defaults()
	last_event = "Headquarters progression reset."
	save_state()
	headquarters_changed.emit()

func save_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"headquarters_level":headquarters_level,
		"department_levels":department_levels,
		"item_levels":item_levels,
		"facility_levels":facility_levels,
		"department_styles":department_styles,
		"facility_styles":facility_styles,
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
	headquarters_level = int(data.get("headquarters_level", 1))
	department_levels = Dictionary(data.get("department_levels", {}))
	item_levels = Dictionary(data.get("item_levels", {}))
	facility_levels = Dictionary(data.get("facility_levels", {}))
	department_styles = Dictionary(data.get("department_styles", {}))
	facility_styles = Dictionary(data.get("facility_styles", {}))
	jobs = _dictionary_array(data.get("jobs", []))
	job_serial = int(data.get("job_serial", 1))
	last_event = String(data.get("last_event", last_event))
	_initialize_defaults()
	return true

func _initialize_defaults() -> void:
	for department_id: String in HeadquartersFacilityCatalog.department_ids():
		if not department_levels.has(department_id): department_levels[department_id] = 1
		if not department_styles.has(department_id): department_styles[department_id] = 0
		for item: Dictionary in HeadquartersFacilityCatalog.department_items(department_id):
			var key := "%s:%s" % [department_id, String(item.get("id", ""))]
			if not item_levels.has(key): item_levels[key] = 1
	for facility_id: String in HeadquartersFacilityCatalog.facility_ids():
		if not facility_levels.has(facility_id): facility_levels[facility_id] = 1
		if not facility_styles.has(facility_id): facility_styles[facility_id] = 0

func _queue_job(kind: String, target: String, level: int, duration: int, meta: Dictionary) -> void:
	var job := {"id":"hq_job_%04d" % job_serial, "kind":kind, "target":target, "level":level, "finish_at":_now()+duration, "duration":duration, "meta":meta}
	job_serial += 1
	jobs.append(job)
	last_event = "%s level %d upgrade started. Time: %d seconds." % [target.replace("_", " ").capitalize(), level, duration]
	save_state()
	headquarters_changed.emit()

func _complete_job(job: Dictionary) -> void:
	var kind := String(job.get("kind", ""))
	var target := String(job.get("target", ""))
	var level := int(job.get("level", 1))
	match kind:
		"headquarters": headquarters_level = maxi(headquarters_level, level)
		"department": department_levels[target] = maxi(department_level(target), level)
		"facility": facility_levels[target] = maxi(facility_level(target), level)
		"item":
			var meta := Dictionary(job.get("meta", {}))
			var department_id := String(meta.get("department_id", ""))
			var item_id := String(meta.get("item_id", ""))
			item_levels["%s:%s" % [department_id, item_id]] = maxi(item_level(department_id, item_id), level)
	last_event = "%s reached level %d." % [target.replace("_", " ").capitalize(), level]

func _spend(cost: Dictionary) -> bool:
	var credits_cost := int(cost.get("credits", 0))
	var resource_cost: Dictionary = cost.duplicate(true)
	resource_cost.erase("credits")
	if PrecinctState.credits < credits_cost or not ResourceHarvest.can_afford(resource_cost):
		return false
	PrecinctState.credits -= credits_cost
	if not resource_cost.is_empty(): ResourceHarvest.spend(resource_cost)
	PrecinctState.state_changed.emit()
	return true

func _cost_message(label: String, cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key_value: Variant in cost.keys():
		parts.append("%d %s" % [int(cost.get(key_value, 0)), String(key_value).replace("_", " ").to_upper()])
	return "%s needs %s." % [label, ", ".join(parts)]

func _find_item(department_id: String, item_id: String) -> Dictionary:
	for item: Dictionary in HeadquartersFacilityCatalog.department_items(department_id):
		if String(item.get("id", "")) == item_id:
			return item
	return {}

func _job_exists(kind: String, target: String) -> bool:
	return not active_job_for(kind, target).is_empty()

func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for entry: Variant in value:
			if entry is Dictionary: result.append(entry as Dictionary)
	return result

func _now() -> int:
	return int(Time.get_unix_time_from_system())

func _result(ok: bool, message: String) -> Dictionary:
	return {"ok":ok, "message":message}
