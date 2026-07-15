class_name PrecinctAgent
extends Node3D

signal reached_job(agent:PrecinctAgent, room_id:String)

var officer_id:String = ""
var display_name:String = "Worker"
var role:String = "Authority"
var assigned_room_id:String = "ops"
var target_position:Vector3 = Vector3.ZERO
var home_position:Vector3 = Vector3.ZERO
var waypoint_queue:Array[Vector3] = []
var move_speed:float = 2.2
var work_timer:float = 0.0
var decision_timer:float = 0.0
var walking:bool = false
var working:bool = false
var visual_root:Node3D
var status_label:Label3D
var rng := RandomNumberGenerator.new()
var step_clock:float = 0.0
var animation_phase:float = 0.0
var left_arm:Node3D
var right_arm:Node3D
var left_leg:Node3D
var right_leg:Node3D
var head_pivot:Node3D

func configure(data:Dictionary, start_position:Vector3) -> void:
	add_to_group("precinct_personnel")
	add_to_group("animated_station_npcs")
	officer_id = str(data.get("id", "worker"))
	display_name = str(data.get("name", "Worker"))
	role = str(data.get("class", data.get("role", "Authority")))
	assigned_room_id = str(data.get("assigned_room", "ops"))
	home_position = start_position
	position = start_position
	rng.seed = officer_id.hash()
	move_speed = 1.75 + rng.randf_range(0.0, 0.8)
	animation_phase = rng.randf_range(0.0, TAU)
	visual_root = OfficerVisualFactory.build_authority_officer({
		"name":display_name,
		"division":_division_for_role(role),
		"rarity":str(data.get("rarity", "Common")),
		"rank":int(data.get("level", 1)),
		"species":_species_for_id(officer_id)
	})
	visual_root.scale = Vector3.ONE * 0.72
	add_child(visual_root)
	left_arm = visual_root.get_node_or_null("ArmLeft") as Node3D
	right_arm = visual_root.get_node_or_null("ArmRight") as Node3D
	left_leg = visual_root.get_node_or_null("LegLeft") as Node3D
	right_leg = visual_root.get_node_or_null("LegRight") as Node3D
	head_pivot = visual_root.get_node_or_null("HeadPivot") as Node3D
	status_label = Label3D.new()
	status_label.text = display_name
	status_label.position = Vector3(0.0, 2.15, 0.0)
	status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	status_label.font_size = 28
	status_label.outline_size = 5
	status_label.modulate = Color("#D9F7FF")
	add_child(status_label)
	decision_timer = rng.randf_range(0.4, 2.0)

func set_job_route(points:Array[Vector3], room_id:String) -> void:
	assigned_room_id = room_id
	waypoint_queue = points.duplicate()
	if waypoint_queue.is_empty():
		working = true
		work_timer = rng.randf_range(2.0, 5.0)
		return
	target_position = waypoint_queue.pop_front()
	walking = true
	working = false
	status_label.text = "%s\n→ %s" % [display_name, room_id.capitalize()]

func send_home(points:Array[Vector3]) -> void:
	set_job_route(points, "quarters")

func _process(delta:float) -> void:
	step_clock += delta
	if walking:
		_move_step(delta)
	elif working:
		_work_step(delta)
	else:
		decision_timer -= delta
		if decision_timer <= 0.0:
			working = true
			work_timer = rng.randf_range(1.5, 3.5)
	_animate_body()

