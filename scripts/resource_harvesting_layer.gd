extends Node
## Builds visible resource sites around the station and a clickable harvesting interface.

const SITE_POSITIONS: Dictionary = {
	"asteroid_cinder9":Vector3(-31.0,3.0,-18.0), "asteroid_iron_choir":Vector3(-39.0,5.0,2.0), "asteroid_blueglass":Vector3(-33.0,7.0,22.0),
	"moon_selene":Vector3(2.0,2.5,-34.0), "moon_mare_vent":Vector3(20.0,4.0,-38.0), "moon_khepri":Vector3(37.0,6.0,-31.0),
	"wreck_courier":Vector3(31.0,5.0,18.0), "wreck_relay":Vector3(39.0,7.0,2.0), "wreck_carrier":Vector3(31.0,9.0,-15.0)
}

var precinct: Node3D
var layer: CanvasLayer
var panel: PanelContainer
var toggle: Button
var balances: Label
var slots_label: Label
var site_list: ItemList
var detail: Label
var progress: ProgressBar
var dispatch_button: Button
var upgrade_button: Button
var focus_button: Button
var selected_index: int = 0
var refresh_clock: float = 0.0
var site_nodes: Dictionary = {}

func _ready() -> void:
	precinct = get_parent() as Node3D
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(12):
		await get_tree().process_frame
	_build_world_sites()
	_build_interface()
	if not ResourceHarvest.resources_changed.is_connected(_refresh):
		ResourceHarvest.resources_changed.connect(_refresh)
	if not ResourceHarvest.site_changed.is_connected(_on_site_changed):
		ResourceHarvest.site_changed.connect(_on_site_changed)
	_refresh()

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock < 0.25:
		return
	refresh_clock = 0.0
	ResourceHarvest.tick()
	if panel != null and panel.visible:
		_refresh_detail()
	_refresh_world_labels()

func _input(event: InputEvent) -> void:
	if precinct == null or not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if panel != null and panel.visible and mouse_event.position.x > 150.0 and mouse_event.position.x < 1130.0:
		return
	var camera_value: Variant = precinct.get("camera")
	if not camera_value is Camera3D:
		return
	var camera_3d := camera_value as Camera3D
	var origin: Vector3 = camera_3d.project_ray_origin(mouse_event.position)
	var direction: Vector3 = camera_3d.project_ray_normal(mouse_event.position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 300.0)
	query.collide_with_areas = true
	var hit: Dictionary = precinct.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.get("collider") as Object
	if collider == null or not collider.has_meta("harvest_site_id"):
		return
	_select_site(String(collider.get_meta("harvest_site_id")))
	panel.visible = true
	_refresh()

