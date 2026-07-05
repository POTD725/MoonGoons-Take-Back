class_name MoonGoonsFixedPointMovementController
extends RefCounted
## Advances authoritative simulation units at a fixed 30 Hz.

var _units_by_id: Dictionary = {}

func register_unit(unit: MoonGoonsSimulationUnit) -> bool:
	if unit.unit_id.is_empty() or _units_by_id.has(unit.unit_id):
		return false
	_units_by_id[unit.unit_id] = unit
	return true

func remove_unit(unit_id: String) -> void:
	_units_by_id.erase(unit_id)

func get_unit(unit_id: String) -> MoonGoonsSimulationUnit:
	var unit: Variant = _units_by_id.get(unit_id)
	if unit is MoonGoonsSimulationUnit:
		return unit as MoonGoonsSimulationUnit
	return null

func get_units() -> Array[MoonGoonsSimulationUnit]:
	var result: Array[MoonGoonsSimulationUnit] = []
	for unit_id: String in _sorted_unit_ids():
		var unit: Variant = _units_by_id[unit_id]
		if unit is MoonGoonsSimulationUnit:
			result.append(unit as MoonGoonsSimulationUnit)
	return result

func issue_move_command(unit_ids: Array[String], target_x_fp: int, target_z_fp: int) -> void:
	for unit_id: String in unit_ids:
		var unit := get_unit(unit_id)
		if unit != null:
			unit.set_move_target(target_x_fp, target_z_fp)

func process_simulation_tick() -> void:
	for unit: MoonGoonsSimulationUnit in get_units():
		if not unit.is_moving:
			continue
		var direction := MoonGoonsFixedVector2.subtract(unit.target_position, unit.current_position)
		var distance_fp := direction.magnitude()
		var step_distance_fp := MoonGoonsFixedMath.movement_step(unit.move_speed_fp)
		if distance_fp <= step_distance_fp or step_distance_fp <= 0:
			unit.current_position = unit.target_position.copy()
			unit.is_moving = false
			continue
		var normalized_direction := direction.normalized()
		unit.current_position.x += MoonGoonsFixedMath.multiply(normalized_direction.x, step_distance_fp)
		unit.current_position.z += MoonGoonsFixedMath.multiply(normalized_direction.z, step_distance_fp)

func serialize_state() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for unit: MoonGoonsSimulationUnit in get_units():
		result.append(unit.serialize_state())
	return result

func _sorted_unit_ids() -> Array[String]:
	var ids: Array[String] = []
	for raw_id: Variant in _units_by_id.keys():
		ids.append(String(raw_id))
	ids.sort()
	return ids
