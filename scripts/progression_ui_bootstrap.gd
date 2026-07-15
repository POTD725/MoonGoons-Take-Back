extends Node
## Prevents the equipment panel from polling before its controls exist and
## keeps the displayed cap aligned with station -> Chief -> room -> item rules.

var precinct: Node3D
var progression_ui: Node
var refresh_clock: float = 0.0

func _ready() -> void:
	precinct = get_parent() as Node3D
	progression_ui = precinct.get_node_or_null("PrecinctProgressionUI") if precinct != null else null
	call_deferred("_enable_after_build")

func _enable_after_build() -> void:
	for _frame: int in range(20):
		await get_tree().process_frame
	if progression_ui != null:
		progression_ui.process_mode = Node.PROCESS_MODE_INHERIT
	_refresh_cap_label()

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock < 0.25:
		return
	refresh_clock = 0.0
	_refresh_cap_label()

func _refresh_cap_label() -> void:
	if precinct == null or progression_ui == null:
		return
	var cap_value: Variant = progression_ui.get("cap_label")
	if not cap_value is Label:
		return
	var room_id: String = String(precinct.get("selected_room_id"))
	var room_level: int = int(PrecinctState.get_room(room_id).get("level", 1))
	var chief_level: int = int(PrecinctState.get_room("chief").get("level", 1))
	(cap_value as Label).text = "ITEM CAP: ROOM L%d   •   CHIEF L%d   •   STATION L%d" % [room_level, chief_level, StationProgression.station_level]
