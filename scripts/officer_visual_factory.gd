class_name OfficerVisualFactory
extends RefCounted

const ARMOR_NAVY: String = "#18263F"
const ARMOR_SHADOW: String = "#0F1828"
const INSIGNIA_GOLD: String = "#D6B14A"
const VISOR_BLUE: String = "#7EDCFF"
const GLOVE_BLACK: String = "#101820"

static func build_authority_officer(officer_data: Dictionary = {}) -> Node3D:
	var root: Node3D = Node3D.new()
	var officer_name: String = str(officer_data.get("name", "Authority Officer"))
	var division: String = str(officer_data.get("division", "Authority"))
	var rarity: String = str(officer_data.get("rarity", "Common"))
	var rank: int = clampi(int(officer_data.get("rank", 1)), 1, 5)
	var skin_color: String = _get_skin_color(officer_data)
	var hardware_color: String = _get_division_color(division)
	root.name = officer_name.replace(" ", "_")
	root.set_meta("officer_name", officer_name)
	root.set_meta("division", division)
	root.set_meta("rarity", rarity)
	root.set_meta("rank", rank)
	_add_lower_body(root)
	_add_torso(root, hardware_color)
	_add_head(root, skin_color, hardware_color)
	_add_rank_insignia(root, rank)
	_add_division_hardware(root, hardware_color)
	return root

static func _add_lower_body(root: Node3D) -> void:
	root.add_child(_make_box(Vector3(0.24, 0.74, 0.24), Vector3(-0.17, 0.39, 0.0), ARMOR_SHADOW))
	root.add_child(_make_box(Vector3(0.24, 0.74, 0.24), Vector3(0.17, 0.39, 0.0), ARMOR_SHADOW))
	root.add_child(_make_box(Vector3(0.27, 0.15, 0.38), Vector3(-0.17, 0.04, 0.05), GLOVE_BLACK))
	root.add_child(_make_box(Vector3(0.27, 0.15, 0.38), Vector3(0.17, 0.04, 0.05), GLOVE_BLACK))
	root.add_child(_make_box(Vector3(0.79, 0.10, 0.29), Vector3(0.0, 0.73, 0.0), INSIGNIA_GOLD))

static func _add_torso(root: Node3D, hardware_color: String) -> void:
	root.add_child(_make_box(Vector3(0.80, 0.84, 0.42), Vector3(0.0, 1.10, 0.0), ARMOR_NAVY))
	root.add_child(_make_box(Vector3(0.59, 0.48, 0.12), Vector3(0.0, 1.12, 0.23), ARMOR_SHADOW))
	root.add_child(_make_box(Vector3(0.25, 0.18, 0.27), Vector3(-0.52, 1.42, 0.0), ARMOR_NAVY))
	root.add_child(_make_box(Vector3(0.25, 0.18, 0.27), Vector3(0.52, 1.42, 0.0), ARMOR_NAVY))
	root.add_child(_make_box(Vector3(0.19, 0.68, 0.19), Vector3(-0.53, 1.02, 0.0), ARMOR_NAVY))
	root.add_child(_make_box(Vector3(0.19, 0.68, 0.19), Vector3(0.53, 1.02, 0.0), ARMOR_NAVY))
	root.add_child(_make_box(Vector3(0.17, 0.17, 0.17), Vector3(-0.53, 0.59, 0.0), GLOVE_BLACK))
	root.add_child(_make_box(Vector3(0.17, 0.17, 0.17), Vector3(0.53, 0.59, 0.0), GLOVE_BLACK))
	root.add_child(_make_box(Vector3(0.36, 0.53, 0.18), Vector3(0.0, 1.12, -0.30), ARMOR_SHADOW))
	root.add_child(_make_emissive_box(Vector3(0.08, 0.20, 0.04), Vector3(0.0, 1.18, -0.41), hardware_color, 0.55))

