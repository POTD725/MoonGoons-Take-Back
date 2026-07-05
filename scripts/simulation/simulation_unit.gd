class_name MoonGoonsSimulationUnit
extends RefCounted
## Authoritative unit state for deterministic movement simulation.
## Visual nodes should mirror this state, not mutate it.

var unit_id: String
var faction_id: String
var current_position: MoonGoonsFixedVector2
var target_position: MoonGoonsFixedVector2
var move_speed_fp: int
var is_moving := false

func _init(
	initial_unit_id: String,
	initial_faction_id: String,
	start_x_fp: int,
	start_z_fp: int,
	initial_move_speed_fp: int
) -> void:
	unit_id = initial_unit_id
	faction_id = initial_faction_id
	current_position = MoonGoonsFixedVector2.new(start_x_fp, start_z_fp)
	target_position = current_position.copy()
	move_speed_fp = initial_move_speed_fp

func set_move_target(target_x_fp: int, target_z_fp: int) -> void:
	target_position = MoonGoonsFixedVector2.new(target_x_fp, target_z_fp)
	is_moving = not current_position.equals(target_position)

func serialize_state() -> Dictionary:
	return {
		"unit_id": unit_id,
		"faction_id": faction_id,
		"x_fp": current_position.x,
		"z_fp": current_position.z,
		"target_x_fp": target_position.x,
		"target_z_fp": target_position.z,
		"move_speed_fp": move_speed_fp,
		"is_moving": is_moving
	}
