class_name HeadquartersVisualFactory
extends RefCounted
## Procedural 3D graphics used by browser, desktop and Android exports.
## Five complete visual themes are available for Headquarters departments and
## every standalone facility without relying on external downloads.

const STYLE_PALETTES: Array[Dictionary] = [
	{"body":"#253D4E", "trim":"#6F8EA0", "dark":"#102431", "glass":"#78E9FF", "light":"#D9F7FF"},
	{"body":"#4A4037", "trim":"#A78963", "dark":"#241E1A", "glass":"#FFB35B", "light":"#FFE0A8"},
	{"body":"#263444", "trim":"#506C86", "dark":"#111A26", "glass":"#69AFFF", "light":"#D4E6FF"},
	{"body":"#E0E8EC", "trim":"#8FA9B8", "dark":"#304552", "glass":"#5BE6FF", "light":"#FFFFFF"},
	{"body":"#28203C", "trim":"#694F8F", "dark":"#100A1D", "glass":"#C77DFF", "light":"#F1D9FF"}
]

static func build_headquarters(style_index: int, level: int) -> Node3D:
	var palette := STYLE_PALETTES[clampi(style_index, 0, STYLE_PALETTES.size() - 1)] as Dictionary
	var root := Node3D.new()
	root.name = "UnifiedPoliceHeadquarters"
	root.set_meta("building_id", "headquarters")
	# One connected station building: armored foundation, three department wings,
	# a central command tower, public reception entrance and roof landing pad.
	root.add_child(_box(Vector3(32.0, 0.7, 22.0), Vector3(0, 0.0, 0), String(palette.dark), 0.0))
	root.add_child(_box(Vector3(29.0, 4.8, 18.0), Vector3(0, 2.7, 0), String(palette.body), 0.0))
	root.add_child(_box(Vector3(30.0, 0.55, 19.0), Vector3(0, 5.25, 0), String(palette.trim), 0.0))
	# Central command tower.
	root.add_child(_box(Vector3(8.4, 6.8, 7.6), Vector3(0, 8.7, -1.0), String(palette.body), 0.0))
	root.add_child(_box(Vector3(7.6, 0.45, 6.8), Vector3(0, 12.3, -1.0), String(palette.trim), 0.0))
	root.add_child(_sphere(1.1, Vector3(0, 13.4, -1.0), String(palette.glass), 0.55))
	# Reception entrance and public approach.
	root.add_child(_box(Vector3(10.5, 3.8, 4.8), Vector3(0, 2.1, 10.0), String(palette.dark), 0.0))
	root.add_child(_box(Vector3(6.6, 2.7, 0.32), Vector3(0, 1.75, 12.45), String(palette.glass), 0.26))
	root.add_child(_box(Vector3(4.2, 0.22, 9.0), Vector3(0, 0.2, 15.5), String(palette.trim), 0.03))
	for index: int in range(5):
		root.add_child(_box(Vector3(3.4, 0.04, 0.12), Vector3(0, 0.34, 12.6 + index * 1.55), String(palette.glass), 0.32))
	# Exterior department windows and clickable roof sectors in a 3x3 grid.
	var departments := HeadquartersFacilityCatalog.DEPARTMENTS
	for index: int in range(departments.size()):
		var department := departments[index] as Dictionary
		var column := index % 3
		var row := int(index / 3)
		var local := Vector3(-9.5 + column * 9.5, 5.65, -5.5 + row * 5.5)
		var accent := String(department.get("accent", palette.glass))
		root.add_child(_box(Vector3(7.3, 0.18, 3.9), local, accent, 0.12 + 0.03 * mini(level, 10)))
		for window_index: int in range(3):
			root.add_child(_box(Vector3(1.55, 0.48, 0.12), Vector3(local.x - 2.1 + window_index * 2.1, 3.4, 9.08), accent, 0.16))
		_add_click_body(root, "HQ_%s" % String(department.get("id", "department")), Vector3(8.4, 6.4, 5.1), Vector3(local.x, 3.2, local.z), {"building_id":"headquarters", "department_id":String(department.get("id", ""))})
	# Landing pad and antenna array.
	root.add_child(_cylinder(3.2, 0.28, Vector3(10.2, 5.65, -5.5), String(palette.dark), 0.0))
	for radius: float in [2.7, 1.9, 1.1]:
		root.add_child(_torus(radius, 0.08, Vector3(10.2, 5.84, -5.5), String(palette.glass), 0.35))
	root.add_child(_cylinder(0.16, 4.2, Vector3(-11.5, 7.4, -5.5), String(palette.trim), 0.0))
	root.add_child(_sphere(0.34, Vector3(-11.5, 9.6, -5.5), String(palette.glass), 0.9))
	_add_label(root, "MOONGOONS PEACEKEEPER HEADQUARTERS  //  LEVEL %d" % level, Vector3(0, 6.1, 9.3), String(palette.light), 38)
	return root

