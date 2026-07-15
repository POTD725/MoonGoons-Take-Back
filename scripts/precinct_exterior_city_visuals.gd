extends Node
## Distinct exterior station buildings for City View. Interior rooms remain below
## the removable shells and are revealed when Equipment mode is selected.

const ACCENTS: Dictionary = {
	"ops":"#45DFFF", "armory":"#FFAA43", "cells":"#72A8FF", "quarters":"#FFD188",
	"medbay":"#54F1C2", "chief":"#FFE26A", "interrogation":"#C47BFF", "transfer":"#61E1FF"
}

var precinct: Node3D
var world: Node3D
var exterior_root: Node3D
var refresh_clock: float = 0.0
var last_mode: String = ""

func _ready() -> void:
	precinct = get_parent() as Node3D
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(30):
		await get_tree().process_frame
	if precinct == null:
		return
	world = precinct.get_node_or_null("LivingPrecinctWorld") as Node3D
	if world == null:
		return
	_build_exteriors()
	if not PrecinctState.state_changed.is_connected(_delayed_rebuild):
		PrecinctState.state_changed.connect(_delayed_rebuild)
	_update_mode()

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock < 0.20:
		return
	refresh_clock = 0.0
	_update_mode()

func _update_mode() -> void:
	if exterior_root == null:
		return
	var ribbon: Node = precinct.get_node_or_null("CompactCommandRibbon")
	var mode: String = String(ribbon.get("active_command")) if ribbon != null else "city"
	if mode == last_mode:
		return
	last_mode = mode
	# Equipment reveals the actual room interiors and 3D upgrade models.
	exterior_root.visible = mode != "equipment"

func _build_exteriors() -> void:
	if exterior_root != null:
		exterior_root.queue_free()
	exterior_root = Node3D.new()
	exterior_root.name = "ExteriorCityModules"
	world.add_child(exterior_root)
	var rooms_value: Variant = precinct.get("room_nodes")
	if not rooms_value is Dictionary:
		return
	var room_nodes: Dictionary = rooms_value as Dictionary
	for room_value: Variant in room_nodes.keys():
		var room_id: String = String(room_value)
		var room_node: Node3D = room_nodes.get(room_id) as Node3D
		if room_node == null:
			continue
		var module: Node3D = _build_module(room_id, PrecinctState.get_room(room_id))
		module.position = room_node.position
		module.rotation.y = room_node.rotation.y
		exterior_root.add_child(module)

