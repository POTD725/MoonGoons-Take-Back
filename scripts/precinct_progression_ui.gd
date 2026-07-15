extends Node
## Adds individual equipment selection, level badges, Chief cap messaging,
## and detailed mission information to the living precinct.

const ITEM_POSITIONS: Dictionary = {
	"ops": [Vector3(0.0,1.45,-0.15), Vector3(-2.55,1.10,-0.15), Vector3(2.55,1.10,-0.15)],
	"armory": [Vector3(-2.6,1.55,-2.65), Vector3(0.0,1.05,0.45), Vector3(2.45,1.0,1.15)],
	"cells": [Vector3(-2.65,1.55,-0.95), Vector3(2.9,1.1,2.05), Vector3(-2.9,1.1,2.05)],
	"quarters": [Vector3(-2.75,1.0,-1.7), Vector3(0.0,1.0,0.2), Vector3(2.75,1.15,1.1)],
	"medbay": [Vector3(-2.55,1.15,-0.65), Vector3(0.0,1.3,-2.75), Vector3(2.55,1.15,-0.65)],
	"chief": [Vector3(0.0,1.3,-0.2), Vector3(0.0,1.8,-2.8), Vector3(2.55,1.45,1.25)],
	"interrogation": [Vector3(0.0,1.4,-0.4), Vector3(-2.45,1.15,1.4), Vector3(2.4,0.9,1.0)],
	"transfer": [Vector3(0.0,1.65,-2.7), Vector3(-2.35,1.1,0.8), Vector3(2.35,1.1,0.8)]
}

var precinct: Node3D
var layer: CanvasLayer
var equipment_toggle: Button
var equipment_panel: PanelContainer
var equipment_title: Label
var cap_label: Label
var equipment_list: ItemList
var equipment_detail: Label
var upgrade_button: Button
var mission_detail: Label
var selected_item_index: int = 0
var selected_room_cache: String = ""
var tab_cache: String = ""
var refresh_clock: float = 0.0

func _ready() -> void:
	precinct = get_parent() as Node3D
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(12):
		await get_tree().process_frame
	if precinct == null:
		return
	_build_equipment_interface()
	_enhance_mission_interface()
	_attach_world_hotspots()
	if not PrecinctEquipment.equipment_changed.is_connected(_on_equipment_changed):
		PrecinctEquipment.equipment_changed.connect(_on_equipment_changed)
	if not PrecinctState.state_changed.is_connected(_on_precinct_state_changed):
		PrecinctState.state_changed.connect(_on_precinct_state_changed)
	_refresh_all()

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock < 0.2 or precinct == null:
		return
	refresh_clock = 0.0
	var room_id: String = String(precinct.get("selected_room_id"))
	var tab_id: String = String(precinct.get("current_tab"))
	if room_id != selected_room_cache:
		selected_room_cache = room_id
		selected_item_index = 0
		if tab_id == "city":
			equipment_panel.visible = true
		_refresh_equipment()
		_refresh_hotspot_visibility()
	if tab_id != tab_cache:
		tab_cache = tab_id
		_update_panel_visibility()

func _input(event: InputEvent) -> void:
	if precinct == null or not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if equipment_panel != null and equipment_panel.visible and mouse_event.position.x < 420.0:
		return
	var camera_value: Variant = precinct.get("camera")
	if not camera_value is Camera3D:
		return
	var camera_3d := camera_value as Camera3D
	var origin: Vector3 = camera_3d.project_ray_origin(mouse_event.position)
	var direction: Vector3 = camera_3d.project_ray_normal(mouse_event.position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 200.0)
	query.collide_with_areas = true
	var hit: Dictionary = precinct.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider") as Object
	if collider == null or not collider.has_meta("equipment_id"):
		return
	var room_id: String = String(collider.get_meta("room_id", "ops"))
	var equipment_id: String = String(collider.get_meta("equipment_id", ""))
	precinct.set("selected_room_id", room_id)
	selected_room_cache = room_id
	_select_equipment_id(equipment_id)
	equipment_panel.visible = true
	_refresh_equipment()
	_refresh_hotspot_visibility()

