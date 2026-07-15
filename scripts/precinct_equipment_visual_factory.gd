class_name PrecinctEquipmentVisualFactory
extends RefCounted
## Procedural 3D graphics for all 24 upgradeable room items.
## Every item supports five visual options while retaining its gameplay identity.

const PALETTES: Array[Dictionary] = [
	{"body":"#29465B", "trim":"#769CB2", "accent":"#5DE5FF", "dark":"#101A24", "warm":"#FFD16E"},
	{"body":"#4B4034", "trim":"#9C8060", "accent":"#FFB454", "dark":"#211B16", "warm":"#FFE3A8"},
	{"body":"#252D38", "trim":"#596979", "accent":"#FF617E", "dark":"#0D1218", "warm":"#FFC0CB"},
	{"body":"#203F49", "trim":"#6AA7B5", "accent":"#68F3D0", "dark":"#0A2026", "warm":"#C8FFF1"},
	{"body":"#392653", "trim":"#8A67B2", "accent":"#C97CFF", "dark":"#160D23", "warm":"#F1D7FF"}
]

static func build(item_id: String, level: int, variant: int = 1) -> Node3D:
	var root := Node3D.new()
	root.name = "EquipmentModel"
	root.set_meta("equipment_id", item_id)
	root.set_meta("variant", clampi(variant, 1, 5))
	root.set_meta("level", clampi(level, 1, 100))
	var palette: Dictionary = PALETTES[clampi(variant, 1, 5) - 1]
	match item_id:
		"command_table", "command_desk", "restraint_table":
			_build_table(root, palette, item_id)
		"dispatch_console", "intake_terminal", "morale_console", "trauma_console", "evidence_console", "transport_console":
			_build_console(root, palette, item_id)
		"holo_map", "strategy_wall", "authority_uplink":
			_build_holographic(root, palette, item_id)
		"weapon_racks", "ammo_loader":
			_build_rack(root, palette, item_id)
		"armor_forge":
			_build_forge(root, palette)
		"cell_locks", "airlock_gate":
			_build_gate(root, palette, item_id)
		"security_scanner", "diagnostic_scanner", "truth_scanner", "prisoner_scanner":
			_build_scanner(root, palette, item_id)
		"bunks":
			_build_bunks(root, palette)
		"mess_station":
			_build_mess(root, palette)
		"med_pods":
			_build_med_pods(root, palette)
		_:
			_build_console(root, palette, item_id)
	_add_variant_details(root, palette, clampi(variant, 1, 5))
	_add_level_lights(root, palette, level)
	var scale_value: float = 0.78 + minf(float(level), 100.0) * 0.0024
	root.scale = Vector3.ONE * scale_value
	return root

static func _build_table(root: Node3D, p: Dictionary, item_id: String) -> void:
	var width: float = 2.45 if item_id == "restraint_table" else 2.15
	root.add_child(_box(Vector3(width, 0.18, 1.18), Vector3(0, 0.92, 0), _c(p, "body"), 0.0))
	root.add_child(_box(Vector3(width - 0.16, 0.09, 1.02), Vector3(0, 1.05, 0), _c(p, "trim"), 0.0))
	for x: float in [-0.78, 0.78]:
		for z: float in [-0.36, 0.36]:
			root.add_child(_box(Vector3(0.16, 0.84, 0.16), Vector3(x, 0.47, z), _c(p, "dark"), 0.0))
	if item_id == "command_table":
		root.add_child(_cylinder(0.48, 0.08, Vector3(0, 1.17, 0), _c(p, "accent"), 0.65))
		var globe := _sphere(0.24, Vector3(0, 1.48, 0), _c(p, "accent"), 0.42)
		globe.transparency = 0.35
		root.add_child(globe)
	elif item_id == "command_desk":
		var screen := _box(Vector3(0.98, 0.58, 0.07), Vector3(0, 1.36, -0.38), _c(p, "accent"), 0.58)
		screen.rotation_degrees.x = -12.0
		root.add_child(screen)
	else:
		for x: float in [-0.72, 0.72]:
			root.add_child(_cylinder(0.08, 0.45, Vector3(x, 1.28, 0), _c(p, "trim"), 0.0))
			root.add_child(_box(Vector3(0.34, 0.12, 0.42), Vector3(x, 1.47, 0), _c(p, "dark"), 0.0))