func _animate_body() -> void:
	if visual_root == null:
		return
	var walk_wave:float = sin(step_clock * 10.0 + animation_phase)
	var idle_wave:float = sin(step_clock * 2.2 + animation_phase)
	var working_wave:float = sin(step_clock * 5.0 + animation_phase)
	var bob:float = walk_wave * 0.055 if walking else idle_wave * 0.018
	visual_root.position.y = bob
	visual_root.rotation_degrees.z = walk_wave * 1.8 if walking else idle_wave * 0.4
	if left_leg != null:
		left_leg.rotation_degrees.x = walk_wave * 28.0 if walking else 0.0
	if right_leg != null:
		right_leg.rotation_degrees.x = -walk_wave * 28.0 if walking else 0.0
	if left_arm != null:
		left_arm.rotation_degrees.x = -walk_wave * 24.0 if walking else _work_arm_angle(true, working_wave)
		left_arm.rotation_degrees.z = -4.0 + idle_wave * 1.5
	if right_arm != null:
		right_arm.rotation_degrees.x = walk_wave * 24.0 if walking else _work_arm_angle(false, working_wave)
		right_arm.rotation_degrees.z = 4.0 - idle_wave * 1.5
	if head_pivot != null:
		head_pivot.rotation_degrees.y = sin(step_clock * 1.35 + animation_phase) * (7.0 if walking else 13.0)
		head_pivot.rotation_degrees.x = working_wave * 3.0 if working else 0.0

func _work_arm_angle(left_side:bool, wave:float) -> float:
	if not working:
		return sin(step_clock * 1.8 + animation_phase) * 2.0
	var normalized:String = role.to_lower()
	if normalized.contains("med"):
		return -38.0 + wave * (13.0 if left_side else -10.0)
	if normalized.contains("engineer") or normalized.contains("tech"):
		return -46.0 + wave * (20.0 if left_side else -18.0)
	if normalized.contains("marksman"):
		return -30.0 + wave * (8.0 if left_side else -8.0)
	if normalized.contains("guard"):
		return -12.0 + wave * (5.0 if left_side else -5.0)
	if normalized.contains("biker"):
		return -25.0 + wave * (12.0 if left_side else -12.0)
	return -18.0 + wave * (10.0 if left_side else -10.0)

func _move_step(delta:float) -> void:
	var flat_target := Vector3(target_position.x, position.y, target_position.z)
	var distance:float = position.distance_to(flat_target)
	if distance <= 0.12:
		position = flat_target
		if waypoint_queue.is_empty():
			walking = false
			working = true
			work_timer = rng.randf_range(4.0, 10.0)
			status_label.text = "%s\n%s" % [display_name, _activity_for_role(role)]
			reached_job.emit(self, assigned_room_id)
		else:
			target_position = waypoint_queue.pop_front()
		return
	var direction:Vector3 = (flat_target - position).normalized()
	position += direction * minf(move_speed * delta, distance)
	if direction.length_squared() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), minf(1.0, delta * 8.0))

func _work_step(delta:float) -> void:
	work_timer -= delta
	if role.to_lower().contains("biker"):
		rotation.y += delta * 0.25
	if work_timer <= 0.0:
		working = false
		decision_timer = rng.randf_range(1.0, 3.0)
		status_label.text = display_name

func _division_for_role(role_value:String) -> String:
	var normalized:String = role_value.to_lower()
	if normalized.contains("marksman") or normalized.contains("guard") or normalized.contains("biker"):
		return "Tactical"
	if normalized.contains("med"):
		return "Medical"
	if normalized.contains("engineer") or normalized.contains("tech"):
		return "Engineering"
	if normalized.contains("cell") or normalized.contains("detention"):
		return "Detention"
	return "Authority"

func _species_for_id(id_value:String) -> String:
	var selector:int = absi(id_value.hash()) % 3
	if selector == 1:
		return "Hybrid"
	if selector == 2:
		return "Human"
	return "Alien"

func _activity_for_role(role_value:String) -> String:
	var normalized:String = role_value.to_lower()
	if normalized.contains("marksman"):
		return "calibrating sights"
	if normalized.contains("biker"):
		return "servicing patrol craft"
	if normalized.contains("guard"):
		return "security duty"
	if normalized.contains("med"):
		return "treating personnel"
	if normalized.contains("engineer") or normalized.contains("tech"):
		return "repairing systems"
	return "working"
