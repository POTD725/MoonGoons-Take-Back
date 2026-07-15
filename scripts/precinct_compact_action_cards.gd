extends Node
## Converts repair, upgrade, training, healing, and equipment actions into compact
## outlined cards that always disclose requirements, cost, duration, and cap state.

var precinct: Node
var repair_card: Button
var room_upgrade_card: Button
var assign_card: Button
var train_card: Button
var heal_card: Button
var post_card: Button
var progression_ui: Node
var refresh_clock: float = 0.0

func _ready() -> void:
	precinct = get_parent()
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(16):
		await get_tree().process_frame
	if precinct == null:
		return
	_build_room_cards()
	_build_officer_cards()
	progression_ui = precinct.get_node_or_null("PrecinctProgressionUI")
	_style_equipment_card()
	_style_station_cards()
	if not PrecinctState.state_changed.is_connected(_refresh):
		PrecinctState.state_changed.connect(_refresh)
	if not PrecinctMeta.meta_changed.is_connected(_refresh):
		PrecinctMeta.meta_changed.connect(_refresh)
	if not PrecinctEquipment.equipment_changed.is_connected(_refresh):
		PrecinctEquipment.equipment_changed.connect(_refresh)
	if not StationProgression.progression_changed.is_connected(_refresh):
		StationProgression.progression_changed.connect(_refresh)
	_refresh()

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock < 0.25:
		return
	refresh_clock = 0.0
	_refresh()

func _build_room_cards() -> void:
	var panel_value: Variant = precinct.get("city_panel")
	if not panel_value is Control:
		return
	var panel := panel_value as Control
	panel.size = Vector2(340.0, 430.0)
	var column: VBoxContainer = panel.get_child(0) as VBoxContainer
	if column == null:
		return
	var info_value: Variant = precinct.get("room_info")
	if info_value is Label:
		var info := info_value as Label
		info.custom_minimum_size = Vector2(310.0, 86.0)
		info.add_theme_font_size_override("font_size", 11)
	for child: Node in column.get_children():
		if child is Button:
			(child as Button).visible = false
	repair_card = _card("REPAIR ROOM", Callable(precinct, "_repair_selected"))
	room_upgrade_card = _card("UPGRADE ROOM", Callable(precinct, "_upgrade_selected"))
	assign_card = _card("POST OFFICER", Callable(precinct, "_assign_selected"))
	column.add_child(repair_card)
	column.add_child(room_upgrade_card)
	column.add_child(assign_card)

func _build_officer_cards() -> void:
	var panel_value: Variant = precinct.get("officer_panel")
	if not panel_value is Control:
		return
	var panel := panel_value as Control
	panel.size = Vector2(340.0, 430.0)
	var column: VBoxContainer = panel.get_child(0) as VBoxContainer
	if column == null:
		return
	var info_value: Variant = precinct.get("officer_info")
	if info_value is Label:
		var info := info_value as Label
		info.custom_minimum_size = Vector2(310.0, 185.0)
		info.add_theme_font_size_override("font_size", 11)
	for child: Node in column.get_children():
		if child is Button or child is HBoxContainer:
			child.visible = false
	var navigator := HBoxContainer.new()
	navigator.add_theme_constant_override("separation", 6)
	var previous := _small_button("PREVIOUS", Callable(precinct, "_previous_officer"))
	var next := _small_button("NEXT", Callable(precinct, "_next_officer"))
	navigator.add_child(previous)
	navigator.add_child(next)
	column.add_child(navigator)
	train_card = _card("TRAIN OFFICER", Callable(precinct, "_train_officer"))
	heal_card = _card("HEAL OFFICER", Callable(precinct, "_heal_officer"))
	post_card = _card("POST TO SELECTED ROOM", Callable(precinct, "_assign_selected"))
	column.add_child(train_card)
	column.add_child(heal_card)
	column.add_child(post_card)

