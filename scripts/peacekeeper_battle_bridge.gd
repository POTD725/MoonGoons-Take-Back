extends Node
## Records cops-side patrol outcomes against the matching Syndicate district.

var district_id: String = ""
var difficulty: int = 1
var recorded: bool = false

func _ready() -> void:
	var call: Dictionary = PrecinctState.active_call
	district_id = String(call.get("district_id", CounterSyndicate.current_target_id))
	difficulty = int(call.get("difficulty", 1))
	set_process(true)

func _process(_delta: float) -> void:
	if recorded:
		return
	var battle: Node = get_parent()
	var battle_over_value: Variant = battle.get("battle_over")
	if not battle_over_value is bool or not bool(battle_over_value):
		return
	var victory_value: Variant = battle.get("victory")
	var won: bool = bool(victory_value) if victory_value is bool else false
	CounterSyndicate.record_patrol_result(district_id, won, difficulty)
	if won:
		CounterSyndicate.record_major_arrest(district_id)
	CounterSyndicate.save_state()
	recorded = true