static func _build_console(root: Node3D, p: Dictionary, item_id: String) -> void:
	root.add_child(_box(Vector3(1.78, 0.72, 0.92), Vector3(0, 0.48, 0), _c(p, "body"), 0.0))
	root.add_child(_box(Vector3(1.58, 0.18, 0.74), Vector3(0, 0.89, -0.06), _c(p, "trim"), 0.0))
	var screen := _box(Vector3(1.28, 0.58, 0.06), Vector3(0, 1.29, -0.34), _c(p, "accent"), 0.62)
	screen.rotation_degrees.x = -14.0
	root.add_child(screen)
	for x: float in [-0.55, 0.0, 0.55]:
		root.add_child(_sphere(0.07, Vector3(x, 0.92, 0.28), _c(p, "warm"), 0.55))
	if item_id in ["dispatch_console", "transport_console"]:
		for side: float in [-1.0, 1.0]:
			root.add_child(_box(Vector3(0.28, 0.95, 0.48), Vector3(side * 1.02, 0.58, 0), _c(p, "dark"), 0.0))
	elif item_id == "trauma_console":
		root.add_child(_cylinder(0.19, 0.64, Vector3(0.74, 1.1, 0.08), _c(p, "accent"), 0.25))
	elif item_id == "morale_console":
		for x: float in [-0.38, 0.0, 0.38]:
			root.add_child(_sphere(0.10, Vector3(x, 1.42, -0.30), _c(p, "warm"), 0.35))

static func _build_holographic(root: Node3D, p: Dictionary, item_id: String) -> void:
	root.add_child(_box(Vector3(1.9, 0.28, 0.92), Vector3(0, 0.32, 0), _c(p, "body"), 0.0))
	root.add_child(_cylinder(0.52, 0.12, Vector3(0, 0.55, 0), _c(p, "trim"), 0.0))
	if item_id == "strategy_wall":
		root.add_child(_box(Vector3(2.15, 1.52, 0.10), Vector3(0, 1.45, -0.34), _c(p, "dark"), 0.0))
		for index: int in range(4):
			var panel := _box(Vector3(0.42, 0.78, 0.04), Vector3(-0.72 + float(index) * 0.48, 1.48, -0.27), _c(p, "accent"), 0.38)
			root.add_child(panel)
	elif item_id == "authority_uplink":
		root.add_child(_cylinder(0.12, 1.42, Vector3(0, 1.18, 0), _c(p, "trim"), 0.0))
		for ring_y: float in [0.85, 1.25, 1.62]:
			root.add_child(_torus(0.36 + ring_y * 0.05, 0.06, Vector3(0, ring_y, 0), _c(p, "accent"), 0.48))
		root.add_child(_sphere(0.19, Vector3(0, 2.02, 0), _c(p, "warm"), 0.75))
	else:
		var globe := _sphere(0.52, Vector3(0, 1.18, 0), _c(p, "accent"), 0.48)
		globe.transparency = 0.48
		root.add_child(globe)
		for angle_index: int in range(3):
			var ring := _torus(0.64, 0.045, Vector3(0, 1.18, 0), _c(p, "accent"), 0.34)
			ring.rotation_degrees = Vector3(30.0 + angle_index * 25.0, angle_index * 60.0, 0.0)
			root.add_child(ring)

static func _build_rack(root: Node3D, p: Dictionary, item_id: String) -> void:
	root.add_child(_box(Vector3(1.82, 1.86, 0.62), Vector3(0, 0.95, 0), _c(p, "body"), 0.0))
	for y_index: int in range(3):
		root.add_child(_box(Vector3(1.58, 0.08, 0.52), Vector3(0, 0.42 + y_index * 0.62, 0), _c(p, "trim"), 0.0))
		for x: float in [-0.48, 0.48]:
			var payload := _cylinder(0.10 if item_id == "ammo_loader" else 0.07, 0.72, Vector3(x, 0.62 + y_index * 0.58, -0.08), _c(p, "accent"), 0.28)
			payload.rotation_degrees.z = 90.0
			root.add_child(payload)
	if item_id == "ammo_loader":
		root.add_child(_box(Vector3(0.88, 0.42, 0.82), Vector3(0, 2.08, 0), _c(p, "dark"), 0.0))

