extends "res://scripts/moongoons_rts_match.gd"
## Thin launch adapter for the playable RTS scene.
## Keeps initial command usage and the F-key Vanguard shortcut aligned with production rules.

func _ready() -> void:
	super._ready()
	command_used = workers.size() * WORKER_CAPACITY + combat_units.size() * DEPUTY_CAPACITY
	mission_state = "Assign Survey Drones, expand Command Capacity, and dismantle the Syndicate hideout."
	queue_redraw()

func _handle_hotkey(keycode: Key) -> void:
	if keycode == KEY_F:
		_queue_vanguard()
		return
	super._handle_hotkey(keycode)
