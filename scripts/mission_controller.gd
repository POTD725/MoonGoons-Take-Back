class_name MoonGoonsMissionController
extends Node
## Data-driven campaign trigger runner for MoonGoons missions.
## Scene code reports events; this controller evaluates the mission JSON and emits effects.

signal mission_loaded(mission_id: String)
signal objective_changed(objective_id: String, state: String)
signal dialogue_requested(speaker: String, text: String)
signal effect_requested(effect: Dictionary)
signal mission_completed(mission_id: String)

const MISSION_DATA_PATH := "res://data/campaign_missions.json"

var _resource_bank: MoonGoonsResourceBank
var _catalog: Dictionary = {}
var _mission: Dictionary = {}
var _objective_states: Dictionary = {}
var _fired_trigger_ids: Dictionary = {}
var errors: Array[String] = []

func _init(resource_bank: MoonGoonsResourceBank = null) -> void:
	_resource_bank = resource_bank

func load_catalog(path: String = MISSION_DATA_PATH) -> bool:
	errors.clear()
	_catalog.clear()
	if not FileAccess.file_exists(path):
		errors.append("Missing campaign mission data: %s" % path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		errors.append("Could not open campaign mission data: %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		errors.append("Campaign mission data must be a JSON object.")
		return false
	_catalog = parsed as Dictionary
	return true

func start_mission(mission_id: String) -> bool:
	if _catalog.is_empty() and not load_catalog():
		return false
	var mission := _find_mission(mission_id)
	if mission.is_empty():
		errors.append("Unknown mission: %s" % mission_id)
		return false
	_mission = mission
	_objective_states.clear()
	_fired_trigger_ids.clear()
	for entry: Variant in _mission.get("objectives", []):
		if entry is Dictionary:
			var objective: Dictionary = entry as Dictionary
			var objective_id := String(objective.get("id", ""))
			if not objective_id.is_empty():
				_objective_states[objective_id] = "hidden"
	mission_loaded.emit(mission_id)
	notify_event("on_mission_started", {})
	return true

func notify_event(event_id: String, payload: Dictionary = {}) -> void:
	if _mission.is_empty():
		return
	for entry: Variant in _mission.get("triggers", []):
		if not (entry is Dictionary):
			continue
		var trigger: Dictionary = entry as Dictionary
		if String(trigger.get("event", "")) != event_id:
			continue
		var trigger_id := String(trigger.get("id", ""))
		if bool(trigger.get("once", false)) and _fired_trigger_ids.has(trigger_id):
			continue
		if not _conditions_match(trigger.get("conditions", {}) as Dictionary, payload):
			continue
		_fired_trigger_ids[trigger_id] = true
		_apply_effects(trigger.get("effects", []) as Array)

func get_objective_state(objective_id: String) -> String:
	return String(_objective_states.get(objective_id, "unknown"))

func serialize_state() -> Dictionary:
	return {
		"mission_id": String(_mission.get("id", "")),
		"objective_states": _objective_states.duplicate(true),
		"fired_trigger_ids": _fired_trigger_ids.duplicate(true)
	}

func restore_state(state: Dictionary) -> bool:
	var mission_id := String(state.get("mission_id", ""))
	if mission_id.is_empty() or not start_mission(mission_id):
		return false
	_objective_states = (state.get("objective_states", {}) as Dictionary).duplicate(true)
	_fired_trigger_ids = (state.get("fired_trigger_ids", {}) as Dictionary).duplicate(true)
	return true

func _find_mission(mission_id: String) -> Dictionary:
	for entry: Variant in _catalog.get("missions", []):
		if entry is Dictionary:
			var mission: Dictionary = entry as Dictionary
			if String(mission.get("id", "")) == mission_id:
				return mission.duplicate(true)
	return {}

func _conditions_match(conditions: Dictionary, payload: Dictionary) -> bool:
	if conditions.is_empty():
		return true
	for key: Variant in conditions:
		var expected: Variant = conditions[key]
		match String(key):
			"required_buildings":
				var built_buildings: Array = payload.get("built_building_ids", [])
				for building_id: Variant in expected as Array:
					if not built_buildings.has(building_id):
						return false
			"health_pct_max":
				if float(payload.get("health_pct", 1.0)) > float(expected):
					return false
			_:
				if payload.get(String(key)) != expected:
					return false
	return true

func _apply_effects(effects: Array) -> void:
	for entry: Variant in effects:
		if not (entry is Dictionary):
			continue
		var effect: Dictionary = entry as Dictionary
		var effect_type := String(effect.get("type", ""))
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
	var player_id := int(effect.get("player_id", 1))
	var amount := int(effect.get("amount", 0))
	match String(effect.get("resource", "")):
		"credits":
			_resource_bank.award_resources_fp(player_id, amount * MoonGoonsFixedMath.SCALE)
		"lunar_alloy":
			_resource_bank.award_resources_fp(player_id, 0, amount * MoonGoonsFixedMath.SCALE)
		"intel":
			_resource_bank.award_resources_fp(player_id, 0, 0, amount * MoonGoonsFixedMath.SCALE)
		"evidence":
			_resource_bank.award_evidence_tokens(player_id, amount)
