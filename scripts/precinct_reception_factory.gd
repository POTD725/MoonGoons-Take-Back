class_name PrecinctReceptionFactory
extends RefCounted
## Procedural 3D Reception interior with a public entrance, intake counter,
## screening arch, report terminals, waiting seats, and clickable collision.

const ROOM_SIZE := Vector3(9.8, 3.8, 7.6)
const ACCENT := "#66F0FF"

static func build_room(room_data: Dictionary) -> Node3D:
	var repaired: bool = bool(room_data.get("repaired", false))
	var level: int = int(room_data.get("level", 1))
	var root := Node3D.new()
	root.name = "Room_reception"
	root.set_meta("room_id", "reception")
	root.set_meta("clickable", true)
	_add_shell(root, repaired)
	_add_intake_counter(root, repaired)
	_add_screening_arch(root, repaired)
	_add_waiting_area(root, repaired)
	_add_case_terminals(root, repaired)
	_add_label(root, repaired, level)
	_add_click_area(root)
	if not repaired:
		_add_damage(root)
	return root

static func _add_shell(root: Node3D, repaired: bool) -> void:
	root.add_child(_box(Vector3(ROOM_SIZE.x, 0.28, ROOM_SIZE.z), Vector3.ZERO, "#163548", 0.03))
	root.add_child(_box(Vector3(ROOM_SIZE.x, ROOM_SIZE.y, 0.25), Vector3(0, 1.9, -3.8), "#203D4D", 0.0))
	root.add_child(_box(Vector3(0.25, ROOM_SIZE.y, ROOM_SIZE.z), Vector3(-4.9, 1.9, 0), "#203D4D", 0.0))
	root.add_child(_box(Vector3(0.25, ROOM_SIZE.y, ROOM_SIZE.z), Vector3(4.9, 1.9, 0), "#203D4D", 0.0))
	root.add_child(_box(Vector3(9.1, 0.09, 0.12), Vector3(0, 3.45, -3.62), ACCENT, 0.72 if repaired else 0.03))
	for x: float in [-3.5, -1.75, 0.0, 1.75, 3.5]:
		root.add_child(_box(Vector3(0.08, 0.03, 6.8), Vector3(x, 0.16, 0), ACCENT, 0.13 if repaired else 0.01))
	_marker(root, "Door", Vector3(0, 0, 4.1))
	_marker(root, "Center", Vector3(0, 0, 0.6))
	_marker(root, "Idle", Vector3(-3.8, 0, 2.5))

static func _add_intake_counter(root: Node3D, repaired: bool) -> void:
	root.add_child(_box(Vector3(6.7, 0.92, 1.15), Vector3(0, 0.58, -0.55), "#35566A", 0.0))
	root.add_child(_box(Vector3(6.25, 0.13, 1.28), Vector3(0, 1.08, -0.55), "#7395A6", 0.0))
	for x: float in [-2.15, 0.0, 2.15]:
		root.add_child(_box(Vector3(1.35, 0.62, 0.08), Vector3(x, 1.43, -1.08), ACCENT, 0.52 if repaired else 0.02))
		_marker(root, "Job%d" % int((x + 2.15) / 2.15), Vector3(x, 0, -1.82))
	_marker(root, "Visitor", Vector3(0, 0, 1.35))

static func _add_screening_arch(root: Node3D, repaired: bool) -> void:
	for x: float in [-1.28, 1.28]:
		root.add_child(_box(Vector3(0.35, 2.65, 0.45), Vector3(x, 1.43, 2.65), "#29485A", 0.0))
	root.add_child(_box(Vector3(2.9, 0.34, 0.45), Vector3(0, 2.72, 2.65), "#29485A", 0.0))
	root.add_child(_box(Vector3(2.25, 0.12, 0.18), Vector3(0, 2.52, 2.87), ACCENT, 0.62 if repaired else 0.02))
	for y: float in [0.65, 1.25, 1.85]:
		root.add_child(_box(Vector3(0.10, 0.26, 0.14), Vector3(-1.02, y, 2.91), ACCENT, 0.38 if repaired else 0.01))

static func _add_waiting_area(root: Node3D, repaired: bool) -> void:
	for side: float in [-1.0, 1.0]:
		for index: int in range(3):
			var z: float = -2.25 + float(index) * 1.15
			root.add_child(_box(Vector3(1.25, 0.26, 0.72), Vector3(side * 3.85, 0.42, z), "#657B88", 0.0))
			root.add_child(_box(Vector3(1.25, 0.78, 0.18), Vector3(side * 3.85, 0.83, z - 0.28), "#516874", 0.0))
			if repaired:
				root.add_child(_box(Vector3(0.88, 0.05, 0.08), Vector3(side * 3.85, 0.62, z + 0.38), ACCENT, 0.12))

static func _add_case_terminals(root: Node3D, repaired: bool) -> void:
	for side: float in [-1.0, 1.0]:
		root.add_child(_box(Vector3(1.25, 1.45, 0.48), Vector3(side * 3.55, 1.05, -3.35), "#193341", 0.0))
		root.add_child(_box(Vector3(0.95, 0.62, 0.08), Vector3(side * 3.55, 1.27, -3.08), ACCENT, 0.46 if repaired else 0.02))

static func _add_label(root: Node3D, repaired: bool, level: int) -> void:
	var label := Label3D.new()
	label.name = "RoomLabel"
	label.text = "RECEPTION  L%d" % level
	label.position = Vector3(0, 3.66, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label.fixed_size = true
	label.font_size = 19
	label.outline_size = 5
	label.modulate = Color(ACCENT) if repaired else Color("#FF7A96")
	root.add_child(label)

static func _add_click_area(root: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "ClickArea"
	body.set_meta("room_id", "reception")
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(9.6, 3.7, 7.4)
	collision.position = Vector3(0, 1.85, 0)
	collision.shape = shape
	body.add_child(collision)
	root.add_child(body)

static func _add_damage(root: Node3D) -> void:
	for index: int in range(4):
		root.add_child(_sphere(0.13 + index * 0.02, Vector3(-3.0 + index * 1.9, 0.55 + (index % 2), -1.8 + (index % 3)), "#FF5B68", 0.55))
	var smoke := _sphere(0.62, Vector3(3.5, 2.65, -2.8), "#292631", 0.0)
	smoke.transparency = 0.52
	root.add_child(smoke)

static func _marker(root: Node3D, marker_name: String, marker_position: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = marker_name
	marker.position = marker_position
	root.add_child(marker)

static func _box(size_value: Vector3, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex, emission)
	return node

static func _sphere(radius_value: float, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius_value
	mesh.height = radius_value * 2.0
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex, emission)
	return node

static func _material(color_hex: String, emission: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var color := Color(color_hex)
	material.albedo_color = color
	material.roughness = 0.56
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material
