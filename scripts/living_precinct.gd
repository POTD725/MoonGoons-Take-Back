extends Node3D
## Living MoonGoons precinct city with clickable rooms and animated personnel.

const ROOM_IDS:Array[String] = ["ops","armory","cells","quarters","medbay","chief","interrogation","transfer"]
const ROOM_POSITIONS:Dictionary = {
	"ops":Vector3(-14.25,0.0,-7.2), "armory":Vector3(-4.75,0.0,-7.2),
	"cells":Vector3(4.75,0.0,-7.2), "quarters":Vector3(14.25,0.0,-7.2),
	"medbay":Vector3(-14.25,0.0,7.2), "chief":Vector3(-4.75,0.0,7.2),
	"interrogation":Vector3(4.75,0.0,7.2), "transfer":Vector3(14.25,0.0,7.2)
}
const EXTRA_WORKERS:Array[Dictionary] = [
	{"id":"tech_1","name":"Patch","class":"Engineer","rarity":"Common","level":1},
	{"id":"tech_2","name":"Circuit","class":"Technician","rarity":"Common","level":1},
	{"id":"medic_1","name":"Mender","class":"Medic","rarity":"Common","level":1},
	{"id":"guard_1","name":"Bulkhead","class":"Guard","rarity":"Common","level":1},
	{"id":"clerk_1","name":"Ledger","class":"Authority","rarity":"Common","level":1},
	{"id":"runner_1","name":"Comet","class":"Biker","rarity":"Common","level":1}
]

var camera:Camera3D
var world_root:Node3D
var rooms_root:Node3D
var agents_root:Node3D
var room_nodes:Dictionary = {}
var agents:Array[PrecinctAgent] = []
var selected_room_id:String = "ops"
var selected_officer_index:int = 0
var selected_call_index:int = 0
var selected_task_index:int = 0
var current_tab:String = "city"
var route_clock:float = 0.0
var state_clock:float = 0.0
var camera_target:Vector3 = Vector3.ZERO
var camera_distance:float = 36.0
var camera_yaw:float = 0.0
var camera_pitch:float = -0.78
var dragging_camera:bool = false

var resource_label:Label
var status_label:Label
var room_title:Label
var room_info:Label
var officer_info:Label
var call_list:ItemList
var team_list:ItemList
var custody_info:Label
var task_list:ItemList
var city_panel:Control
var officer_panel:Control
var patrol_panel:Control
var custody_panel:Control
var tasks_panel:Control
var nav_buttons:Dictionary = {}

func _ready() -> void:
	_build_world()
	_build_interface()
	_connect_state()
	_rebuild_rooms()
	_spawn_agents()
	_refresh_interface()
	_update_camera()
	MoonGoonsAudio.play("confirm")

func _connect_state() -> void:
	if not PrecinctState.state_changed.is_connected(_on_state_changed):
		PrecinctState.state_changed.connect(_on_state_changed)
	if not PrecinctMeta.meta_changed.is_connected(_on_state_changed):
		PrecinctMeta.meta_changed.connect(_on_state_changed)

func _process(delta:float) -> void:
	state_clock += delta
	route_clock += delta
	if state_clock >= 0.25:
		state_clock = 0.0
		PrecinctState.tick()
	if route_clock >= 7.0:
		route_clock = 0.0
		_route_idle_agents()
	_update_camera_keyboard(delta)
	_update_camera()
	_animate_world(delta)

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			camera_distance = maxf(18.0,camera_distance-3.0)
			MoonGoonsAudio.play("click")
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			camera_distance = minf(54.0,camera_distance+3.0)
			MoonGoonsAudio.play("click")
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			dragging_camera = mouse_event.pressed
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_pick_world(mouse_event.position)
	elif event is InputEventMouseMotion and dragging_camera:
		var motion := event as InputEventMouseMotion
		camera_yaw -= motion.relative.x * 0.006
		camera_pitch = clampf(camera_pitch-motion.relative.y*0.004,-1.18,-0.38)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		camera_target.x -= drag.relative.x * 0.025
		camera_target.z -= drag.relative.y * 0.025

