extends SceneTree

var failures: int = 0
var precinct_state: Node
var equipment_state: Node
var side_ops: Node
var station_progression: Node
var precinct_meta: Node
var counter_syndicate: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	precinct_state = root.get_node_or_null("PrecinctState")
	equipment_state = root.get_node_or_null("PrecinctEquipment")
	side_ops = root.get_node_or_null("SideOperations")
	station_progression = root.get_node_or_null("StationProgression")
	precinct_meta = root.get_node_or_null("PrecinctMeta")
	counter_syndicate = root.get_node_or_null("CounterSyndicate")
	_expect(precinct_state != null and equipment_state != null and side_ops != null and station_progression != null and precinct_meta != null and counter_syndicate != null, "Progression autoload services are available")
	if failures > 0:
		quit(failures)
		return
	precinct_state.call("reset_state")
	equipment_state.call("reset_state")
	side_ops.call("reset_state")
	station_progression.call("reset_state")
	precinct_meta.call("reset_meta")
	counter_syndicate.call("reset_state")
	precinct_state.set("credits", 50000)
	var chief: Dictionary = precinct_state.call("get_room", "chief") as Dictionary
	var ops: Dictionary = precinct_state.call("get_room", "ops") as Dictionary
	chief["repaired"] = true
	ops["repaired"] = true
	chief["level"] = 1
	ops["level"] = 1

	_expect(int(equipment_state.call("total_item_count")) == 24, "Eight rooms expose twenty-four individual equipment items")
	_expect((equipment_state.call("room_items", "ops") as Array).size() == 3, "Operations Center exposes three upgradeable items")
	_expect(int(equipment_state.call("item_level", "ops", "command_table")) == 1, "Equipment starts at level one")
	var item_locked: Dictionary = equipment_state.call("upgrade_item", "ops", "command_table") as Dictionary
	_expect(not bool(item_locked.get("ok", false)), "Equipment cannot exceed its room level")
	var station_duration_l1: int = int(station_progression.call("station_upgrade_duration"))
	var room_duration_l1: int = int(station_progression.call("room_upgrade_duration", "ops"))
	var item_duration_l1: int = int(station_progression.call("item_upgrade_duration", "ops", "command_table"))

	var station_start: Dictionary = station_progression.call("begin_station_upgrade") as Dictionary
	_expect(bool(station_start.get("ok", false)) and (station_progression.get("upgrade_jobs") as Array).size() == 1, "Station expansion enters a timed construction slot")
	_expect(int(station_progression.get("station_level")) == 1, "Station level does not increase before the timer completes")
	_finish_all_jobs()
	_expect(int(station_progression.get("station_level")) == 2, "Completed station timer raises the station to level two")
	_expect(int(station_progression.call("station_upgrade_duration")) > station_duration_l1, "Station upgrade time grows at higher levels")

	var chief_start: Dictionary = precinct_meta.call("upgrade_room", "chief") as Dictionary
	_expect(bool(chief_start.get("ok", false)), "Station level two unlocks a timed Chief's Office upgrade")
	_finish_all_jobs()
	_expect(int(chief.get("level", 1)) == 2, "Chief's Office reaches level two after its timer")

	var room_start: Dictionary = precinct_meta.call("upgrade_room", "ops") as Dictionary
	_expect(bool(room_start.get("ok", false)), "Chief level two unlocks a timed room upgrade")
	_finish_all_jobs()
	_expect(int(ops.get("level", 1)) == 2, "Operations Center reaches level two after its timer")
	_expect(int(station_progression.call("room_upgrade_duration", "ops")) > room_duration_l1, "Room upgrade time grows at higher levels")

	var item_start: Dictionary = equipment_state.call("upgrade_item", "ops", "command_table") as Dictionary
	_expect(bool(item_start.get("ok", false)), "Room level two unlocks a timed equipment upgrade")
	_expect(int(equipment_state.call("item_level", "ops", "command_table")) == 1, "Equipment level remains unchanged while its timer runs")
	_finish_all_jobs()
	_expect(int(equipment_state.call("item_level", "ops", "command_table")) == 2, "Equipment reaches level two after its timer")
	_expect(int(station_progression.call("item_upgrade_duration", "ops", "command_table")) > item_duration_l1, "Equipment upgrade time grows at higher levels")
	var item_capped: Dictionary = equipment_state.call("upgrade_item", "ops", "command_table") as Dictionary
	_expect(not bool(item_capped.get("ok", false)), "Equipment stops when it reaches the room level")

	var defense_start: Dictionary = station_progression.call("begin_defense_upgrade", "point_defense") as Dictionary
	_expect(bool(defense_start.get("ok", false)), "Station level two unlocks a timed point-defense upgrade")
	_finish_all_jobs()
	_expect(int(station_progression.call("defense_level", "point_defense")) == 2, "Point-defense turrets reach level two after construction")
	_expect(int(station_progression.call("defense_rating")) > 0, "Station defense rating combines weapons, shields, interceptors, and Side Ops bonuses")

	station_progression.call("trigger_marauder_wave")
	var wave: Dictionary = station_progression.get("active_marauder_wave") as Dictionary
	wave["power"] = 0
	var defense_win: Dictionary = station_progression.call("resolve_marauder_wave") as Dictionary
	_expect(bool(defense_win.get("ok", false)) and int(station_progression.get("attacks_survived")) == 1, "Station defenses can repel a marauder wave")
	station_progression.call("trigger_marauder_wave")
	station_progression.set("station_hull", 100)
	station_progression.set("station_shield", 0)
	wave = station_progression.get("active_marauder_wave") as Dictionary
	wave["power"] = 999
	var defense_loss: Dictionary = station_progression.call("resolve_marauder_wave") as Dictionary
	_expect(not bool(defense_loss.get("ok", false)) and int(station_progression.get("station_hull")) < 100, "Overwhelming marauders damage the station hull")

	var missions: Array = precinct_meta.call("task_catalog") as Array
	_expect(missions.size() >= 25, "Mission board includes campaign, Side Ops, station, and defense objectives")
	var groups: Dictionary = {}
	for mission_value: Variant in missions:
		if mission_value is Dictionary:
			groups[String((mission_value as Dictionary).get("group", ""))] = true
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
	var jobs: Array = station_progression.get("upgrade_jobs") as Array
	for job_value: Variant in jobs:
		if job_value is Dictionary:
			(job_value as Dictionary)["finish_at"] = now - 1
	station_progression.call("tick")

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
