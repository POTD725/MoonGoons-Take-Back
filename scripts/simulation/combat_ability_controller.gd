class_name MoonGoonsCombatAbilityController
extends RefCounted
## Deterministic ability cooldown, duration, and channel controller.
## Target-specific combat effects are emitted as state requests for the mission/combat layer.

signal ability_started(unit_id: String, ability_id: String, target_payload: Dictionary)
signal ability_ended(unit_id: String, ability_id: String)
signal ability_effect_requested(unit_id: String, ability_id: String, target_payload: Dictionary)

class AbilityState:
	var ability_id: String
	var owner_player_id: int
	var is_passive := false
	var is_active := false
	var cooldown_remaining_ticks := 0
	var duration_remaining_ticks := 0
	var cooldown_total_ticks := 0
	var duration_total_ticks := 0
	var effects: Dictionary = {}
	var target_payload: Dictionary = {}

	func _init(initial_ability_id: String, initial_owner_player_id: int, definition: Dictionary) -> void:
		ability_id = initial_ability_id
		owner_player_id = initial_owner_player_id
		is_passive = bool(definition.get("is_passive", false))
		cooldown_total_ticks = _seconds_to_ticks(float(definition.get("cooldown", 0.0)))
		duration_total_ticks = _seconds_to_ticks(float(definition.get("duration", 0.0)))
		effects = (definition.get("effects", {}) as Dictionary).duplicate(true)

	func serialize_state() -> Dictionary:
		return {
			"ability_id": ability_id,
			"owner_player_id": owner_player_id,
			"is_passive": is_passive,
			"is_active": is_active,
			"cooldown_remaining_ticks": cooldown_remaining_ticks,
			"duration_remaining_ticks": duration_remaining_ticks,
			"cooldown_total_ticks": cooldown_total_ticks,
			"duration_total_ticks": duration_total_ticks,
			"effects": effects.duplicate(true),
			"target_payload": target_payload.duplicate(true)
		}

	static func _seconds_to_ticks(seconds: float) -> int:
		return maxi(0, roundi(seconds * MoonGoonsFixedMath.TICKS_PER_SECOND))

var _resource_bank: MoonGoonsResourceBank
var _states_by_unit: Dictionary = {}

func _init(resource_bank: MoonGoonsResourceBank) -> void:
	_resource_bank = resource_bank

func register_unit_abilities(unit_id: String, owner_player_id: int, ability_definitions: Array) -> void:
	var states_by_ability: Dictionary = {}
	for entry: Variant in ability_definitions:
		if not (entry is Dictionary):
			continue
		var definition: Dictionary = entry as Dictionary
		var ability_id := String(definition.get("id", ""))
		if ability_id.is_empty():
			continue
		states_by_ability[ability_id] = AbilityState.new(ability_id, owner_player_id, definition)
	_states_by_unit[unit_id] = states_by_ability

func can_execute(unit_id: String, ability_id: String) -> bool:
	var state := _get_state(unit_id, ability_id)
	return state != null and state.cooldown_remaining_ticks <= 0 and not state.is_active

func execute_ability(unit_id: String, ability_id: String, target_payload: Dictionary = {}) -> Dictionary:
	var state := _get_state(unit_id, ability_id)
	if state == null:
		return {"ok": false, "reason": "unknown_ability"}
	if state.cooldown_remaining_ticks > 0:
		return {"ok": false, "reason": "cooldown", "remaining_ticks": state.cooldown_remaining_ticks}
	if state.is_active and ability_id != "siphon":
		return {"ok": false, "reason": "already_active"}
	if ability_id == "siphon" and not bool(target_payload.get("valid_resource_node", false)):
		return {"ok": false, "reason": "siphon_requires_resource_node"}
	state.is_active = true
	state.target_payload = target_payload.duplicate(true)
	state.duration_remaining_ticks = state.duration_total_ticks
	state.cooldown_remaining_ticks = state.cooldown_total_ticks
	ability_started.emit(unit_id, ability_id, state.target_payload.duplicate(true))
	ability_effect_requested.emit(unit_id, ability_id, state.target_payload.duplicate(true))
	return {"ok": true, "ability_id": ability_id}

