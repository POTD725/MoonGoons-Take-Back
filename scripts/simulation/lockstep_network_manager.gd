class_name MoonGoonsLockstepNetworkManager
extends RefCounted
## Transport-agnostic deterministic lockstep turn buffer.
## A future ENet/WebSocket adapter should submit validated packets to this class.

signal synchronization_waiting_changed(is_waiting: bool)
signal turn_executed(turn_id: int, simulation_tick: int)

const INPUT_DELAY_TURNS: int = 2
const SIMULATION_TICKS_PER_NETWORK_TURN: int = 3

var current_network_turn := 0
var current_simulation_tick := 0
var expected_player_ids: Array[int] = []
var _input_buffer: Dictionary = {}
var _movement_controller: MoonGoonsFixedPointMovementController
var _is_waiting := false

func _init(movement_controller: MoonGoonsFixedPointMovementController, player_ids: Array[int]) -> void:
	_movement_controller = movement_controller
	expected_player_ids = player_ids.duplicate()
	expected_player_ids.sort()

func queue_local_commands(player_id: int, commands: Array[Dictionary]) -> Dictionary:
	return make_input_packet(current_network_turn + INPUT_DELAY_TURNS, player_id, commands)

func make_input_packet(turn_id: int, player_id: int, commands: Array[Dictionary]) -> Dictionary:
	return {
		"turn_id": turn_id,
		"player_id": player_id,
		"commands": commands.duplicate(true)
	}

func receive_input_packet(packet: Dictionary) -> bool:
	var validation := validate_input_packet(packet)
	if not bool(validation.get("ok", false)):
		push_warning("Lockstep packet rejected: %s" % String(validation.get("error", "unknown validation error")))
		return false
	var turn_id := int(packet["turn_id"])
	var player_id := int(packet["player_id"])
	if turn_id < current_network_turn:
		return false
	if not _input_buffer.has(turn_id):
		_input_buffer[turn_id] = {}
	var by_player: Dictionary = _input_buffer[turn_id]
	by_player[player_id] = packet.duplicate(true)
	_input_buffer[turn_id] = by_player
	return true

func update_network_turn_loop() -> Dictionary:
	var packets: Dictionary = _input_buffer.get(current_network_turn, {})
	if not _has_all_player_packets(packets):
		_set_waiting(true)
		return {"advanced": false, "turn_id": current_network_turn, "reason": "waiting_for_input_packets"}
	_set_waiting(false)
	for player_id: int in expected_player_ids:
		var packet: Dictionary = packets[player_id]
		_execute_packet(packet)
	for step: int in SIMULATION_TICKS_PER_NETWORK_TURN:
		_movement_controller.process_simulation_tick()
		current_simulation_tick += 1
	_input_buffer.erase(current_network_turn)
	var executed_turn := current_network_turn
	current_network_turn += 1
	turn_executed.emit(executed_turn, current_simulation_tick)
	return {"advanced": true, "turn_id": executed_turn, "simulation_tick": current_simulation_tick}

func validate_input_packet(packet: Dictionary) -> Dictionary:
	for required_key: String in ["turn_id", "player_id", "commands"]:
		if not packet.has(required_key):
			return {"ok": false, "error": "Missing packet key: %s" % required_key}
	var player_id := int(packet.get("player_id", -1))
	if not expected_player_ids.has(player_id):
		return {"ok": false, "error": "Unexpected player id: %d" % player_id}
	if not (packet.get("commands") is Array):
		return {"ok": false, "error": "Packet commands must be an array."}
	for command: Variant in packet.get("commands", []):
		if not (command is Dictionary):
			return {"ok": false, "error": "Packet contains a non-dictionary command."}
		var command_validation := _validate_command(command as Dictionary)
		if not bool(command_validation.get("ok", false)):
			return command_validation
	return {"ok": true}

func _validate_command(command: Dictionary) -> Dictionary:
	var command_type := String(command.get("command_type", ""))
	if command_type == "no_op":
		return {"ok": true}
	if command_type != "move":
		return {"ok": false, "error": "Unsupported command type: %s" % command_type}
	for key: String in ["selected_unit_ids", "target_x_fp", "target_z_fp"]:
		if not command.has(key):
			return {"ok": false, "error": "Move command missing: %s" % key}
	if not (command["selected_unit_ids"] is Array):
		return {"ok": false, "error": "Move command selected_unit_ids must be an array."}
	return {"ok": true}

func _execute_packet(packet: Dictionary) -> void:
	var commands: Array = packet.get("commands", [])
	for command: Variant in commands:
		if command is Dictionary:
			_execute_command(command as Dictionary)

func _execute_command(command: Dictionary) -> void:
	if String(command.get("command_type", "")) != "move":
		return
	var unit_ids: Array[String] = []
	for raw_id: Variant in command.get("selected_unit_ids", []):
		unit_ids.append(String(raw_id))
	unit_ids.sort()
	_movement_controller.issue_move_command(
		unit_ids,
		int(command.get("target_x_fp", 0)),
		int(command.get("target_z_fp", 0))
	)

func _has_all_player_packets(packets: Dictionary) -> bool:
	for player_id: int in expected_player_ids:
		if not packets.has(player_id):
			return false
	return true

func _set_waiting(next_waiting: bool) -> void:
	if _is_waiting == next_waiting:
		return
	_is_waiting = next_waiting
	synchronization_waiting_changed.emit(_is_waiting)
