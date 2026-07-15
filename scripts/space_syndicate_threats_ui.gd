extends Node
## Displays Syndicate Rising commanders as attackable space fleets.

const SITE_POSITIONS: Dictionary = {
	"asteroid_cinder9":Vector3(-31.0,3.0,-18.0), "asteroid_iron_choir":Vector3(-39.0,5.0,2.0), "asteroid_blueglass":Vector3(-33.0,7.0,22.0),
	"moon_selene":Vector3(2.0,2.5,-34.0), "moon_mare_vent":Vector3(20.0,4.0,-38.0), "moon_khepri":Vector3(37.0,6.0,-31.0),
	"wreck_courier":Vector3(31.0,5.0,18.0), "wreck_relay":Vector3(39.0,7.0,2.0), "wreck_carrier":Vector3(31.0,9.0,-15.0)
}

var precinct: Node3D
var layer: CanvasLayer
var panel: PanelContainer
var toggle: Button
var target_list: ItemList
var portrait: TextureRect
var title_label: Label
var detail: Label
var enemy_bar: ProgressBar
var player_shield_bar: ProgressBar
var player_hull_bar: ProgressBar
var battle_log: Label
var engage_button: Button
var cannons_button: Button
var rail_button: Button
var scan_button: Button
var evade_button: Button
var retreat_button: Button
var focus_button: Button
var selected_index: int = 0
var fleet_nodes: Dictionary = {}
var refresh_clock: float = 0.0

func _ready() -> void:
	precinct = get_parent() as Node3D
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(14):
		await get_tree().process_frame
	_build_world_fleets()
	_build_interface()
	if not SpaceThreats.threats_changed.is_connected(_refresh):
		SpaceThreats.threats_changed.connect(_refresh)
	if not SpaceThreats.battle_changed.is_connected(_refresh):
		SpaceThreats.battle_changed.connect(_refresh)
	_refresh()

func _process(delta: float) -> void:
	refresh_clock += delta
	for node_value: Variant in fleet_nodes.values():
		if node_value is Node3D:
			var fleet := node_value as Node3D
			fleet.rotation.y += delta * 0.18
	if refresh_clock < 0.25:
		return
	refresh_clock = 0.0
	SpaceThreats.tick()
	_refresh_world_fleets()
	if panel != null and panel.visible:
		_refresh_detail()

func _input(event: InputEvent) -> void:
	if precinct == null or not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if panel != null and panel.visible and mouse_event.position.x > 120.0 and mouse_event.position.x < 1160.0:
		return
	var camera_value: Variant = precinct.get("camera")
	if not camera_value is Camera3D:
		return
	var camera_3d := camera_value as Camera3D
	var origin: Vector3 = camera_3d.project_ray_origin(mouse_event.position)
	var direction: Vector3 = camera_3d.project_ray_normal(mouse_event.position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 320.0)
	query.collide_with_areas = true
	var hit: Dictionary = precinct.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider") as Object
	if collider == null or not collider.has_meta("space_target_id"):
		return
	_select_target(String(collider.get_meta("space_target_id")))
	panel.visible = true
	_refresh()

