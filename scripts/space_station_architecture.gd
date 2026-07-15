extends Node
## Converts the living precinct's separate room modules into one connected station.

const ROOM_ORDER: Array[String] = ["ops", "armory", "cells", "quarters", "medbay", "chief", "interrogation", "transfer"]
const X_POSITIONS: Array[float] = [-12.9, -4.3, 4.3, 12.9]
const NORTH_Z: float = -5.7
const SOUTH_Z: float = 5.7
const ROOM_WIDTH: float = 8.6
const ROOM_DEPTH: float = 7.2
const WALL_HEIGHT: float = 3.8
const CORRIDOR_HALF: float = 2.1

var precinct: Node3D
var hull_root: Node3D

func _ready() -> void:
	precinct = get_parent() as Node3D
	call_deferred("_assemble_station")

func _assemble_station() -> void:
	for _frame: int in range(8):
		await get_tree().process_frame
	if precinct == null:
		return
	var world: Node3D = precinct.get_node_or_null("LivingPrecinctWorld") as Node3D
	var rooms: Node3D = precinct.get_node_or_null("LivingPrecinctWorld/Rooms") as Node3D
	if world == null or rooms == null:
		return
	_remove_old_corridor(world)
	_snap_rooms_into_hull(rooms)
	_remove_individual_room_walls(rooms)
	_build_shared_hull(world)
	precinct.set("camera_target", Vector3(0.0, 0.0, 0.2))
	precinct.set("camera_distance", 33.5)

func _remove_old_corridor(world: Node3D) -> void:
	for child: Node in world.get_children():
		if not child is MeshInstance3D:
			continue
		var mesh_instance := child as MeshInstance3D
		if not mesh_instance.mesh is BoxMesh:
			continue
		var size: Vector3 = (mesh_instance.mesh as BoxMesh).size
		var old_corridor: bool = _near_vec(size, Vector3(39.5, 0.22, 4.2))
		var old_branch: bool = _near_vec(size, Vector3(3.0, 0.24, 5.2))
		var old_strip: bool = _near_vec(size, Vector3(1.35, 0.03, 0.10))
		var old_side_barrier: bool = _near_vec(size, Vector3(0.4, 2.3, 22.0))
		if old_corridor or old_branch or old_strip or old_side_barrier:
			mesh_instance.queue_free()

func _snap_rooms_into_hull(rooms: Node3D) -> void:
	for index: int in range(ROOM_ORDER.size()):
		var room_id: String = ROOM_ORDER[index]
		var room: Node3D = rooms.get_node_or_null("Room_%s" % room_id) as Node3D
		if room == null:
			continue
		var column: int = index % 4
		var south_row: bool = index >= 4
		room.position = Vector3(X_POSITIONS[column], 0.0, SOUTH_Z if south_row else NORTH_Z)
		room.rotation.y = PI if south_row else 0.0

func _remove_individual_room_walls(rooms: Node3D) -> void:
	for room_node: Node in rooms.get_children():
		if not room_node is Node3D:
			continue
		var room := room_node as Node3D
		for child: Node in room.get_children():
			if child is Label3D and child.name == "RoomLabel":
				(child as Label3D).visible = false
				continue
			if not child is MeshInstance3D:
				continue
			var mesh_instance := child as MeshInstance3D
			if not mesh_instance.mesh is BoxMesh:
				continue
			var size: Vector3 = (mesh_instance.mesh as BoxMesh).size
			var back_wall: bool = size.y > 3.0 and size.x > 7.5 and size.z < 0.4
			var side_wall: bool = size.y > 3.0 and size.x < 0.4 and size.z > 6.5
			var backdrop_frame: bool = size.y > 2.8 and size.x > 7.0 and size.z < 0.2
			if back_wall or side_wall or backdrop_frame:
				mesh_instance.queue_free()

func _build_shared_hull(world: Node3D) -> void:
	var previous: Node = world.get_node_or_null("SharedStationHull")
	if previous != null:
		previous.queue_free()
	hull_root = Node3D.new()
	hull_root.name = "SharedStationHull"
	hull_root.set_meta("shared_walls", true)
	hull_root.set_meta("automatic_doors", 8)
	world.add_child(hull_root)
	_build_deck()
	_build_outer_hull()
	_build_shared_partitions()
	_build_corridor_bulkheads()
	_build_ceiling_ribs()
	_build_utilities()
	_build_airlocks()