func _build_equipment_interface() -> void:
	layer = CanvasLayer.new()
	layer.name = "EquipmentProgressionLayer"
	layer.layer = 24
	precinct.add_child(layer)
	equipment_toggle = Button.new()
	equipment_toggle.name = "EquipmentToggle"
	equipment_toggle.text = "ROOM EQUIPMENT"
	equipment_toggle.position = Vector2(172.0, 84.0)
	equipment_toggle.size = Vector2(176.0, 38.0)
	equipment_toggle.pressed.connect(_toggle_equipment_panel)
	layer.add_child(equipment_toggle)
	equipment_panel = PanelContainer.new()
	equipment_panel.name = "RoomEquipmentPanel"
	equipment_panel.position = Vector2(18.0, 128.0)
	equipment_panel.size = Vector2(382.0, 480.0)
	equipment_panel.visible = false
	layer.add_child(equipment_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	equipment_panel.add_child(column)
	equipment_title = Label.new()
	equipment_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equipment_title.add_theme_font_size_override("font_size", 18)
	column.add_child(equipment_title)
	cap_label = Label.new()
	cap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(cap_label)
	equipment_list = ItemList.new()
	equipment_list.custom_minimum_size = Vector2(350.0, 190.0)
	equipment_list.item_selected.connect(_on_equipment_selected)
	column.add_child(equipment_list)
	equipment_detail = Label.new()
	equipment_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equipment_detail.custom_minimum_size = Vector2(350.0, 118.0)
	column.add_child(equipment_detail)
	upgrade_button = Button.new()
	upgrade_button.text = "UPGRADE SELECTED ITEM"
	upgrade_button.custom_minimum_size = Vector2(350.0, 42.0)
	upgrade_button.pressed.connect(_upgrade_selected_item)
	column.add_child(upgrade_button)
	var close_button := Button.new()
	close_button.text = "CLOSE EQUIPMENT"
	close_button.pressed.connect(_toggle_equipment_panel)
	column.add_child(close_button)

func _enhance_mission_interface() -> void:
	var nav_value: Variant = precinct.get("nav_buttons")
	if nav_value is Dictionary and (nav_value as Dictionary).has("tasks"):
		var mission_button: Button = (nav_value as Dictionary)["tasks"] as Button
		if mission_button != null:
			mission_button.text = "MISSIONS"
	var task_list_value: Variant = precinct.get("task_list")
	if not task_list_value is ItemList:
		return
	var mission_list := task_list_value as ItemList
	mission_list.custom_minimum_size = Vector2(300.0, 280.0)
	mission_list.item_selected.connect(_on_mission_selected)
	var column: Node = mission_list.get_parent()
	if column == null:
		return
	mission_detail = Label.new()
	mission_detail.name = "MissionDetail"
	mission_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_detail.custom_minimum_size = Vector2(300.0, 118.0)
	column.add_child(mission_detail)
	if column.get_child_count() >= 2:
		column.move_child(mission_detail, column.get_child_count() - 2)

func _toggle_equipment_panel() -> void:
	if equipment_panel == null:
		return
	equipment_panel.visible = not equipment_panel.visible
	MoonGoonsAudio.play("click")

func _update_panel_visibility() -> void:
	if equipment_toggle == null or equipment_panel == null:
		return
	var city_active: bool = String(precinct.get("current_tab")) == "city"
	equipment_toggle.visible = city_active
	if not city_active:
		equipment_panel.visible = false
	_refresh_mission_detail()

func _refresh_all() -> void:
	selected_room_cache = String(precinct.get("selected_room_id"))
	tab_cache = String(precinct.get("current_tab"))
	_refresh_equipment()
	_refresh_mission_detail()
	_refresh_hotspot_visibility()
	_update_panel_visibility()

func _refresh_equipment() -> void:
	if equipment_list == null:
		return
	var room_id: String = String(precinct.get("selected_room_id"))
	var room: Dictionary = PrecinctState.get_room(room_id)
	var items: Array[Dictionary] = PrecinctEquipment.room_items(room_id)
	equipment_title.text = "%s EQUIPMENT" % String(room.get("name", "Room")).to_upper()
	cap_label.text = "CHIEF'S OFFICE CAP: LEVEL %d   •   ROOM RATING: %d" % [PrecinctEquipment.chief_level(), PrecinctEquipment.room_operational_rating(room_id)]
	equipment_list.clear()
	for item: Dictionary in items:
		equipment_list.add_item("LV %d / %d   %s" % [int(item.get("level", 1)), int(item.get("cap", 1)), String(item.get("name", "Equipment"))])
	if not items.is_empty():
		selected_item_index = clampi(selected_item_index, 0, items.size() - 1)
		equipment_list.select(selected_item_index)
		var selected: Dictionary = items[selected_item_index]
		var current_level: int = int(selected.get("level", 1))
		var cap: int = int(selected.get("cap", 1))
		var lock_text: String = "READY TO UPGRADE" if current_level < cap else "LOCKED AT COMMAND CAP"
		equipment_detail.text = "%s\nLEVEL %d / %d\nEFFECT: %s\nNEXT COST: %d CREDITS\n\n%s" % [String(selected.get("name", "Equipment")).to_upper(), current_level, cap, String(selected.get("effect", "Station capability")), int(selected.get("upgrade_cost", 0)), lock_text]
		upgrade_button.disabled = current_level >= cap or not bool(room.get("repaired", false))
	else:
		equipment_detail.text = "No equipment catalog is assigned to this room."
		upgrade_button.disabled = true

func _refresh_mission_detail() -> void:
	if mission_detail == null:
		return
	var tasks: Array[Dictionary] = PrecinctMeta.task_catalog()
	if tasks.is_empty():
		mission_detail.text = "No active missions."
		return
	var selected_index: int = clampi(int(precinct.get("selected_task_index")), 0, tasks.size() - 1)
	var task: Dictionary = tasks[selected_index]
	var claim_state: String = "CLAIMED" if PrecinctMeta.task_claimed(String(task.get("id", ""))) else "ACTIVE"
	mission_detail.text = "%s // %s\n%s\nPROGRESS %d / %d\nREWARD: %d CREDITS + %d INTEL" % [String(task.get("group", "MISSION")), claim_state, String(task.get("description", "Complete the objective.")), int(task.get("progress", 0)), int(task.get("target", 1)), int(task.get("reward_credits", 0)), int(task.get("reward_intel", 0))]

func _on_equipment_selected(index: int) -> void:
	selected_item_index = index
	MoonGoonsAudio.play("click")
	_refresh_equipment()

func _on_mission_selected(_index: int) -> void:
	call_deferred("_refresh_mission_detail")

func _upgrade_selected_item() -> void:
	var room_id: String = String(precinct.get("selected_room_id"))
	var items: Array[Dictionary] = PrecinctEquipment.room_items(room_id)
	if items.is_empty():
		return
	selected_item_index = clampi(selected_item_index, 0, items.size() - 1)
	var item_id: String = String(items[selected_item_index].get("id", ""))
	var result: Dictionary = PrecinctEquipment.upgrade_item(room_id, item_id)
	var status_value: Variant = precinct.get("status_label")
	if status_value is Label:
		(status_value as Label).text = String(result.get("message", "Equipment action complete."))
	MoonGoonsAudio.play("upgrade" if bool(result.get("ok", false)) else "error")
	_refresh_equipment()
	_attach_world_hotspots()
	_refresh_mission_detail()

func _select_equipment_id(equipment_id: String) -> void:
	var room_id: String = String(precinct.get("selected_room_id"))
	var items: Array[Dictionary] = PrecinctEquipment.room_items(room_id)
	for index: int in range(items.size()):
		if String(items[index].get("id", "")) == equipment_id:
			selected_item_index = index
			return

func _attach_world_hotspots() -> void:
	if precinct == null:
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
		var previous: Node = room_node.get_node_or_null("EquipmentHotspots")
		if previous != null:
			previous.queue_free()
		var hotspot_root := Node3D.new()
		hotspot_root.name = "EquipmentHotspots"
		room_node.add_child(hotspot_root)
		var items: Array[Dictionary] = PrecinctEquipment.room_items(room_id)
		var positions: Array = ITEM_POSITIONS.get(room_id, []) as Array
		for index: int in range(items.size()):
			var item: Dictionary = items[index]
			var hotspot := Area3D.new()
			hotspot.name = "Equipment_%s" % String(item.get("id", "item"))
			hotspot.position = positions[index] as Vector3 if index < positions.size() else Vector3(float(index - 1) * 1.5, 1.2, 0.0)
			hotspot.set_meta("room_id", room_id)
			hotspot.set_meta("equipment_id", String(item.get("id", "")))
			var collision := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(1.3, 1.5, 1.3)
			collision.shape = shape
			hotspot.add_child(collision)
			var badge := Label3D.new()
			badge.name = "LevelBadge"
			badge.text = "%s\nLV %d" % [String(item.get("name", "ITEM")).to_upper(), int(item.get("level", 1))]
			badge.position = Vector3(0.0, 1.1, 0.0)
			badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			badge.font_size = 23
			badge.outline_size = 6
			badge.modulate = Color("#BDF8FF") if int(item.get("level", 1)) < int(item.get("cap", 1)) else Color("#FFD66E")
			hotspot.add_child(badge)
			hotspot_root.add_child(hotspot)
	_refresh_hotspot_visibility()

func _refresh_hotspot_visibility() -> void:
	if precinct == null:
		return
	var room_nodes_value: Variant = precinct.get("room_nodes")
	if not room_nodes_value is Dictionary:
		return
	var selected_room: String = String(precinct.get("selected_room_id"))
	for room_value: Variant in (room_nodes_value as Dictionary).keys():
		var room_id: String = String(room_value)
		var room_node: Node3D = (room_nodes_value as Dictionary).get(room_id) as Node3D
		if room_node == null:
			continue
		var hotspot_root: Node3D = room_node.get_node_or_null("EquipmentHotspots") as Node3D
		if hotspot_root != null:
			hotspot_root.visible = room_id == selected_room

func _on_equipment_changed() -> void:
	_refresh_equipment()
	_attach_world_hotspots()
	_refresh_mission_detail()

func _on_precinct_state_changed() -> void:
	call_deferred("_delayed_world_refresh")

func _delayed_world_refresh() -> void:
	for _frame: int in range(3):
		await get_tree().process_frame
	_attach_world_hotspots()
	_refresh_all()
