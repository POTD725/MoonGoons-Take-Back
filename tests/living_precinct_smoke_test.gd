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
	var campaign_script:Script = load("res://scripts/peacekeeper_campaign_mode.gd") as Script
	var cleanup_script:Script = load("res://scripts/living_precinct_view_cleanup.gd") as Script
	_expect(room_factory != null,"3D room factory loads")
	_expect(officer_factory != null,"Officer visual factory loads")
	_expect(agent_script != null,"Walking agent AI loads")
	_expect(audio_script != null,"Generated audio service loads")
	_expect(living_script != null,"Living precinct controller loads")
	_expect(polish_script != null,"Responsive precinct graphics layer loads")
	_expect(input_script != null,"Camera input bridge loads")
	_expect(campaign_script != null,"Peacekeeper counter-Syndicate identity layer loads")
	_expect(cleanup_script != null,"Unobstructed precinct view cleanup loads")

	var art_paths:Array[String] = [
		"res://assets/precinct/rooms/ops_center.svg",
		"res://assets/precinct/rooms/armory.svg",
		"res://assets/precinct/rooms/holding_cells.svg",
		"res://assets/precinct/rooms/crew_quarters.svg",
		"res://assets/precinct/rooms/medbay.svg",
		"res://assets/precinct/rooms/chief_office.svg",
		"res://assets/precinct/rooms/interrogation.svg",
		"res://assets/precinct/rooms/transfer_hall.svg",
		"res://assets/ui/patrol_spacecraft.svg"
	]
	for art_path:String in art_paths:
		_expect(load(art_path) is Texture2D,"Artwork imports: %s" % art_path.get_file())

	var room_data:Dictionary = {"name":"Operations Center","repaired":true,"level":2}
	var room:Node3D = PrecinctRoomFactory.build_room("ops",room_data)
	root.add_child(room)
	_expect(room.has_meta("room_id"),"Room exposes a selectable room id")
	_expect(room.get_node_or_null("Door") is Marker3D,"Room exposes a corridor door marker")
	_expect(room.get_node_or_null("Job0") is Marker3D,"Room exposes worker job markers")
	_expect(room.get_node_or_null("ClickArea") is StaticBody3D,"Room exposes a 3D click collider")
	var room_label:Label3D = room.get_node_or_null("RoomLabel") as Label3D
	_expect(room_label != null and not room_label.text.contains("\n"),"Room signage is compact and single-line")
	room.queue_free()

	var officer:Node3D = OfficerVisualFactory.build_authority_officer({"name":"Test Officer","division":"Tactical","rank":2})
	root.add_child(officer)
	_expect(officer.get_child_count() >= 10,"Officer factory builds a full multipart character")
	_expect(officer.get_node_or_null("ArmLeft") is Node3D and officer.get_node_or_null("ArmRight") is Node3D,"Officer rig has articulated arms")
	_expect(officer.get_node_or_null("LegLeft") is Node3D and officer.get_node_or_null("LegRight") is Node3D,"Officer rig has articulated legs")
	_expect(officer.get_node_or_null("HeadPivot") is Node3D,"Officer rig has an animated head pivot")
	officer.queue_free()

	var agent:PrecinctAgent = PrecinctAgent.new()
	root.add_child(agent)
	agent.configure({"id":"test_agent","name":"Test Agent","class":"Engineer"},Vector3.ZERO)
	agent.set_job_route([Vector3(1.0,0.0,0.0),Vector3(2.0,0.0,0.0)],"ops")
	var start_position:Vector3 = agent.position
	var start_arm_rotation:Vector3 = (agent.visual_root.get_node("ArmLeft") as Node3D).rotation_degrees
	for _frame:int in range(20):
		await process_frame
	_expect(agent.walking,"Configured agent begins walking a job route")
	_expect(agent.position.distance_to(start_position) > 0.01,"Animated NPC moves across the station deck")
	_expect((agent.visual_root.get_node("ArmLeft") as Node3D).rotation_degrees.distance_to(start_arm_rotation) > 0.1,"Animated NPC swings articulated limbs")
	_expect(agent.is_in_group("animated_station_npcs"),"NPC is registered for animation auditing")
	agent.queue_free()

	var scene:PackedScene = load("res://scenes/LivingPrecinct.tscn") as PackedScene
	_expect(scene != null,"Living precinct scene parses")
	if scene != null:
		var instance:Node = scene.instantiate()
		root.add_child(instance)
		for _frame:int in range(16):
			await process_frame
		_expect(instance.get_node_or_null("LivingPrecinctWorld") is Node3D,"Full station world builds at runtime")
		_expect(instance.get_node_or_null("CityCamera") is Camera3D,"Runtime station camera is active")
		_expect(instance.get_node_or_null("Interface") is CanvasLayer,"Runtime management interface builds")
		_expect(instance.get_node_or_null("VisualPolish") is Node,"Responsive art and HUD polish layer is attached")
		_expect(instance.get_node_or_null("PeacekeeperCampaignMode") is Node,"Peacekeeper campaign mode is attached")
		_expect(instance.get_node_or_null("UnobstructedViewCleanup") is Node,"Unobstructed station cleanup is attached")
		var input_bridge:Node = instance.get_node_or_null("CameraInputBridge")
		_expect(input_bridge != null,"Camera input bridge is attached")
		var rooms_node:Node = instance.get_node_or_null("LivingPrecinctWorld/Rooms")
		var personnel_node:Node = instance.get_node_or_null("LivingPrecinctWorld/Personnel")
		_expect(rooms_node != null and rooms_node.get_child_count() == 8,"All eight room interiors build at runtime")
		_expect(personnel_node != null and personnel_node.get_child_count() >= 10,"Walking officer and worker population builds at runtime")
		var animated_count:int = 0
		if personnel_node != null:
			for npc:Node in personnel_node.get_children():
				if npc.is_in_group("animated_station_npcs"):
					animated_count += 1
		_expect(animated_count == personnel_node.get_child_count(),"Every on-screen station NPC uses the animated rig")
		var billboard_count:int = 0
		if rooms_node != null:
			for room_node:Node in rooms_node.get_children():
				if room_node.get_node_or_null("RoomArt") != null:
					billboard_count += 1
				if room_node.get_node_or_null("EstablishedMoonGoonsArt") != null:
					billboard_count += 1
		_expect(billboard_count == 0,"No wall-sized schematic billboards obstruct the 3D precinct")
		_expect(_find_by_name(instance,"SelectedRoomArtwork") == null,"Generic selected-room illustration is removed from the inspector")
		var room_toggle:Button = _find_by_name(instance,"RoomDetailsToggle") as Button
		_expect(room_toggle != null,"Compact room-details toggle builds at runtime")
		var city_panel_value:Variant = instance.get("city_panel")
		_expect(city_panel_value is Control and not (city_panel_value as Control).visible,"Room inspector starts collapsed so the station stays visible")
		var title_label:Label = _find_label(instance,"LUNAR PEACEKEEPER PRECINCT")
		var resource_value:Variant = instance.get("resource_label")
		_expect(title_label != null,"Header identifies Take Back as the Peacekeeper precinct")
		_expect(resource_value is Label and title_label != null and (resource_value as Label).get_parent() != title_label.get_parent(),"Title and economy telemetry use separate header rows")
		var threat_button:Button = _find_button(instance,"SYNDICATE THREAT MAP")
		_expect(threat_button != null,"Navigation opens a cops-side Syndicate threat map")
		_expect(_find_button(instance,"CAMPAIGN ROUTER") == null,"Criminal campaign router is removed from normal Take Back play")
		if input_bridge != null:
			_expect(input_bridge.get_node_or_null("CameraControlsLayer") is CanvasLayer,"On-screen camera controls build at runtime")
			var target_before:Vector3 = instance.get("camera_target")
			input_bridge.call("nudge_camera",Vector2(1.0,0.0),2.0)
			var target_after:Vector3 = instance.get("camera_target")
			_expect(target_after.distance_to(target_before) > 1.0,"Camera input command moves the station target")
			var distance_before:float = float(instance.get("camera_distance"))
			input_bridge.call("zoom_camera",-3.0)
			_expect(float(instance.get("camera_distance")) < distance_before,"Camera input command changes zoom")
		instance.queue_free()

	var project_file:ConfigFile = ConfigFile.new()
	var config_error:Error = project_file.load("res://project.godot")
	_expect(config_error == OK,"Project configuration loads")
	_expect(String(project_file.get_value("application","run/main_scene","")) == "res://scenes/PeacekeeperStationDeck.tscn","Take Back starts in the portrait cops-side station deck")
	_expect(String(project_file.get_value("autoload","MoonGoonsAudio","")) == "*res://scripts/moongoons_audio.gd","Precinct audio service is registered")
	_expect(String(project_file.get_value("autoload","CounterSyndicate","")) == "*res://scripts/counter_syndicate_state.gd","Counter-Syndicate campaign service is registered")

	await process_frame
	if failures == 0:
		print("SUCCESS: Living Peacekeeper precinct graphics, animated NPCs, input, and portrait hub integration passed.")
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

func _find_button(root_node:Node,text_value:String) -> Button:
	if root_node is Button and (root_node as Button).text == text_value:
		return root_node as Button
	for child:Node in root_node.get_children():
		var found:Button = _find_button(child,text_value)
		if found != null:
			return found
	return null

func _expect(condition:bool,label:String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
