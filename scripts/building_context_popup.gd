extends Node
## Small contextual popup opened only after a Headquarters department or standalone
## facility is touched. It never becomes a full-screen menu.

var precinct: Node
var layer: CanvasLayer
var panel: PanelContainer
var title: Label
var summary: Label
var item_list: ItemList
var item_detail: Label
var status: Label
var upgrade_department_button: Button
var upgrade_item_button: Button
var headquarters_button: Button
var staff_button: Button
var style_buttons: Array[Button] = []
var current_mode := ""
var current_id := ""
var selected_item_index := 0
var refresh_clock := 0.0

func _ready() -> void:
	precinct = get_parent()
	_build_popup()
	if not HeadquartersProgression.headquarters_changed.is_connected(_refresh): HeadquartersProgression.headquarters_changed.connect(_refresh)
	if not ResourceHarvest.resources_changed.is_connected(_refresh): ResourceHarvest.resources_changed.connect(_refresh)
	if not PrecinctState.state_changed.is_connected(_refresh): PrecinctState.state_changed.connect(_refresh)

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock >= 0.35:
		refresh_clock = 0.0
		if panel.visible: _refresh()

func open_department(department_id: String, screen_position: Vector2) -> void:
	current_mode = "department"; current_id = department_id; selected_item_index = 0
	_position_panel(screen_position); panel.visible = true; _refresh(); MoonGoonsAudio.play("door")

func open_facility(facility_id: String, screen_position: Vector2) -> void:
	current_mode = "facility"; current_id = facility_id; selected_item_index = 0
	_position_panel(screen_position); panel.visible = true; _refresh(); MoonGoonsAudio.play("door")

func close() -> void:
	panel.visible = false; current_mode = ""; current_id = ""

func _build_popup() -> void:
	layer = CanvasLayer.new(); layer.name = "BuildingPopupLayer"; layer.layer = 88; precinct.add_child(layer)
	panel = PanelContainer.new(); panel.name = "BuildingContextPanel"; panel.custom_minimum_size = Vector2(410, 535); panel.visible = false; panel.add_theme_stylebox_override("panel", _panel_style()); layer.add_child(panel)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 6); panel.add_child(column)
	var header := HBoxContainer.new(); column.add_child(header)
	title = Label.new(); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; title.add_theme_font_size_override("font_size", 18); header.add_child(title)
	var close_button := _small_button("X", close); close_button.custom_minimum_size = Vector2(38,32); header.add_child(close_button)
	summary = Label.new(); summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; summary.custom_minimum_size = Vector2(385, 62); summary.add_theme_font_size_override("font_size", 11); column.add_child(summary)
	var style_label := Label.new(); style_label.text = "VISUAL SKIN  //  FIVE OPTIONS"; style_label.add_theme_font_size_override("font_size", 10); column.add_child(style_label)
	var styles := HBoxContainer.new(); styles.add_theme_constant_override("separation", 4); column.add_child(styles)
	for index: int in range(HeadquartersFacilityCatalog.STYLE_NAMES.size()):
		var button := _small_button(["AUTH","IND","TACT","CIVIC","PROTO"][index], _select_style.bind(index)); button.tooltip_text = HeadquartersFacilityCatalog.STYLE_NAMES[index]; button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; styles.add_child(button); style_buttons.append(button)
	item_list = ItemList.new(); item_list.custom_minimum_size = Vector2(385, 190); item_list.item_selected.connect(_on_item_selected); column.add_child(item_list)
	item_detail = Label.new(); item_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; item_detail.custom_minimum_size = Vector2(385, 66); item_detail.add_theme_font_size_override("font_size", 11); column.add_child(item_detail)
	headquarters_button = _action_button("UPGRADE HEADQUARTERS", _upgrade_headquarters); column.add_child(headquarters_button)
	upgrade_department_button = _action_button("UPGRADE DEPARTMENT", _upgrade_department_or_facility); column.add_child(upgrade_department_button)
	upgrade_item_button = _action_button("UPGRADE SELECTED ITEM", _upgrade_item); column.add_child(upgrade_item_button)
	var bottom := HBoxContainer.new(); bottom.add_theme_constant_override("separation", 5); column.add_child(bottom)
	staff_button = _small_button("STAFF / TROOPS", _open_staff); staff_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; bottom.add_child(staff_button)
	var map_button := _small_button("ORBITAL MAP", _open_orbital_map); map_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL; bottom.add_child(map_button)
	status = Label.new(); status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; status.custom_minimum_size = Vector2(385, 38); status.add_theme_font_size_override("font_size", 10); status.add_theme_color_override("font_color", Color("89ECFF")); column.add_child(status)

