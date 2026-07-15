class_name LivingPrecinctInputBridge
extends Node
## Receives input before the full-screen HUD can consume it.
## Keeps room buttons clickable while enabling camera movement over the 3D world.

const MOVE_KEYS: Array[int] = [
	KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN,
	KEY_A, KEY_D, KEY_W, KEY_S
]
const PAN_LIMIT_X: float = 26.0
const PAN_LIMIT_Z: float = 17.0
const MIN_DISTANCE: float = 17.0
const MAX_DISTANCE: float = 56.0
const DRAG_THRESHOLD: float = 5.0

var precinct: Node
var held_keys: Dictionary = {}
var held_virtual: Dictionary = {}
var left_dragging: bool = false
var right_dragging: bool = false
var touch_dragging: bool = false
var pointer_moved: bool = false
var pointer_start: Vector2 = Vector2.ZERO
var controls_layer: CanvasLayer

func _ready() -> void:
	precinct = get_parent()
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	set_process_input(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_camera_controls()
	call_deferred("_finish_setup")

func _finish_setup() -> void:
	for _frame: int in range(5):
		await get_tree().process_frame
	_refresh_help_text()

func _process(delta: float) -> void:
	if precinct == null:
		return
	var direction: Vector2 = _keyboard_direction() + _virtual_direction()
	if direction.length_squared() > 0.0:
		nudge_camera(direction.normalized(), delta * 8.5)

func _input(event: InputEvent) -> void:
	if precinct == null:
		return
	if event is InputEventKey:
		_handle_key(event as InputEventKey)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventScreenTouch:
		_handle_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_touch_drag(event as InputEventScreenDrag)
	elif event is InputEventMagnifyGesture:
		var magnify: InputEventMagnifyGesture = event as InputEventMagnifyGesture
		zoom_camera((1.0 - magnify.factor) * 14.0)
		get_viewport().set_input_as_handled()
	elif event is InputEventPanGesture:
		var pan_event: InputEventPanGesture = event as InputEventPanGesture
		_pan_by_pixels(pan_event.delta * 24.0)
		get_viewport().set_input_as_handled()

func _handle_key(event: InputEventKey) -> void:
	var code: int = int(event.keycode)
	if code == 0:
		code = int(event.physical_keycode)
	if MOVE_KEYS.has(code):
		held_keys[code] = event.pressed
		get_viewport().set_input_as_handled()
		return
	if not event.pressed or event.echo:
		return
	match code:
		KEY_Q:
			rotate_camera(-0.16)
		KEY_E:
			rotate_camera(0.16)
		KEY_MINUS, KEY_KP_SUBTRACT:
			zoom_camera(3.0)
		KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
			zoom_camera(-3.0)
		KEY_HOME, KEY_F:
			reset_camera()
		_:
			return
	get_viewport().set_input_as_handled()

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		zoom_camera(-3.0)
		get_viewport().set_input_as_handled()
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		zoom_camera(3.0)
		get_viewport().set_input_as_handled()
		return
	if event.button_index == MOUSE_BUTTON_RIGHT:
		right_dragging = event.pressed
		pointer_start = event.position
		pointer_moved = false
		get_viewport().set_input_as_handled()
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if _pointer_over_interactive_control():
			return
		left_dragging = true
		pointer_start = event.position
		pointer_moved = false
		get_viewport().set_input_as_handled()
	else:
		if not left_dragging:
			return
		left_dragging = false
		if not pointer_moved and pointer_start.distance_to(event.position) < DRAG_THRESHOLD:
			precinct.call("_pick_world", event.position)
		get_viewport().set_input_as_handled()

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if right_dragging:
		precinct.set("camera_yaw", float(precinct.get("camera_yaw")) - event.relative.x * 0.007)
		precinct.set("camera_pitch", clampf(float(precinct.get("camera_pitch")) - event.relative.y * 0.005, -1.22, -0.32))
		pointer_moved = true
		get_viewport().set_input_as_handled()
	elif left_dragging:
		if pointer_start.distance_to(event.position) >= DRAG_THRESHOLD:
			pointer_moved = true
		if pointer_moved:
			_pan_by_pixels(event.relative)
		get_viewport().set_input_as_handled()

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _pointer_over_interactive_control():
			return
		touch_dragging = true
		pointer_start = event.position
		pointer_moved = false
		get_viewport().set_input_as_handled()
	else:
		if not touch_dragging:
			return
		touch_dragging = false
		if not pointer_moved and pointer_start.distance_to(event.position) < DRAG_THRESHOLD:
			precinct.call("_pick_world", event.position)
		get_viewport().set_input_as_handled()

func _handle_touch_drag(event: InputEventScreenDrag) -> void:
	if not touch_dragging:
		return
	pointer_moved = true
	_pan_by_pixels(event.relative)
	get_viewport().set_input_as_handled()

func nudge_camera(direction: Vector2, amount: float = 1.0) -> void:
	if precinct == null:
		return
	var yaw: float = float(precinct.get("camera_yaw"))
	var right: Vector3 = Vector3(cos(yaw), 0.0, -sin(yaw))
	var forward: Vector3 = Vector3(-sin(yaw), 0.0, -cos(yaw))
	var movement: Vector3 = right * direction.x + forward * -direction.y
	if movement.length_squared() > 1.0:
		movement = movement.normalized()
	var target: Vector3 = precinct.get("camera_target")
	target += movement * amount
	precinct.set("camera_target", _clamp_target(target))

func rotate_camera(amount: float) -> void:
	if precinct != null:
		precinct.set("camera_yaw", float(precinct.get("camera_yaw")) + amount)

func zoom_camera(amount: float) -> void:
	if precinct == null:
		return
	precinct.set("camera_distance", clampf(float(precinct.get("camera_distance")) + amount, MIN_DISTANCE, MAX_DISTANCE))

func reset_camera() -> void:
	if precinct == null:
		return
	precinct.set("camera_target", Vector3(3.2, 0.0, 0.0))
	precinct.set("camera_distance", 31.5)
	precinct.set("camera_yaw", 0.0)
	precinct.set("camera_pitch", -0.78)

func _pan_by_pixels(relative: Vector2) -> void:
	var distance: float = float(precinct.get("camera_distance"))
	var scale: float = clampf(distance * 0.0021, 0.038, 0.12)
	var yaw: float = float(precinct.get("camera_yaw"))
	var right: Vector3 = Vector3(cos(yaw), 0.0, -sin(yaw))
	var forward: Vector3 = Vector3(-sin(yaw), 0.0, -cos(yaw))
	var target: Vector3 = precinct.get("camera_target")
	target -= right * relative.x * scale
	target -= forward * relative.y * scale
	precinct.set("camera_target", _clamp_target(target))

func _clamp_target(target: Vector3) -> Vector3:
	target.x = clampf(target.x, -PAN_LIMIT_X, PAN_LIMIT_X)
	target.z = clampf(target.z, -PAN_LIMIT_Z, PAN_LIMIT_Z)
	target.y = 0.0
	return target

func _keyboard_direction() -> Vector2:
	var direction: Vector2 = Vector2.ZERO
	if _key_held(KEY_LEFT) or _key_held(KEY_A):
		direction.x -= 1.0
	if _key_held(KEY_RIGHT) or _key_held(KEY_D):
		direction.x += 1.0
	if _key_held(KEY_UP) or _key_held(KEY_W):
		direction.y -= 1.0
	if _key_held(KEY_DOWN) or _key_held(KEY_S):
		direction.y += 1.0
	return direction

func _virtual_direction() -> Vector2:
	var direction: Vector2 = Vector2.ZERO
	for value: Variant in held_virtual.values():
		direction += value as Vector2
	return direction

func _key_held(code: int) -> bool:
	return bool(held_keys.get(code, false))

func _pointer_over_interactive_control() -> bool:
	var hovered: Control = get_viewport().gui_get_hovered_control()
	while hovered != null:
		if hovered is BaseButton or hovered is ItemList or hovered is LineEdit or hovered is TextEdit or hovered is Range:
			return true
		hovered = hovered.get_parent_control()
	return false

func _build_camera_controls() -> void:
	controls_layer = CanvasLayer.new()
	controls_layer.name = "CameraControlsLayer"
	controls_layer.layer = 40
	add_child(controls_layer)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "CameraControls"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -180.0
	panel.offset_top = 108.0
	panel.offset_right = -14.0
	panel.offset_bottom = 326.0
	controls_layer.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	var title: Label = Label.new()
	title.text = "CAMERA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var rotate_row: HBoxContainer = HBoxContainer.new()
	rotate_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(rotate_row)
	rotate_row.add_child(_action_button("↶", rotate_camera.bind(-0.20), "Rotate left"))
	rotate_row.add_child(_action_button("HOME", reset_camera, "Reset camera"))
	rotate_row.add_child(_action_button("↷", rotate_camera.bind(0.20), "Rotate right"))
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(grid)
	grid.add_child(_spacer())
	grid.add_child(_hold_button("▲", Vector2(0.0, -1.0), "Pan forward"))
	grid.add_child(_spacer())
	grid.add_child(_hold_button("◀", Vector2(-1.0, 0.0), "Pan left"))
	grid.add_child(_action_button("◎", reset_camera, "Center city"))
	grid.add_child(_hold_button("▶", Vector2(1.0, 0.0), "Pan right"))
	grid.add_child(_spacer())
	grid.add_child(_hold_button("▼", Vector2(0.0, 1.0), "Pan backward"))
	grid.add_child(_spacer())
	var zoom_row: HBoxContainer = HBoxContainer.new()
	zoom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(zoom_row)
	zoom_row.add_child(_action_button("−", zoom_camera.bind(3.0), "Zoom out"))
	zoom_row.add_child(_action_button("+", zoom_camera.bind(-3.0), "Zoom in"))
	var help: Label = Label.new()
	help.text = "Drag pan • RMB orbit"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 10)
	column.add_child(help)

func _action_button(text_value: String, callback: Callable, tooltip: String) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(46.0, 30.0)
	button.tooltip_text = tooltip
	button.pressed.connect(callback)
	return button

func _hold_button(text_value: String, direction: Vector2, tooltip: String) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(46.0, 34.0)
	button.tooltip_text = tooltip
	var key: String = str(direction)
	button.button_down.connect(_set_virtual_direction.bind(key, direction))
	button.button_up.connect(_clear_virtual_direction.bind(key))
	button.mouse_exited.connect(_clear_virtual_direction.bind(key))
	return button

func _set_virtual_direction(key: String, direction: Vector2) -> void:
	held_virtual[key] = direction

func _clear_virtual_direction(key: String) -> void:
	held_virtual.erase(key)

func _spacer() -> Control:
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(46.0, 34.0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer

func _refresh_help_text() -> void:
	if precinct == null:
		return
	var labels: Array[Node] = precinct.find_children("*", "Label", true, false)
	for node: Node in labels:
		var label: Label = node as Label
		if label != null and (label.text.contains("RMB") or label.text.contains("WASD")):
			label.text = "Drag pan • RMB orbit • wheel zoom • arrows/WASD   "
