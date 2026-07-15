extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	PrecinctState.reset_state()
	PrecinctMeta.reset_meta()
	PrecinctEquipment.reset_state()
	CounterSyndicate.reset_state()
	_expect(PrecinctEquipment.total_item_count() == 24, "Eight rooms expose twenty-four individual equipment items")
	_expect(PrecinctEquipment.room_items("ops").size() == 3, "Operations Center exposes three upgradeable items")
	_expect(PrecinctEquipment.item_level("ops", "command_table") == 1, "Equipment starts at level one")
	var chief: Dictionary = PrecinctState.get_room("chief")
	var ops: Dictionary = PrecinctState.get_room("ops")
	chief["repaired"] = true
	chief["level"] = 1
	ops["repaired"] = true
	ops["level"] = 1
	PrecinctState.credits = 10000
	var locked_item: Dictionary = PrecinctEquipment.upgrade_item("ops", "command_table")
	_expect(not bool(locked_item.get("ok", false)), "Equipment cannot exceed the Chief's Office level")
	chief["level"] = 2
	var upgraded_item: Dictionary = PrecinctEquipment.upgrade_item("ops", "command_table")
	_expect(bool(upgraded_item.get("ok", false)), "Raising the Chief's Office cap unlocks an equipment upgrade")
	_expect(PrecinctEquipment.item_level("ops", "command_table") == 2, "Selected equipment records its own level")
	var capped_again: Dictionary = PrecinctEquipment.upgrade_item("ops", "command_table")
	_expect(not bool(capped_again.get("ok", false)), "Equipment stops again when it reaches the command cap")
	ops["level"] = 2
	var room_capped: Dictionary = PrecinctMeta.upgrade_room("ops")
	_expect(not bool(room_capped.get("ok", false)), "Room upgrades cannot exceed the Chief's Office level")
	var chief_upgrade: Dictionary = PrecinctMeta.upgrade_room("chief")
	_expect(bool(chief_upgrade.get("ok", false)) and int(chief.get("level", 1)) == 3, "Chief's Office upgrades raise the station-wide cap")
	var missions: Array[Dictionary] = PrecinctMeta.task_catalog()
	_expect(missions.size() >= 18, "Expanded mission board contains chapter, daily, patrol, investigation, district, and station missions")
	var groups: Dictionary = {}
	for mission: Dictionary in missions:
		groups[String(mission.get("group", ""))] = true
	for required_group: String in ["CHAPTER 1", "CHAPTER 2", "DAILY", "PATROL", "INVESTIGATION", "DISTRICT", "STATION"]:
		_expect(groups.has(required_group), "Mission group available: %s" % required_group)
	var scene: PackedScene = load("res://scenes/LivingPrecinct.tscn") as PackedScene
	_expect(scene != null, "Living precinct scene loads with progression controls")
	if scene != null:
		var instance: Node = scene.instantiate()
		root.add_child(instance)
		for _frame: int in range(22):
			await process_frame
		var progression: Node = instance.get_node_or_null("PrecinctProgressionUI")
		_expect(progression != null, "Equipment and mission controller is attached")
		var panel: Control = instance.get_node_or_null("EquipmentProgressionLayer/RoomEquipmentPanel") as Control
		var toggle: Button = instance.get_node_or_null("EquipmentProgressionLayer/EquipmentToggle") as Button
		_expect(panel != null and toggle != null, "Room equipment panel and toggle exist")
		var ops_room: Node3D = instance.get_node_or_null("LivingPrecinctWorld/Rooms/Room_ops") as Node3D
		var hotspots: Node3D = ops_room.get_node_or_null("EquipmentHotspots") as Node3D if ops_room != null else null
		_expect(hotspots != null and hotspots.get_child_count() == 3, "Selected room receives three clickable equipment hotspots with level badges")
		var task_list_value: Variant = instance.get("task_list")
		var mission_detail: Label = null
		if task_list_value is ItemList:
			mission_detail = (task_list_value as ItemList).get_parent().get_node_or_null("MissionDetail") as Label
		_expect(mission_detail != null, "Mission screen shows objective and reward details")
		instance.queue_free()
		await process_frame
	if failures == 0:
		print("SUCCESS: Individual equipment caps and expanded mission board passed.")
	else:
		push_error("FAILED: %d equipment or mission check(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