func _build_interface() -> void:
	layer = CanvasLayer.new()
	layer.name = "ResourceHarvestLayer"
	layer.layer = 28
	precinct.add_child(layer)
	toggle = Button.new()
	toggle.name = "ResourceMapButton"
	toggle.text = "RESOURCE MAP"
	toggle.position = Vector2(536.0,84.0)
	toggle.size = Vector2(160.0,38.0)
	toggle.pressed.connect(_toggle_panel)
	layer.add_child(toggle)
	panel = PanelContainer.new()
	panel.name = "ResourceMapPanel"
	panel.position = Vector2(150.0,118.0)
	panel.size = Vector2(980.0,560.0)
	panel.visible = false
	layer.add_child(panel)
	var root_row := HBoxContainer.new()
	root_row.add_theme_constant_override("separation",16)
	panel.add_child(root_row)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(430.0,520.0)
	root_row.add_child(left)
	var title := Label.new()
	title.text = "LUNAR RESOURCE OPERATIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",22)
	left.add_child(title)
	balances = Label.new()
	balances.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(balances)
	slots_label = Label.new()
	slots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(slots_label)
	site_list = ItemList.new()
	site_list.custom_minimum_size = Vector2(420.0,405.0)
	site_list.item_selected.connect(_on_site_selected)
	left.add_child(site_list)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(500.0,520.0)
	root_row.add_child(right)
	detail = Label.new()
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(490.0,290.0)
	detail.add_theme_font_size_override("font_size",16)
	right.add_child(detail)
	progress = ProgressBar.new()
	progress.custom_minimum_size = Vector2(490.0,28.0)
	progress.show_percentage = false
	right.add_child(progress)
	dispatch_button = Button.new()
	dispatch_button.text = "DISPATCH HARVESTER"
	dispatch_button.custom_minimum_size = Vector2(490.0,44.0)
	dispatch_button.pressed.connect(_dispatch)
	right.add_child(dispatch_button)
	upgrade_button = Button.new()
	upgrade_button.text = "UPGRADE EXTRACTION SITE"
	upgrade_button.custom_minimum_size = Vector2(490.0,44.0)
	upgrade_button.pressed.connect(_upgrade_site)
	right.add_child(upgrade_button)
	focus_button = Button.new()
	focus_button.text = "FOCUS CAMERA ON SITE"
	focus_button.pressed.connect(_focus_site)
	right.add_child(focus_button)
	var close := Button.new()
	close.text = "CLOSE RESOURCE MAP"
	close.pressed.connect(_toggle_panel)
	right.add_child(close)