func _position_panel(screen_position: Vector2) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var desired := screen_position + Vector2(18, -80)
	if desired.x + 420 > viewport_size.x: desired.x = screen_position.x - 430
	desired.x = clampf(desired.x, 10, maxf(10, viewport_size.x - 420))
	desired.y = clampf(desired.y, 78, maxf(78, viewport_size.y - 545))
	panel.position = desired

func _refresh() -> void:
	if current_mode == "department": _refresh_department()
	elif current_mode == "facility": _refresh_facility()

func _refresh_department() -> void:
	var data := HeadquartersFacilityCatalog.department(current_id)
	var level := HeadquartersProgression.department_level(current_id)
	title.text = "%s  //  LEVEL %d" % [String(data.get("name", current_id)).to_upper(), level]
	summary.text = "%s\nHQ CAP %d  |  CONSTRUCTION SLOTS %d/%d" % [String(data.get("function", "Police department")), HeadquartersProgression.headquarters_level, HeadquartersProgression.active_jobs(), HeadquartersProgression.construction_slots()]
	item_list.visible = true; item_detail.visible = true; upgrade_item_button.visible = true; staff_button.visible = true
	item_list.clear(); var items := HeadquartersFacilityCatalog.department_items(current_id)
	for item: Dictionary in items:
		var item_id := String(item.get("id", "")); var item_level := HeadquartersProgression.item_level(current_id, item_id)
		var job := HeadquartersProgression.active_job_for("item", "%s:%s" % [current_id, item_id])
		var state := "UPGRADING %ds" % HeadquartersProgression.job_time_left(job) if not job.is_empty() else "READY"
		item_list.add_item("L%02d  %s  //  %s" % [item_level, String(item.get("name", "ITEM")), state])
	if not items.is_empty(): selected_item_index = clampi(selected_item_index, 0, items.size()-1); item_list.select(selected_item_index)
	var dept_cost := HeadquartersFacilityCatalog.department_upgrade_cost(current_id, level); var dept_time := HeadquartersFacilityCatalog.department_upgrade_time(level)
	upgrade_department_button.text = "UPGRADE DEPARTMENT TO LEVEL %d\nREQUIRES: HQ CAP %d  |  COST: %s  |  TIME: %s" % [level+1, HeadquartersProgression.headquarters_level, _cost_text(dept_cost), _duration(dept_time)]
	upgrade_department_button.disabled = level >= HeadquartersProgression.headquarters_level or HeadquartersProgression.available_slots() <= 0
	headquarters_button.visible = current_id == "chief"
	if headquarters_button.visible:
		var hq_cost := HeadquartersFacilityCatalog.facility_upgrade_cost("headquarters", HeadquartersProgression.headquarters_level)
		headquarters_button.text = "UPGRADE HEADQUARTERS TO LEVEL %d\nCOST: %s  |  TIME: %s" % [HeadquartersProgression.headquarters_level+1, _cost_text(hq_cost), _duration(HeadquartersFacilityCatalog.facility_upgrade_time(HeadquartersProgression.headquarters_level))]
	_refresh_selected_item()
	_update_style_buttons(HeadquartersProgression.department_style(current_id))

func _refresh_facility() -> void:
	var data := HeadquartersFacilityCatalog.facility(current_id); var level := HeadquartersProgression.facility_level(current_id)
	title.text = "%s  //  LEVEL %d" % [String(data.get("name", current_id)).to_upper(), level]
	summary.text = "%s\nHQ CAP %d  |  CONSTRUCTION SLOTS %d/%d" % [String(data.get("function", "Standalone facility")), HeadquartersProgression.headquarters_level, HeadquartersProgression.active_jobs(), HeadquartersProgression.construction_slots()]
	item_list.visible = false; item_detail.visible = false; upgrade_item_button.visible = false; headquarters_button.visible = false; staff_button.visible = true
	var cost := HeadquartersFacilityCatalog.facility_upgrade_cost(current_id, level); var seconds := HeadquartersFacilityCatalog.facility_upgrade_time(level)
	upgrade_department_button.text = "UPGRADE FACILITY TO LEVEL %d\nREQUIRES: HQ CAP %d  |  COST: %s  |  TIME: %s" % [level+1, HeadquartersProgression.headquarters_level, _cost_text(cost), _duration(seconds)]
	upgrade_department_button.disabled = level >= HeadquartersProgression.headquarters_level or HeadquartersProgression.available_slots() <= 0
	_update_style_buttons(HeadquartersProgression.facility_style(current_id))