func _build_world() -> void:
	world_root = Node3D.new()
	world_root.name = "LivingPrecinctWorld"
	add_child(world_root)
	rooms_root = Node3D.new()
	rooms_root.name = "Rooms"
	world_root.add_child(rooms_root)
	agents_root = Node3D.new()
	agents_root.name = "Personnel"
	world_root.add_child(agents_root)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#020610")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#86BDE1")
	environment.ambient_light_energy = 0.48
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	add_child(environment_node)
	camera = Camera3D.new()
	camera.name = "CityCamera"
	camera.current = true
	camera.fov = 48.0
	add_child(camera)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-58.0,-28.0,0.0)
	key_light.light_color = Color("#D3EBFF")
	key_light.light_energy = 1.75
	key_light.shadow_enabled = true
	add_child(key_light)
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(0.0,14.0,0.0)
	fill_light.light_color = Color("#4AAEFF")
	fill_light.light_energy = 7.5
	fill_light.omni_range = 42.0
	add_child(fill_light)
	_build_moon_surface()
	_build_corridors()
	_build_exterior()

func _build_moon_surface() -> void:
	world_root.add_child(_box_mesh(Vector3(62.0,0.6,42.0),Vector3(0.0,-0.45,0.0),"#182231",0.0))
	for crater_index in range(18):
		world_root.add_child(_cylinder_mesh(1.1+float(crater_index%4)*0.55,0.08,Vector3(-28.0+float((crater_index*7)%56),-0.1,-18.0+float((crater_index*11)%36)),"#101824",0.0))
	for star_index in range(70):
		world_root.add_child(_sphere_mesh(0.035+float(star_index%3)*0.018,Vector3(-36.0+float((star_index*13)%72),12.0+float((star_index*17)%26),-30.0-float(star_index%5)),"#BEEBFF",0.6))

func _build_corridors() -> void:
	world_root.add_child(_box_mesh(Vector3(39.5,0.22,4.2),Vector3.ZERO,"#203950",0.02))
	for x_value in [-14.25,-4.75,4.75,14.25]:
		world_root.add_child(_box_mesh(Vector3(3.0,0.24,5.2),Vector3(float(x_value),0.02,0.0),"#26445C",0.03))
	for strip_index in range(18):
		world_root.add_child(_box_mesh(Vector3(1.35,0.03,0.10),Vector3(-16.8+float(strip_index)*1.98,0.17,0.0),"#54D8F4",0.23))
	for x_value in [-19.1,19.1]:
		world_root.add_child(_box_mesh(Vector3(0.4,2.3,22.0),Vector3(float(x_value),1.15,0.0),"#23384B",0.0))

func _build_exterior() -> void:
	world_root.add_child(_cylinder_mesh(6.2,0.35,Vector3(25.2,0.0,7.2),"#243D51",0.0))
	for ring_radius in [5.5,4.0,2.3]:
		world_root.add_child(_torus_mesh(float(ring_radius),0.10,Vector3(25.2,0.22,7.2),"#35D8FF",0.65))
	var shuttle := Node3D.new()
	shuttle.name = "PatrolShuttle"
	shuttle.position = Vector3(25.2,0.9,7.2)
	shuttle.add_child(_box_mesh(Vector3(4.6,0.9,2.2),Vector3.ZERO,"#253C5C",0.0))
	shuttle.add_child(_box_mesh(Vector3(1.6,0.55,1.9),Vector3(1.4,0.55,0.0),"#3B6480",0.0))
	shuttle.add_child(_box_mesh(Vector3(0.95,0.32,1.6),Vector3(2.22,0.58,0.0),"#79E5FF",0.55))
	for engine_z in [-0.72,0.72]:
		shuttle.add_child(_cylinder_mesh(0.28,0.85,Vector3(-2.1,0.0,float(engine_z)),"#66DFFF",0.85))
	world_root.add_child(shuttle)
	world_root.add_child(_cylinder_mesh(1.1,7.0,Vector3(-25.0,3.4,-10.0),"#23374D",0.0))
	world_root.add_child(_sphere_mesh(1.4,Vector3(-25.0,7.25,-10.0),"#55DFFF",0.35))