func _build_world_sites() -> void:
	var world: Node3D = precinct.get_node_or_null("LivingPrecinctWorld") as Node3D
	if world == null:
		return
	var previous: Node = world.get_node_or_null("ResourceHarvestSites")
	if previous != null:
		previous.queue_free()
	var root := Node3D.new()
	root.name = "ResourceHarvestSites"
	world.add_child(root)
	for site: Dictionary in ResourceHarvest.site_catalog():
		var site_id: String = String(site.get("id", ""))
		var node := Node3D.new()
		node.name = "Harvest_%s" % site_id
		node.position = SITE_POSITIONS.get(site_id, Vector3.ZERO) as Vector3
		root.add_child(node)
		var area := Area3D.new()
		area.name = "HarvestArea"
		area.set_meta("harvest_site_id", site_id)
		var collision := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 3.4
		collision.shape = shape
		area.add_child(collision)
		node.add_child(area)
		_build_site_geometry(node, site)
		var label := Label3D.new()
		label.name = "SiteLabel"
		label.position = Vector3(0.0,4.3,0.0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 24
		label.outline_size = 7
		node.add_child(label)
		site_nodes[site_id] = node
	_refresh_world_labels()

func _build_site_geometry(root: Node3D, site: Dictionary) -> void:
	var kind: String = String(site.get("kind", "asteroid"))
	var color: Color = ResourceHarvest.resource_color(String(site.get("resource", "moonsteel")))
	if kind == "asteroid":
		for index: int in range(5):
			var rock := MeshInstance3D.new()
			var mesh := SphereMesh.new()
			mesh.radius = 1.1 + float(index % 3) * 0.35
			mesh.height = mesh.radius * 2.0
			rock.mesh = mesh
			rock.scale = Vector3(1.3,0.8,1.0)
			rock.position = Vector3(float(index - 2) * 1.25, sin(float(index)) * 0.8, cos(float(index)) * 1.3)
			rock.material_override = _material(Color("#4C4544"),0.0)
			root.add_child(rock)
	elif kind == "moon":
		var moon := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 3.0
		sphere.height = 6.0
		moon.mesh = sphere
		moon.scale = Vector3(1.0,0.55,1.0)
		moon.material_override = _material(Color("#6C7380"),0.0)
		root.add_child(moon)
		for drill_x: float in [-1.2,0.0,1.2]:
			var drill := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.18
			cylinder.bottom_radius = 0.28
			cylinder.height = 2.2
			drill.mesh = cylinder
			drill.position = Vector3(drill_x,1.2,0.0)
			drill.material_override = _material(color,0.25)
			root.add_child(drill)
	else:
		for index: int in range(6):
			var wreck := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(1.2 + float(index % 2),0.45,0.7 + float((index + 1) % 3) * 0.4)
			wreck.mesh = box
			wreck.position = Vector3(float(index - 3) * 0.9, sin(float(index) * 1.7), cos(float(index)) * 1.4)
			wreck.rotation = Vector3(float(index) * 0.3,float(index) * 0.5,float(index) * 0.2)
			wreck.material_override = _material(Color("#394956"),0.0)
			root.add_child(wreck)
	var beacon := MeshInstance3D.new()
	var beacon_mesh := SphereMesh.new()
	beacon_mesh.radius = 0.42
	beacon_mesh.height = 0.84
	beacon.mesh = beacon_mesh
	beacon.position = Vector3(0.0,2.8,0.0)
	beacon.material_override = _material(color,2.3)
	root.add_child(beacon)

func _refresh() -> void:
	if site_list == null:
		return
	balances.text = "MOONSTEEL %d     HELIUM-3 %d     QUANTUM SALVAGE %d" % [ResourceHarvest.resource_amount("moonsteel"),ResourceHarvest.resource_amount("helium3"),ResourceHarvest.resource_amount("quantum_salvage")]
	slots_label.text = "HARVEST CREWS %d / %d DEPLOYED" % [ResourceHarvest.active_harvest_count(),ResourceHarvest.harvest_slots()]
	var catalog: Array[Dictionary] = ResourceHarvest.site_catalog()
	site_list.clear()
	for site: Dictionary in catalog:
		var state_text: String = "READY"
		if bool(site.get("locked",false)):
			state_text = "LOCKED L%d" % int(site.get("unlock_level",1))
		elif int(site.get("time_left",0)) > 0:
			state_text = "HARVESTING %ds" % int(site.get("time_left",0))
		elif int(site.get("recovery_left",0)) > 0:
			state_text = "RECOVERING %ds" % int(site.get("recovery_left",0))
		site_list.add_item("[%s] %s  •  %s  •  %s" % [String((ResourceHarvest.RESOURCE_DEFS[String(site.get("resource","moonsteel"))] as Dictionary).get("short","RES")),String(site.get("name","Site")),String(site.get("location","Space")),state_text])
	if not catalog.is_empty():
		selected_index = clampi(selected_index,0,catalog.size()-1)
		site_list.select(selected_index)
	_refresh_detail()

func _refresh_detail() -> void:
	if detail == null:
		return
	var catalog: Array[Dictionary] = ResourceHarvest.site_catalog()
	if catalog.is_empty():
		return
	selected_index = clampi(selected_index,0,catalog.size()-1)
	var site: Dictionary = catalog[selected_index]
	var resource_id: String = String(site.get("resource","moonsteel"))
	var state_text: String = "READY FOR DEPLOYMENT"
	if bool(site.get("locked",false)):
		state_text = "LOCKED UNTIL STATION LEVEL %d" % int(site.get("unlock_level",1))
	elif int(site.get("time_left",0)) > 0:
		state_text = "HARVEST IN PROGRESS • %d SECONDS REMAIN" % int(site.get("time_left",0))
	elif int(site.get("recovery_left",0)) > 0:
		state_text = "FIELD DEPLETED • RECOVERY %d SECONDS" % int(site.get("recovery_left",0))
	detail.text = "%s\n%s • %s\n\nRESOURCE: %s\nEXTRACTION LEVEL: %d\nPROJECTED YIELD: %d\nRESERVE: %d / %d\nRISK TIER: %d\nHARVEST TIME: %d SECONDS\n\n%s\n\nUSE: %s" % [String(site.get("name","SITE")).to_upper(),String(site.get("location","SPACE")),String(site.get("kind","site")).to_upper(),ResourceHarvest.resource_name(resource_id),int(site.get("level",1)),int(site.get("yield",0)),int(site.get("reserve",0)),int(site.get("max_reserve",0)),int(site.get("risk",1)),ResourceHarvest.harvest_duration(site),state_text,String((ResourceHarvest.RESOURCE_DEFS[resource_id] as Dictionary).get("use","Station operations"))]
	var duration: int = ResourceHarvest.harvest_duration(site)
	var left: int = int(site.get("time_left",0))
	progress.max_value = max(1,duration)
	progress.value = duration-left if left > 0 else 0
	dispatch_button.disabled = bool(site.get("locked",false)) or left > 0 or int(site.get("recovery_left",0)) > 0 or ResourceHarvest.active_harvest_count() >= ResourceHarvest.harvest_slots()
	upgrade_button.disabled = int(site.get("level",1)) >= int(get_node("/root/StationProgression").get("station_level"))

func _refresh_world_labels() -> void:
	for site: Dictionary in ResourceHarvest.site_catalog():
		var site_id: String = String(site.get("id",""))
		var node: Node3D = site_nodes.get(site_id) as Node3D
		if node == null:
			continue
		var label: Label3D = node.get_node_or_null("SiteLabel") as Label3D
		if label == null:
			continue
		var status: String = "READY"
		if bool(site.get("locked",false)):
			status = "LOCKED L%d" % int(site.get("unlock_level",1))
		elif int(site.get("time_left",0)) > 0:
			status = "%ds" % int(site.get("time_left",0))
		elif int(site.get("recovery_left",0)) > 0:
			status = "DEPLETED"
		label.text = "%s\n%s • %s" % [String(site.get("name","SITE")).to_upper(),ResourceHarvest.resource_name(String(site.get("resource","moonsteel"))),status]
		label.modulate = ResourceHarvest.resource_color(String(site.get("resource","moonsteel")))

func _toggle_panel() -> void:
	panel.visible = not panel.visible
	MoonGoonsAudio.play("click")
	if panel.visible:
		_refresh()

func _on_site_selected(index: int) -> void:
	selected_index = index
	MoonGoonsAudio.play("click")
	_refresh_detail()

func _select_site(site_id: String) -> void:
	var catalog: Array[Dictionary] = ResourceHarvest.site_catalog()
	for index: int in range(catalog.size()):
		if String(catalog[index].get("id","")) == site_id:
			selected_index = index
			return

func _dispatch() -> void:
	var catalog: Array[Dictionary] = ResourceHarvest.site_catalog()
	if catalog.is_empty():
		return
	var result: Dictionary = ResourceHarvest.begin_harvest(String(catalog[selected_index].get("id","")))
	_set_status(String(result.get("message","Harvest action complete.")))
	MoonGoonsAudio.play("dispatch" if bool(result.get("ok",false)) else "error")
	_refresh()

func _upgrade_site() -> void:
	var catalog: Array[Dictionary] = ResourceHarvest.site_catalog()
	if catalog.is_empty():
		return
	var result: Dictionary = ResourceHarvest.upgrade_site(String(catalog[selected_index].get("id","")))
	_set_status(String(result.get("message","Site upgrade complete.")))
	MoonGoonsAudio.play("upgrade" if bool(result.get("ok",false)) else "error")
	_refresh()

func _focus_site() -> void:
	var catalog: Array[Dictionary] = ResourceHarvest.site_catalog()
	if catalog.is_empty():
		return
	var site_id: String = String(catalog[selected_index].get("id",""))
	precinct.set("camera_target",SITE_POSITIONS.get(site_id,Vector3.ZERO))
	precinct.set("camera_distance",19.0)
	panel.visible = false

func _on_site_changed(_site_id: String) -> void:
	_refresh()

func _set_status(text: String) -> void:
	var value: Variant = precinct.get("status_label")
	if value is Label:
		(value as Label).text = text

func _material(color: Color, emission: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.35
	material.roughness = 0.62
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material
