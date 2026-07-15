extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var research: Node = root.get_node_or_null("AllianceResearch")
	var harvest: Node = root.get_node_or_null("ResourceHarvest")
	var precinct: Node = root.get_node_or_null("PrecinctState")
	var station: Node = root.get_node_or_null("StationProgression")
	_expect(research != null and harvest != null and precinct != null and station != null, "Alliance research and economy services exist")
	if research == null or harvest == null or precinct == null or station == null:
		quit(1)
		return

	research.call("reset_state")
	harvest.call("reset_state")
	precinct.call("reset_state")

	var branches: Array = research.call("branch_catalog") as Array
	_expect(branches.size() == 3, "Exactly three Alliance branches exist")
	_expect(branches.has("construction") and branches.has("technology") and branches.has("weapons"), "Branches are Construction, Technology, and Weapons")

	var all_nodes: Array = research.call("node_catalog", "") as Array
	_expect(all_nodes.size() == 15, "Fifteen Alliance research nodes are available")
	var total_schedule_rows: int = 0
	var seen_gaps: Dictionary = {}
	for branch_value: Variant in branches:
		var branch: String = String(branch_value)
		var branch_nodes: Array = research.call("node_catalog", branch) as Array
		_expect(branch_nodes.size() == 5, "%s has five research nodes" % branch.capitalize())
		for node_value: Variant in branch_nodes:
			var node: Dictionary = node_value as Dictionary
			var node_id: String = String(node.get("id", ""))
			var schedule: Array = research.call("level_schedule", node_id) as Array
			total_schedule_rows += schedule.size()
			_expect(schedule.size() == 100, "%s has exact Level 1-100 quotes" % String(node.get("name", node_id)))
			var first: Dictionary = schedule[0] as Dictionary
			var second: Dictionary = schedule[1] as Dictionary
			var final_quote: Dictionary = schedule[99] as Dictionary
			_expect(int(first.get("target_level", 0)) == 1 and int(first.get("seconds", -1)) == 0, "%s starts at Level 1 without a research charge" % node_id)
			_expect(int(final_quote.get("target_level", 0)) == 100, "%s schedule ends at Level 100" % node_id)
			_expect(int(final_quote.get("seconds", 0)) > int(second.get("seconds", 0)), "%s time increases through Level 100" % node_id)
			_expect(int(final_quote.get("credits", 0)) > int(second.get("credits", 0)), "%s credit cost increases through Level 100" % node_id)
			var final_costs: Dictionary = final_quote.get("costs", {}) as Dictionary
			var second_costs: Dictionary = second.get("costs", {}) as Dictionary
			for resource_id: String in ["moonsteel", "helium3", "quantum_salvage"]:
				_expect(int(final_costs.get(resource_id, 0)) > int(second_costs.get(resource_id, 0)), "%s %s cost scales to Level 100" % [node_id, resource_id])
			var gap: int = int(node.get("gap", 0))
			if gap > 0:
				seen_gaps[gap] = true
				var expected_parent: int = 97 if gap == 3 else 95
				_expect(int(final_quote.get("parent_required", 0)) == expected_parent, "%s Level 100 uses its %d-level parent gap" % [node_id, gap])

	_expect(total_schedule_rows == 1500, "The tree exposes 1,500 exact level quotes")
	_expect(seen_gaps.has(3) and seen_gaps.has(5), "Both 3-level and 5-level prerequisite gaps are used")

	precinct.set("credits", 99999999)
	harvest.call("add_resource", "moonsteel", 999999)
	harvest.call("add_resource", "helium3", 999999)
	harvest.call("add_resource", "quantum_salvage", 999999)

	var construction_start: Dictionary = research.call("begin_research", "modular_foundry") as Dictionary
	var technology_start: Dictionary = research.call("begin_research", "quantum_computing") as Dictionary
	var weapons_start: Dictionary = research.call("begin_research", "pulse_harmonization") as Dictionary
	_expect(bool(construction_start.get("ok", false)), "Construction research can start")
	_expect(bool(technology_start.get("ok", false)), "Technology research can start concurrently")
	_expect(bool(weapons_start.get("ok", false)), "Weapons research can start concurrently")
	_expect((research.get("active_jobs") as Dictionary).size() == 3, "Each branch owns one simultaneous Alliance research slot")

	var blocked_same_branch: Dictionary = research.call("begin_research", "rapid_assembly") as Dictionary
	_expect(not bool(blocked_same_branch.get("ok", false)), "A branch cannot start a second job while its slot is occupied")

	for branch_value: Variant in branches:
		research.call("complete_job_now", String(branch_value))
	_expect(int(research.call("level", "modular_foundry")) == 2, "Construction completion raises its node level")
	_expect(int(research.call("level", "quantum_computing")) == 2, "Technology completion raises its node level")
	_expect(int(research.call("level", "pulse_harmonization")) == 2, "Weapons completion raises its node level")

	var levels: Dictionary = research.get("levels") as Dictionary
	levels["modular_foundry"] = 100
	levels["rapid_assembly"] = 100
	levels["autonomous_builders"] = 100
	levels["reinforced_superstructure"] = 100
	levels["pulse_harmonization"] = 100
	levels["rail_capacitors"] = 100
	levels["siege_network"] = 100
	levels["fusion_grid"] = 100
	levels["targeting_ai"] = 100
	levels["deep_scan_network"] = 100
	levels["interceptor_doctrine"] = 100
	_expect(int(research.call("adjust_construction_time", 1000)) <= 500, "Max Construction research cuts build timers by up to half")
	_expect(int(research.call("defense_rating_bonus")) > 0, "Alliance construction and siege research add defense rating")
	_expect(int(research.call("weapon_attack_bonus")) > 0 and int(research.call("rail_damage_bonus")) > 0, "Alliance Weapons research adds live combat damage")
	_expect(int(research.call("shield_bonus")) > 0 and int(research.call("scan_damage_bonus")) > 0, "Alliance Technology research adds shields and scan damage")
	_expect(int(station.call("defense_rating")) >= int(research.call("defense_rating_bonus")), "Station defense rating includes Alliance research")

	if failures == 0:
		print("SUCCESS: Alliance Level 1-100 research tree passed.")
	else:
		push_error("FAILED: %d Alliance research check(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
