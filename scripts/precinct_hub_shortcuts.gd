extends Node
## Handles the large city-view command queue cards without coupling them to
## the main hub's action dispatch table.

func _input(event: InputEvent) -> void:
	var position: Vector2 = Vector2.ZERO
	var pressed: bool = false
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		position = mouse_event.position
		pressed = mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event: InputEventScreenTouch = event as InputEventScreenTouch
		position = touch_event.position
		pressed = touch_event.pressed
	if not pressed:
		return
	var hub: Node = get_parent()
	if hub == null or String(hub.get("current_view")) != "city":
		return
	if Rect2(986.0, 236.0, 244.0, 84.0).has_point(position):
		hub.set("current_view", "patrol")
		hub.set("status_message", "Patrol board opened from the command queue.")
		hub.queue_redraw()
	elif Rect2(986.0, 332.0, 244.0, 84.0).has_point(position):
		hub.set("current_view", "custody")
		hub.set("status_message", "Detention management opened.")
		hub.queue_redraw()
	elif Rect2(986.0, 428.0, 244.0, 84.0).has_point(position):
		hub.set("current_view", "tasks")
		hub.set("status_message", "Chapter and daily objectives opened.")
		hub.queue_redraw()