func _refresh_selected_item() -> void:
	var items := HeadquartersFacilityCatalog.department_items(current_id)
	if items.is_empty(): return
	selected_item_index = clampi(selected_item_index, 0, items.size()-1)
	var item := items[selected_item_index]; var item_id := String(item.get("id", "")); var level := HeadquartersProgression.item_level(current_id, item_id)
	var cost := HeadquartersFacilityCatalog.item_cost(item, level); var seconds := HeadquartersFacilityCatalog.item_time(item, level)
	item_detail.text = "%s  //  LEVEL %d\nTwo-resource upgrade: %s  |  Completion: %s" % [String(item.get("name", "Item")), level, _cost_text(cost), _duration(seconds)]
	upgrade_item_button.text = "UPGRADE %s TO LEVEL %d\nREQUIRES: DEPARTMENT CAP %d  |  COST: %s  |  TIME: %s" % [String(item.get("name", "ITEM")).to_upper(), level+1, HeadquartersProgression.department_level(current_id), _cost_text(cost), _duration(seconds)]
	upgrade_item_button.disabled = level >= HeadquartersProgression.department_level(current_id) or HeadquartersProgression.available_slots() <= 0

func _on_item_selected(index: int) -> void:
	selected_item_index = index; _refresh_selected_item(); MoonGoonsAudio.play("click")

func _select_style(index: int) -> void:
	if current_mode == "department": HeadquartersProgression.set_department_style(current_id, index)
	elif current_mode == "facility": HeadquartersProgression.set_facility_style(current_id, index)
	status.text = HeadquartersProgression.last_event

func _upgrade_headquarters() -> void:
	var result := HeadquartersProgression.begin_headquarters_upgrade(); status.text = String(result.get("message", "")); _refresh()

func _upgrade_department_or_facility() -> void:
	var result := HeadquartersProgression.begin_department_upgrade(current_id) if current_mode == "department" else HeadquartersProgression.begin_facility_upgrade(current_id)
	status.text = String(result.get("message", "")); _refresh()

func _upgrade_item() -> void:
	var items := HeadquartersFacilityCatalog.department_items(current_id)
	if items.is_empty(): return
	var item := items[clampi(selected_item_index,0,items.size()-1)]
	var result := HeadquartersProgression.begin_item_upgrade(current_id, String(item.get("id", ""))); status.text = String(result.get("message", "")); _refresh()

func _open_staff() -> void:
	close(); var ribbon := precinct.get_node_or_null("CompactCommandRibbon")
	if ribbon != null and ribbon.has_method("_activate"): ribbon.call("_activate", "officers")

func _open_orbital_map() -> void:
	close(); var orbital := precinct.get_node_or_null("OrbitalOperationsMap")
	if orbital != null and orbital.has_method("open_map"): orbital.call("open_map")

func _update_style_buttons(active_index: int) -> void:
	for index: int in range(style_buttons.size()): style_buttons[index].disabled = index == active_index

func _cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for key_value: Variant in cost.keys(): parts.append("%d %s" % [int(cost.get(key_value,0)), String(key_value).replace("quantum_salvage","Q-SALV").replace("moonsteel","ORE").replace("helium3","HE-3").to_upper()])
	return " + ".join(parts)

func _duration(seconds: int) -> String:
	if seconds < 60: return "%ds" % seconds
	return "%dm %02ds" % [int(seconds/60), seconds%60]

func _action_button(text_value: String, callback: Callable) -> Button:
	var button := Button.new(); button.text = text_value; button.custom_minimum_size = Vector2(385, 58); button.alignment = HORIZONTAL_ALIGNMENT_LEFT; button.add_theme_font_size_override("font_size",10); button.pressed.connect(callback); _style_button(button); return button
func _small_button(text_value: String, callback: Callable) -> Button:
	var button := Button.new(); button.text=text_value; button.custom_minimum_size=Vector2(70,32); button.add_theme_font_size_override("font_size",10); button.pressed.connect(callback); _style_button(button); return button
func _style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _outline(Color("091722"),Color("47788D"))); button.add_theme_stylebox_override("hover", _outline(Color("102B3A"),Color("6DEBFF"))); button.add_theme_stylebox_override("pressed", _outline(Color("173B4D"),Color("9AF4FF"))); button.add_theme_stylebox_override("disabled", _outline(Color("090D12"),Color("293943")))
func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color=Color("06121C",0.97); style.border_color=Color("60DFF5"); style.set_border_width_all(2); style.set_corner_radius_all(7); style.set_content_margin_all(9); return style
func _outline(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color=fill; style.border_color=border; style.set_border_width_all(1); style.set_corner_radius_all(4); style.set_content_margin_all(5); return style
