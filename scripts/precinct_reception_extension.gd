extends Node
## Adds Reception to existing and new saves, builds the ninth station room, and
## reconnects it after the core room collection rebuilds.

const RECEPTION_POSITION := Vector3(0.0, 0.0, 15.4)
const RECEPTION_DATA: Dictionary = {
	"id":"reception",
	"name":"Public Reception & Intake",
	"function":"Civilian Assistance and Case Intake",
	"level":1,
	"repaired":false,
	"repair_cost":110,
	"repair_end":0
}

var precinct: Node3D
var rebuild_pending: bool = false

func _ready() -> void:
	precinct = get_parent() as Node3D
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(12):
		await get_tree().process_frame
	_ensure_reception_state()
	_ensure_reception_world()
	if not PrecinctState.state_changed.is_connected(_schedule_rebuild):
		PrecinctState.state_changed.connect(_schedule_rebuild)
	PrecinctState.state_changed.emit()

func _ensure_reception_state() -> void:
	if not PrecinctState.get_room("reception").is_empty():
		return
	PrecinctState.rooms.append(RECEPTION_DATA.duplicate(true))
	PrecinctState.last_event = "Reception identified at the station entrance. Restore it to resume public intake."

func _schedule_rebuild() -> void:
	if rebuild_pending:
		return
	rebuild_pending = true
	call_deferred("_rebuild_after_core")

func _rebuild_after_core() -> void:
	for _frame: int in range(5):
		await get_tree().process_frame
	_ensure_reception_state()
	_ensure_reception_world()
	rebuild_pending = false

func _ensure_reception_world() -> void:
	if precinct == null:
		return
	var rooms_value: Variant = precinct.get("rooms_root")
	var world_value: Variant = precinct.get("world_root")
	var room_nodes_value: Variant = precinct.get("room_nodes")
	if not rooms_value is Node3D or not world_value is Node3D or not room_nodes_value is Dictionary:
		return
	var rooms_root := rooms_value as Node3D
	var world_root := world_value as Node3D
	var room_nodes := room_nodes_value as Dictionary
	var current: Node3D = rooms_root.get_node_or_null("Room_reception") as Node3D
	if current == null:
		current = PrecinctReceptionFactory.build_room(PrecinctState.get_room("reception"))
		current.position = RECEPTION_POSITION
		current.rotation.y = PI
		rooms_root.add_child(current)
	room_nodes["reception"] = current
	precinct.set("room_nodes", room_nodes)
	_build_approach(world_root)
	_route_front_desk_staff()

func _build_approach(world_root: Node3D) -> void:
	var previous: Node = world_root.get_node_or_null("ReceptionApproach")
	if previous != null:
		return
	var approach := Node3D.new()
	approach.name = "ReceptionApproach"
	world_root.add_child(approach)
	approach.add_child(_box(Vector3(4.2, 0.24, 11.8), Vector3(0.0, 0.02, 8.0), "#284A61", 0.03))
	for index: int in range(7):
		approach.add_child(_box(Vector3(2.9, 0.035, 0.11), Vector3(0.0, 0.18, 3.2 + index * 1.55), "#61E8FF", 0.28))
	for side: float in [-1.0, 1.0]:
		approach.add_child(_box(Vector3(0.20, 1.20, 11.2), Vector3(side * 2.0, 0.62, 8.0), "#1A3343", 0.0))

func _route_front_desk_staff() -> void:
	var agents_value: Variant = precinct.get("agents")
	if not agents_value is Array:
		return
	for raw_agent: Variant in agents_value:
		if not raw_agent is PrecinctAgent:
			continue
		var agent := raw_agent as PrecinctAgent
		if agent.officer_id == "clerk_1":
			precinct.call("_route_agent", agent, "reception")
			return

func _box(size_value: Vector3, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.position = position_value
	var material := StandardMaterial3D.new()
	var color := Color(color_hex)
	material.albedo_color = color
	material.roughness = 0.58
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	node.material_override = material
	return node
