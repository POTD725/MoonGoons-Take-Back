extends Node
## Replaces the disconnected room row with one Police Headquarters and standalone
## upgradeable facilities. Clicking a building opens a compact contextual popup.

var precinct: Node3D
var world: Node3D
var city_root: Node3D
var animation_clock: float = 0.0
var rebuild_pending := false

func _ready() -> void:
	precinct = get_parent() as Node3D
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(28): await get_tree().process_frame
	if precinct == null: return
	world = precinct.get_node_or_null("LivingPrecinctWorld") as Node3D
	if world == null: return
	_hide_legacy_city()
	_build_city()
	if not HeadquartersProgression.headquarters_changed.is_connected(_schedule_rebuild):
		HeadquartersProgression.headquarters_changed.connect(_schedule_rebuild)

func _process(delta: float) -> void:
	animation_clock += delta
	if city_root == null: return
	var shuttle := city_root.get_node_or_null("FacilityRing/PatrolShuttle") as Node3D
	if shuttle != null:
		shuttle.position.y = 4.4 + sin(animation_clock * 1.4) * 0.28
		shuttle.rotation.y += delta * 0.18
	var drone_root := city_root.get_node_or_null("ServiceDrones") as Node3D
	if drone_root != null:
		for index: int in range(drone_root.get_child_count()):
			var drone := drone_root.get_child(index) as Node3D
			var angle := animation_clock * (0.18 + index * 0.025) + index * 1.5
			drone.position = Vector3(cos(angle) * (13.0 + index * 2.0), 2.2 + sin(angle * 2.0) * 0.5, sin(angle) * (9.0 + index))

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return
	var mouse := event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index != MOUSE_BUTTON_LEFT: return
	# Browser city clicks are handled by headquarters_web_city.gd.
	if OS.has_feature("web"): return
	var camera_value: Variant = precinct.get("camera")
	if not camera_value is Camera3D: return
	var camera := camera_value as Camera3D
	var origin := camera.project_ray_origin(mouse.position)
	var direction := camera.project_ray_normal(mouse.position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 400.0)
	var result := precinct.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty(): return
	var collider: Object = result.get("collider") as Object
	if collider == null: return
	if collider.has_meta("department_id"):
		_open_department(String(collider.get_meta("department_id")), mouse.position)
		get_viewport().set_input_as_handled()
	elif collider.has_meta("facility_id"):
		_open_facility(String(collider.get_meta("facility_id")), mouse.position)
		get_viewport().set_input_as_handled()

func _hide_legacy_city() -> void:
	for path: String in ["Rooms", "ExteriorCityModules", "ResourceHarvestSites", "SyndicateSpaceFleets"]:
		var node := world.get_node_or_null(path)
		if node != null: node.visible = false
	var old_backdrop := precinct.get_node_or_null("PrecinctWebBackdropLayer/PrecinctWebBackdrop") as Control
	if old_backdrop != null: old_backdrop.visible = false

func _build_city() -> void:
	if city_root != null: city_root.queue_free()
	city_root = Node3D.new()
	city_root.name = "UnifiedPrecinctCity"
	world.add_child(city_root)
	_build_ground_and_roads()
	var headquarters := HeadquartersVisualFactory.build_headquarters(HeadquartersProgression.department_style("chief"), HeadquartersProgression.headquarters_level)
	headquarters.name = "PoliceHeadquarters"
	city_root.add_child(headquarters)
	var facility_ring := Node3D.new(); facility_ring.name = "FacilityRing"; city_root.add_child(facility_ring)
	for facility_data: Dictionary in HeadquartersFacilityCatalog.FACILITIES:
		var facility_id := String(facility_data.get("id", ""))
		var position_2d := facility_data.get("position", Vector2.ZERO) as Vector2
		var facility := HeadquartersVisualFactory.build_facility(facility_id, HeadquartersProgression.facility_style(facility_id), HeadquartersProgression.facility_level(facility_id))
		facility.position = Vector3(position_2d.x, 0.0, position_2d.y)
		facility.look_at(Vector3.ZERO, Vector3.UP)
		facility.rotation.x = 0.0; facility.rotation.z = 0.0
		facility_ring.add_child(facility)
	_build_patrol_shuttle(facility_ring)
	_build_service_drones()
	_build_expansion_pads()

func _build_ground_and_roads() -> void:
	city_root.add_child(_box(Vector3(68.0, 0.32, 60.0), Vector3(0, -0.28, 2), "#121B28", 0.0))
	city_root.add_child(_box(Vector3(40.0, 0.16, 7.0), Vector3(0, 0.02, 0), "#234157", 0.03))
	city_root.add_child(_box(Vector3(7.0, 0.16, 47.0), Vector3(0, 0.03, 2), "#234157", 0.03))
	for facility_data: Dictionary in HeadquartersFacilityCatalog.FACILITIES:
		var pos := facility_data.get("position", Vector2.ZERO) as Vector2
		var road := _box(Vector3(2.6, 0.12, maxf(4.0, Vector2(pos.x, pos.y).length() - 5.0)), Vector3(pos.x * 0.48, 0.07, pos.y * 0.48), "#2A5068", 0.03)
		road.rotation.y = -atan2(pos.x, pos.y)
		city_root.add_child(road)
	for strip: int in range(13):
		city_root.add_child(_box(Vector3(1.25, 0.035, 0.11), Vector3(-9.0 + strip * 1.5, 0.16, 0), "#5EE4FF", 0.28))

