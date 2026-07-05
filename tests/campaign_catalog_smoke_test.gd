extends SceneTree
## Run with:
## godot --headless --path . --script res://tests/campaign_catalog_smoke_test.gd

var failures: Array[String] = []

func _init() -> void:
	var game_data := MoonGoonsGameData.new()
	if not game_data.load_all():
		failures.append("Campaign catalog data failed to load: %s" % ", ".join(game_data.errors))
	else:
		_validate_catalog(game_data)
		_validate_runtime_lookup()
	if failures.is_empty():
		print("MoonGoons campaign catalog smoke test passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _validate_catalog(game_data: MoonGoonsGameData) -> void:
	var validator := MoonGoonsCampaignCatalogValidator.new()
	var issues: Array[String] = validator.validate(game_data)
	if not issues.is_empty():
		failures.append("Campaign catalog validation issues: %s" % ", ".join(issues))
	if game_data.get_mission("m_1_03").is_empty():
		failures.append("Mission 1.03 was not resolved from the extended catalog.")
	if game_data.get_mission("m_1_20").is_empty():
		failures.append("Mission 1.20 was not resolved from the extended catalog.")
	if game_data.get_all_missions().size() != 20:
		failures.append("Expected exactly 20 merged campaign missions.")

func _validate_runtime_lookup() -> void:
	var bank := MoonGoonsResourceBank.new()
	bank.initialize_player_account(1, 20)
	var missions := MoonGoonsMissionController.new(bank)
	if not missions.load_catalog() or not missions.start_mission("m_1_03"):
		failures.append("Mission controller could not start extended Mission 1.03.")
		return
	missions.notify_event("on_counter_changed", {"counter_id": "freighters_tagged", "value": 3})
	if missions.get_objective_state("tag_freighters") != "completed":
		failures.append("Counter-based objective completion failed for Mission 1.03.")
	if not missions.start_mission("m_1_20"):
		failures.append("Mission controller could not start final Mission 1.20.")