static func _add_head(root: Node3D, skin_color: String, hardware_color: String) -> void:
	root.add_child(_make_sphere(0.29, Vector3(0.0, 1.73, 0.0), skin_color))
	root.add_child(_make_box(Vector3(0.64, 0.27, 0.54), Vector3(0.0, 1.94, 0.0), ARMOR_NAVY))
	root.add_child(_make_box(Vector3(0.60, 0.13, 0.59), Vector3(0.0, 2.04, 0.0), ARMOR_SHADOW))
	root.add_child(_make_emissive_box(Vector3(0.45, 0.12, 0.08), Vector3(0.0, 1.75, 0.25), VISOR_BLUE, 0.82))
	root.add_child(_make_antenna(Vector3(-0.11, 2.18, 0.0), skin_color))
	root.add_child(_make_antenna(Vector3(0.11, 2.18, 0.0), skin_color))
	root.add_child(_make_emissive_box(Vector3(0.08, 0.08, 0.07), Vector3(0.0, 2.15, 0.10), hardware_color, 0.65))

static func _add_rank_insignia(root: Node3D, rank: int) -> void:
	for index: int in range(rank):
		root.add_child(_make_box(Vector3(0.065, 0.085, 0.035), Vector3(-0.16 + float(index) * 0.08, 1.34, 0.255), INSIGNIA_GOLD))

static func _add_division_hardware(root: Node3D, hardware_color: String) -> void:
	root.add_child(_make_emissive_box(Vector3(0.13, 0.34, 0.12), Vector3(-0.36, 1.10, 0.25), hardware_color, 0.50))
	root.add_child(_make_emissive_box(Vector3(0.13, 0.34, 0.12), Vector3(0.36, 1.10, 0.25), hardware_color, 0.50))
	root.add_child(_make_emissive_box(Vector3(0.30, 0.045, 0.04), Vector3(0.0, 1.52, 0.25), hardware_color, 0.45))

static func _make_antenna(position_value: Vector3, color_hex: String) -> MeshInstance3D:
	var antenna: MeshInstance3D = MeshInstance3D.new()
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = 0.01
	mesh.bottom_radius = 0.03
	mesh.height = 0.20
	antenna.mesh = mesh
	antenna.position = position_value
	antenna.material_override = _make_material(color_hex, 0.0)
	return antenna

static func _make_box(size_value: Vector3, position_value: Vector3, color_hex: String) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _make_material(color_hex, 0.0)
	return node

static func _make_sphere(radius_value: float, position_value: Vector3, color_hex: String) -> MeshInstance3D:
	var node: MeshInstance3D = MeshInstance3D.new()
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius_value
	mesh.height = radius_value * 2.0
	node.mesh = mesh
	node.position = position_value
	node.material_override = _make_material(color_hex, 0.0)
	return node

static func _make_emissive_box(size_value: Vector3, position_value: Vector3, color_hex: String, energy: float) -> MeshInstance3D:
	var node: MeshInstance3D = _make_box(size_value, position_value, color_hex)
	node.material_override = _make_material(color_hex, energy)
	return node

static func _make_material(color_hex: String, emission_energy: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	var color: Color = Color.from_string(color_hex, Color.WHITE)
	material.albedo_color = color
	material.roughness = 0.62
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material

static func _get_skin_color(officer_data: Dictionary) -> String:
	if officer_data.has("skin_color"):
		return str(officer_data.get("skin_color", "#6FB8FF"))
	match str(officer_data.get("species", "Alien")).to_lower():
		"hybrid": return "#7FE3E1"
		"human": return "#A9C8FF"
		_: return "#6FB8FF"

static func _get_division_color(division: String) -> String:
	match division.to_lower():
		"tactical", "riot": return "#FF6A4A"
		"research", "science", "medical": return "#46E0D1"
		"detention", "prison": return "#7A8DFF"
		"logistics", "engineering": return "#FFB347"
		_: return "#4AA3FF"