func _style_equipment_card() -> void:
	if progression_ui == null:
		return
	var value: Variant = progression_ui.get("upgrade_button")
	if value is Button:
		var button := value as Button
		button.custom_minimum_size = Vector2(350.0, 78.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_apply_outline(button)

func _style_station_cards() -> void:
	var station_ui: Node = precinct.get_node_or_null("StationCommandUI")
	if station_ui == null:
		return
	for button: Button in _find_buttons(station_ui):
		if button.text.contains("UPGRADE") or button.text.contains("REPAIR") or button.text.contains("TURRET") or button.text.contains("BATTERY") or button.text.contains("GRID") or button.text.contains("BAY"):
			button.custom_minimum_size.y = 62.0
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			_apply_outline(button)

func _refresh() -> void:
	_refresh_room_cards()
	_refresh_officer_cards()
	_refresh_equipment_card()
	_refresh_station_card_text()

func _refresh_room_cards() -> void:
	if repair_card == null:
		return
	var room_id: String = String(precinct.get("selected_room_id"))
	var room: Dictionary = PrecinctState.get_room(room_id)
	if room.is_empty():
		return
	var repaired: bool = bool(room.get("repaired", false))
	var repair_end: int = int(room.get("repair_end", 0))
	var repair_cost: int = int(room.get("repair_cost", 0))
	if repaired:
		repair_card.text = "REPAIR ROOM\nSTATUS: OPERATIONAL  |  COST: NONE  |  TIME: COMPLETE"
		repair_card.disabled = true
	elif repair_end > Time.get_unix_time_from_system():
		repair_card.text = "REPAIR IN PROGRESS\nREQUIREMENT MET  |  COST PAID  |  TIME LEFT: %s" % _duration(repair_end - int(Time.get_unix_time_from_system()))
		repair_card.disabled = true
	else:
		repair_card.text = "REPAIR ROOM\nREQUIRES: DAMAGED ROOM  |  COST: %d CREDITS  |  TIME: 12 SEC" % repair_cost
		repair_card.disabled = PrecinctState.credits < repair_cost

	var level: int = int(room.get("level", 1))
	var cap: int = StationProgression.station_level if room_id == "chief" else int(PrecinctState.get_room("chief").get("level", 1))
	var cost: int = 90 + level * 55
	var seconds: int = StationProgression.room_upgrade_duration(room_id)
	var requirement: String = "ROOM ONLINE, %s CAP %d" % ["STATION" if room_id == "chief" else "CHIEF", cap]
	room_upgrade_card.text = "UPGRADE ROOM TO LEVEL %d\nREQUIRES: %s  |  COST: %d CREDITS  |  TIME: %s" % [level + 1, requirement, cost, _duration(seconds)]
	room_upgrade_card.disabled = not repaired or level >= cap or StationProgression.available_slots() <= 0 or PrecinctState.credits < cost

	var officer_name: String = "SELECT AN OFFICER"
	var officer_index: int = int(precinct.get("selected_officer_index"))
	if not PrecinctState.officers.is_empty() and officer_index >= 0 and officer_index < PrecinctState.officers.size():
		officer_name = String(PrecinctState.officers[officer_index].get("name", "OFFICER")).to_upper()
	assign_card.text = "POST %s\nREQUIRES: ROOM ONLINE  |  COST: NONE  |  TIME: IMMEDIATE" % officer_name
	assign_card.disabled = not repaired or PrecinctState.officers.is_empty()

func _refresh_officer_cards() -> void:
	if train_card == null or PrecinctState.officers.is_empty():
		return
	var index: int = clampi(int(precinct.get("selected_officer_index")), 0, PrecinctState.officers.size() - 1)
	var officer: Dictionary = PrecinctState.officers[index]
	var name: String = String(officer.get("name", "OFFICER")).to_upper()
	var level: int = int(officer.get("level", 1))
	var train_cost: int = 70 + level * 35
	train_card.text = "TRAIN %s TO LEVEL %d\nREQUIRES: OFFICER AVAILABLE  |  COST: %d CREDITS  |  TIME: IMMEDIATE" % [name, level + 1, train_cost]
	train_card.disabled = level >= 100 or not PrecinctState.officer_available(officer) or PrecinctState.credits < train_cost
	heal_card.text = "HEAL %s\nREQUIRES: MEDBAY ONLINE  |  COST: 45 CREDITS  |  TIME: IMMEDIATE" % name
	heal_card.disabled = not PrecinctState.is_room_repaired("medbay") or PrecinctState.credits < 45 or int(officer.get("hp", 0)) >= int(officer.get("max_hp", 100))
	var room_id: String = String(precinct.get("selected_room_id"))
	var room: Dictionary = PrecinctState.get_room(room_id)
	post_card.text = "POST TO %s\nREQUIRES: ROOM ONLINE  |  COST: NONE  |  TIME: IMMEDIATE" % String(room.get("name", "ROOM")).to_upper()
	post_card.disabled = not bool(room.get("repaired", false))

func _refresh_equipment_card() -> void:
	if progression_ui == null:
		return
	var value: Variant = progression_ui.get("upgrade_button")
	if not value is Button:
		return
	var button := value as Button
	var room_id: String = String(precinct.get("selected_room_id"))
	var room: Dictionary = PrecinctState.get_room(room_id)
	var items: Array[Dictionary] = PrecinctEquipment.room_items(room_id)
	if items.is_empty():
		button.text = "NO UPGRADEABLE EQUIPMENT IN THIS ROOM"
		button.disabled = true
		return
	var selected: int = clampi(int(progression_ui.get("selected_item_index")), 0, items.size() - 1)
	var item: Dictionary = items[selected]
	var item_id: String = String(item.get("id", ""))
	var level: int = int(item.get("level", 1))
	var cap: int = int(item.get("cap", 1))
	var cost: int = int(item.get("upgrade_cost", 0))
	var seconds: int = StationProgression.item_upgrade_duration(room_id, item_id)
	button.text = "UPGRADE %s TO LEVEL %d\nREQUIRES: ROOM ONLINE, ROOM CAP %d  |  COST: %d CREDITS  |  TIME: %s" % [String(item.get("name", "ITEM")).to_upper(), level + 1, cap, cost, _duration(seconds)]
	button.disabled = not bool(room.get("repaired", false)) or level >= cap or StationProgression.available_slots() <= 0 or PrecinctState.credits < cost

func _refresh_station_card_text() -> void:
	var station_ui: Node = precinct.get_node_or_null("StationCommandUI")
	if station_ui == null:
		return
	for button: Button in _find_buttons(station_ui):
		if button.text.begins_with("UPGRADE STATION"):
			var level: int = StationProgression.station_level
			var cost: int = 500 + level * 280
			button.text = "UPGRADE STATION TO LEVEL %d\nREQUIRES: FREE CONSTRUCTION SLOT  |  COST: %d CREDITS  |  TIME: %s" % [level + 1, cost, _duration(StationProgression.station_upgrade_duration())]
			button.disabled = StationProgression.available_slots() <= 0 or PrecinctState.credits < cost or level >= 100
		elif button.text.begins_with("UPGRADE SELECTED ROOM"):
			var room_id: String = String(precinct.get("selected_room_id"))
			var room: Dictionary = PrecinctState.get_room(room_id)
			var level: int = int(room.get("level", 1))
			var cost: int = 90 + level * 55
			button.text = "UPGRADE SELECTED ROOM TO LEVEL %d\nCOST: %d CREDITS  |  TIME: %s" % [level + 1, cost, _duration(StationProgression.room_upgrade_duration(room_id))]

func _card(title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(310.0, 72.0)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(callback)
	_apply_outline(button)
	return button

func _small_button(title: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(150.0, 32.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	_apply_outline(button)
	return button

func _apply_outline(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("DFF8FF"))
	button.add_theme_color_override("font_disabled_color", Color("71818C"))
	button.add_theme_stylebox_override("normal", _outline_style(Color("0A1721"), Color("4A8199")))
	button.add_theme_stylebox_override("hover", _outline_style(Color("102938"), Color("6DEBFF")))
	button.add_theme_stylebox_override("pressed", _outline_style(Color("173849"), Color("8CF3FF")))
	button.add_theme_stylebox_override("disabled", _outline_style(Color("090E13"), Color("293944")))

func _outline_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

func _find_buttons(root: Node) -> Array[Button]:
	var result: Array[Button] = []
	if root is Button:
		result.append(root as Button)
	for child: Node in root.get_children():
		result.append_array(_find_buttons(child))
	return result

func _duration(seconds: int) -> String:
	var safe: int = maxi(0, seconds)
	if safe < 60:
		return "%d SEC" % safe
	if safe < 3600:
		return "%d MIN %02d SEC" % [safe / 60, safe % 60]
	if safe < 86400:
		return "%d HR %02d MIN" % [safe / 3600, (safe % 3600) / 60]
	return "%d DAY %02d HR" % [safe / 86400, (safe % 86400) / 3600]
