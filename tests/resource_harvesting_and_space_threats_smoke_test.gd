extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var precinct_state: Node = root.get_node_or_null("PrecinctState")
	var station: Node = root.get_node_or_null("StationProgression")
	var harvest: Node = root.get_node_or_null("ResourceHarvest")
	var threats: Node = root.get_node_or_null("SpaceThreats")
	_expect(precinct_state != null and station != null and harvest != null and threats != null, "Resource and space-threat autoload services exist")
	if precinct_state == null or station == null or harvest == null or threats == null:
		quit(1)
		return
	precinct_state.call("reset_state")
	station.call("reset_state")
	harvest.call("reset_state")
	threats.call("reset_state")
	station.set("station_level", 10)
	precinct_state.set("credits", 50000)
	precinct_state.set("intel", 100)

	var resource_ids: Array = harvest.get("RESOURCE_IDS") as Array
	_expect(resource_ids.size() == 3, "Exactly three harvest resources are defined")
	_expect(resource_ids.has("moonsteel") and resource_ids.has("helium3") and resource_ids.has("quantum_salvage"), "Moonsteel, Helium-3, and Quantum Salvage are available")
	var sites: Array = harvest.call("site_catalog") as Array
	_expect(sites.size() == 9, "Nine asteroid, moon, and drifting-wreck harvest sites exist")
	var site_kinds: Dictionary = {}
	for site_value: Variant in sites:
		var site: Dictionary = site_value as Dictionary
		site_kinds[String(site.get("kind", ""))] = true
	_expect(site_kinds.has("asteroid") and site_kinds.has("moon") and site_kinds.has("wreck"), "Harvest sites cover asteroids, moons, and open-space wrecks")

	var targets: Array = threats.call("target_catalog") as Array
	_expect(targets.size() == 9, "Nine Syndicate fleets occupy the nine resource lanes")
	var commanders: Dictionary = {}
	var minimum_level: int = 999
	var maximum_level: int = 0
	var difficulties: Dictionary = {}
	for target_value: Variant in targets:
		var target: Dictionary = target_value as Dictionary
		var commander_text: String = String(target.get("commander", ""))
		for commander_name: String in ["Nyx Raze", "Vox-13", "Cinder Quell", "Grit Mercer"]:
			if commander_text.contains(commander_name):
				commanders[commander_name] = true
		minimum_level = mini(minimum_level, int(target.get("level", 1)))
		maximum_level = maxi(maximum_level, int(target.get("level", 1)))
		difficulties[int(target.get("difficulty", 1))] = true
	_expect(commanders.size() == 4, "All four established Syndicate Rising criminals command space targets")
	_expect(minimum_level == 1 and maximum_level == 10, "Space targets escalate from level 1 to level 10")
	_expect(difficulties.size() == 5, "Targets span all five difficulty ratings")
	var boss: Dictionary = threats.call("get_target", "crater_crown_command") as Dictionary
	_expect(int(boss.get("level", 0)) == 10 and int(boss.get("difficulty", 0)) == 5, "Crater Crown command carrier is a level 10 boss target")

	var blocked_site_id: String = "wreck_courier"
	_expect(bool(threats.call("site_is_threatened", blocked_site_id)), "Vox-13 initially occupies the Courier Wreck resource lane")
	var blocked_harvest: Dictionary = harvest.call("begin_harvest", blocked_site_id) as Dictionary
	_expect(not bool(blocked_harvest.get("ok", false)), "A Syndicate-controlled resource site blocks harvesting")

	var salvage_before: int = int(harvest.call("resource_amount", "quantum_salvage"))
	var battle_start: Dictionary = threats.call("begin_battle", "vox_courier_pack") as Dictionary
	_expect(bool(battle_start.get("ok", false)), "Authority interceptors can engage Vox-13")
	var active_battle: Dictionary = threats.get("active_battle") as Dictionary
	active_battle["enemy_hp"] = 1
	var battle_result: Dictionary = threats.call("battle_action", "cannons") as Dictionary
	_expect(bool(battle_result.get("ok", false)), "Space combat can defeat the Syndicate fleet")
	_expect((threats.get("active_battle") as Dictionary).is_empty(), "Victory closes the active space battle")
	_expect(not bool(threats.call("site_is_threatened", blocked_site_id)), "Defeating Vox-13 temporarily clears the resource lane")
	_expect(int(harvest.call("resource_amount", "quantum_salvage")) > salvage_before, "Space victory awards the guarded resource")

	var harvest_start: Dictionary = harvest.call("begin_harvest", blocked_site_id) as Dictionary
	_expect(bool(harvest_start.get("ok", false)), "A cleared resource lane accepts a harvesting crew")
	var site: Dictionary = harvest.call("get_site", blocked_site_id) as Dictionary
	site["harvest_end"] = int(Time.get_unix_time_from_system()) - 1
	var resource_before_delivery: int = int(harvest.call("resource_amount", "quantum_salvage"))
	harvest.call("tick")
	_expect(int(harvest.get("total_harvests")) == 1, "Completed extraction increments the harvest counter")
	_expect(int(harvest.call("resource_amount", "quantum_salvage")) > resource_before_delivery, "Completed extraction delivers resources to the station")

	var scene: PackedScene = load("res://scenes/LivingPrecinct.tscn") as PackedScene
	_expect(scene != null, "Living precinct scene loads with resource and space-combat systems")
	if scene != null:
		var instance: Node = scene.instantiate()
		root.add_child(instance)
		for _frame: int in range(32):
			await process_frame
		_expect(instance.has_node("ResourceHarvestController"), "Resource harvesting controller is attached")
		_expect(instance.has_node("SpaceThreatOperations"), "Syndicate space threat controller is attached")
		var resource_root: Node = instance.get_node_or_null("LivingPrecinctWorld/ResourceHarvestSites")
		var threat_root: Node = instance.get_node_or_null("LivingPrecinctWorld/SyndicateSpaceFleets")
		_expect(resource_root != null and resource_root.get_child_count() == 9, "Nine harvest locations are visible in the 3D world")
		_expect(threat_root != null and threat_root.get_child_count() == 9, "Nine Syndicate fleets are visible around the resource lanes")
		var resource_button: Button = instance.get_node_or_null("ResourceHarvestLayer/ResourceMapButton") as Button
		var threat_button: Button = instance.get_node_or_null("SpaceThreatLayer/SpaceThreatButton") as Button
		_expect(resource_button != null and threat_button != null, "Resource Map and Space Threats buttons are available")
		instance.queue_free()
		await process_frame

	if failures == 0:
		print("SUCCESS: Resource harvesting and Syndicate space targets passed.")
	else:
		push_error("FAILED: %d resource or space-threat check(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