func _rebuild_rooms() -> void:
	for child:Node in rooms_root.get_children(): child.queue_free()
	room_nodes.clear()
	for index in range(ROOM_IDS.size()):
		var room_id:String = ROOM_IDS[index]
		var room_node:Node3D = PrecinctRoomFactory.build_room(room_id,PrecinctState.get_room(room_id))
		room_node.position = ROOM_POSITIONS[room_id] as Vector3
		if index >= 4: room_node.rotation.y = PI
		rooms_root.add_child(room_node)
		room_nodes[room_id] = room_node

func _spawn_agents() -> void:
	for child:Node in agents_root.get_children(): child.queue_free()
	agents.clear()
	var roster:Array[Dictionary] = []
	for officer:Dictionary in PrecinctState.officers:
		var data:Dictionary = officer.duplicate(true)
		data["assigned_room"] = PrecinctMeta.assigned_room_id(str(officer.get("id","")))
		roster.append(data)
	for extra:Dictionary in EXTRA_WORKERS: roster.append(extra.duplicate(true))
	for index in range(roster.size()):
		var agent := PrecinctAgent.new()
		agent.name = "Agent_%d" % index
		agent.configure(roster[index],Vector3(18.5+float(index%3)*0.8,0.0,3.2+float(index/3)*0.8))
		agent.reached_job.connect(_on_agent_reached_job)
		agents_root.add_child(agent)
		agents.append(agent)
		_route_agent(agent,_initial_room_for(roster[index],index))

func _initial_room_for(data:Dictionary,index:int) -> String:
	var assigned:String = str(data.get("assigned_room",""))
	if not assigned.is_empty() and room_nodes.has(assigned): return assigned
	var role:String = str(data.get("class","Authority")).to_lower()
	if role.contains("med"): return "medbay"
	if role.contains("engineer") or role.contains("tech"): return "armory" if index%2==0 else "ops"
	if role.contains("marksman") or role.contains("biker"): return "armory"
	if role.contains("guard"): return "cells"
	return ROOM_IDS[index%ROOM_IDS.size()]

func _route_idle_agents() -> void:
	for index in range(agents.size()):
		var agent:PrecinctAgent = agents[index]
		if agent.walking: continue
		var assigned:String = PrecinctMeta.assigned_room_id(agent.officer_id)
		var destination:String = assigned if not assigned.is_empty() else ROOM_IDS[(index+int(Time.get_ticks_msec()/7000))%ROOM_IDS.size()]
		if not bool(PrecinctState.get_room(destination).get("repaired",false)): destination = "ops"
		_route_agent(agent,destination)

func _route_agent(agent:PrecinctAgent,room_id:String) -> void:
	if not room_nodes.has(room_id): return
	var room_node:Node3D = room_nodes[room_id] as Node3D
	var door:Marker3D = room_node.get_node_or_null("Door") as Marker3D
	if door == null: return
	var job_markers:Array[Marker3D] = []
	for child:Node in room_node.get_children():
		if child is Marker3D and child.name.begins_with("Job"): job_markers.append(child as Marker3D)
	var job:Marker3D = door
	if not job_markers.is_empty(): job = job_markers[absi(agent.officer_id.hash())%job_markers.size()]
	var route:Array[Vector3] = [
		Vector3(agent.position.x,0.0,0.0),
		Vector3(door.global_position.x,0.0,0.0),
		Vector3(door.global_position.x,0.0,door.global_position.z),
		Vector3(job.global_position.x,0.0,job.global_position.z)
	]
	agent.set_job_route(route,room_id)

func _pick_world(screen_position:Vector2) -> void:
	var origin:Vector3 = camera.project_ray_origin(screen_position)
	var direction:Vector3 = camera.project_ray_normal(screen_position)
	var result:Dictionary = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,origin+direction*200.0))
	if result.is_empty(): return
	var collider:Object = result.get("collider") as Object
	if collider == null or not collider.has_meta("room_id"): return
	selected_room_id = str(collider.get_meta("room_id","ops"))
	camera_target = ROOM_POSITIONS[selected_room_id] as Vector3
	camera_distance = 28.0
	_show_tab("city")
	MoonGoonsAudio.play("door")

