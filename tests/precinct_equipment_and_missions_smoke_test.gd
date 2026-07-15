extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	PrecinctState.reset_state()
	PrecinctEquipment.reset_state()
	SideOperations.reset_state()
	StationProgression.reset_state()
	PrecinctMeta.reset_meta()
	CounterSyndicate.reset_state()
	PrecinctState.credits = 50000
	var chief: Dictionary = PrecinctState.get_room("chief")
	var ops: Dictionary = PrecinctState.get_room("ops")
	chief["repaired"] = true
	ops["repaired"] = true
	chief["level"] = 1
	ops["level"] = 1

	_expect(PrecinctEquipment.total_item_count() == 24, "Eight rooms expose twenty-four individual equipment items")
	_expect(PrecinctEquipment.room_items("ops").size() == 3, "Operations Center exposes three upgradeable items")
	_expect(PrecinctEquipment.item_level("ops", "command_table") == 1, "Equipment starts at level one")
	var item_locked: Dictionary = PrecinctEquipment.upgrade_item("ops", "command_table")
	_expect(not bool(item_locked.get("ok", false)), "Equipment cannot exceed its room level")
	var station_duration_l1: int = StationProgression.station_upgrade_duration()
	var room_duration_l1: int = StationProgression.room_upgrade_duration("ops")
	var item_duration_l1: int = StationProgression.item_upgrade_duration("ops", "command_table")

	var station_start: Dictionary = StationProgression.begin_station_upgrade()
	_expect(bool(station_start.get("ok", false)) and StationProgression.upgrade_jobs.size() == 1, "Station expansion enters a timed construction slot")
	_expect(StationProgression.station_level == 1, "Station level does not increase before the timer completes")
	_finish_all_jobs()
	_expect(StationProgression.station_level == 2, "Completed station timer raises the station to level two")
	_expect(StationProgression.station_upgrade_duration() > station_duration_l1, "Station upgrade time grows at higher levels")

	var chief_start: Dictionary = PrecinctMeta.upgrade_room("chief")
	_expect(bool(chief_start.get("ok", false)), "Station level two unlocks a timed Chief's Office upgrade")
	_finish_all_jobs()
	_expect(int(chief.get("level", 1)) == 2, "Chief's Office reaches level two after its timer")

	var room_start: Dictionary = PrecinctMeta.upgrade_room("ops")
	_expect(bool(room_start.get("ok", false)), "Chief level two unlocks a timed room upgrade")
	_finish_all_jobs()
	_expect(int(ops.get("level", 1)) == 2, "Operations Center reaches level two after its timer")
	_expect(StationProgression.room_upgrade_duration("ops") > room_duration_l1, "Room upgrade time grows at higher levels")

	var item_start: Dictionary = PrecinctEquipment.upgrade_item("ops", "command_table")
	_expect(bool(item_start.get("ok", false)), "Room level two unlocks a timed equipment upgrade")
	_expect(PrecinctEquipment.item_level("ops", "command_table") == 1, "Equipment level remains unchanged while its timer runs")
	_finish_all_jobs()
	_expect(PrecinctEquipment.item_level("ops", "command_table") == 2, "Equipment reaches level two after its timer")
	_expect(StationProgression.item_upgrade_duration("ops", "command_table") > item_duration_l1, "Equipment upgrade time grows at higher levels")
	var item_capped: Dictionary = PrecinctEquipment.upgrade_item("ops", "command_table")
	_expect(not bool(item_capped.get("ok", false)), "Equipment stops when it reaches the room level")

	var defense_start: Dictionary = StationProgression.begin_defense_upgrade("point_defense")
	_expect(bool(defense_start.get("ok", false)), "Station level two unlocks a timed point-defense upgrade")
	_finish_all_jobs()
	_expect(StationProgression.defense_level("point_defense") == 2, "Point-defense turrets reach level two after construction")
	_expect(StationProgression.defense_rating() > 0, "Station defense rating combines weapons, shields, interceptors, and Side Ops bonuses")

	StationProgression.trigger_marauder_wave()
	StationProgression.active_marauder_wave["power"] = 0
	var defense_win: Dictionary = StationProgression.resolve_marauder_wave()
	_expect(bool(defense_win.get("ok", false)) and StationProgression.attacks_survived == 1, "Station defenses can repel a marauder wave")
	StationProgression.trigger_marauder_wave()
	StationProgression.station_hull = 100
	StationProgression.station_shield = 0
	StationProgression.active_marauder_wave["power"] = 999
	var defense_loss: Dictionary = StationProgression.resolve_marauder_wave()
	_expect(not bool(defense_loss.get("ok", false)) and StationProgression.station_hull < 100, "Overwhelming marauders damage the station hull")

	var missions: Array[Dictionary] = PrecinctMeta.task_catalog()
	_expect(missions.size() >= 25, "Mission board includes campaign, Side Ops, station, and defense objectives")
	var groups: Dictionary = {}
	for mission: Dictionary in missions:
		groups[String(mission.get("group", ""))] = true
	for required_group: String in ["CHAPTER 1", "CHAPTER 2", "DAILY", "PATROL", "INVESTIGATION", "DISTRICT", "STATION", "SIDE OPS", "DEFENSE"]:
		_expect(groups.has(required_group), "Mission group available: %s" % required_group)

	var scene: PackedScene = load("res://scenes/LivingPrecinct.tscn") as PackedScene
	_expect(scene != null, "Living precinct scene loads with progression and defense controls")
	if scene != null:
		var instance: Node = scene.instantiate()
		root.add_child(instance)
		for _frame: int in range(32):
			await process_frame
		_expect(instance.has_node("PrecinctProgressionUI"), "Equipment and mission controller is attached")
		_expect(instance.has_node("StationCommandUI"), "Station command controller is attached")
		_expect(instance.has_node("SideOperationsUI"), "Side operation controller is attached")
		var panel: Control = instance.get_node_or_null("EquipmentProgressionLayer/RoomEquipmentPanel") as Control
		var toggle: Button = instance.get_node_or_null("EquipmentProgressionLayer/EquipmentToggle") as Button
		_expect(panel != null and toggle != null, "Room equipment panel and toggle exist")
		var command_button: Button = instance.get_node_or_null("StationCommandLayer/StationCommandButton") as Button
		var command_panel: PanelContainer = instance.get_node_or_null("StationCommandLayer/StationCommandPanel") as PanelContainer
		_expect(command_button != null and command_panel != null, "Station command button and hierarchy panel exist")
		var side_button: Button = instance.get_node_or_null("SideOperationsLayer/SideOperationsButton") as Button
		_expect(side_button != null, "Side Operations button exists")
		var ops_room: Node3D = instance.get_node_or_null("LivingPrecinctWorld/Rooms/Room_ops") as Node3D
		var hotspots: Node3D = ops_room.get_node_or_null("EquipmentHotspots") as Node3D if ops_room != null else null
		_expect(hotspots != null and hotspots.get_child_count() == 3, "Selected room receives three clickable equipment hotspots with level badges")
		var defense_visuals: Node3D = instance.get_node_or_null("LivingPrecinctWorld/StationDefenseVisuals") as Node3D
		_expect(defense_visuals != null and int(defense_visuals.get_meta("defense_systems", 0)) == 4, "Exterior renders four station-defense system families")
		var task_list_value: Variant = instance.get("task_list")
		var mission_detail: Label = null
		if task_list_value is ItemList:
			mission_detail = (task_list_value as ItemList).get_parent().get_node_or_null("MissionDetail") as Label
		_expect(mission_detail != null, "Mission screen shows objective and reward details")
		instance.queue_free()
		await process_frame

	if failures == 0:
		print("SUCCESS: Timed hierarchy, missions, and marauder defense passed.")
	else:
		push_error("FAILED: %d hierarchy, mission, or defense check(s) failed." % failures)
	quit(failures)

func _finish_all_jobs() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	for job: Dictionary in StationProgression.upgrade_jobs:
		job["finish_at"] = now - 1
	StationProgression.tick()

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