static func build_facility(facility_id: String, style_index: int, level: int) -> Node3D:
	var data := HeadquartersFacilityCatalog.facility(facility_id)
	var palette := STYLE_PALETTES[clampi(style_index, 0, STYLE_PALETTES.size() - 1)] as Dictionary
	var accent := String(data.get("accent", palette.glass))
	var root := Node3D.new()
	root.name = "Facility_%s" % facility_id
	root.set_meta("facility_id", facility_id)
	root.add_child(_box(Vector3(9.2, 0.55, 8.2), Vector3.ZERO, String(palette.dark), 0.0))
	root.add_child(_box(Vector3(8.3, 3.9, 7.3), Vector3(0, 2.2, 0), String(palette.body), 0.0))
	root.add_child(_box(Vector3(8.8, 0.38, 7.8), Vector3(0, 4.35, 0), String(palette.trim), 0.0))
	root.add_child(_box(Vector3(2.6, 2.45, 0.52), Vector3(0, 1.5, 3.75), String(palette.dark), 0.0))
	root.add_child(_box(Vector3(1.85, 1.85, 0.18), Vector3(0, 1.35, 4.05), accent, 0.28))
	_add_facility_identity(root, facility_id, palette, accent, level)
	_add_click_body(root, "Click_%s" % facility_id, Vector3(8.7, 6.2, 7.8), Vector3(0, 3.1, 0), {"facility_id":facility_id})
	_add_label(root, "%s  //  L%d" % [String(data.get("name", facility_id)).to_upper(), level], Vector3(0, 5.35, 3.15), accent, 24)
	return root