func _build_interface() -> void:
	layer = CanvasLayer.new()
	layer.name = "SpaceThreatLayer"
	layer.layer = 29
	precinct.add_child(layer)
	toggle = Button.new()
	toggle.name = "SpaceThreatButton"
	toggle.text = "SPACE THREATS"
	toggle.position = Vector2(704.0,84.0)
	toggle.size = Vector2(160.0,38.0)
	toggle.pressed.connect(_toggle_panel)
	layer.add_child(toggle)
	panel = PanelContainer.new()
	panel.name = "SpaceThreatPanel"
	panel.position = Vector2(118.0,112.0)
	panel.size = Vector2(1044.0,584.0)
	panel.visible = false
	layer.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",14)
	panel.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(390.0,544.0)
	row.add_child(left)
	var header := Label.new()
	header.text = "SYNDICATE SPACE TARGETS"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size",21)
	left.add_child(header)
	target_list = ItemList.new()
	target_list.custom_minimum_size = Vector2(380.0,465.0)
	target_list.item_selected.connect(_on_target_selected)
	left.add_child(target_list)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(620.0,544.0)
	row.add_child(right)
	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation",14)
	right.add_child(identity_row)
	portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(142.0,142.0)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	identity_row.add_child(portrait)
	var identity_column := VBoxContainer.new()
	identity_column.custom_minimum_size = Vector2(450.0,142.0)
	identity_row.add_child(identity_column)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size",20)
	identity_column.add_child(title_label)
	detail = Label.new()
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(450.0,105.0)
	identity_column.add_child(detail)
	enemy_bar = _meter("ENEMY FLEET INTEGRITY")
	right.add_child(enemy_bar)
	player_shield_bar = _meter("AUTHORITY SHIELD")
	right.add_child(player_shield_bar)
	player_hull_bar = _meter("AUTHORITY HULL")
	right.add_child(player_hull_bar)
	battle_log = Label.new()
	battle_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_log.custom_minimum_size = Vector2(610.0,92.0)
	right.add_child(battle_log)
	var action_grid := GridContainer.new()
	action_grid.columns = 3
	action_grid.add_theme_constant_override("h_separation",8)
	action_grid.add_theme_constant_override("v_separation",8)
	right.add_child(action_grid)
	engage_button = _action_button("ENGAGE TARGET", _engage)
	cannons_button = _action_button("FIRE CANNONS", func(): _battle_action("cannons"))
	rail_button = _action_button("RAIL STRIKE", func(): _battle_action("rail_strike"))
	scan_button = _action_button("TACTICAL SCAN", func(): _battle_action("scan"))
	evade_button = _action_button("EVADE", func(): _battle_action("evade"))
	retreat_button = _action_button("RETREAT", func(): _battle_action("retreat"))
	for button: Button in [engage_button,cannons_button,rail_button,scan_button,evade_button,retreat_button]:
		action_grid.add_child(button)
	focus_button = Button.new()
	focus_button.text = "FOCUS CAMERA ON FLEET"
	focus_button.pressed.connect(_focus_target)
	right.add_child(focus_button)
	var close := Button.new()
	close.text = "CLOSE SPACE THREATS"
	close.pressed.connect(_toggle_panel)
	right.add_child(close)

func _meter(label_text: String) -> ProgressBar:
	var meter := ProgressBar.new()
	meter.custom_minimum_size = Vector2(610.0,26.0)
	meter.show_percentage = false
	meter.tooltip_text = label_text
	return meter