func _build_deck() -> void:
	hull_root.add_child(_box(Vector3(34.6, 0.22, 18.8), Vector3(0.0, -0.04, 0.0), "#172736", 0.0, "StationDeck"))
	hull_root.add_child(_box(Vector3(34.3, 0.12, 4.0), Vector3(0.0, 0.11, 0.0), "#294960", 0.02, "CentralCorridor"))
	for panel_index: int in range(16):
		var x: float = -16.0 + float(panel_index) * 2.12
		hull_root.add_child(_box(Vector3(1.72, 0.025, 3.62), Vector3(x, 0.19, 0.0), "#31566D" if panel_index % 2 == 0 else "#27485E", 0.0, "CorridorPanel"))
	for rail_z: float in [-1.76, 1.76]:
		hull_root.add_child(_box(Vector3(34.2, 0.08, 0.10), Vector3(0.0, 0.23, rail_z), "#61E2F8", 0.55, "GuideLight"))

func _build_outer_hull() -> void:
	var wall_color: String = "#243746"
	hull_root.add_child(_box(Vector3(34.6, WALL_HEIGHT, 0.32), Vector3(0.0, 1.9, -9.3), wall_color, 0.0, "NorthHull"))
	hull_root.add_child(_box(Vector3(34.6, WALL_HEIGHT, 0.32), Vector3(0.0, 1.9, 9.3), wall_color, 0.0, "SouthHull"))
	hull_root.add_child(_box(Vector3(0.32, WALL_HEIGHT, 18.9), Vector3(-17.3, 1.9, 0.0), wall_color, 0.0, "WestHull"))
	hull_root.add_child(_box(Vector3(0.32, WALL_HEIGHT, 18.9), Vector3(17.3, 1.9, 0.0), wall_color, 0.0, "EastHull"))
	for x: float in X_POSITIONS:
		for z: float in [-9.12, 9.12]:
			hull_root.add_child(_box(Vector3(4.8, 0.62, 0.12), Vector3(x, 2.35, z), "#102A3A", 0.0, "HullWindowFrame"))
			hull_root.add_child(_box(Vector3(4.35, 0.34, 0.08), Vector3(x, 2.35, z - signf(z) * 0.08), "#5CD9F0", 0.22, "HullWindow"))

func _build_shared_partitions() -> void:
	for divider_x: float in [-8.6, 0.0, 8.6]:
		for row_z: float in [NORTH_Z, SOUTH_Z]:
			hull_root.add_child(_box(Vector3(0.24, WALL_HEIGHT, ROOM_DEPTH), Vector3(divider_x, 1.9, row_z), "#2A4050", 0.0, "SharedPartition"))
			for brace_z: float in [-2.5, 0.0, 2.5]:
				hull_root.add_child(_box(Vector3(0.38, 0.18, 0.7), Vector3(divider_x, 3.45, row_z + brace_z), "#5B7487", 0.0, "PartitionBrace"))

func _build_corridor_bulkheads() -> void:
	for index: int in range(ROOM_ORDER.size()):
		var room_id: String = ROOM_ORDER[index]
		var column: int = index % 4
		var south_row: bool = index >= 4
		var x: float = X_POSITIONS[column]
		var z: float = CORRIDOR_HALF if south_row else -CORRIDOR_HALF
		var accent: Color = _room_accent(room_id)
		var segment_width: float = 3.12
		for side: float in [-1.0, 1.0]:
			var segment_x: float = x + side * 2.72
			hull_root.add_child(_box(Vector3(segment_width, WALL_HEIGHT, 0.26), Vector3(segment_x, 1.9, z), "#263D4C", 0.0, "CorridorBulkhead"))
		hull_root.add_child(_box(Vector3(2.32, 0.78, 0.26), Vector3(x, 3.41, z), "#263D4C", 0.0, "DoorLintel"))
		var door := StationDoor.new()
		door.position = Vector3(x, 0.0, z)
		door.configure(room_id, accent, not bool(PrecinctState.get_room(room_id).get("repaired", false)))
		hull_root.add_child(door)
		for light_x: float in [-3.75, 3.75]:
			hull_root.add_child(_box(Vector3(0.34, 0.12, 0.10), Vector3(x + light_x, 3.34, z - signf(z) * 0.18), accent.to_html(false), 0.8, "DoorGuide"))

