class_name MoonGoonsAICommander
extends RefCounted
## Data-driven macro AI for skirmish opponents.
## The mission controller supplies a lightweight world snapshot every frame.
## This class evaluates it every two seconds and returns high-level orders.

enum State {
	BOOTSTRAP,
	MACRO_EXPAND,
	HARASS,
	DEFEND,
	FULL_ASSAULT
}

const THINK_INTERVAL_SECONDS := 2.0
const HOME_THREAT_THRESHOLD := 0.20
const HARASS_MIN_TIER_ONE_UNITS := 4
const ASSAULT_COMMAND_CAPACITY_THRESHOLD := 0.80

var faction_id := "lunar_peacekeepers"
var state: State = State.BOOTSTRAP
var thinking_enabled := true
var _think_timer := 0.0

func configure(new_faction_id: String) -> void:
	faction_id = new_faction_id
	state = State.BOOTSTRAP
	_think_timer = 0.0

func set_thinking_enabled(is_enabled: bool) -> void:
	thinking_enabled = is_enabled

func update(delta: float, snapshot: Dictionary) -> Dictionary:
	if not thinking_enabled:
		return {"state": state_name(), "orders": [], "frozen": true}
	_think_timer += delta
	if _think_timer < THINK_INTERVAL_SECONDS:
		return {}
	_think_timer = 0.0
	return _evaluate(snapshot)

func calculate_sector_threat(snapshot: Dictionary) -> float:
	var enemy_units := float(snapshot.get("enemy_combat_units_in_target_sector", 0))
	var enemy_defenses := float(snapshot.get("enemy_defensive_buildings_in_target_sector", 0))
	var friendly_units := float(snapshot.get("friendly_combat_units_in_target_sector", 0))
	return enemy_units + enemy_defenses * 1.5 - friendly_units * 1.2

func state_name() -> String:
	match state:
		State.BOOTSTRAP:
			return "BOOTSTRAP"
		State.MACRO_EXPAND:
			return "MACRO_EXPAND"
		State.HARASS:
			return "HARASS"
		State.DEFEND:
			return "DEFEND"
		State.FULL_ASSAULT:
			return "FULL_ASSAULT"
	return "UNKNOWN"

func _evaluate(snapshot: Dictionary) -> Dictionary:
	var sector_threat := calculate_sector_threat(snapshot)
	var home_threat := float(snapshot.get("home_sector_threat_pct", 0.0))
	var tier_one_units := int(snapshot.get("tier_one_combat_units", 0))
	var capacity_used := float(snapshot.get("command_capacity_used", 0.0))
	var capacity_total := maxf(1.0, float(snapshot.get("command_capacity_total", 1.0)))
	var capacity_utilization := capacity_used / capacity_total
	var enemy_security_gap := bool(snapshot.get("enemy_security_gap_confirmed", false))
	var has_exposed_target := bool(snapshot.get("exposed_target_found", false))

	if home_threat >= HOME_THREAT_THRESHOLD or sector_threat > 1.5:
		state = State.DEFEND
	elif capacity_utilization >= ASSAULT_COMMAND_CAPACITY_THRESHOLD or enemy_security_gap:
		state = State.FULL_ASSAULT
	elif tier_one_units >= HARASS_MIN_TIER_ONE_UNITS and has_exposed_target:
		state = State.HARASS
	elif state == State.BOOTSTRAP and bool(snapshot.get("starting_economy_initialized", false)):
		state = State.MACRO_EXPAND
	elif state != State.BOOTSTRAP:
		state = State.MACRO_EXPAND

	return {
		"state": state_name(),
		"sector_threat_value": sector_threat,
		"command_capacity_utilization": capacity_utilization,
		"orders": _build_orders(snapshot)
	}

func _build_orders(snapshot: Dictionary) -> Array[Dictionary]:
	match state:
		State.BOOTSTRAP:
			return [
				_order("assign_workers_to_nearest_resources"),
				_order("queue_tier_one_scout"),
				_order("build_first_production_structure")
			]
		State.MACRO_EXPAND:
			return _macro_orders()
		State.HARASS:
			return _harass_orders(snapshot)
		State.DEFEND:
			return _defend_orders()
		State.FULL_ASSAULT:
			return [
				_order("form_primary_combat_group"),
				_order("attack_high_value_sector_or_structure"),
				_order("reinforce_attack_route")
			]
	return []

func _macro_orders() -> Array[Dictionary]:
	var orders: Array[Dictionary] = [
		_order("spend_economy_budget", {"income_share": 0.70}),
		_order("expand_command_capacity"),
		_order("scout_nearest_uncaptured_sector")
	]
	match faction_id:
		"lunar_peacekeepers":
			orders.append(_order("require_armory_and_two_turrets_before_second_base"))
		"the_syndicate":
			orders.append(_order("prioritize_flank_intel_relays_and_mobile_siphons"))
		"the_nullborn":
			orders.append(_order("extend_corrupted_ground_toward_center"))
	return orders

func _harass_orders(snapshot: Dictionary) -> Array[Dictionary]:
	var target := String(snapshot.get("preferred_harass_target", "enemy_natural_expansion"))
	var orders: Array[Dictionary] = [
		_order("form_small_raiding_group"),
		_order("attack_target", {"target": target})
	]
	if faction_id == "the_syndicate":
		orders.append(_order("retreat_if_no_breakthrough", {"seconds": 15.0}))
	return orders

func _defend_orders() -> Array[Dictionary]:
	var orders: Array[Dictionary] = [
		_order("cancel_noncritical_expansion_queues"),
		_order("recall_nearby_squads_to_home_sector"),
		_order("prioritize_static_defense"),
		_order("focus_fire_nearest_hostiles")
	]
	if faction_id == "lunar_peacekeepers":
		orders.append(_order("regroup_inside_security_grid"))
	elif faction_id == "the_syndicate":
		orders.append(_order("retreat_into_signal_jammer_shroud"))
	else:
		orders.append(_order("spread_corrupted_ground_near_choke"))
	return orders

func _order(action: String, payload: Dictionary = {}) -> Dictionary:
	return {"action": action, "payload": payload}
