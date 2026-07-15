extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/LivingPrecinct.tscn") as PackedScene
	_expect(scene != null, "Living precinct scene loads")
	if scene == null:
		quit(1)
		return
	var instance: Node = scene.instantiate()
	root.add_child(instance)
	for _frame: int in range(16):
		await process_frame
	var hull: Node3D = instance.get_node_or_null("LivingPrecinctWorld/SharedStationHull") as Node3D
	_expect(hull != null, "Shared station hull builds at runtime")
	if hull != null:
		_expect(bool(hull.get_meta("shared_walls", false)), "Hull declares shared-wall architecture")
		_expect(int(hull.get_meta("automatic_doors", 0)) == 8, "Hull declares eight room doors")
		_expect(_count_box_size(hull, Vector3(0.24, 3.8, 7.2)) == 6, "Six shared partitions divide adjacent rooms")
		_expect(_count_prefixed(hull, "Door_") >= 9, "Eight room doors and patrol airlock exist")
		_expect(_count_box_size(hull, Vector3(3.12, 3.8, 0.26)) == 16, "Corridor-facing bulkhead segments seal room fronts")
		_expect(_count_box_size(hull, Vector3(0.24, 0.28, 18.4)) >= 9, "Station ceiling ribs connect the hull")
		_expect(_count_cylinder_height(hull, 33.5) >= 6, "Utility piping details the station interior")
		_expect(hull.get_node_or_null("Door_PATROL AIRLOCK") is StationDoor, "Patrol airlock uses an automatic station door")
	var rooms: Node3D = instance.get_node_or_null("LivingPrecinctWorld/Rooms") as Node3D
	_expect(rooms != null and rooms.get_child_count() == 8, "All eight rooms remain playable")
	if rooms != null:
		var ops: Node3D = rooms.get_node_or_null("Room_ops") as Node3D
		var armory: Node3D = rooms.get_node_or_null("Room_armory") as Node3D
		_expect(ops != null and armory != null and is_equal_approx(armory.position.x - ops.position.x, 8.6), "Adjacent rooms snap to one shared wall grid")
		_expect(ops != null and is_equal_approx(ops.position.z, -5.7), "North rooms align with the central corridor")
	var personnel: Array[Node] = get_nodes_in_group("precinct_personnel")
	_expect(personnel.size() >= 10, "Walking personnel register with automatic doors")
	if hull != null and not personnel.is_empty():
		var ops_door: StationDoor = hull.get_node_or_null("Door_ops") as StationDoor
		var agent: Node3D = personnel[0] as Node3D
		if ops_door != null and agent != null:
			agent.global_position = ops_door.global_position
			for _frame: int in range(8):
				await process_frame
			_expect(ops_door.open_amount > 0.1, "Room door opens when personnel approach")
	instance.queue_free()
	await process_frame
	if failures == 0:
		print("SUCCESS: Shared space-station hull and automatic doors passed.")
	else:
		push_error("FAILED: %d station architecture check(s) failed." % failures)
	quit(failures)

func _count_box_size(root_node: Node, expected: Vector3, tolerance: float = 0.06) -> int:
	var total: int = 0
	if root_node is MeshInstance3D:
		var mesh_instance := root_node as MeshInstance3D
		if mesh_instance.mesh is BoxMesh:
			var size: Vector3 = (mesh_instance.mesh as BoxMesh).size
			if absf(size.x - expected.x) <= tolerance and absf(size.y - expected.y) <= tolerance and absf(size.z - expected.z) <= tolerance:
				total = 1
	for child: Node in root_node.get_children():
		total += _count_box_size(child, expected, tolerance)
	return total

func _count_cylinder_height(root_node: Node, expected_height: float, tolerance: float = 0.06) -> int:
	var total: int = 0
	if root_node is MeshInstance3D:
		var mesh_instance := root_node as MeshInstance3D
		if mesh_instance.mesh is CylinderMesh and absf((mesh_instance.mesh as CylinderMesh).height - expected_height) <= tolerance:
			total = 1
	for child: Node in root_node.get_children():
		total += _count_cylinder_height(child, expected_height, tolerance)
	return total

func _count_prefixed(root_node: Node, prefix: String) -> int:
	var total: int = 1 if String(root_node.name).begins_with(prefix) else 0
	for child: Node in root_node.get_children():
		total += _count_prefixed(child, prefix)
	return total

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