func _build_ceiling_ribs() -> void:
	for x: float in [-17.2, -12.9, -8.6, -4.3, 0.0, 4.3, 8.6, 12.9, 17.2]:
		hull_root.add_child(_box(Vector3(0.24, 0.28, 18.4), Vector3(x, 3.82, 0.0), "#435B6C", 0.0, "HullRib"))
	for z: float in [-9.2, -2.1, 2.1, 9.2]:
		hull_root.add_child(_box(Vector3(34.4, 0.24, 0.24), Vector3(0.0, 3.82, z), "#435B6C", 0.0, "CrossRib"))
	for x: float in X_POSITIONS:
		hull_root.add_child(_box(Vector3(3.8, 0.08, 0.18), Vector3(x, 3.66, 0.0), "#B9F7FF", 0.55, "CorridorCeilingLight"))

func _build_utilities() -> void:
	for row_z: float in [-8.92, 8.92]:
		for y: float in [0.72, 1.12, 1.52]:
			var pipe := _cylinder(0.09, 33.5, Vector3(0.0, y, row_z), "#597387", 0.0, "UtilityPipe")
			pipe.rotation_degrees.z = 90.0
			hull_root.add_child(pipe)
	for x: float in [-15.4, -6.8, 1.8, 10.4]:
		for z: float in [-9.08, 9.08]:
			hull_root.add_child(_box(Vector3(1.2, 0.72, 0.12), Vector3(x, 1.25, z - signf(z) * 0.12), "#151F28", 0.0, "VentPanel"))
			for slit: int in range(5):
				hull_root.add_child(_box(Vector3(0.10, 0.48, 0.04), Vector3(x - 0.42 + float(slit) * 0.21, 1.25, z - signf(z) * 0.19), "#6A879A", 0.0, "VentSlit"))

func _build_airlocks() -> void:
	var east_airlock := StationDoor.new()
	east_airlock.position = Vector3(17.28, 0.0, SOUTH_Z)
	east_airlock.rotation.y = PI * 0.5
	east_airlock.configure("PATROL AIRLOCK", Color("#56E8FF"), false)
	hull_root.add_child(east_airlock)
	for ring_index: int in range(3):
		var frame := _box(Vector3(0.20, 3.6 - float(ring_index) * 0.34, 4.2 - float(ring_index) * 0.36), Vector3(18.0 + float(ring_index) * 0.38, 1.8, SOUTH_Z), "#365264", 0.0, "AirlockFrame")
		hull_root.add_child(frame)

func _room_accent(room_id: String) -> Color:
	var accents: Dictionary = {
		"ops": Color("#00C8FF"), "armory": Color("#FF9E22"), "cells": Color("#5A9DFF"),
		"quarters": Color("#FFD18A"), "medbay": Color("#44FFBF"), "chief": Color("#FFD447"),
		"interrogation": Color("#B75CFF"), "transfer": Color("#3FD0FF")
	}
	return accents.get(room_id, Color("#56DFFF")) as Color

func _near_vec(value: Vector3, expected: Vector3, tolerance: float = 0.08) -> bool:
	return absf(value.x - expected.x) <= tolerance and absf(value.y - expected.y) <= tolerance and absf(value.z - expected.z) <= tolerance

func _box(size_value: Vector3, position_value: Vector3, color_hex: String, emission: float, node_name: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex, emission)
	return node

func _cylinder(radius_value: float, height_value: float, position_value: Vector3, color_hex: String, emission: float, node_name: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius_value
	mesh.bottom_radius = radius_value
	mesh.height = height_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex, emission)
	return node

func _material(color_hex: String, emission: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var color := Color.from_string(color_hex, Color.WHITE)
	material.albedo_color = color
	material.metallic = 0.28
	material.roughness = 0.44
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material
