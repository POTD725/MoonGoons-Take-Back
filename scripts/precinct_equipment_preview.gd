extends Node
## Live 3D preview inside the non-blocking Equipment side tray.
## Keeps models visible in browser builds even while the illustrated city is active.

var precinct: Node
var progression_ui: Node
var styles: Node
var container: SubViewportContainer
var viewport: SubViewport
var model_root: Node3D
var caption: Label
var current_model: Node3D
var selection_key: String = ""
var refresh_clock: float = 0.0

func _ready() -> void:
	precinct = get_parent()
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(28):
		await get_tree().process_frame
	if precinct == null:
		return
	progression_ui = precinct.get_node_or_null("PrecinctProgressionUI")
	styles = precinct.get_node_or_null("EquipmentStyleState")
	_build_preview()
	if styles != null and not styles.style_changed.is_connected(_on_style_changed):
		styles.style_changed.connect(_on_style_changed)
	if not PrecinctEquipment.equipment_changed.is_connected(_refresh_model):
		PrecinctEquipment.equipment_changed.connect(_refresh_model)
	_refresh_model()

func _process(delta: float) -> void:
	if current_model != null:
		current_model.rotation.y += delta * 0.42
	refresh_clock += delta
	if refresh_clock < 0.18:
		return
	refresh_clock = 0.0
	var key: String = _current_key()
	if key != selection_key:
		selection_key = key
		_refresh_model()

func _build_preview() -> void:
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
	caption = Label.new()
	caption.name = "EquipmentPreviewCaption"
	caption.text = "LIVE 3D EQUIPMENT PREVIEW"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 10)
	caption.modulate = Color("9DEFFF")
	column.add_child(caption)
	container = SubViewportContainer.new()
	container.name = "Equipment3DPreview"
	container.custom_minimum_size = Vector2(350.0, 154.0)
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(container)
	var detail_value: Variant = progression_ui.get("equipment_detail")
	if detail_value is Control:
		column.move_child(caption, (detail_value as Control).get_index() + 1)
		column.move_child(container, caption.get_index() + 1)
	viewport = SubViewport.new()
	viewport.name = "EquipmentPreviewViewport"
	viewport.size = Vector2i(700, 308)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	container.add_child(viewport)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#040A10")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#9ACEE8")
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	viewport.add_child(environment_node)
	model_root = Node3D.new()
	model_root.name = "PreviewWorld"
	viewport.add_child(model_root)
	var floor := MeshInstance3D.new()
	var floor_mesh := CylinderMesh.new()
	floor_mesh.top_radius = 1.85
	floor_mesh.bottom_radius = 1.95
	floor_mesh.height = 0.14
	floor.mesh = floor_mesh
	floor.position = Vector3(0.0, -0.14, 0.0)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("#142B38")
	floor_material.metallic = 0.35
	floor_material.roughness = 0.52
	floor.material_override = floor_material
	model_root.add_child(floor)
	for radius: float in [1.35, 1.70]:
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = radius - 0.035
		ring_mesh.outer_radius = radius
		ring.mesh = ring_mesh
		ring.position.y = -0.055
		var ring_material := StandardMaterial3D.new()
		ring_material.albedo_color = Color("#54DFF5")
		ring_material.emission_enabled = true
		ring_material.emission = Color("#54DFF5")
		ring_material.emission_energy_multiplier = 0.55
		ring.material_override = ring_material
		model_root.add_child(ring)
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 2.25, 5.4)
	camera.fov = 42.0
	camera.look_at(Vector3(0.0, 0.92, 0.0), Vector3.UP)
	camera.current = true
	viewport.add_child(camera)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-45.0, -35.0, 0.0)
	key_light.light_energy = 1.65
	key_light.light_color = Color("#D8F2FF")
	viewport.add_child(key_light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-2.4, 2.0, 2.8)
	fill.light_color = Color("#52D9FF")
	fill.light_energy = 4.0
	fill.omni_range = 8.0
	viewport.add_child(fill)

func _refresh_model() -> void:
	if model_root == null or progression_ui == null or styles == null:
		return
	if current_model != null:
		current_model.queue_free()
		current_model = null
	var room_id: String = String(precinct.get("selected_room_id"))
	var items: Array[Dictionary] = PrecinctEquipment.room_items(room_id)
	if items.is_empty():
		if caption != null:
			caption.text = "NO EQUIPMENT SELECTED"
		return
	var selected: int = clampi(int(progression_ui.get("selected_item_index")), 0, items.size() - 1)
	var item: Dictionary = items[selected]
	var item_id: String = String(item.get("id", ""))
	var variant: int = int(styles.call("item_variant", room_id, item_id))
	current_model = PrecinctEquipmentVisualFactory.build(item_id, int(item.get("level", 1)), variant)
	current_model.position = Vector3(0.0, 0.0, 0.0)
	current_model.scale *= 1.18
	model_root.add_child(current_model)
	if caption != null:
		caption.text = "%s  //  %s  //  LEVEL %d" % [String(item.get("name", "ITEM")).to_upper(), String(styles.call("variant_name", variant)), int(item.get("level", 1))]

func _on_style_changed(_room_id: String, _item_id: String, _variant: int) -> void:
	_refresh_model()

func _current_key() -> String:
	if progression_ui == null or styles == null:
		return ""
	var room_id: String = String(precinct.get("selected_room_id"))
	var items: Array[Dictionary] = PrecinctEquipment.room_items(room_id)
	if items.is_empty():
		return room_id
	var selected: int = clampi(int(progression_ui.get("selected_item_index")), 0, items.size() - 1)
	var item: Dictionary = items[selected]
	var item_id: String = String(item.get("id", ""))
	return "%s:%s:%d:%d" % [room_id, item_id, int(item.get("level", 1)), int(styles.call("item_variant", room_id, item_id))]