func _build_module(room_id: String, room: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "Building_%s" % room_id
	root.set_meta("room_id", room_id)
	var repaired: bool = bool(room.get("repaired", false))
	var level: int = int(room.get("level", 1))
	var accent: String = String(ACCENTS.get(room_id, "#5DE5FF"))
	var body: String = "#263C4B" if repaired else "#292B31"
	var trim: String = "#5B7485" if repaired else "#4A3B42"
	# Raised foundation, armored walls, roof and forward airlock make each room read as a building.
	root.add_child(_box(Vector3(9.1, 0.42, 7.7), Vector3(0, 0.10, 0), "#111D27", 0.0))
	root.add_child(_box(Vector3(8.55, 3.45, 6.75), Vector3(0, 1.90, -0.22), body, 0.0))
	root.add_child(_box(Vector3(8.92, 0.36, 7.10), Vector3(0, 3.72, -0.22), trim, 0.0))
	root.add_child(_box(Vector3(2.50, 2.28, 0.54), Vector3(0, 1.26, 3.34), "#142733", 0.0))
	root.add_child(_box(Vector3(1.72, 1.82, 0.20), Vector3(0, 1.08, 3.65), accent, 0.25 if repaired else 0.02))
	for x: float in [-3.25, -1.62, 1.62, 3.25]:
		root.add_child(_box(Vector3(1.05, 0.42, 0.10), Vector3(x, 2.32, 3.22), accent, 0.22 if repaired else 0.01))
	for side: float in [-1.0, 1.0]:
		root.add_child(_box(Vector3(0.32, 3.15, 6.95), Vector3(side * 4.30, 1.82, -0.20), trim, 0.0))
	_add_identity_shape(root, room_id, accent, repaired)
	_add_level_array(root, level, accent, repaired)
	_add_sign(root, room_id, level, accent, repaired)
	if not repaired:
		_add_damage(root)
	return root

func _add_identity_shape(root: Node3D, room_id: String, accent: String, repaired: bool) -> void:
	match room_id:
		"ops":
			root.add_child(_cylinder(1.12, 1.05, Vector3(0, 4.28, -0.5), "#1A3443", 0.0))
			root.add_child(_sphere(0.72, Vector3(0, 5.04, -0.5), accent, 0.35 if repaired else 0.02))
			for y: float in [4.48, 4.82, 5.16]:
				root.add_child(_torus(1.12, 0.08, Vector3(0, y, -0.5), accent, 0.38 if repaired else 0.01))
		"armory":
			for side: float in [-1.0, 1.0]:
				root.add_child(_box(Vector3(2.15, 1.24, 2.40), Vector3(side * 4.32, 1.02, -0.7), "#3C3228", 0.0))
			root.add_child(_cylinder(0.78, 0.62, Vector3(0, 4.18, -0.4), "#2B3035", 0.0))
			var barrel := _cylinder(0.12, 2.2, Vector3(0, 4.32, -1.45), accent, 0.20 if repaired else 0.0)
			barrel.rotation_degrees.x = 90.0
			root.add_child(barrel)
		"cells":
			for x: float in [-3.15, -1.58, 0.0, 1.58, 3.15]:
				root.add_child(_box(Vector3(0.38, 3.70, 0.48), Vector3(x, 2.02, 3.18), "#152433", 0.0))
			for y: float in [0.75, 1.55, 2.35, 3.15]:
				root.add_child(_box(Vector3(7.45, 0.10, 0.12), Vector3(0, y, 3.48), accent, 0.14 if repaired else 0.01))
		"quarters":
			for x: float in [-2.35, 2.35]:
				var dome := _sphere(1.42, Vector3(x, 4.03, -0.3), "#385364", 0.0)
				dome.scale.y = 0.55
				root.add_child(dome)
				root.add_child(_box(Vector3(1.95, 0.46, 0.10), Vector3(x, 2.15, 3.30), accent, 0.22 if repaired else 0.01))
		"medbay":
			root.add_child(_cylinder(1.15, 1.45, Vector3(0, 4.35, -0.4), "#E3F5F2", 0.0))
			root.add_child(_box(Vector3(0.54, 1.62, 0.18), Vector3(0, 4.55, 0.77), accent, 0.42 if repaired else 0.02))
			root.add_child(_box(Vector3(1.62, 0.54, 0.18), Vector3(0, 4.55, 0.77), accent, 0.42 if repaired else 0.02))
		"chief":
			root.add_child(_box(Vector3(3.35, 2.15, 3.20), Vector3(0, 4.72, -0.6), "#303B50", 0.0))
			root.add_child(_box(Vector3(2.62, 0.42, 0.12), Vector3(0, 4.82, 1.02), accent, 0.42 if repaired else 0.02))
			root.add_child(_cylinder(0.18, 2.35, Vector3(0, 6.72, -0.6), "#9BAAB2", 0.0))
			root.add_child(_sphere(0.28, Vector3(0, 7.86, -0.6), accent, 0.75 if repaired else 0.02))
		"interrogation":
			root.add_child(_cylinder(1.22, 0.52, Vector3(0, 4.08, -0.4), "#252035", 0.0))
			var dish := _sphere(1.15, Vector3(0, 4.75, -0.4), accent, 0.24 if repaired else 0.01)
			dish.scale = Vector3(1.0, 0.28, 1.0)
			dish.rotation_degrees.x = 18.0
			root.add_child(dish)
			root.add_child(_sphere(0.18, Vector3(0, 5.32, -0.12), "#FFD8FF", 0.78 if repaired else 0.02))
		"transfer":
			root.add_child(_box(Vector3(6.65, 2.55, 2.45), Vector3(0, 1.42, 3.30), "#18313E", 0.0))
			root.add_child(_box(Vector3(5.52, 1.65, 0.18), Vector3(0, 1.22, 4.58), accent, 0.20 if repaired else 0.01))
			for x: float in [-2.48, 2.48]:
				root.add_child(_cylinder(0.32, 1.18, Vector3(x, 4.28, -0.6), accent, 0.20 if repaired else 0.01))

func _add_level_array(root: Node3D, level: int, accent: String, repaired: bool) -> void:
	var active_count: int = clampi(int(ceil(float(level) / 20.0)), 1, 5)
	for index: int in range(5):
		root.add_child(_box(Vector3(0.58, 0.10, 0.10), Vector3(-1.44 + index * 0.72, 3.62, 3.44), accent if index < active_count else "#18222A", 0.55 if repaired and index < active_count else 0.0))

func _add_sign(root: Node3D, room_id: String, level: int, accent: String, repaired: bool) -> void:
	var label := Label3D.new()
	label.name = "ExteriorSign"
	label.text = "%s  //  LEVEL %d" % [room_id.replace("_", " ").to_upper(), level]
	label.position = Vector3(0, 3.16, 3.62)
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label.font_size = 28
	label.outline_size = 7
	label.modulate = Color(accent) if repaired else Color("FF7890")
	root.add_child(label)

func _add_damage(root: Node3D) -> void:
	for index: int in range(4):
		root.add_child(_sphere(0.13 + index * 0.03, Vector3(-2.6 + index * 1.7, 3.85 + (index % 2) * 0.45, 1.8 - index * 0.4), "#FF5A6B", 0.65))
	var smoke := _sphere(0.72, Vector3(2.8, 4.30, -1.7), "#25232B", 0.0)
	smoke.transparency = 0.48
	root.add_child(smoke)

func _delayed_rebuild() -> void:
	call_deferred("_wait_rebuild")

func _wait_rebuild() -> void:
	for _frame: int in range(4):
		await get_tree().process_frame
	_build_exteriors()
	_update_mode()

func _box(size_value: Vector3, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex, emission)
	return node

func _sphere(radius_value: float, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius_value
	mesh.height = radius_value * 2.0
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex, emission)
	return node

func _cylinder(radius_value: float, height_value: float, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius_value
	mesh.bottom_radius = radius_value
	mesh.height = height_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex, emission)
	return node

func _torus(radius_value: float, tube_radius: float, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = maxf(0.05, radius_value - tube_radius)
	mesh.outer_radius = radius_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex, emission)
	return node

func _material(color_hex: String, emission: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var color := Color.from_string(color_hex, Color.WHITE)
	material.albedo_color = color
	material.roughness = 0.58
	material.metallic = 0.24
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material
