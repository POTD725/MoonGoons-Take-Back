extends Node
## Compact station command panel for timed upgrades and marauder defense.

var precinct: Node3D
var layer: CanvasLayer
var open_button: Button
var panel: PanelContainer
var hierarchy_label: Label
var hull_bar: ProgressBar
var shield_bar: ProgressBar
var defense_label: Label
var marauder_label: Label
var jobs_list: ItemList
var status_label: Label
var selected_room_label: Label
var refresh_clock: float = 0.0

func _ready() -> void:
	precinct = get_parent() as Node3D
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(14):
		await get_tree().process_frame
	if precinct == null:
		return
	_build_interface()
	if not StationProgression.progression_changed.is_connected(_refresh):
		StationProgression.progression_changed.connect(_refresh)
	if not PrecinctState.state_changed.is_connected(_refresh):
		PrecinctState.state_changed.connect(_refresh)
	_refresh()

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock < 0.25:
		return
	refresh_clock = 0.0
	StationProgression.tick()
	if panel != null and panel.visible:
		_refresh()

func _build_interface() -> void:
	layer = CanvasLayer.new()
	layer.name = "StationCommandLayer"
	layer.layer = 27
	precinct.add_child(layer)
	open_button = Button.new()
	open_button.name = "StationCommandButton"
	open_button.text = "STATION COMMAND"
	open_button.position = Vector2(830.0, 84.0)
	open_button.size = Vector2(184.0, 38.0)
	open_button.pressed.connect(_toggle_panel)
	layer.add_child(open_button)
	panel = PanelContainer.new()
	panel.name = "StationCommandPanel"
	panel.position = Vector2(698.0, 128.0)
	panel.size = Vector2(552.0, 492.0)
	panel.visible = false
	layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "ORBITAL STATION COMMAND"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 19)
	header.add_child(title)
	var close := Button.new()
	close.text = "CLOSE"
	close.pressed.connect(_toggle_panel)
	header.add_child(close)
	hierarchy_label = Label.new()
	hierarchy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hierarchy_label)
	var meter_row := HBoxContainer.new()
	column.add_child(meter_row)
	var hull_column := VBoxContainer.new()
	hull_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter_row.add_child(hull_column)
	var hull_title := Label.new()
	hull_title.text = "HULL INTEGRITY"
	hull_column.add_child(hull_title)
	hull_bar = ProgressBar.new()
	hull_bar.max_value = 100
	hull_bar.show_percentage = true
	hull_column.add_child(hull_bar)
	var shield_column := VBoxContainer.new()
	shield_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter_row.add_child(shield_column)
	var shield_title := Label.new()
	shield_title.text = "SHIELD GRID"
	shield_column.add_child(shield_title)
	shield_bar = ProgressBar.new()
	shield_bar.max_value = 100
	shield_bar.show_percentage = true
	shield_column.add_child(shield_bar)
	var hierarchy_buttons := HBoxContainer.new()
	column.add_child(hierarchy_buttons)
	hierarchy_buttons.add_child(_button("UPGRADE STATION", _upgrade_station))
	hierarchy_buttons.add_child(_button("UPGRADE SELECTED ROOM", _upgrade_selected_room))
	selected_room_label = Label.new()
	selected_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(selected_room_label)
	var jobs_title := Label.new()
	jobs_title.text = "CONSTRUCTION QUEUE"
	column.add_child(jobs_title)
	jobs_list = ItemList.new()
	jobs_list.custom_minimum_size = Vector2(520.0, 92.0)
	column.add_child(jobs_list)
	defense_label = Label.new()
	column.add_child(defense_label)
	var defense_grid := GridContainer.new()
	defense_grid.columns = 2
	column.add_child(defense_grid)
	for defense_id: String in ["point_defense", "rail_battery", "shield_grid", "interceptor_bay"]:
		defense_grid.add_child(_button(StationProgression.defense_name(defense_id), _upgrade_defense.bind(defense_id)))
	marauder_label = Label.new()
	marauder_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(marauder_label)
	var defense_actions := HBoxContainer.new()
	column.add_child(defense_actions)
	defense_actions.add_child(_button("TRIGGER TEST WAVE", _trigger_wave))
	defense_actions.add_child(_button("RESOLVE DEFENSE", _resolve_wave))
	defense_actions.add_child(_button("REPAIR HULL", _repair_hull))
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)