static func _add_facility_identity(root: Node3D, facility_id: String, palette: Dictionary, accent: String, level: int) -> void:
	match facility_id:
		"research_center":
			root.add_child(_sphere(1.45, Vector3(0, 5.2, -0.5), accent, 0.30))
			for radius: float in [1.75, 2.25]: root.add_child(_torus(radius, 0.09, Vector3(0, 5.2, -0.5), accent, 0.42))
		"guard_academy":
			root.add_child(_box(Vector3(4.8, 1.8, 2.4), Vector3(0, 5.1, -0.7), String(palette.dark), 0.0))
			root.add_child(_box(Vector3(0.65, 2.4, 0.22), Vector3(0, 5.25, 0.55), accent, 0.45))
			root.add_child(_box(Vector3(2.3, 0.65, 0.22), Vector3(0, 5.25, 0.55), accent, 0.45))
		"biker_garage":
			for side: float in [-1.0, 1.0]:
				root.add_child(_torus(1.25, 0.28, Vector3(side * 2.1, 4.85, 0), accent, 0.18))
			root.add_child(_box(Vector3(5.5, 0.55, 1.2), Vector3(0, 5.0, 0), String(palette.dark), 0.0))
		"marksman_range":
			var barrel := _cylinder(0.22, 6.2, Vector3(0, 5.35, -1.5), accent, 0.25)
			barrel.rotation_degrees.x = 90.0
			root.add_child(barrel)
			root.add_child(_sphere(0.8, Vector3(0, 5.2, 1.5), String(palette.dark), 0.0))
		"robotics_bay":
			for side: float in [-1.0, 1.0]:
				root.add_child(_cylinder(0.8, 2.2, Vector3(side * 2.0, 5.35, 0), String(palette.dark), 0.0))
				root.add_child(_sphere(0.62, Vector3(side * 2.0, 6.55, 0), accent, 0.35))
		"hospital":
			root.add_child(_cylinder(1.45, 1.7, Vector3(0, 5.35, -0.2), String(palette.light), 0.0))
			root.add_child(_box(Vector3(0.62, 2.0, 0.20), Vector3(0, 5.55, 1.0), accent, 0.45))
			root.add_child(_box(Vector3(2.0, 0.62, 0.20), Vector3(0, 5.55, 1.0), accent, 0.45))
		"crime_lab":
			for x: float in [-2.2, 0.0, 2.2]:
				root.add_child(_cylinder(0.58, 1.5, Vector3(x, 5.15, 0), String(palette.light), 0.0))
				root.add_child(_sphere(0.42, Vector3(x, 6.05, 0), accent, 0.30))
		"storage_depot":
			for x: float in [-2.5, 0.0, 2.5]: root.add_child(_box(Vector3(1.8, 1.6, 2.0), Vector3(x, 5.15, 0), accent if x == 0.0 else String(palette.dark), 0.12))
		"vehicle_depot":
			root.add_child(_box(Vector3(6.6, 2.2, 2.5), Vector3(0, 4.85, 1.4), String(palette.dark), 0.0))
			for x: float in [-2.45, 2.45]: root.add_child(_cylinder(0.42, 1.2, Vector3(x, 5.0, 2.8), accent, 0.22))
	# Five illuminated bars communicate advancement without filling the screen with text.
	var active := clampi(int(ceil(float(level) / 20.0)), 1, 5)
	for index: int in range(5):
		root.add_child(_box(Vector3(0.75, 0.12, 0.12), Vector3(-1.8 + index * 0.9, 4.55, 3.72), accent if index < active else String(palette.dark), 0.55 if index < active else 0.0))

static func _add_click_body(root: Node3D, body_name: String, size_value: Vector3, position_value: Vector3, metadata: Dictionary) -> void:
	var body := StaticBody3D.new()
	body.name = body_name
	for key_value: Variant in metadata.keys(): body.set_meta(String(key_value), metadata[key_value])
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size_value
	collision.shape = shape
	collision.position = position_value
	body.add_child(collision)
	root.add_child(body)

static func _add_label(root: Node3D, text_value: String, position_value: Vector3, color_hex: String, font_size_value: int) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.position = position_value
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label.fixed_size = true
	label.font_size = font_size_value
	label.outline_size = 7
	label.modulate = Color(color_hex)
	root.add_child(label)

static func _box(size_value: Vector3, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size_value
	node.mesh = mesh; node.position = position_value; node.material_override = _material(color_hex, emission); return node

static func _sphere(radius_value: float, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new(); var mesh := SphereMesh.new(); mesh.radius = radius_value; mesh.height = radius_value * 2.0
	node.mesh = mesh; node.position = position_value; node.material_override = _material(color_hex, emission); return node

static func _cylinder(radius_value: float, height_value: float, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new(); var mesh := CylinderMesh.new(); mesh.top_radius = radius_value; mesh.bottom_radius = radius_value; mesh.height = height_value
	node.mesh = mesh; node.position = position_value; node.material_override = _material(color_hex, emission); return node

static func _torus(radius_value: float, tube_radius: float, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new(); var mesh := TorusMesh.new(); mesh.inner_radius = maxf(0.02, radius_value - tube_radius); mesh.outer_radius = radius_value + tube_radius
	node.mesh = mesh; node.position = position_value; node.material_override = _material(color_hex, emission); return node

static func _material(color_hex: String, emission: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new(); var color := Color(color_hex)
	material.albedo_color = color; material.roughness = 0.56
	if emission > 0.0:
		material.emission_enabled = true; material.emission = color; material.emission_energy_multiplier = emission
	return material
