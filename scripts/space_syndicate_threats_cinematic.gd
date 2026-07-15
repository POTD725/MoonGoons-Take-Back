extends "res://scripts/space_syndicate_threats_state.gd"
## Preserves the tested combat state while adding cinematics and alliance research bonuses.

signal battle_started(target_id: String)

var active_target_id: String:
	get:
		return String(active_battle.get("target_id", ""))

func begin_battle(target_id: String) -> Dictionary:
	var result: Dictionary = super.begin_battle(target_id)
	if bool(result.get("ok", false)) and not active_battle.is_empty():
		var extra_shield: int = AllianceResearch.shield_bonus() + AllianceResearch.interceptor_shield_bonus()
		active_battle["player_attack"] = int(active_battle.get("player_attack", 14)) + AllianceResearch.weapon_attack_bonus()
		active_battle["player_defense"] = int(active_battle.get("player_defense", 6)) + int(AllianceResearch.defense_rating_bonus() / 10)
		active_battle["player_max_shield"] = int(active_battle.get("player_max_shield", 55)) + extra_shield
		active_battle["player_shield"] = int(active_battle.get("player_shield", 55)) + extra_shield
		active_battle["alliance_research"] = true
		save_state()
		battle_changed.emit()
		battle_started.emit(target_id)
	return result

func battle_action(action: String) -> Dictionary:
	if not active_battle.is_empty() and action == "rail_strike" and int(active_battle.get("rail_cooldown", 0)) <= 0:
		active_battle["scan_bonus"] = int(active_battle.get("scan_bonus", 0)) + AllianceResearch.rail_damage_bonus()
	var result: Dictionary = super.battle_action(action)
	if bool(result.get("ok", false)) and not active_battle.is_empty():
		if action == "scan":
			active_battle["scan_bonus"] = int(active_battle.get("scan_bonus", 0)) + AllianceResearch.scan_damage_bonus()
		elif action == "evade":
			var recovery_bonus: int = int(round(float(AllianceResearch.interceptor_shield_bonus()) * 0.20))
			active_battle["player_shield"] = mini(
				int(active_battle.get("player_max_shield", 100)),
				int(active_battle.get("player_shield", 0)) + recovery_bonus
			)
		save_state()
		battle_changed.emit()
	return result
