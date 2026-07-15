extends SceneTree
## Headless checks for the precinct management and patrol-combat vertical slice.

var failures: int = 0

func _init() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	print("[PRECINCT] Loading shared state script...")
	var state_script: Script = load("res://scripts/precinct_state.gd") as Script
	_expect(state_script != null, "Precinct state script loads")
	if state_script == null:
		quit(1)
		return
	var state_node: Node = state_script.new() as Node
	root.add_child(state_node)
	await process_frame
	state_node.call("reset_state")
	var rooms_value: Variant = state_node.get("rooms")
	var officers_value: Variant = state_node.get("officers")
	_expect(rooms_value is Array and (rooms_value as Array).size() == 8, "Eight precinct rooms exist")
	_expect(officers_value is Array and (officers_value as Array).size() == 4, "Four starter officers exist")

	var repair_result: Dictionary = state_node.call("repair_room", "armory") as Dictionary
	_expect(bool(repair_result.get("ok", false)), "Damaged room can enter the repair queue")
	var armory: Dictionary = state_node.call("get_room", "armory") as Dictionary
	_expect(int(armory.get("repair_end", 0)) > 0, "Repair queue stores an absolute completion timer")

	var cells: Dictionary = state_node.call("get_room", "cells") as Dictionary
	cells["repaired"] = true
	state_node.set("prisoners", 1)
	var credits_before_processing: int = int(state_node.get("credits"))
	var process_result: Dictionary = state_node.call("process_prisoner") as Dictionary
	_expect(bool(process_result.get("ok", false)), "Prisoner processing works when cells are restored")
	_expect(int(state_node.get("credits")) > credits_before_processing, "Prisoner processing awards credits")

	state_node.call("_generate_call")
	var calls_value: Variant = state_node.get("patrol_calls")
	_expect(calls_value is Array and not (calls_value as Array).is_empty(), "Distress call generation produces a patrol target")
	if calls_value is Array and not (calls_value as Array).is_empty():
		var first_call: Dictionary = (calls_value as Array)[0] as Dictionary
		var call_id: String = String(first_call.get("id", ""))
		var officer_ids: Array[String] = ["officer_1"]
		var dispatch_result: Dictionary = state_node.call("begin_patrol", call_id, officer_ids) as Dictionary
		_expect(bool(dispatch_result.get("ok", false)), "An available officer can be dispatched")
		var active_call_value: Variant = state_node.get("active_call")
		_expect(active_call_value is Dictionary and not (active_call_value as Dictionary).is_empty(), "Dispatch moves the call into active battle state")
		var hp_results: Dictionary = {"officer_1": 80}
		state_node.call("finish_patrol", true, hp_results)
		_expect(int(state_node.get("prisoners")) >= 1, "Winning a patrol detains a suspect")

	var precinct_scene: PackedScene = load("res://scenes/PrecinctVerticalSlice.tscn") as PackedScene
	var battle_scene: PackedScene = load("res://scenes/PrecinctBattle.tscn") as PackedScene
	_expect(precinct_scene != null, "Precinct scene parses")
	_expect(battle_scene != null, "Patrol battle scene parses")

	state_node.queue_free()
	await process_frame
	if failures == 0:
		print("SUCCESS: Precinct vertical slice smoke tests passed.")
	else:
		push_error("FAILED: %d precinct smoke test(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
