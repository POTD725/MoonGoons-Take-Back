extends Node
## Builds visible exterior defense hardware and marauder-wave ships.

var precinct: Node3D
var world: Node3D
var defense_root: Node3D
var turret_heads: Array[Node3D] = []
var marauder_ships: Array[Node3D] = []
var animation_clock: float = 0.0

func _ready() -> void:
	precinct = get_parent() as Node3D
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(18):
		await get_tree().process_frame
	if precinct == null:
		return
	world = precinct.get_node_or_null("LivingPrecinctWorld") as Node3D
	if world == null:
		return
	if not StationProgression.progression_changed.is_connected(_rebuild):
		StationProgression.progression_changed.connect(_rebuild)
	if not StationProgression.marauder_alert.is_connected(_rebuild):
		StationProgression.marauder_alert.connect(_rebuild)
	_rebuild()

func _process(delta: float) -> void:
	animation_clock += delta
	for index: int in range(turret_heads.size()):
		var head: Node3D = turret_heads[index]
		if is_instance_valid(head):
			head.rotation.y += delta * (0.25 + float(index % 3) * 0.08)
	for index: int in range(marauder_ships.size()):
		var ship: Node3D = marauder_ships[index]
		if not is_instance_valid(ship):
			continue
		var angle: float = animation_clock * (0.08 + float(index % 3) * 0.015) + float(index) * 0.9
		var radius: float = 31.0 + float(index % 2) * 4.0
		ship.position.x = cos(angle) * radius
		ship.position.z = sin(angle) * radius
		ship.position.y = 5.0 + sin(angle * 2.0) * 1.4
		ship.look_at(Vector3.ZERO, Vector3.UP)

func _rebuild() -> void:
	if world == null:
		return
	var previous: Node = world.get_node_or_null("StationDefenseVisuals")
	if previous != null:
		previous.queue_free()
	defense_root = Node3D.new()
	defense_root.name = "StationDefenseVisuals"
	defense_root.set_meta("defense_systems", 4)
	world.add_child(defense_root)
	turret_heads.clear()
	marauder_ships.clear()
	_build_point_defense()
	_build_rail_batteries()
	_build_shield_grid()
	_build_interceptor_bay()
	_build_marauder_wave()

func _build_point_defense() -> void:
	var level: int = StationProgression.defense_level("point_defense")
	var positions: Array[Vector3] = [
		Vector3(-16.2, 4.1, -8.1), Vector3(16.2, 4.1, -8.1),
		Vector3(-16.2, 4.1, 8.1), Vector3(16.2, 4.1, 8.1),
		Vector3(0.0, 4.1, -9.0), Vector3(0.0, 4.1, 9.0)
	]
	var count: int = mini(positions.size(), 3 + level)
	for index: int in range(count):
		var turret := Node3D.new()
		turret.name = "PointDefense_%02d" % index
		turret.position = positions[index]
		defense_root.add_child(turret)
		turret.add_child(_cylinder(0.65, 0.46, Vector3.ZERO, "#31495D", 0.0))
		var head := Node3D.new()
		head.name = "TurretHead"
		head.position.y = 0.48
		turret.add_child(head)
		head.add_child(_box(Vector3(1.35, 0.45, 0.92), Vector3.ZERO, "#496A82", 0.0))
		for barrel_x: float in [-0.33, 0.33]:
			var barrel := _cylinder(0.10, 1.7 + float(level) * 0.10, Vector3(barrel_x, 0.0, -1.05), "#89E8FF", 0.25)
			barrel.rotation_degrees.x = 90.0
			head.add_child(barrel)
		head.add_child(_sphere(0.17, Vector3(0.0, 0.28, -0.25), "#63F4FF", 0.85))
		turret_heads.append(head)

func _build_rail_batteries() -> void:
	var level: int = StationProgression.defense_level("rail_battery")
	for side: float in [-1.0, 1.0]:
		var battery := Node3D.new()
		battery.name = "RailBattery_%s" % ("West" if side < 0.0 else "East")
		battery.position = Vector3(side * 20.2, 2.6, -1.5)
		battery.rotation_degrees.y = -90.0 if side < 0.0 else 90.0
		defense_root.add_child(battery)
		battery.add_child(_box(Vector3(4.2, 1.1, 2.6), Vector3.ZERO, "#263A4C", 0.0))
		battery.add_child(_box(Vector3(1.4, 0.6, 6.5 + float(level) * 0.55), Vector3(0.0, 0.45, -3.0), "#617F91", 0.0))
		battery.add_child(_box(Vector3(0.42, 0.22, 6.8 + float(level) * 0.55), Vector3(0.0, 0.55, -3.2), "#FFCB68", 0.5))
		battery.add_child(_sphere(0.28, Vector3(0.0, 0.55, -6.6), "#FF9E42", 0.9))