static func _build_forge(root: Node3D, p: Dictionary) -> void:
	root.add_child(_box(Vector3(1.82, 0.62, 1.36), Vector3(0, 0.36, 0), _c(p, "body"), 0.0))
	root.add_child(_cylinder(0.52, 1.18, Vector3(0, 1.05, 0), _c(p, "dark"), 0.0))
	root.add_child(_cylinder(0.38, 0.74, Vector3(0, 1.08, 0), _c(p, "accent"), 0.72))
	root.add_child(_torus(0.61, 0.09, Vector3(0, 1.62, 0), _c(p, "trim"), 0.0))
	for side: float in [-1.0, 1.0]:
		var arm := _box(Vector3(0.24, 1.12, 0.28), Vector3(side * 0.82, 1.0, 0), _c(p, "trim"), 0.0)
		arm.rotation_degrees.z = side * 12.0
		root.add_child(arm)

static func _build_gate(root: Node3D, p: Dictionary, item_id: String) -> void:
	var width: float = 2.35 if item_id == "airlock_gate" else 1.92
	for x: float in [-width * 0.5, width * 0.5]:
		root.add_child(_box(Vector3(0.24, 2.18, 0.36), Vector3(x, 1.08, 0), _c(p, "body"), 0.0))
	root.add_child(_box(Vector3(width + 0.26, 0.24, 0.36), Vector3(0, 2.06, 0), _c(p, "trim"), 0.0))
	for bar_index: int in range(5):
		root.add_child(_box(Vector3(0.08, 1.68, 0.08), Vector3(-0.72 + bar_index * 0.36, 1.0, 0), _c(p, "accent"), 0.28))
	root.add_child(_box(Vector3(0.38, 0.52, 0.12), Vector3(width * 0.62, 1.05, -0.22), _c(p, "accent"), 0.60))

static func _build_scanner(root: Node3D, p: Dictionary, item_id: String) -> void:
	root.add_child(_box(Vector3(1.46, 0.42, 1.24), Vector3(0, 0.25, 0), _c(p, "body"), 0.0))
	for x: float in [-0.58, 0.58]:
		root.add_child(_cylinder(0.10, 1.62, Vector3(x, 1.18, 0), _c(p, "trim"), 0.0))
	root.add_child(_box(Vector3(1.32, 0.18, 0.38), Vector3(0, 1.94, 0), _c(p, "trim"), 0.0))
	var scan_color: String = _c(p, "accent")
	var beam := _box(Vector3(1.12, 0.05, 0.76), Vector3(0, 1.22, 0), scan_color, 0.78)
	beam.transparency = 0.55
	root.add_child(beam)
	if item_id in ["truth_scanner", "diagnostic_scanner"]:
		root.add_child(_sphere(0.18, Vector3(0, 1.94, 0), _c(p, "warm"), 0.75))

static func _build_bunks(root: Node3D, p: Dictionary) -> void:
	for y: float in [0.42, 1.18]:
		root.add_child(_box(Vector3(2.15, 0.22, 0.92), Vector3(0, y, 0), _c(p, "body"), 0.0))
		root.add_child(_box(Vector3(1.82, 0.14, 0.78), Vector3(0, y + 0.18, 0), _c(p, "warm"), 0.0))
	for x: float in [-0.96, 0.96]:
		root.add_child(_box(Vector3(0.14, 1.48, 0.14), Vector3(x, 0.74, -0.36), _c(p, "trim"), 0.0))

static func _build_mess(root: Node3D, p: Dictionary) -> void:
	root.add_child(_box(Vector3(2.05, 0.18, 1.24), Vector3(0, 0.82, 0), _c(p, "body"), 0.0))
	for x: float in [-0.72, 0.72]:
		root.add_child(_box(Vector3(0.18, 0.72, 0.18), Vector3(x, 0.42, 0), _c(p, "dark"), 0.0))
	for x: float in [-0.58, 0.0, 0.58]:
		root.add_child(_cylinder(0.16, 0.07, Vector3(x, 1.0, 0), _c(p, "accent"), 0.22))
	root.add_child(_box(Vector3(1.42, 0.72, 0.48), Vector3(0, 1.38, -0.42), _c(p, "trim"), 0.0))

