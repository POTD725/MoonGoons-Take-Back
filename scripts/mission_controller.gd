class_name MoonGoonsMissionController
extends Node
## Data-driven campaign trigger runner for MoonGoons missions.
## Scene code reports events; this controller evaluates mission data and emits effects.

signal mission_loaded(mission_id: String)
signal objective_changed(objective_id: String, state: String)
signal dialogue_requested(speaker: String, text: String)
signal effect_requested(effect: Dictionary)
signal mission_completed(mission_id: String)

const MISSION_DATA_PATHS := [
	"res://data/campaign_missions.json",
	"res://data/campaign_missions_act_2_to_4.json"
]

var _resource_bank: MoonGoonsResourceBank
var _catalog: Dictionary = {"missions": []}
var _mission: Dictionary = {}
var _objective_states: Dictionary = {}
var _fired_trigger_ids: Dictionary = {}
var errors: Array[String] = []

func _init(resource_bank: MoonGoonsResourceBank = null) -> void:
	_resource_bank = resource_bank

func load_catalog(paths: Array = []) -> bool:
	errors.clear()
	_catalog = {"missions": []}
	var loaded_mission_ids: Dictionary = {}
	var selected_paths: Array = MISSION_DATA_PATHS if paths.is_empty() else paths
	var catalog_missions: Array = []
	for source_path_value: Variant in selected_paths:
		var source_path: String = String(source_path_value)
		var source: Dictionary = _load_catalog_source(source_path)
		if source.is_empty():
			continue
		var source_missions: Array = source.get("missions", []) as Array
		for entry: Variant in source_missions:
			if not (entry is Dictionary):
				errors.append("Campaign source contains a non-dictionary mission: %s" % source_path)
				continue
			var mission: Dictionary = entry as Dictionary
			var mission_id: String = String(mission.get("id", ""))
			if mission_id.is_empty() or loaded_mission_ids.has(mission_id):
				errors.append("Campaign source has duplicate or empty mission id: %s" % mission_id)
				continue
			catalog_missions.append(mission.duplicate(true))
			loaded_mission_ids[mission_id] = true
	_catalog["missions"] = catalog_missions
	return errors.is_empty()

func start_mission(mission_id: String) -> bool:
	var loaded_missions: Array = _catalog.get("missions", []) as Array
	if loaded_missions.is_empty() and not load_catalog():
		return false
	var mission: Dictionary = _find_mission(mission_id)
	if mission.is_empty():
		errors.append("Unknown mission: %s" % mission_id)
		return false
	_mission = mission
	_objective_states.clear()
	_fired_trigger_ids.clear()
	var objectives: Array = _mission.get("objectives", []) as Array
	for entry: Variant in objectives:
		if entry is Dictionary:
			var objective: Dictionary = entry as Dictionary
			var objective_id: String = String(objective.get("id", ""))
			if not objective_id.is_empty():
				_objective_states[objective_id] = "hidden"
	mission_loaded.emit(mission_id)
	notify_event("on_mission_started", {})
	return true

func notify_event(event_id: String, payload: Dictionary = {}) -> void:
	if _mission.is_empty():
		return
	_update_objective_completions(event_id, payload)
	var triggers: Array = _mission.get("triggers", []) as Array
	for entry: Variant in triggers:
		if not (entry is Dictionary):
			continue
		var trigger: Dictionary = entry as Dictionary
		if String(trigger.get("event", "")) != event_id:
			continue
		var trigger_id: String = String(trigger.get("id", ""))
		if bool(trigger.get("once", false)) and _fired_trigger_ids.has(trigger_id):
			continue
		var conditions: Dictionary = trigger.get("conditions", {}) as Dictionary
		if not _conditions_match(conditions, payload):
			continue
		_fired_trigger_ids[trigger_id] = true
		var effects: Array = trigger.get("effects", []) as Array
		_apply_effects(effects)

func get_objective_state(objective_id: String) -> String:
	return String(_objective_states.get(objective_id, "unknown"))

func get_loaded_mission_ids() -> Array[String]:
	var result: Array[String] = []
	var missions: Array = _catalog.get("missions", []) as Array
	for entry: Variant in missions:
		if entry is Dictionary:
			result.append(String((entry as Dictionary).get("id", "")))
	result.sort()
	return result