func _build_patrol_shuttle(parent: Node3D) -> void:
	var shuttle := Node3D.new(); shuttle.name = "PatrolShuttle"; shuttle.position = Vector3(14, 4.4, 11)
	shuttle.add_child(_box(Vector3(4.8, 0.9, 2.3), Vector3.ZERO, "#29445E", 0.0))
	shuttle.add_child(_box(Vector3(1.6, 0.62, 1.8), Vector3(1.4, 0.58, 0), "#5A7890", 0.0))
	shuttle.add_child(_box(Vector3(1.2, 0.38, 1.45), Vector3(2.15, 0.62, 0), "#76EAFF", 0.42))
	for z: float in [-0.78, 0.78]: shuttle.add_child(_cylinder(0.28, 0.8, Vector3(-2.15, 0, z), "#69E9FF", 0.85))
	parent.add_child(shuttle)

func _build_service_drones() -> void:
	var root := Node3D.new(); root.name = "ServiceDrones"; city_root.add_child(root)
	for index: int in range(4):
		var drone := Node3D.new(); drone.name = "Drone_%d" % index
		drone.add_child(_sphere(0.34, Vector3.ZERO, "#8DEEFF", 0.55))
		for side: float in [-1.0, 1.0]: drone.add_child(_box(Vector3(0.72, 0.10, 0.22), Vector3(side * 0.55, 0, 0), "#506C80", 0.0))
		root.add_child(drone)

func _build_expansion_pads() -> void:
	var positions := [Vector3(-29,0,22), Vector3(29,0,22), Vector3(-29,0,-20), Vector3(29,0,-20)]
	for index: int in range(positions.size()):
		var pad := Node3D.new(); pad.name = "ExpansionPad_%d" % (index + 1); pad.position = positions[index]
		pad.add_child(_cylinder(3.2, 0.25, Vector3.ZERO, "#1A2E3C", 0.0))
		for radius: float in [2.7, 1.9]: pad.add_child(_torus(radius, 0.08, Vector3(0,0.18,0), "#476D80", 0.18))
		var label := Label3D.new(); label.text = "FUTURE ADD-ON"; label.position = Vector3(0,0.8,0); label.billboard = BaseMaterial3D.BILLBOARD_ENABLED; label.font_size = 18; label.outline_size = 5; pad.add_child(label)
		city_root.add_child(pad)

func _open_department(department_id: String, screen_position: Vector2) -> void:
	var popup := precinct.get_node_or_null("BuildingContextPopup")
	if popup != null and popup.has_method("open_department"): popup.call("open_department", department_id, screen_position)

func _open_facility(facility_id: String, screen_position: Vector2) -> void:
	var popup := precinct.get_node_or_null("BuildingContextPopup")
	if popup != null and popup.has_method("open_facility"): popup.call("open_facility", facility_id, screen_position)

func _schedule_rebuild() -> void:
	if rebuild_pending: return
	rebuild_pending = true; call_deferred("_delayed_rebuild")

func _delayed_rebuild() -> void:
	for _frame: int in range(3): await get_tree().process_frame
	_build_city(); rebuild_pending = false

func _box(size_value: Vector3, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size_value; node.mesh = mesh; node.position = position_value; node.material_override = _material(color_hex, emission); return node
func _sphere(radius_value: float, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new(); var mesh := SphereMesh.new(); mesh.radius = radius_value; mesh.height = radius_value*2; node.mesh = mesh; node.position = position_value; node.material_override = _material(color_hex, emission); return node
func _cylinder(radius_value: float, height_value: float, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new(); var mesh := CylinderMesh.new(); mesh.top_radius=radius_value; mesh.bottom_radius=radius_value; mesh.height=height_value; node.mesh=mesh; node.position=position_value; node.material_override=_material(color_hex,emission); return node
func _torus(radius_value: float, tube_radius: float, position_value: Vector3, color_hex: String, emission: float) -> MeshInstance3D:
	var node := MeshInstance3D.new(); var mesh := TorusMesh.new(); mesh.inner_radius=maxf(0.02,radius_value-tube_radius); mesh.outer_radius=radius_value+tube_radius; node.mesh=mesh; node.position=position_value; node.material_override=_material(color_hex,emission); return node
func _material(color_hex: String, emission: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new(); var color := Color(color_hex); material.albedo_color=color; material.roughness=0.58
	if emission>0.0: material.emission_enabled=true; material.emission=color; material.emission_energy_multiplier=emission
	return material
