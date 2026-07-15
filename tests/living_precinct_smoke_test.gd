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
	_expect(room_factory != null,"3D room factory loads")
	_expect(officer_factory != null,"Officer visual factory loads")
	_expect(agent_script != null,"Walking agent AI loads")
	_expect(audio_script != null,"Generated audio service loads")
	_expect(living_script != null,"Living precinct controller loads")

	var room_data:Dictionary = {"name":"Operations Center","repaired":true,"level":2}
	var room:Node3D = PrecinctRoomFactory.build_room("ops",room_data)
	root.add_child(room)
	_expect(room.has_meta("room_id"),"Room exposes a selectable room id")
	_expect(room.get_node_or_null("Door") is Marker3D,"Room exposes a corridor door marker")
	_expect(room.get_node_or_null("Job0") is Marker3D,"Room exposes worker job markers")
	_expect(room.get_node_or_null("ClickArea") is StaticBody3D,"Room exposes a 3D click collider")
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
	_expect(scene != null,"Living precinct startup scene parses")
	var project_file:ConfigFile = ConfigFile.new()
	var config_error:Error = project_file.load("res://project.godot")
	_expect(config_error == OK,"Project configuration loads")
	_expect(String(project_file.get_value("application","run/main_scene","")) == "res://scenes/LivingPrecinct.tscn","Living precinct is the startup scene")
	_expect(String(project_file.get_value("autoload","MoonGoonsAudio","")) == "*res://scripts/moongoons_audio.gd","Audio service is registered")

	await process_frame
	if failures == 0:
		print("SUCCESS: Living precinct smoke tests passed.")
	else:
		push_error("FAILED: %d living precinct smoke test(s) failed." % failures)
	quit(failures)

func _expect(condition:bool,label:String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