func serialize_state() -> Dictionary:
	return {
		"mission_id": String(_mission.get("id", "")),
		"objective_states": _objective_states.duplicate(true),
		"fired_trigger_ids": _fired_trigger_ids.duplicate(true)
	}

func restore_state(state: Dictionary) -> bool:
	var mission_id: String = String(state.get("mission_id", ""))
	if mission_id.is_empty() or not start_mission(mission_id):
		return false
	_objective_states = (state.get("objective_states", {}) as Dictionary).duplicate(true)
	_fired_trigger_ids = (state.get("fired_trigger_ids", {}) as Dictionary).duplicate(true)
	return true

func _load_catalog_source(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("Missing campaign mission data: %s" % path)
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Could not open campaign mission data: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		errors.append("Campaign mission data must be a JSON object: %s" % path)
		return {}
	return parsed as Dictionary

func _find_mission(mission_id: String) -> Dictionary:
	var missions: Array = _catalog.get("missions", []) as Array
	for entry: Variant in missions:
		if entry is Dictionary:
			var mission: Dictionary = entry as Dictionary
			if String(mission.get("id", "")) == mission_id:
				return mission.duplicate(true)
	return {}

func _update_objective_completions(event_id: String, payload: Dictionary) -> void:
	var objectives: Array = _mission.get("objectives", []) as Array
	for entry: Variant in objectives:
		if not (entry is Dictionary):
			continue
		var objective: Dictionary = entry as Dictionary
		var objective_id: String = String(objective.get("id", ""))
		if objective_id.is_empty() or get_objective_state(objective_id) == "completed":
			continue
		if String(objective.get("completion_event", "")) != event_id:
			continue
		var completion_conditions: Dictionary = objective.get("completion_conditions", {}) as Dictionary
		if _conditions_match(completion_conditions, payload):
			_set_objective_state(objective_id, "completed")

func _conditions_match(conditions: Dictionary, payload: Dictionary) -> bool:
	if conditions.is_empty():
		return true
	for key: Variant in conditions:
		var key_name: String = String(key)
		var expected: Variant = conditions[key]
		match key_name:
			"required_buildings":
				var built_buildings: Array = payload.get("built_building_ids", []) as Array
				var required_buildings: Array = expected as Array
				for building_id: Variant in required_buildings:
					if not built_buildings.has(building_id):
						return false
			"minimum":
				var current_value: int = int(payload.get("value", payload.get("counter_value", 0)))
				if current_value < int(expected):
					return false
			"health_pct_max":
				if float(payload.get("health_pct", 1.0)) > float(expected):
					return false
			_:
				if payload.get(key_name) != expected:
					return false
	return true

func _apply_effects(effects: Array) -> void:
	for entry: Variant in effects:
		if not (entry is Dictionary):
			continue
		var effect: Dictionary = entry as Dictionary
		var effect_type: String = String(effect.get("type", ""))
		match effect_type:
			"set_objective":
				_set_objective_state(String(effect.get("objective_id", "")), "active")
			"complete_objective":
				_set_objective_state(String(effect.get("objective_id", "")), "completed")
			"dialogue":
				dialogue_requested.emit(String(effect.get("speaker", "")), String(effect.get("text", "")))
			"award_resource":
				_award_resource(effect)
			"complete_mission":
				mission_completed.emit(String(effect.get("mission_id", _mission.get("id", ""))))
			_:
				effect_requested.emit(effect.duplicate(true))

func _set_objective_state(objective_id: String, state: String) -> void:
	if objective_id.is_empty():
		return
	_objective_states[objective_id] = state
	objective_changed.emit(objective_id, state)

func _award_resource(effect: Dictionary) -> void:
	if _resource_bank == null:
		return
	var player_id: int = int(effect.get("player_id", 1))
	var amount: int = int(effect.get("amount", 0))
	match String(effect.get("resource", "")):
		"credits":
			_resource_bank.award_resources_fp(player_id, amount * MoonGoonsFixedMath.SCALE)
		"lunar_alloy":
			_resource_bank.award_resources_fp(player_id, 0, amount * MoonGoonsFixedMath.SCALE)
		"intel":
			_resource_bank.award_resources_fp(player_id, 0, 0, amount * MoonGoonsFixedMath.SCALE)
		"evidence":
			_resource_bank.award_evidence_tokens(player_id, amount)