func _update_camera_keyboard(delta:float) -> void:
	var move := Vector3.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): move.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): move.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): move.z += 1.0
	if move.length_squared() > 0.0:
		camera_target += move.normalized()*delta*9.0
		camera_target.x = clampf(camera_target.x,-24.0,24.0)
		camera_target.z = clampf(camera_target.z,-15.0,15.0)

func _update_camera() -> void:
	if camera == null: return
	var horizontal:float = cos(camera_pitch)*camera_distance
	camera.position = camera_target+Vector3(sin(camera_yaw)*horizontal,-sin(camera_pitch)*camera_distance,cos(camera_yaw)*horizontal)
	camera.look_at(camera_target+Vector3(0.0,0.8,0.0),Vector3.UP)

func _animate_world(delta:float) -> void:
	var shuttle:Node3D = world_root.get_node_or_null("PatrolShuttle") as Node3D
	if shuttle != null:
		shuttle.position.y = 0.9+sin(float(Time.get_ticks_msec())*0.0013)*0.12
		shuttle.rotation.y += delta*0.035

func _build_interface() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Interface"
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 64.0
	root.add_child(top)
	var top_row := HBoxContainer.new()
	top.add_child(top_row)
	var title := Label.new()
	title.text = "  MOONGOONS TAKE BACK // LIVING LUNAR PRECINCT"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size",18)
	top_row.add_child(title)
	resource_label = Label.new()
	resource_label.custom_minimum_size = Vector2(600.0,0.0)
	resource_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_row.add_child(resource_label)
	var zoom_help := Label.new()
	zoom_help.text = "   RMB drag • wheel zoom • WASD pan   "
	top_row.add_child(zoom_help)
	city_panel = _make_city_panel(root)
	officer_panel = _make_officer_panel(root)
	patrol_panel = _make_patrol_panel(root)
	custody_panel = _make_custody_panel(root)
	tasks_panel = _make_tasks_panel(root)
	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -70.0
	root.add_child(bottom)
	var bottom_column := VBoxContainer.new()
	bottom.add_child(bottom_column)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_column.add_child(nav)
	for tab_id in ["city","officers","patrol","custody","tasks"]:
		var button := Button.new()
		button.text = str(tab_id).to_upper()
		button.custom_minimum_size = Vector2(138.0,36.0)
		button.pressed.connect(_on_tab_pressed.bind(str(tab_id)))
		nav.add_child(button)
		nav_buttons[tab_id] = button
	var router_button := Button.new()
	router_button.text = "CAMPAIGN ROUTER"
	router_button.custom_minimum_size = Vector2(164.0,36.0)
	router_button.pressed.connect(_open_router)
	nav.add_child(router_button)
	var rts_button := Button.new()
	rts_button.text = "RTS FRONT"
	rts_button.custom_minimum_size = Vector2(130.0,36.0)
	rts_button.pressed.connect(_open_rts)
	nav.add_child(rts_button)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.text = "Precinct online. Select a room or command view."
	bottom_column.add_child(status_label)
	_show_tab("city")

