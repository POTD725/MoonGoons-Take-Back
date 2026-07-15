extends SceneTree

var failures:int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var room_factory:Script = load("res://scripts/precinct_room_factory.gd") as Script
	var officer_factory:Script = load("res://scripts/officer_visual_factory.gd") as Script
	var agent_script:Script = load("res://scripts/precinct_agent.gd") as Script
	var audio_script:Script = load("res://scripts/moongoons_audio.gd") as Script
	var living_script:Script = load("res://scripts/living_precinct.gd") as Script
	var polish_script:Script = load("res://scripts/living_precinct_ui_polish.gd") as Script
	var input_script:Script = load("res://scripts/living_precinct_input_bridge.gd") as Script
	_expect(room_factory != null,"3D room factory loads")
	_expect(officer_factory != null,"Officer visual factory loads")
	_expect(agent_script != null,"Walking agent AI loads")
	_expect(audio_script != null,"Generated audio service loads")
	_expect(living_script != null,"Living precinct controller loads")
	_expect(polish_script != null,"Responsive precinct graphics layer loads")
	_expect(input_script != null,"Camera input bridge loads")

	var art_paths:Array[String] = [
		"res://assets/precinct/rooms/ops_center.svg",
		"res://assets/precinct/rooms/armory.svg",
		"res://assets/precinct/rooms/holding_cells.svg",
		"res://assets/precinct/rooms/crew_quarters.svg",
		"res://assets/precinct/rooms/medbay.svg",
		"res://assets/precinct/rooms/chief_office.svg",
		"res://assets/precinct/rooms/interrogation.svg",
		"res://assets/precinct/rooms/transfer_hall.svg"
	]
	for art_path:String in art_paths:
		_expect(load(art_path) is Texture2D,"Illustrated room art imports: %s" % art_path.get_file())

	var room_data:Dictionary = {"name":"Operations Center","repaired":true,"level":2}
	var room:Node3D = PrecinctRoomFactory.build_room("ops",room_data)
	root.add_child(room)
	_expect(room.has_meta("room_id"),"Room exposes a selectable room id")
	_expect(room.get_node_or_null("Door") is Marker3D,"Room exposes a corridor door marker")
	_expect(room.get_node_or_null("Job0") is Marker3D,"Room exposes worker job markers")
	_expect(room.get_node_or_null("ClickArea") is StaticBody3D,"Room exposes a 3D click collider")
	_expect(room.get_node_or_null("RoomArt") is MeshInstance3D,"Room mounts an illustrated interior backdrop")
	var room_label:Label3D = room.get_node_or_null("RoomLabel") as Label3D
	_expect(room_label != null and not room_label.text.contains("\n"),"Room signage is compact and single-line")
	var skin_service:Node = root.get_node_or_null("MoonGoonsSkins")
	if skin_service != null and bool(skin_service.call("assets_ready")):
		_expect(room.get_node_or_null("EstablishedMoonGoonsArt") is MeshInstance3D,"Room mounts established MoonGoons artwork")
	room.queue_free()

	var officer:Node3D = OfficerVisualFactory.build_authority_officer({"name":"Test Officer","division":"Tactical","rank":2})
	root.add_child(officer)
	_expect(officer.get_child_count() >= 10,"Officer factory builds a full multipart character")
	officer.queue_free()

	var agent:PrecinctAgent = PrecinctAgent.new()
	root.add_child(agent)
	agent.configure({"id":"test_agent","name":"Test Agent","class":"Engineer"},Vector3.ZERO)
	agent.set_job_route([Vector3(1.0,0.0,0.0),Vector3(2.0,0.0,0.0)],"ops")
	_expect(agent.walking,"Configured agent begins walking a job route")
	_expect(agent.waypoint_queue.size() == 1,"Agent consumes the first target and preserves the remaining route")
	agent.queue_free()

	var scene:PackedScene = load("res://scenes/LivingPrecinct.tscn") as PackedScene
	_expect(scene != null,"Living precinct scene parses")
	if scene != null:
		var instance:Node = scene.instantiate()
		root.add_child(instance)
		await process_frame
		await process_frame
		await process_frame
		await process_frame
		await process_frame
		await process_frame
		_expect(instance.get_node_or_null("LivingPrecinctWorld") is Node3D,"Full city world builds at runtime")
		_expect(instance.get_node_or_null("CityCamera") is Camera3D,"Runtime camera is active")
		_expect(instance.get_node_or_null("Interface") is CanvasLayer,"Runtime management interface builds")
		_expect(instance.get_node_or_null("VisualPolish") is Node,"Responsive art and HUD polish layer is attached")
		var input_bridge:Node = instance.get_node_or_null("CameraInputBridge")
		_expect(input_bridge != null,"Camera input bridge is attached")
		var rooms_node:Node = instance.get_node_or_null("LivingPrecinctWorld/Rooms")
		var personnel_node:Node = instance.get_node_or_null("LivingPrecinctWorld/Personnel")
		_expect(rooms_node != null and rooms_node.get_child_count() == 8,"All eight room interiors build at runtime")
		_expect(personnel_node != null and personnel_node.get_child_count() >= 10,"Walking officer and worker population builds at runtime")
		var preview:TextureRect = _find_by_name(instance,"SelectedRoomArtwork") as TextureRect
		_expect(preview != null and preview.texture != null,"Selected-room inspector displays illustrated artwork")
		var title_label:Label = _find_label(instance,"LIVING LUNAR PRECINCT")
		var resource_value:Variant = instance.get("resource_label")
		_expect(title_label != null,"Responsive header preserves the precinct title")
		_expect(resource_value is Label and title_label != null and (resource_value as Label).get_parent() != title_label.get_parent(),"Title and economy telemetry use separate header rows")
		if input_bridge != null:
			_expect(input_bridge.get_node_or_null("CameraControlsLayer") is CanvasLayer,"On-screen camera controls build at runtime")
			var target_before:Vector3 = instance.get("camera_target")
			input_bridge.call("nudge_camera",Vector2(1.0,0.0),2.0)
			var target_after:Vector3 = instance.get("camera_target")
			_expect(target_after.distance_to(target_before) > 1.0,"Camera input command moves the city target")
			var distance_before:float = float(instance.get("camera_distance"))
			input_bridge.call("zoom_camera",-3.0)
			_expect(float(instance.get("camera_distance")) < distance_before,"Camera input command changes zoom")
		instance.queue_free()

	var project_file:ConfigFile = ConfigFile.new()
	var config_error:Error = project_file.load("res://project.godot")
	_expect(config_error == OK,"Project configuration loads")
	_expect(String(project_file.get_value("application","run/main_scene","")) == "res://scenes/CampaignRouter.tscn","Campaign router remains the startup scene")
	_expect(String(project_file.get_value("autoload","MoonGoonsAudio","")) == "*res://scripts/moongoons_audio.gd","Precinct audio service is registered")
	_expect(String(project_file.get_value("autoload","SyndicateAudio","")) == "*res://scripts/syndicate_audio.gd","Syndicate audio service remains registered")
	var router_file:FileAccess = FileAccess.open("res://scripts/campaign_router.gd",FileAccess.READ)
	_expect(router_file != null,"Campaign router script can be read")
	if router_file != null:
		var router_text:String = router_file.get_as_text()
		_expect(router_text.contains("res://scenes/LivingPrecinct.tscn"),"Peacekeeper campaign routes to the living precinct")

	await process_frame
	if failures == 0:
		print("SUCCESS: Living precinct graphics, input, and integration smoke tests passed.")
	else:
		push_error("FAILED: %d living precinct smoke test(s) failed." % failures)
	quit(failures)

func _find_by_name(root_node:Node,node_name:String) -> Node:
	if root_node.name == node_name:
		return root_node
	for child:Node in root_node.get_children():
		var found:Node = _find_by_name(child,node_name)
		if found != null:
			return found
	return null

func _find_label(root_node:Node,needle:String) -> Label:
	if root_node is Label and (root_node as Label).text.contains(needle):
		return root_node as Label
	for child:Node in root_node.get_children():
		var found:Label = _find_label(child,needle)
		if found != null:
			return found
	return null

func _expect(condition:bool,label:String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