func _action_button(text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(194.0,38.0)
	button.pressed.connect(callback)
	return button

func _build_world_fleets() -> void:
	var world: Node3D = precinct.get_node_or_null("LivingPrecinctWorld") as Node3D
	if world == null:
		return
	var previous: Node = world.get_node_or_null("SyndicateSpaceFleets")
	if previous != null:
		previous.queue_free()
	var root := Node3D.new()
	root.name = "SyndicateSpaceFleets"
	world.add_child(root)
	fleet_nodes = {}
	for target: Dictionary in SpaceThreats.target_catalog():
		var target_id: String = String(target.get("id", ""))
		var fleet := Node3D.new()
		fleet.name = "Fleet_%s" % target_id
		var site_position: Vector3 = SITE_POSITIONS.get(String(target.get("site_id", "")), Vector3.ZERO) as Vector3
		fleet.position = site_position + Vector3(4.5,2.4,0.5)
		root.add_child(fleet)
		var area := Area3D.new()
		area.name = "ThreatArea"
		area.set_meta("space_target_id", target_id)
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 3.2
		collision.shape = shape
		area.add_child(collision)
		fleet.add_child(area)
		_build_fleet_geometry(fleet, target)
		var label := Label3D.new()
		label.name = "ThreatLabel"
		label.position = Vector3(0.0,3.5,0.0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 21
		label.outline_size = 7
		fleet.add_child(label)
		fleet_nodes[target_id] = fleet
	_refresh_world_fleets()

func _build_fleet_geometry(root: Node3D, target: Dictionary) -> void:
	var difficulty: int = int(target.get("difficulty",1))
	var ship_count: int = mini(7,2+difficulty)
	var hull_color := Color("#4B1834")
	var glow_color := Color("#FF437E")
	for index: int in range(ship_count):
		var ship := Node3D.new()
		ship.name = "SyndicateShip_%d" % index
		var angle: float = TAU * float(index) / float(ship_count)
		ship.position = Vector3(cos(angle)*2.2,sin(float(index)*1.3)*0.7,sin(angle)*1.6)
		ship.rotation_degrees.y = rad_to_deg(-angle)
		root.add_child(ship)
		var body := MeshInstance3D.new()
		var body_mesh := BoxMesh.new()
		body_mesh.size = Vector3(1.45+float(difficulty)*0.12,0.42,0.7)
		body.mesh = body_mesh
		body.material_override = _material(hull_color,0.0)
		ship.add_child(body)
		for wing_side: float in [-1.0,1.0]:
			var wing := MeshInstance3D.new()
			var wing_mesh := BoxMesh.new()
			wing_mesh.size = Vector3(0.65,0.12,0.9)
			wing.mesh = wing_mesh
			wing.position = Vector3(0.0,0.0,wing_side*0.65)
			wing.material_override = _material(Color("#72214A"),0.0)
			ship.add_child(wing)
		var engine := MeshInstance3D.new()
		var engine_mesh := SphereMesh.new()
		engine_mesh.radius = 0.16
		engine_mesh.height = 0.32
		engine.mesh = engine_mesh
		engine.position = Vector3(-0.82,0.0,0.0)
		engine.material_override = _material(glow_color,2.4)
		ship.add_child(engine)

func _refresh() -> void:
	if target_list == null:
		return
	var catalog: Array[Dictionary] = SpaceThreats.target_catalog()
	target_list.clear()
	for target: Dictionary in catalog:
		var state_text: String = "ACTIVE"
		if bool(target.get("locked",false)):
			state_text = "LOCKED STATION L%d" % int(target.get("unlock_level",1))
		elif bool(target.get("defeated",false)):
			state_text = "DRIVEN OFF %ds" % int(target.get("respawn_left",0))
		target_list.add_item("L%d • %s • %s\n%s — %s" % [int(target.get("level",1)),String(target.get("difficulty_name","EASY")),state_text,String(target.get("commander","Syndicate")),String(target.get("title","Fleet"))])
	if not catalog.is_empty():
		selected_index = clampi(selected_index,0,catalog.size()-1)
		target_list.select(selected_index)
	_refresh_detail()
	_refresh_world_fleets()

func _refresh_detail() -> void:
	if detail == null:
		return
	var catalog: Array[Dictionary] = SpaceThreats.target_catalog()
	if catalog.is_empty():
		return
	selected_index = clampi(selected_index,0,catalog.size()-1)
	var target: Dictionary = catalog[selected_index]
	title_label.text = "%s\nLEVEL %d • %s" % [String(target.get("commander","SYNDICATE")).to_upper(),int(target.get("level",1)),String(target.get("difficulty_name","EASY"))]
	var portrait_path: String = String(target.get("portrait",""))
	portrait.texture = load(portrait_path) as Texture2D if ResourceLoader.exists(portrait_path) else null
	detail.text = "%s\nROLE: %s\nFLEET: %s\nRESOURCE LANE: %s\nPOWER %d • DEFENSE %d\nREWARDS: %d CREDITS, %d INTEL, %d %s" % [String(target.get("title","Syndicate Fleet")),String(target.get("class","Criminal")),String(target.get("ship","Raider Ships")),String(target.get("site_id","Unknown")).replace("_"," ").capitalize(),int(target.get("power",10)),int(target.get("defense",4)),int(target.get("credits",80)),int(target.get("intel",2)),int(target.get("resource_reward",10)),String(target.get("resource","resource")).replace("_"," ").capitalize()]
	var active: Dictionary = SpaceThreats.active_battle
	var active_for_target: bool = not active.is_empty() and String(active.get("target_id","")) == String(target.get("id",""))
	if active_for_target:
		enemy_bar.max_value = int(active.get("enemy_max_hp",100))
		enemy_bar.value = int(active.get("enemy_hp",0))
		player_shield_bar.max_value = int(active.get("player_max_shield",100))
		player_shield_bar.value = int(active.get("player_shield",0))
		player_hull_bar.max_value = int(active.get("player_max_hull",100))
		player_hull_bar.value = int(active.get("player_hull",0))
		battle_log.text = "TURN %d\n%s" % [int(active.get("turn",1)),String(active.get("log","Engagement active."))]
	else:
		enemy_bar.max_value = int(target.get("max_hp",100))
		enemy_bar.value = 0 if bool(target.get("defeated",false)) else int(target.get("max_hp",100))
		player_shield_bar.max_value = 100
		player_shield_bar.value = 0
		player_hull_bar.max_value = 100
		player_hull_bar.value = 0
		battle_log.text = "Select ENGAGE TARGET to deploy Authority interceptors."
	engage_button.visible = SpaceThreats.active_battle.is_empty()
	engage_button.disabled = bool(target.get("locked",false)) or bool(target.get("defeated",false))
	for button: Button in [cannons_button,rail_button,scan_button,evade_button,retreat_button]:
		button.visible = active_for_target

func _refresh_world_fleets() -> void:
	for target: Dictionary in SpaceThreats.target_catalog():
		var target_id: String = String(target.get("id",""))
		var fleet: Node3D = fleet_nodes.get(target_id) as Node3D
		if fleet == null:
			continue
		fleet.visible = not bool(target.get("defeated",false)) and not bool(target.get("locked",false))
		var label: Label3D = fleet.get_node_or_null("ThreatLabel") as Label3D
		if label != null:
			label.text = "%s\nLV %d • %s" % [String(target.get("commander","SYNDICATE")).to_upper(),int(target.get("level",1)),String(target.get("difficulty_name","EASY"))]
			label.modulate = Color("#FF5B8D")

func _toggle_panel() -> void:
	panel.visible = not panel.visible
	MoonGoonsAudio.play("click")
	if panel.visible:
		_refresh()

func _on_target_selected(index: int) -> void:
	selected_index = index
	MoonGoonsAudio.play("click")
	_refresh_detail()

func _select_target(target_id: String) -> void:
	var catalog: Array[Dictionary] = SpaceThreats.target_catalog()
	for index: int in range(catalog.size()):
		if String(catalog[index].get("id","")) == target_id:
			selected_index = index
			return

func _engage() -> void:
	var catalog: Array[Dictionary] = SpaceThreats.target_catalog()
	if catalog.is_empty():
		return
	var result: Dictionary = SpaceThreats.begin_battle(String(catalog[selected_index].get("id","")))
	_set_status(String(result.get("message","Engagement action complete.")))
	MoonGoonsAudio.play("dispatch" if bool(result.get("ok",false)) else "error")
	_refresh()

func _battle_action(action: String) -> void:
	var result: Dictionary = SpaceThreats.battle_action(action)
	_set_status(String(result.get("message","Space combat action complete.")))
	MoonGoonsAudio.play("impact" if action in ["cannons","rail_strike"] else "click")
	_refresh()

func _focus_target() -> void:
	var catalog: Array[Dictionary] = SpaceThreats.target_catalog()
	if catalog.is_empty():
		return
	var site_position: Vector3 = SITE_POSITIONS.get(String(catalog[selected_index].get("site_id","")),Vector3.ZERO) as Vector3
	precinct.set("camera_target",site_position+Vector3(4.5,1.0,0.5))
	precinct.set("camera_distance",17.0)
	panel.visible = false

func _set_status(text: String) -> void:
	var status_value: Variant = precinct.get("status_label")
	if status_value is Label:
		(status_value as Label).text = text

func _material(color: Color, emission: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.62
	material.roughness = 0.34
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material