func stop_ability(unit_id: String, ability_id: String) -> bool:
	var state := _get_state(unit_id, ability_id)
	if state == null or not state.is_active:
		return false
	state.is_active = false
	state.duration_remaining_ticks = 0
	state.target_payload.clear()
	ability_ended.emit(unit_id, ability_id)
	return true

func process_simulation_tick() -> void:
	for unit_id: String in _sorted_unit_ids():
		var states: Dictionary = _states_by_unit[unit_id]
		var ability_ids: Array[String] = []
		for raw_ability_id: Variant in states.keys():
			ability_ids.append(String(raw_ability_id))
		ability_ids.sort()
		for ability_id: String in ability_ids:
			var state: AbilityState = states[ability_id]
			_process_state_tick(unit_id, state)

func get_ability_snapshot(unit_id: String, ability_id: String) -> Dictionary:
	var state := _get_state(unit_id, ability_id)
	return state.serialize_state() if state != null else {}

func serialize_state() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for unit_id: String in _sorted_unit_ids():
		var states: Dictionary = _states_by_unit[unit_id]
		var ability_ids: Array[String] = []
		for raw_ability_id: Variant in states.keys():
			ability_ids.append(String(raw_ability_id))
		ability_ids.sort()
		for ability_id: String in ability_ids:
			var state: AbilityState = states[ability_id]
			result.append({"unit_id": unit_id, "state": state.serialize_state()})
	return result

func restore_state(serialized_states: Array[Dictionary]) -> void:
	_states_by_unit.clear()
	for record: Dictionary in serialized_states:
		var unit_id := String(record.get("unit_id", ""))
		var raw_state: Dictionary = record.get("state", {})
		var ability_id := String(raw_state.get("ability_id", ""))
		if unit_id.is_empty() or ability_id.is_empty():
			continue
		if not _states_by_unit.has(unit_id):
			_states_by_unit[unit_id] = {}
		var definition := {
			"id": ability_id,
			"cooldown": 0.0,
			"duration": 0.0,
			"is_passive": bool(raw_state.get("is_passive", false)),
			"effects": raw_state.get("effects", {})
		}
		var state := AbilityState.new(ability_id, int(raw_state.get("owner_player_id", -1)), definition)
		state.is_active = bool(raw_state.get("is_active", false))
		state.cooldown_remaining_ticks = int(raw_state.get("cooldown_remaining_ticks", 0))
		state.duration_remaining_ticks = int(raw_state.get("duration_remaining_ticks", 0))
		state.cooldown_total_ticks = int(raw_state.get("cooldown_total_ticks", 0))
		state.duration_total_ticks = int(raw_state.get("duration_total_ticks", 0))
		state.effects = (raw_state.get("effects", {}) as Dictionary).duplicate(true)
		state.target_payload = (raw_state.get("target_payload", {}) as Dictionary).duplicate(true)
		(_states_by_unit[unit_id] as Dictionary)[ability_id] = state

func _process_state_tick(unit_id: String, state: AbilityState) -> void:
	if state.cooldown_remaining_ticks > 0:
		state.cooldown_remaining_ticks -= 1
	if not state.is_active:
		return
	if state.ability_id == "siphon":
		_resource_bank.process_passive_income_tick(state.owner_player_id, 2 * MoonGoonsFixedMath.SCALE)
	if state.duration_total_ticks > 0:
		state.duration_remaining_ticks -= 1
		if state.duration_remaining_ticks <= 0:
			state.duration_remaining_ticks = 0
			state.is_active = false
			state.target_payload.clear()
			ability_ended.emit(unit_id, state.ability_id)

func _get_state(unit_id: String, ability_id: String) -> AbilityState:
	var states: Variant = _states_by_unit.get(unit_id)
	if not (states is Dictionary):
		return null
	var state: Variant = (states as Dictionary).get(ability_id)
	return state as AbilityState if state is AbilityState else null

func _sorted_unit_ids() -> Array[String]:
	var unit_ids: Array[String] = []
	for raw_unit_id: Variant in _states_by_unit.keys():
		unit_ids.append(String(raw_unit_id))
	unit_ids.sort()
	return unit_ids