func _button(text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(160.0, 36.0)
	button.pressed.connect(callback)
	return button

func _toggle_panel() -> void:
	panel.visible = not panel.visible
	MoonGoonsAudio.play("click")
	if panel.visible:
		_refresh()

func _refresh() -> void:
	if panel == null:
		return
	var chief_level: int = int(PrecinctState.get_room("chief").get("level", 1))
	var room_id: String = String(precinct.get("selected_room_id"))
	var room: Dictionary = PrecinctState.get_room(room_id)
	var room_level: int = int(room.get("level", 1))
	hierarchy_label.text = "LEVEL CHAIN  STATION %d → CHIEF %d → %s %d → EQUIPMENT ≤ %d\nCONSTRUCTION SLOTS %d / %d AVAILABLE" % [StationProgression.station_level, chief_level, String(room.get("name", "Room")).to_upper(), room_level, room_level, StationProgression.available_slots(), StationProgression.construction_slots()]
	selected_room_label.text = "SELECTED: %s  LEVEL %d  •  NEXT ROOM TIME %s" % [String(room.get("name", "Room")).to_upper(), room_level, _format_time(StationProgression.room_upgrade_duration(room_id))]
	hull_bar.value = StationProgression.station_hull
	shield_bar.value = StationProgression.station_shield
	jobs_list.clear()
	for job: Dictionary in StationProgression.upgrade_jobs:
		jobs_list.add_item("%s → L%d   %s" % [String(job.get("display_name", "Upgrade")), int(job.get("target_level", 1)), _format_time(StationProgression.job_time_left(job))])
	if StationProgression.upgrade_jobs.is_empty():
		jobs_list.add_item("No active construction jobs.")
	defense_label.text = "DEFENSE RATING %d  •  WEAPONS BONUS %d\nPD L%d   RAIL L%d   SHIELD L%d   INTERCEPTORS L%d" % [StationProgression.defense_rating(), SideOperations.defense_bonus, StationProgression.defense_level("point_defense"), StationProgression.defense_level("rail_battery"), StationProgression.defense_level("shield_grid"), StationProgression.defense_level("interceptor_bay")]
	if StationProgression.active_marauder_wave.is_empty():
		marauder_label.text = "MARAUDER STATUS: CLEAR\nNEXT ESTIMATED CONTACT: %s" % _format_time(maxi(0, StationProgression.next_marauder_attack_at - int(Time.get_unix_time_from_system())))
	else:
		var wave: Dictionary = StationProgression.active_marauder_wave
		marauder_label.text = "MARAUDER ALERT  TIER %d  •  %d SHIPS  •  ATTACK POWER %d\nAUTO-RESOLVE IN %s" % [int(wave.get("tier", 1)), int(wave.get("ships", 1)), int(wave.get("power", 0)), _format_time(maxi(0, int(wave.get("resolve_at", 0)) - int(Time.get_unix_time_from_system())))]
	if status_label.text.is_empty():
		status_label.text = "Upgrade times increase quadratically with level and continue while the game is closed."

func _upgrade_station() -> void:
	_handle_result(StationProgression.begin_station_upgrade())

func _upgrade_selected_room() -> void:
	_handle_result(StationProgression.begin_room_upgrade(String(precinct.get("selected_room_id"))))

func _upgrade_defense(defense_id: String) -> void:
	_handle_result(StationProgression.begin_defense_upgrade(defense_id))

func _trigger_wave() -> void:
	_handle_result(StationProgression.trigger_marauder_wave())

func _resolve_wave() -> void:
	_handle_result(StationProgression.resolve_marauder_wave())

func _repair_hull() -> void:
	_handle_result(StationProgression.repair_station_hull())

func _handle_result(result: Dictionary) -> void:
	status_label.text = String(result.get("message", "Station command updated."))
	MoonGoonsAudio.play("confirm" if bool(result.get("ok", false)) else "error")
	_refresh()

func _format_time(seconds: int) -> String:
	var safe_seconds: int = maxi(0, seconds)
	var hours: int = safe_seconds / 3600
	var minutes: int = (safe_seconds % 3600) / 60
	var secs: int = safe_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]