func _build_shield_grid() -> void:
	var level: int = StationProgression.defense_level("shield_grid")
	var positions: Array[Vector3] = [
		Vector3(-19.0, 1.0, -7.0), Vector3(19.0, 1.0, -7.0),
		Vector3(-19.0, 1.0, 7.0), Vector3(19.0, 1.0, 7.0)
	]
	for index: int in range(positions.size()):
		var generator := Node3D.new()
		generator.name = "ShieldGenerator_%02d" % index
		generator.position = positions[index]
		defense_root.add_child(generator)
		generator.add_child(_cylinder(0.75, 1.3, Vector3.ZERO, "#243B50", 0.0))
		for ring_index: int in range(2 + mini(2, level)):
			var ring := _torus(0.8 + float(ring_index) * 0.3, 0.08, Vector3(0.0, 0.65 + float(ring_index) * 0.22, 0.0), "#55E9FF", 0.7)
			generator.add_child(ring)
		generator.add_child(_sphere(0.30, Vector3(0.0, 1.45, 0.0), "#A7F6FF", 0.95))

func _build_interceptor_bay() -> void:
	var level: int = StationProgression.defense_level("interceptor_bay")
	var bay := Node3D.new()
	bay.name = "InterceptorBay"
	bay.position = Vector3(25.2, 0.5, -7.0)
	defense_root.add_child(bay)
	bay.add_child(_cylinder(5.0, 0.35, Vector3.ZERO, "#20374A", 0.0))
	for line_index: int in range(4):
		bay.add_child(_box(Vector3(8.4, 0.04, 0.10), Vector3(0.0, 0.22, -2.4 + float(line_index) * 1.6), "#5CDFFF", 0.6))
	var ship_count: int = mini(8, 2 + level)
	for index: int in range(ship_count):
		var ship := _interceptor_model("#3E8FB8", "#72EEFF")
		ship.name = "Interceptor_%02d" % index
		ship.position = Vector3(-3.2 + float(index % 4) * 2.1, 0.55, -1.7 + float(index / 4) * 3.3)
		bay.add_child(ship)

func _build_marauder_wave() -> void:
	if StationProgression.active_marauder_wave.is_empty():
		defense_root.set_meta("marauder_visuals", 0)
		return
	var ships: int = int(StationProgression.active_marauder_wave.get("ships", 3))
	defense_root.set_meta("marauder_visuals", ships)
	for index: int in range(ships):
		var ship := _interceptor_model("#6E2535", "#FF5577")
		ship.name = "Marauder_%02d" % index
		ship.scale = Vector3(1.35, 1.35, 1.35)
		defense_root.add_child(ship)
		marauder_ships.append(ship)

func _interceptor_model(body_color: String, glow_color: String) -> Node3D:
	var ship := Node3D.new()
	ship.add_child(_box(Vector3(2.2, 0.38, 1.0), Vector3.ZERO, body_color, 0.0))
	ship.add_child(_box(Vector3(1.1, 0.30, 2.8), Vector3(0.0, 0.05, 0.0), body_color, 0.0))
	ship.add_child(_box(Vector3(3.7, 0.12, 0.55), Vector3(0.0, 0.0, 0.3), body_color, 0.0))
	ship.add_child(_sphere(0.24, Vector3(0.0, 0.25, -0.5), glow_color, 0.8))
	for engine_x: float in [-0.65, 0.65]:
		ship.add_child(_sphere(0.14, Vector3(engine_x, 0.0, 1.35), glow_color, 1.0))
	return ship

func _box(size_value: Vector3, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
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

func _sphere(radius_value: float, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius_value
	mesh.height = radius_value * 2.0
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex, emission)
	return node

func _torus(radius_value: float, tube_radius: float, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = maxf(0.1, radius_value - tube_radius)
	mesh.outer_radius = radius_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex, emission)
	return node

func _material(color_hex: String, emission: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var color := Color.from_string(color_hex, Color.WHITE)
	material.albedo_color = color
	material.roughness = 0.48
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material
