class_name StationDoor
extends Node3D

var left_panel: MeshInstance3D
var right_panel: MeshInstance3D
var open_amount: float = 0.0
var accent: Color = Color("#56DFFF")
var room_id: String = ""
var locked: bool = false

func configure(id_value: String, accent_value: Color, locked_value: bool = false) -> void:
	room_id = id_value
	accent = accent_value
	locked = locked_value
	name = "Door_%s" % room_id
	_build_visuals()

func _process(delta: float) -> void:
	var should_open: bool = not locked and _personnel_nearby()
	var target: float = 1.0 if should_open else 0.0
	open_amount = move_toward(open_amount, target, delta * 3.2)
	if left_panel != null:
		left_panel.position.x = lerpf(-0.56, -1.58, open_amount)
	if right_panel != null:
		right_panel.position.x = lerpf(0.56, 1.58, open_amount)

func _personnel_nearby() -> bool:
	for node: Node in get_tree().get_nodes_in_group("precinct_personnel"):
		if node is Node3D and (node as Node3D).global_position.distance_to(global_position) <= 2.35:
			return true
	return false

func _build_visuals() -> void:
	for child: Node in get_children():
		child.queue_free()
	var frame_color := Color("#31485B")
	add_child(_box(Vector3(0.26, 3.2, 0.28), Vector3(-1.38, 1.6, 0.0), frame_color, 0.0))
	add_child(_box(Vector3(0.26, 3.2, 0.28), Vector3(1.38, 1.6, 0.0), frame_color, 0.0))
	add_child(_box(Vector3(3.02, 0.32, 0.28), Vector3(0.0, 3.04, 0.0), frame_color, 0.0))
	left_panel = _box(Vector3(1.08, 2.62, 0.18), Vector3(-0.56, 1.55, 0.0), Color("#182B3B"), 0.0)
	right_panel = _box(Vector3(1.08, 2.62, 0.18), Vector3(0.56, 1.55, 0.0), Color("#182B3B"), 0.0)
	add_child(left_panel)
	add_child(right_panel)
	for panel: MeshInstance3D in [left_panel, right_panel]:
		var seam := _box(Vector3(0.07, 2.25, 0.05), Vector3.ZERO, accent, 0.65)
		panel.add_child(seam)
	var header := Label3D.new()
	header.text = room_id.to_upper()
	header.position = Vector3(0.0, 3.35, 0.0)
	header.font_size = 18
	header.outline_size = 4
	header.fixed_size = true
	header.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	header.modulate = accent if not locked else Color("#FF667D")
	add_child(header)
	add_child(_box(Vector3(0.42, 0.16, 0.12), Vector3(1.58, 2.5, 0.0), accent if not locked else Color("#FF667D"), 0.9))

func _box(size_value: Vector3, position_value: Vector3, color_value: Color, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.position = position_value
	var material := StandardMaterial3D.new()
	material.albedo_color = color_value
	material.roughness = 0.48
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color_value
		material.emission_energy_multiplier = emission
	node.material_override = material
	return node