static func _build_med_pods(root: Node3D, p: Dictionary) -> void:
	for x: float in [-0.58, 0.58]:
		root.add_child(_box(Vector3(0.94, 0.38, 1.74), Vector3(x, 0.34, 0), _c(p, "body"), 0.0))
		var canopy := _box(Vector3(0.78, 0.62, 1.34), Vector3(x, 0.76, -0.06), _c(p, "accent"), 0.32)
		canopy.transparency = 0.42
		root.add_child(canopy)
		root.add_child(_sphere(0.08, Vector3(x, 1.12, -0.48), _c(p, "warm"), 0.70))

static func _add_variant_details(root: Node3D, p: Dictionary, variant: int) -> void:
	match variant:
		1:
			for x: float in [-0.42, 0.42]:
				root.add_child(_box(Vector3(0.24, 0.08, 0.08), Vector3(x, 0.12, 0.62), _c(p, "accent"), 0.52))
		2:
			for x: float in [-0.72, 0.72]:
				var pipe := _cylinder(0.07, 1.28, Vector3(x, 0.76, 0.52), _c(p, "warm"), 0.0)
				root.add_child(pipe)
			for stripe: int in range(4):
				root.add_child(_box(Vector3(0.26, 0.05, 0.18), Vector3(-0.45 + stripe * 0.30, 0.14, -0.62), _c(p, "accent"), 0.28))
		3:
			for side: float in [-1.0, 1.0]:
				var armor := _box(Vector3(0.28, 1.24, 0.76), Vector3(side * 0.92, 0.82, 0), _c(p, "dark"), 0.0)
				armor.rotation_degrees.z = side * 8.0
				root.add_child(armor)
			root.add_child(_sphere(0.10, Vector3(0, 1.92, 0.48), _c(p, "accent"), 0.90))
		4:
			var antenna := _cylinder(0.06, 1.0, Vector3(0, 1.72, 0.46), _c(p, "trim"), 0.0)
			root.add_child(antenna)
			root.add_child(_torus(0.28, 0.04, Vector3(0, 2.12, 0.46), _c(p, "accent"), 0.58))
			root.add_child(_sphere(0.09, Vector3(0, 2.12, 0.46), _c(p, "warm"), 0.75))
		5:
			var core := _sphere(0.22, Vector3(0, 1.58, 0.46), _c(p, "accent"), 1.05)
			core.transparency = 0.18
			root.add_child(core)
			for angle_index: int in range(2):
				var ring := _torus(0.36 + angle_index * 0.10, 0.035, Vector3(0, 1.58, 0.46), _c(p, "warm"), 0.62)
				ring.rotation_degrees = Vector3(35.0 + angle_index * 40.0, angle_index * 70.0, 0.0)
				root.add_child(ring)

static func _add_level_lights(root: Node3D, p: Dictionary, level: int) -> void:
	var tier_count: int = clampi(int(ceil(float(clampi(level, 1, 100)) / 20.0)), 1, 5)
	for index: int in range(5):
		var active: bool = index < tier_count
		root.add_child(_box(Vector3(0.18, 0.06, 0.08), Vector3(-0.48 + index * 0.24, 0.10, -0.68), _c(p, "accent") if active else _c(p, "dark"), 0.62 if active else 0.0))

static func _c(p: Dictionary, key: String) -> String:
	return String(p.get(key, "#FFFFFF"))

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

static func _cylinder(radius_value: float, height_value: float, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius_value
	mesh.bottom_radius = radius_value
	mesh.height = height_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex, emission)
	return node

static func _torus(radius_value: float, tube_radius: float, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = maxf(0.05, radius_value - tube_radius)
	mesh.outer_radius = radius_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex, emission)
	return node

static func _material(color_hex: String, emission: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var color := Color.from_string(color_hex, Color.WHITE)
	material.albedo_color = color
	material.roughness = 0.54
	material.metallic = 0.18
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material