func _panel_base(root:Control,title_text:String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.position = Vector2(18.0,82.0)
	panel.size = Vector2(330.0,540.0)
	root.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	panel.add_child(column)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",17)
	column.add_child(title)
	return column

func _make_city_panel(root:Control) -> Control:
	var column:VBoxContainer = _panel_base(root,"SELECTED DIVISION")
	room_title = Label.new()
	room_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_title.add_theme_font_size_override("font_size",20)
	column.add_child(room_title)
	room_info = Label.new()
	room_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	room_info.custom_minimum_size = Vector2(300.0,255.0)
	column.add_child(room_info)
	column.add_child(_button("REPAIR ROOM",_repair_selected))
	column.add_child(_button("UPGRADE ROOM",_upgrade_selected))
	column.add_child(_button("ASSIGN SELECTED OFFICER",_assign_selected))
	column.add_child(_button("FOCUS CAMERA",_focus_selected_room))
	return column.get_parent() as Control

func _make_officer_panel(root:Control) -> Control:
	var column:VBoxContainer = _panel_base(root,"OFFICER PERSONNEL")
	officer_info = Label.new()
	officer_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	officer_info.custom_minimum_size = Vector2(300.0,320.0)
	column.add_child(officer_info)
	var row := HBoxContainer.new()
	row.add_child(_button("◀ PREVIOUS",_previous_officer))
	row.add_child(_button("NEXT ▶",_next_officer))
	column.add_child(row)
	column.add_child(_button("TRAIN OFFICER",_train_officer))
	column.add_child(_button("HEAL OFFICER",_heal_officer))
	column.add_child(_button("POST TO SELECTED ROOM",_assign_selected))
	return column.get_parent() as Control

func _make_patrol_panel(root:Control) -> Control:
	var column:VBoxContainer = _panel_base(root,"PATROL DISPATCH")
	call_list = ItemList.new()
	call_list.custom_minimum_size = Vector2(300.0,190.0)
	call_list.item_selected.connect(_on_call_selected)
	column.add_child(call_list)
	var formation_label := Label.new()
	formation_label.text = "FORMATION // SELECT UP TO 3"
	column.add_child(formation_label)
	team_list = ItemList.new()
	team_list.select_mode = ItemList.SELECT_MULTI
	team_list.custom_minimum_size = Vector2(300.0,180.0)
	column.add_child(team_list)
	column.add_child(_button("DISPATCH PATROL",_dispatch_patrol))
	return column.get_parent() as Control

func _make_custody_panel(root:Control) -> Control:
	var column:VBoxContainer = _panel_base(root,"CUSTODY OPERATIONS")
	custody_info = Label.new()
	custody_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	custody_info.custom_minimum_size = Vector2(300.0,300.0)
	column.add_child(custody_info)
	column.add_child(_button("PROCESS PRISONER",_process_prisoner))
	column.add_child(_button("INTERROGATE",_interrogate_prisoner))
	column.add_child(_button("SECURE TRANSFER",_transfer_prisoner))
	return column.get_parent() as Control

func _make_tasks_panel(root:Control) -> Control:
	var column:VBoxContainer = _panel_base(root,"CHAPTER & DAILY TASKS")
	task_list = ItemList.new()
	task_list.custom_minimum_size = Vector2(300.0,390.0)
	task_list.item_selected.connect(_on_task_selected)
	column.add_child(task_list)
	column.add_child(_button("CLAIM SELECTED REWARD",_claim_task))
	return column.get_parent() as Control

func _button(text_value:String,callback:Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(140.0,38.0)
	button.pressed.connect(callback)
	return button

func _show_tab(tab_id:String) -> void:
	current_tab = tab_id
	city_panel.visible = tab_id=="city"
	officer_panel.visible = tab_id=="officers"
	patrol_panel.visible = tab_id=="patrol"
	custody_panel.visible = tab_id=="custody"
	tasks_panel.visible = tab_id=="tasks"
	for key_value:Variant in nav_buttons.keys():
		var key:String = str(key_value)
		(nav_buttons[key] as Button).disabled = key==tab_id
	_refresh_interface()

func _refresh_interface() -> void:
	if resource_label == null: return
	resource_label.text = "CREDITS %04d   INTEL %03d   EVIDENCE %02d   PRISONERS %02d   REP %03d  " % [PrecinctState.credits,PrecinctState.intel,PrecinctState.evidence,PrecinctState.prisoners,PrecinctMeta.reputation]
	var room:Dictionary = PrecinctState.get_room(selected_room_id)
	room_title.text = str(room.get("name","Room")).to_upper()
	var assigned_id:String = PrecinctMeta.assigned_officer_id(selected_room_id)
	var assigned_name:String = "UNSTAFFED"
	if not assigned_id.is_empty(): assigned_name = str(PrecinctState.get_officer(assigned_id).get("name",assigned_id))
	room_info.text = "STATUS: %s\nLEVEL: %d\nFUNCTION: %s\nSTAFF: %s\nREPAIR COST: %d\n\nClick the room in the city to focus it. Repairs and upgrades immediately change its lighting, equipment, and worker activity." % ["ONLINE" if bool(room.get("repaired",false)) else "DAMAGED",int(room.get("level",1)),str(room.get("function","Operations")),assigned_name,int(room.get("repair_cost",0))]
	if not PrecinctState.officers.is_empty():
		selected_officer_index = clampi(selected_officer_index,0,PrecinctState.officers.size()-1)
		var officer:Dictionary = PrecinctState.officers[selected_officer_index]
		var assignment:String = PrecinctMeta.assigned_room_id(str(officer.get("id","")))
		officer_info.text = "%s\n%s // %s\nLEVEL %d\nPOWER %d\nDEFENSE %d\nHEALTH %d / %d\nXP %d\nPOSTED: %s\n\nTraining increases combat stats. Posting an officer makes their character walk to that room and work there." % [str(officer.get("name","Officer")).to_upper(),str(officer.get("class","Guard")),str(officer.get("rarity","Common")),int(officer.get("level",1)),int(officer.get("power",0)),int(officer.get("defense",0)),int(officer.get("hp",0)),int(officer.get("max_hp",100)),int(officer.get("xp",0)),assignment.capitalize() if not assignment.is_empty() else "UNASSIGNED"]
	_refresh_patrol_lists()
	custody_info.text = "DETAINED SUSPECTS: %d\nEVIDENCE ITEMS: %d\nINTERROGATED: %d\nTRANSFERRED: %d\n\nProcessing earns credits and intel. Interrogation requires the Interrogation division. Secure transfer requires the Transfer Hall." % [PrecinctState.prisoners,PrecinctState.evidence,PrecinctMeta.prisoners_interrogated,PrecinctMeta.prisoners_transferred]
	_refresh_tasks()

func _refresh_patrol_lists() -> void:
	if call_list == null: return
	call_list.clear()
	for call:Dictionary in PrecinctState.patrol_calls:
		call_list.add_item("D%d  %s // %s // %d CR" % [int(call.get("difficulty",1)),str(call.get("title","Call")),str(call.get("sector","Sector")),int(call.get("reward",0))])
	if not PrecinctState.patrol_calls.is_empty():
		selected_call_index = clampi(selected_call_index,0,PrecinctState.patrol_calls.size()-1)
		call_list.select(selected_call_index)
	team_list.clear()
	for officer:Dictionary in PrecinctState.officers:
		var available:bool = PrecinctState.officer_available(officer)
		team_list.add_item("%s // %s // PWR %d%s" % [str(officer.get("name","Officer")),str(officer.get("class","Guard")),int(officer.get("power",0)),"" if available else " // BUSY"])

func _refresh_tasks() -> void:
	if task_list == null: return
	task_list.clear()
	for task:Dictionary in PrecinctMeta.task_catalog():
		var task_id:String = str(task.get("id",""))
		var claimed:String = " // CLAIMED" if PrecinctMeta.task_claimed(task_id) else ""
		task_list.add_item("[%s] %s  %d/%d%s" % [str(task.get("group","TASK")),str(task.get("title","Task")),int(task.get("progress",0)),int(task.get("target",1)),claimed])
	if task_list.item_count>0:
		selected_task_index = clampi(selected_task_index,0,task_list.item_count-1)
		task_list.select(selected_task_index)

func _repair_selected() -> void: _action_result(PrecinctState.repair_room(selected_room_id),"repair")
func _upgrade_selected() -> void: _action_result(PrecinctMeta.upgrade_room(selected_room_id),"upgrade")

func _assign_selected() -> void:
	if PrecinctState.officers.is_empty(): return
	var officer:Dictionary = PrecinctState.officers[selected_officer_index]
	var result:Dictionary = PrecinctMeta.assign_officer(str(officer.get("id","")),selected_room_id)
	_action_result(result,"confirm")
	if bool(result.get("ok",false)):
		for agent:PrecinctAgent in agents:
			if agent.officer_id==str(officer.get("id","")): _route_agent(agent,selected_room_id)

func _train_officer() -> void:
	if not PrecinctState.officers.is_empty(): _action_result(PrecinctMeta.train_officer(str(PrecinctState.officers[selected_officer_index].get("id",""))),"upgrade")

func _heal_officer() -> void:
	if not PrecinctState.officers.is_empty(): _action_result(PrecinctMeta.heal_officer(str(PrecinctState.officers[selected_officer_index].get("id",""))),"confirm")

func _previous_officer() -> void:
	if PrecinctState.officers.is_empty(): return
	selected_officer_index = wrapi(selected_officer_index-1,0,PrecinctState.officers.size())
	MoonGoonsAudio.play("click")
	_refresh_interface()

func _next_officer() -> void:
	if PrecinctState.officers.is_empty(): return
	selected_officer_index = wrapi(selected_officer_index+1,0,PrecinctState.officers.size())
	MoonGoonsAudio.play("click")
	_refresh_interface()

func _dispatch_patrol() -> void:
	if PrecinctState.patrol_calls.is_empty():
		_action_result({"ok":false,"message":"No active distress call."},"error")
		return
	var ids:Array[String] = []
	for item_index:int in team_list.get_selected_items():
		if item_index>=0 and item_index<PrecinctState.officers.size(): ids.append(str(PrecinctState.officers[item_index].get("id","")))
	var call:Dictionary = PrecinctState.patrol_calls[selected_call_index]
	var result:Dictionary = PrecinctState.begin_patrol(str(call.get("id","")),ids)
	if bool(result.get("ok",false)):
		MoonGoonsAudio.play("dispatch")
		get_tree().change_scene_to_file("res://scenes/PrecinctBattle.tscn")
	else: _action_result(result,"error")

func _process_prisoner() -> void: _action_result(PrecinctMeta.custody_action("process"),"reward")
func _interrogate_prisoner() -> void: _action_result(PrecinctMeta.custody_action("interrogate"),"confirm")
func _transfer_prisoner() -> void: _action_result(PrecinctMeta.custody_action("transfer"),"dispatch")

func _claim_task() -> void:
	var tasks:Array[Dictionary] = PrecinctMeta.task_catalog()
	if tasks.is_empty(): return
	selected_task_index = clampi(selected_task_index,0,tasks.size()-1)
	_action_result(PrecinctMeta.claim_task(str(tasks[selected_task_index].get("id",""))),"reward")

func _focus_selected_room() -> void:
	camera_target = ROOM_POSITIONS[selected_room_id] as Vector3
	camera_distance = 24.0
	MoonGoonsAudio.play("click")

func _on_tab_pressed(tab_id:String) -> void:
	MoonGoonsAudio.play("click")
	_show_tab(tab_id)

func _on_call_selected(index:int) -> void:
	selected_call_index = index
	MoonGoonsAudio.play("click")

func _on_task_selected(index:int) -> void:
	selected_task_index = index
	MoonGoonsAudio.play("click")

func _open_router() -> void:
	MoonGoonsAudio.play("confirm")
	get_tree().change_scene_to_file("res://scenes/CampaignRouter.tscn")

func _open_rts() -> void:
	MoonGoonsAudio.play("dispatch")
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _action_result(result:Dictionary,success_sound:String) -> void:
	status_label.text = str(result.get("message","Action completed."))
	MoonGoonsAudio.play(success_sound if bool(result.get("ok",false)) else "error")
	_refresh_interface()

func _on_state_changed() -> void:
	_rebuild_rooms()
	_refresh_interface()

func _on_agent_reached_job(_agent:PrecinctAgent,_room_id:String) -> void:
	if randi()%4==0: MoonGoonsAudio.play("work")

func _box_mesh(size_value:Vector3,position_value:Vector3,color_hex:String,emission:float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex,emission)
	return node

func _sphere_mesh(radius_value:float,position_value:Vector3,color_hex:String,emission:float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius_value
	mesh.height = radius_value*2.0
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex,emission)
	return node

func _cylinder_mesh(radius_value:float,height_value:float,position_value:Vector3,color_hex:String,emission:float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius_value
	mesh.bottom_radius = radius_value
	mesh.height = height_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex,emission)
	return node

func _torus_mesh(radius_value:float,tube_radius:float,position_value:Vector3,color_hex:String,emission:float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = maxf(0.1,radius_value-tube_radius)
	mesh.outer_radius = radius_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex,emission)
	return node

func _material(color_hex:String,emission:float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var color := Color.from_string(color_hex,Color.WHITE)
	material.albedo_color = color
	material.roughness = 0.62
	if emission>0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material
