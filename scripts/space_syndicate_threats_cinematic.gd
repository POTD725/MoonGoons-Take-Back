extends "res://scripts/space_syndicate_threats_state.gd"
## Thin integration hook that preserves the tested combat state while announcing new engagements.

signal battle_started(target_id: String)

func begin_battle(target_id: String) -> Dictionary:
	var result: Dictionary = super.begin_battle(target_id)
	if bool(result.get("ok", false)) and not active_battle.is_empty():
		battle_started.emit(target_id)
	return result
