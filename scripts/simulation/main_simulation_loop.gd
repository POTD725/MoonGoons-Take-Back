class_name MoonGoonsMainSimulationLoop
extends RefCounted
## Composes the authoritative simulation subsystems for local tests and future mission controllers.
## Rendering scenes should observe this object through adapters rather than mutate it directly.

var game_data := MoonGoonsGameData.new()
var unit_parser := MoonGoonsAbilityDataParser.new()
var resource_bank := MoonGoonsResourceBank.new()
var movement_controller := MoonGoonsFixedPointMovementController.new()
var combat_damage := MoonGoonsCombatDamageProcessor.new(resource_bank)
var combat_abilities := MoonGoonsCombatAbilityController.new(resource_bank)
var mission_controller := MoonGoonsMissionController.new(resource_bank)
var random_source := MoonGoonsGameRand.new(1)
var lockstep: MoonGoonsLockstepNetworkManager
var player_ids: Array[int] = []
var _passive_income_rates: Dictionary = {}
var errors: Array[String] = []

func initialize(initial_player_ids: Array[int], match_seed: int) -> bool:
	errors.clear()
	player_ids = initial_player_ids.duplicate()
	player_ids.sort()
	if player_ids.is_empty():
		errors.append("Simulation requires at least one player.")
		return false
	if not game_data.load_all():
		errors.append_array(game_data.errors)
		return false
	if not unit_parser.initialize_from_game_data(game_data):
		errors.append_array(unit_parser.errors)
		return false
	for player_id: int in player_ids:
		var starting_capacity: int = 20 if player_id == 1 else 15
		resource_bank.initialize_player_account(player_id, starting_capacity)
	lockstep = MoonGoonsLockstepNetworkManager.new(movement_controller, player_ids)
	lockstep.simulation_tick_executed.connect(_on_simulation_tick)
	random_source = MoonGoonsGameRand.new(match_seed)
	if not mission_controller.load_catalog():
		errors.append_array(mission_controller.errors)
		return false
	return true

func spawn_unit_from_profile(
	profile_id: String,
	instance_id: String,
	owner_player_id: int,
	faction_id: String,
	start_x_fp: int,
	start_z_fp: int,
	charge_cost: bool = false
) -> bool:
	var profile: Dictionary = unit_parser.get_profile(profile_id)
	if profile.is_empty() or not resource_bank.has_player(owner_player_id):
		return false
	var cost: Dictionary = profile.get("cost", {})
	if charge_cost and not resource_bank.try_spend(owner_player_id, cost):
		return false
	var unit: MoonGoonsSimulationUnit = unit_parser.spawn_unit_from_catalog(profile_id, faction_id, start_x_fp, start_z_fp, instance_id)
	if unit == null or not movement_controller.register_unit(unit):
		return false
	var stats: Dictionary = profile.get("stats", {})
	var class_id := String(profile.get("class", "light_infantry"))
	var is_organic := class_id != "mechanical_vehicle" and class_id != "light_vehicle"
	var combat_entity := MoonGoonsCombatDamageProcessor.CombatEntity.new(
		instance_id,
		owner_player_id,
		faction_id,
		class_id,
		MoonGoonsFixedMath.from_float(float(stats.get("max_hp", 1.0))),
		is_organic
	)
	if not combat_damage.register_entity(combat_entity):
		movement_controller.remove_unit(instance_id)
		return false
	combat_abilities.register_unit_abilities(instance_id, owner_player_id, profile.get("abilities", []) as Array)
	return true

func submit_packet(packet: Dictionary) -> bool:
	if lockstep == null:
		return false
	return lockstep.receive_input_packet(packet)

func process_network_turn(passive_income_rates: Dictionary = {}) -> Dictionary:
	if lockstep == null:
		return {"advanced": false, "reason": "not_initialized"}
	_passive_income_rates = passive_income_rates.duplicate(true)
	return lockstep.update_network_turn_loop()

func make_authoritative_snapshot() -> Dictionary:
	return MoonGoonsGameStateHash.make_authoritative_snapshot(
		lockstep.current_network_turn if lockstep != null else 0,
		lockstep.current_simulation_tick if lockstep != null else 0,
		resource_bank.get_all_player_snapshots(),
		movement_controller.serialize_state(),
		{
			"combat_entities": combat_damage.get_all_entity_snapshots(),
			"abilities": combat_abilities.serialize_state()
		},
		mission_controller.serialize_state(),
		random_source.serialize_state()
	)

func current_state_hash() -> String:
	return MoonGoonsGameStateHash.hash_snapshot(make_authoritative_snapshot())

func _on_simulation_tick(_simulation_tick: int) -> void:
	for player_id: int in player_ids:
		var rates: Dictionary = _passive_income_rates.get(player_id, {})
		resource_bank.process_passive_income_tick(
			player_id,
			int(rates.get("credits_per_second_fp", 0)),
			int(rates.get("alloy_per_second_fp", 0)),
			int(rates.get("intel_per_second_fp", 0))
		)
	combat_abilities.process_simulation_tick()
	combat_damage.process_status_tick()
