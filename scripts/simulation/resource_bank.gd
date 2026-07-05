class_name MoonGoonsResourceBank
extends RefCounted
## Authoritative fixed-point economy ledger for deterministic simulation.
## All stored resource values use MoonGoonsFixedMath.SCALE subunits.

const INTEL_CAP_FP: int = 200 * MoonGoonsFixedMath.SCALE

class PlayerAccount:
	var player_id: int
	var credits_fp := 0
	var lunar_alloy_fp := 0
	var intel_fp := 0
	var evidence_fp := 0
	var current_command_used := 0
	var max_command_capacity := 0
	var income_remainders: Dictionary = {
		"credits": 0,
		"lunar_alloy": 0,
		"intel": 0
	}

	func _init(initial_player_id: int, initial_capacity: int) -> void:
		player_id = initial_player_id
		max_command_capacity = initial_capacity

	func serialize_state() -> Dictionary:
		return {
			"player_id": player_id,
			"credits_fp": credits_fp,
			"lunar_alloy_fp": lunar_alloy_fp,
			"intel_fp": intel_fp,
			"evidence_fp": evidence_fp,
			"current_command_used": current_command_used,
			"max_command_capacity": max_command_capacity,
			"income_remainders": income_remainders.duplicate(true)
		}

var _accounts: Dictionary = {}

func initialize_player_account(
	player_id: int,
	starting_max_command: int,
	starting_credits: int = 200,
	starting_lunar_alloy: int = 0,
	starting_intel: int = 0,
	starting_evidence: int = 0
) -> PlayerAccount:
	var account := PlayerAccount.new(player_id, starting_max_command)
	account.credits_fp = starting_credits * MoonGoonsFixedMath.SCALE
	account.lunar_alloy_fp = starting_lunar_alloy * MoonGoonsFixedMath.SCALE
	account.intel_fp = mini(starting_intel * MoonGoonsFixedMath.SCALE, INTEL_CAP_FP)
	account.evidence_fp = starting_evidence * MoonGoonsFixedMath.SCALE
	_accounts[player_id] = account
	return account

func has_player(player_id: int) -> bool:
	return _accounts.has(player_id)

func get_account(player_id: int) -> PlayerAccount:
	var account: Variant = _accounts.get(player_id)
	if account is PlayerAccount:
		return account as PlayerAccount
	return null

func get_player_snapshot(player_id: int) -> Dictionary:
	var account := get_account(player_id)
	return account.serialize_state() if account != null else {}

func get_all_player_snapshots() -> Array[Dictionary]:
	var player_ids: Array[int] = []
	for raw_id: Variant in _accounts.keys():
		player_ids.append(int(raw_id))
	player_ids.sort()
	var snapshots: Array[Dictionary] = []
	for player_id: int in player_ids:
		snapshots.append(get_player_snapshot(player_id))
	return snapshots

func process_passive_income_tick(
	player_id: int,
	credits_per_second_fp: int = 0,
	alloy_per_second_fp: int = 0,
	intel_per_second_fp: int = 0
) -> void:
	var account := get_account(player_id)
	if account == null:
		return
	account.credits_fp += _apply_per_second_rate(account, "credits", credits_per_second_fp)
	account.lunar_alloy_fp += _apply_per_second_rate(account, "lunar_alloy", alloy_per_second_fp)
	account.intel_fp = mini(INTEL_CAP_FP, account.intel_fp + _apply_per_second_rate(account, "intel", intel_per_second_fp))

func award_resources_fp(
	player_id: int,
	credits_fp: int = 0,
	alloy_fp: int = 0,
	intel_fp: int = 0,
	evidence_fp: int = 0
) -> void:
	var account := get_account(player_id)
	if account == null:
		return
	account.credits_fp = maxi(0, account.credits_fp + credits_fp)
	account.lunar_alloy_fp = maxi(0, account.lunar_alloy_fp + alloy_fp)
	account.intel_fp = clampi(account.intel_fp + intel_fp, 0, INTEL_CAP_FP)
	account.evidence_fp = maxi(0, account.evidence_fp + evidence_fp)

func award_evidence_tokens(player_id: int, quantity: int) -> void:
	award_resources_fp(player_id, 0, 0, 0, quantity * MoonGoonsFixedMath.SCALE)

func can_afford(player_id: int, cost: Dictionary) -> bool:
	var account := get_account(player_id)
	if account == null:
		return false
	var credit_cost_fp := int(cost.get("credits", 0)) * MoonGoonsFixedMath.SCALE
	var alloy_cost_fp := int(cost.get("lunar_alloy", 0)) * MoonGoonsFixedMath.SCALE
	var intel_cost_fp := int(cost.get("intel", 0)) * MoonGoonsFixedMath.SCALE
	var evidence_cost_fp := int(cost.get("evidence", 0)) * MoonGoonsFixedMath.SCALE
	var capacity_cost := int(cost.get("command_capacity", 0))
	return account.credits_fp >= credit_cost_fp \
		and account.lunar_alloy_fp >= alloy_cost_fp \
		and account.intel_fp >= intel_cost_fp \
		and account.evidence_fp >= evidence_cost_fp \
		and account.current_command_used + capacity_cost <= account.max_command_capacity

func try_spend(player_id: int, cost: Dictionary) -> bool:
	if not can_afford(player_id, cost):
		return false
	var account := get_account(player_id)
	account.credits_fp -= int(cost.get("credits", 0)) * MoonGoonsFixedMath.SCALE
	account.lunar_alloy_fp -= int(cost.get("lunar_alloy", 0)) * MoonGoonsFixedMath.SCALE
	account.intel_fp -= int(cost.get("intel", 0)) * MoonGoonsFixedMath.SCALE
	account.evidence_fp -= int(cost.get("evidence", 0)) * MoonGoonsFixedMath.SCALE
	account.current_command_used += int(cost.get("command_capacity", 0))
	return true

func release_command_capacity(player_id: int, amount: int) -> void:
	var account := get_account(player_id)
	if account != null:
		account.current_command_used = maxi(0, account.current_command_used - maxi(0, amount))

func modify_max_command_capacity(player_id: int, amount: int) -> void:
	var account := get_account(player_id)
	if account != null:
		account.max_command_capacity = maxi(0, account.max_command_capacity + amount)

func restore_state(snapshots: Array[Dictionary]) -> void:
	_accounts.clear()
	for snapshot: Dictionary in snapshots:
		var player_id := int(snapshot.get("player_id", -1))
		if player_id < 0:
			continue
		var account := PlayerAccount.new(player_id, int(snapshot.get("max_command_capacity", 0)))
		account.credits_fp = int(snapshot.get("credits_fp", 0))
		account.lunar_alloy_fp = int(snapshot.get("lunar_alloy_fp", 0))
		account.intel_fp = clampi(int(snapshot.get("intel_fp", 0)), 0, INTEL_CAP_FP)
		account.evidence_fp = int(snapshot.get("evidence_fp", 0))
		account.current_command_used = int(snapshot.get("current_command_used", 0))
		account.income_remainders = (snapshot.get("income_remainders", {}) as Dictionary).duplicate(true)
		_accounts[player_id] = account

func _apply_per_second_rate(account: PlayerAccount, resource_id: String, rate_fp: int) -> int:
	var accumulated := rate_fp + int(account.income_remainders.get(resource_id, 0))
	var increment := accumulated / MoonGoonsFixedMath.TICKS_PER_SECOND
	account.income_remainders[resource_id] = accumulated % MoonGoonsFixedMath.TICKS_PER_SECOND
	return increment
