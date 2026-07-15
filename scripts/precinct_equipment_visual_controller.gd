extends Node
## Places real 3D models on all 24 equipment hotspots and adds five compact
## style buttons to the Equipment side tray.

var precinct: Node
var styles: Node
var progression_ui: Node
var variant_label: Label
var variant_buttons: Array[Button] = []
var refresh_clock: float = 0.0
var last_selection_key: String = ""

func _ready() -> void:
	precinct = get_parent()
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(24):
		await get_tree().process_frame
	if precinct == null:
		return
	styles = precinct.get_node_or_null("EquipmentStyleState")
	progression_ui = precinct.get_node_or_null("PrecinctProgressionUI")
	_build_style_selector()
	if styles != null and not styles.style_changed.is_connected(_on_style_changed):
		styles.style_changed.connect(_on_style_changed)
	if not PrecinctEquipment.equipment_changed.is_connected(_rebuild_models):
		PrecinctEquipment.equipment_changed.connect(_rebuild_models)
	if not PrecinctState.state_changed.is_connected(_delayed_rebuild):
		PrecinctState.state_changed.connect(_delayed_rebuild)
	_rebuild_models()
	_refresh_selector()

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock < 0.18:
		return
	refresh_clock = 0.0
	var key: String = _selected_key()
	if key != last_selection_key:
		last_selection_key = key
		_refresh_selector()

func _build_style_selector() -> void:
	if progression_ui == null:
		return
	var panel_value: Variant = progression_ui.get("equipment_panel")
	if not panel_value is PanelContainer:
		return
	var panel := panel_value as PanelContainer
	if panel.get_child_count() == 0:
		return
	var column := panel.get_child(0) as VBoxContainer
	if column == null:
		return
	variant_label = Label.new()
	variant_label.name = "EquipmentStyleLabel"
	variant_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	variant_label.add_theme_font_size_override("font_size", 11)
	variant_label.modulate = Color("9DEFFF")
	column.add_child(variant_label)
	var row := HBoxContainer.new()
	row.name = "EquipmentStyleButtons"
	row.add_theme_constant_override("separation", 4)
	column.add_child(row)
	var upgrade_value: Variant = progression_ui.get("upgrade_button")
	if upgrade_value is Control:
		column.move_child(variant_label, (upgrade_value as Control).get_index())
		column.move_child(row, variant_label.get_index() + 1)
	for variant: int in range(1, 6):
		var button := Button.new()
		button.text = "%d %s" % [variant, _short_name(variant)]
		button.tooltip_text = _variant_name(variant)
		button.custom_minimum_size = Vector2(62.0, 30.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 9)
		button.pressed.connect(_select_variant.bind(variant))
		button.add_theme_stylebox_override("normal", _style(Color("0A1822"), Color("355D70")))
		button.add_theme_stylebox_override("hover", _style(Color("123344"), Color("6DEBFF")))
		button.add_theme_stylebox_override("pressed", _style(Color("19465A"), Color("A4F7FF")))
		row.add_child(button)
		variant_buttons.append(button)

func _select_variant(variant: int) -> void:
	if styles == null or progression_ui == null:
		return
	var room_id: String = String(precinct.get("selected_room_id"))
	var items: Array[Dictionary] = PrecinctEquipment.room_items(room_id)
	if items.is_empty():
		return
	var selected: int = clampi(int(progression_ui.get("selected_item_index")), 0, items.size() - 1)
	var item_id: String = String(items[selected].get("id", ""))
	styles.call("set_item_variant", room_id, item_id, variant)
	MoonGoonsAudio.play("click")

func _refresh_selector() -> void:
	if variant_label == null or styles == null or progression_ui == null:
		return
	var room_id: String = String(precinct.get("selected_room_id"))
	var items: Array[Dictionary] = PrecinctEquipment.room_items(room_id)
	if items.is_empty():
		variant_label.text = "NO VISUAL OPTIONS"
		for button: Button in variant_buttons:
			button.disabled = true
		return
	var selected: int = clampi(int(progression_ui.get("selected_item_index")), 0, items.size() - 1)
	var item: Dictionary = items[selected]
	var item_id: String = String(item.get("id", ""))
	var variant: int = int(styles.call("item_variant", room_id, item_id))
	variant_label.text = "%s  |  3D STYLE: %s  |  FIVE OPTIONS" % [String(item.get("name", "ITEM")).to_upper(), _variant_name(variant)]
	for index: int in range(variant_buttons.size()):
		variant_buttons[index].disabled = index + 1 == variant

func _rebuild_models() -> void:
	if precinct == null or styles == null:
		return
	var rooms_value: Variant = precinct.get("room_nodes")
	if not rooms_value is Dictionary:
		return
	var room_nodes: Dictionary = rooms_value as Dictionary
	for room_value: Variant in room_nodes.keys():
		var room_id: String = String(room_value)
		var room_node: Node3D = room_nodes.get(room_id) as Node3D
		if room_node == null:
			continue
		var hotspot_root: Node3D = room_node.get_node_or_null("EquipmentHotspots") as Node3D
		if hotspot_root == null:
			continue
		for item: Dictionary in PrecinctEquipment.room_items(room_id):
			var item_id: String = String(item.get("id", ""))
			var hotspot: Node3D = hotspot_root.get_node_or_null("Equipment_%s" % item_id) as Node3D
			if hotspot == null:
				continue
			var old_model: Node = hotspot.get_node_or_null("EquipmentModel")
			if old_model != null:
				old_model.queue_free()
			var variant: int = int(styles.call("item_variant", room_id, item_id))
			var model: Node3D = PrecinctEquipmentVisualFactory.build(item_id, int(item.get("level", 1)), variant)
			model.position = Vector3(0.0, -0.72, 0.0)
			model.rotation.y = _item_rotation(room_id, item_id)
			hotspot.add_child(model)
	_refresh_selector()

func _delayed_rebuild() -> void:
	call_deferred("_wait_and_rebuild")

func _wait_and_rebuild() -> void:
	for _frame: int in range(4):
		await get_tree().process_frame
	_rebuild_models()

func _on_style_changed(_room_id: String, _item_id: String, _variant: int) -> void:
	_rebuild_models()

func _selected_key() -> String:
	if progression_ui == null:
		return ""
	return "%s:%d" % [String(precinct.get("selected_room_id")), int(progression_ui.get("selected_item_index"))]

func _variant_name(variant: int) -> String:
	return String(styles.call("variant_name", variant)) if styles != null else "STYLE %d" % variant

func _short_name(variant: int) -> String:
	return ["AUTH", "IND", "TACT", "ORBIT", "PROTO"][clampi(variant, 1, 5) - 1]

func _item_rotation(room_id: String, item_id: String) -> float:
	var seed: int = absi((room_id + item_id).hash())
	return float(seed % 5 - 2) * 0.08

func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style
