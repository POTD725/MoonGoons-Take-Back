extends Node
## Applies picture icons and station-console hover cards to every interactive item.
## Buttons created later by missions, research, stores, threats, or upgrades are
## decorated automatically through SceneTree.node_added.

var precinct: Node
var tooltip_layer: CanvasLayer
var tooltip_panel: PanelContainer
var tooltip_icon: TextureRect
var tooltip_title: Label
var tooltip_description: Label
var tooltip_facts: Label
var refresh_clock: float = 0.0
var list_signatures: Dictionary = {}
var current_hover_key: String = ""

const EQUIPMENT_DESCRIPTIONS: Dictionary = {
	"command_table":"Projects patrol routes, active calls, officer positions, and command priorities above the Operations deck.",
	"dispatch_console":"Coordinates distress calls and shortens the time between an alert, officer assignment, and launch clearance.",
	"holo_map":"Builds a live three-dimensional map of lunar districts, orbital lanes, criminal activity, and mission routes.",
	"weapon_racks":"Stores calibrated Peacekeeper weapons and improves the attack readiness of officers posted to the Armory.",
	"armor_forge":"Fabricates and repairs pressure-rated armor plates, helmets, seals, and defensive field components.",
	"ammo_loader":"Loads patrol craft and response teams with ammunition, power cells, and mission-specific equipment.",
	"cell_locks":"Controls reinforced detention doors, emergency lockdowns, prisoner capacity, and escape resistance.",
	"security_scanner":"Searches detainees and cargo for contraband, hidden weapons, trackers, and Syndicate devices.",
	"intake_terminal":"Processes arrests, identity records, evidence links, charges, and secure prisoner assignments.",
	"bunks":"Provides pressure-safe crew rest quarters that improve recovery between patrols and station emergencies.",
	"mess_station":"Produces crew meals and hydration packs, improving stamina during long duty rotations.",
	"morale_console":"Tracks fatigue, commendations, team cohesion, and training efficiency across the station crew.",
	"med_pods":"Stabilizes injured officers and civilians inside automated recovery capsules with life-support monitoring.",
	"diagnostic_scanner":"Detects internal injuries, toxins, radiation exposure, alien pathogens, and suit-seal failures.",
	"trauma_console":"Coordinates critical treatment, surgical tools, emergency medication, and medical side operations.",
	"command_desk":"Sets the maximum level for station rooms and equipment while coordinating precinct-wide authority.",
	"strategy_wall":"Combines mission intelligence, fleet movements, evidence, and district control into command plans.",
	"authority_uplink":"Maintains encrypted contact with regional Peacekeeper command and expands station command range.",
	"truth_scanner":"Compares stress, voice, bio-signals, evidence, and testimony during interrogation operations.",
	"evidence_console":"Catalogs recovered evidence and links suspects, locations, ships, crimes, and Syndicate networks.",
	"restraint_table":"Secures dangerous suspects while preserving monitored, controlled interrogation conditions.",
	"airlock_gate":"Seals prisoner-transfer corridors and prevents decompression, escape, or hostile boarding.",
	"prisoner_scanner":"Performs final identity, health, contraband, and tracking checks before secure transport.",
	"transport_console":"Schedules prisoner shuttles, escort teams, docking windows, routes, and transfer rewards."
}

const GENERIC_DESCRIPTIONS: Dictionary = {
	"station_deck":"Return to the orbital station deck. Inspect connected modules, corridors, crew activity, damage, and current room levels.",
	"missions":"Review chapter, daily, patrol, investigation, defense, harvesting, and Side Ops objectives with their rewards and progress.",
	"dispatch":"Select an active incident, assign one or more available officers, compare team strength, and launch the response shuttle.",
	"officers":"Inspect Peacekeeper personnel, health, level, assignment, training status, recovery, and combat readiness.",
	"equipment":"Inspect every upgradeable room system, its picture, level, effect, visual style, cost, prerequisite, and timer.",
	"resources":"Manage Moonsteel, Helium-3, and Quantum Salvage extraction sites, crews, reserves, upgrades, and occupied lanes.",
	"threats":"Track Syndicate fleets and marauder attacks. Scan targets, compare power, engage, retreat, and collect combat rewards.",
	"side_ops":"Open interactive engine repair, weapons fitting, medical treatment, and interrogation operations.",
	"research":"Browse Alliance Construction, Technology, and Weapons research from level 1 through level 100.",
	"repair":"Restore a damaged room, station system, defense module, or mission component to operational condition.",
	"upgrade":"Raise the selected system by one level after checking command caps, resource costs, prerequisites, and construction time.",
	"train":"Improve an officer or troop unit, increasing performance while respecting the current training and command limits.",
	"heal":"Treat injuries through the Medbay and return personnel to operational health.",
	"assign":"Post the selected officer, crew, or unit to the chosen room, mission, defense position, or resource site.",
	"moonsteel":"Dense lunar alloy used for station construction, armor, hull reinforcement, turrets, and heavy equipment.",
	"helium":"High-energy Helium-3 fuel used by reactors, shields, research systems, engines, and advanced weapons.",
	"salvage":"Recovered quantum components used for experimental technology, sensors, robotics, and high-level upgrades.",
	"turret":"Automated point-defense hardware that attacks boarding craft, missiles, drones, and marauder ships.",
	"shield":"Station shield hardware that absorbs incoming damage before the orbital hull is struck.",
	"rail":"Long-range kinetic station weapon used against armored hostile ships and command carriers.",
	"interceptor":"Launches Peacekeeper interceptors to screen the station and engage hostile craft before they reach the hull.",
	"interrogation":"Run evidence-based questioning while balancing guilt, stress, cooperation, and confession reliability.",
	"weapons":"Configure capacitors, cooling, targeting, ammunition feeds, stability, and emitter alignment.",
	"cutaway":"Open the selected station module as a room cutaway and reveal its interior equipment hotspots.",
	"map":"Switch to the tactical deck map for station layout, mission lanes, and operational positioning.",
	"zoom_in":"Move the command camera closer to the station deck.",
	"zoom_out":"Move the command camera farther from the station deck.",
	"previous":"Move to the previous item, officer, room, visual style, or camera angle.",
	"next":"Move to the next item, officer, room, visual style, or camera angle.",
	"close":"Close this station console without changing the current selection."
}

func _ready() -> void:
	precinct = get_parent()
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(32):
		await get_tree().process_frame
	_build_tooltip_panel()
	_decorate_tree(precinct)
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock >= 0.35:
		refresh_clock = 0.0
		_decorate_tree(precinct)
	_update_hover_card()

func _on_node_added(node: Node) -> void:
	call_deferred("_decorate_tree", node)

func _decorate_tree(root: Node) -> void:
	if root == null:
		return
	if root is Button:
		_decorate_button(root as Button)
	elif root is ItemList:
		_decorate_item_list(root as ItemList)
	elif root is OptionButton:
		_decorate_option_button(root as OptionButton)
	for child: Node in root.get_children():
		_decorate_tree(child)

func _decorate_button(button: Button) -> void:
	if button == null or button.text.strip_edges().is_empty():
		return
	var signature: String = button.text + "|" + button.name
	if String(button.get_meta("icon_hover_signature", "")) == signature:
		return
	var original_tooltip: String = button.tooltip_text.strip_edges()
	var title: String = button.text.get_slice("\n", 0).strip_edges()
	var key: String = GameIconRegistry.semantic_key(String(button.get_meta("icon_key", button.name + " " + title)))
	var description: String = original_tooltip if not original_tooltip.is_empty() else _description_for_key(key, title)
	var facts: String = _button_facts(button.text)
	button.icon = GameIconRegistry.icon_for(key, 28, _accent_for_key(key))
	button.icon_max_width = 28
	button.expand_icon = false
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.tooltip_text = ""
	button.set_meta("icon_key", key)
	button.set_meta("hover_title", title)
	button.set_meta("hover_description", description)
	button.set_meta("hover_facts", facts)
	button.set_meta("icon_hover_signature", signature)

func _decorate_option_button(option: OptionButton) -> void:
	for index: int in range(option.item_count):
		var text: String = option.get_item_text(index)
		var key: String = GameIconRegistry.semantic_key(text)
		option.set_item_icon(index, GameIconRegistry.icon_for(key, 24, _accent_for_key(key)))
	if option.selected >= 0 and option.selected < option.item_count:
		var selected_text: String = option.get_item_text(option.selected)
		var selected_key: String = GameIconRegistry.semantic_key(selected_text)
		option.icon = GameIconRegistry.icon_for(selected_key, 26, _accent_for_key(selected_key))
		option.set_meta("hover_title", selected_text)
		option.set_meta("hover_description", _description_for_key(selected_key, selected_text))
		option.set_meta("hover_facts", "SELECT A STATION OPTION")

func _decorate_item_list(list: ItemList) -> void:
	var signature: String = _item_list_signature(list)
	if String(list_signatures.get(list.get_instance_id(), "")) == signature:
		return
	list_signatures[list.get_instance_id()] = signature
	var equipment_ui: Node = precinct.get_node_or_null("PrecinctProgressionUI")
	var equipment_list_value: Variant = equipment_ui.get("equipment_list") if equipment_ui != null else null
	var task_list_value: Variant = precinct.get("task_list")
	if list == equipment_list_value:
		_decorate_equipment_list(list)
	elif list == task_list_value:
		_decorate_mission_list(list)
	else:
		_decorate_generic_list(list)

func _decorate_equipment_list(list: ItemList) -> void:
	var room_id: String = String(precinct.get("selected_room_id"))
	var items: Array[Dictionary] = PrecinctEquipment.room_items(room_id)
	for index: int in range(list.item_count):
		var item: Dictionary = items[index] if index < items.size() else {}
		var item_id: String = String(item.get("icon", item.get("id", list.get_item_text(index))))
		var key: String = GameIconRegistry.semantic_key(item_id)
		var description: String = String(item.get("description", EQUIPMENT_DESCRIPTIONS.get(key, _description_for_key(key, list.get_item_text(index)))))
		var facts: String = "LEVEL %d / %d\nEFFECT: %s\nNEXT COST: %d CREDITS" % [int(item.get("level", 1)), int(item.get("cap", 1)), String(item.get("effect", "Station capability")), int(item.get("upgrade_cost", 0))]
		list.set_item_icon(index, GameIconRegistry.icon_for(key, 34, _accent_for_key(key)))
		list.set_item_tooltip(index, "%s\n\n%s" % [description, facts])
		list.set_item_tooltip_enabled(index, true)
		list.set_item_metadata(index, {"icon_key":key, "title":String(item.get("name", list.get_item_text(index))), "description":description, "facts":facts})

func _decorate_mission_list(list: ItemList) -> void:
	var tasks: Array[Dictionary] = PrecinctMeta.task_catalog()
	for index: int in range(list.item_count):
		var task: Dictionary = tasks[index] if index < tasks.size() else {}
		var text: String = list.get_item_text(index)
		var key: String = GameIconRegistry.semantic_key(String(task.get("group", text)) + " mission")
		var description: String = String(task.get("description", _description_for_key("missions", text)))
		var facts: String = "PROGRESS %d / %d\nREWARD: %d CREDITS + %d INTEL" % [int(task.get("progress", 0)), int(task.get("target", 1)), int(task.get("reward_credits", 0)), int(task.get("reward_intel", 0))]
		list.set_item_icon(index, GameIconRegistry.icon_for(key, 34, _accent_for_key(key)))
		list.set_item_tooltip(index, "%s\n\n%s" % [description, facts])
		list.set_item_tooltip_enabled(index, true)
		list.set_item_metadata(index, {"icon_key":key, "title":String(task.get("name", text)), "description":description, "facts":facts})

func _decorate_generic_list(list: ItemList) -> void:
	for index: int in range(list.item_count):
		var text: String = list.get_item_text(index)
		var key: String = GameIconRegistry.semantic_key(text)
		var description: String = _description_for_key(key, text)
		list.set_item_icon(index, GameIconRegistry.icon_for(key, 30, _accent_for_key(key)))
		list.set_item_tooltip(index, description)
		list.set_item_tooltip_enabled(index, true)
		list.set_item_metadata(index, {"icon_key":key, "title":text, "description":description, "facts":"SELECT FOR DETAILS"})

func _item_list_signature(list: ItemList) -> String:
	var parts: PackedStringArray = PackedStringArray([str(list.item_count)])
	for index: int in range(list.item_count):
		parts.append(list.get_item_text(index))
	return "|".join(parts)

func _build_tooltip_panel() -> void:
	tooltip_layer = CanvasLayer.new()
	tooltip_layer.name = "StationHoverCardLayer"
	tooltip_layer.layer = 96
	precinct.add_child(tooltip_layer)
	tooltip_panel = PanelContainer.new()
	tooltip_panel.name = "StationHoverCard"
	tooltip_panel.custom_minimum_size = Vector2(390.0, 164.0)
	tooltip_panel.size = Vector2(390.0, 164.0)
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.visible = false
	tooltip_panel.add_theme_stylebox_override("panel", _panel_style())
	tooltip_layer.add_child(tooltip_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.add_child(row)
	tooltip_icon = TextureRect.new()
	tooltip_icon.custom_minimum_size = Vector2(64.0, 64.0)
	tooltip_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tooltip_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tooltip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(tooltip_icon)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	tooltip_title = Label.new()
	tooltip_title.add_theme_font_size_override("font_size", 15)
	tooltip_title.add_theme_color_override("font_color", Color("#E9FBFF"))
	tooltip_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(tooltip_title)
	tooltip_description = Label.new()
	tooltip_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_description.custom_minimum_size = Vector2(285.0, 70.0)
	tooltip_description.add_theme_font_size_override("font_size", 11)
	tooltip_description.add_theme_color_override("font_color", Color("#B8D6E3"))
	tooltip_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(tooltip_description)
	tooltip_facts = Label.new()
	tooltip_facts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_facts.add_theme_font_size_override("font_size", 10)
	tooltip_facts.add_theme_color_override("font_color", Color("#FFD36A"))
	tooltip_facts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(tooltip_facts)

func _update_hover_card() -> void:
	if tooltip_panel == null:
		return
	var hovered: Control = get_viewport().gui_get_hovered_control()
	var data: Dictionary = _hover_data(hovered)
	if data.is_empty():
		var focused: Control = get_viewport().gui_get_focus_owner()
		data = _hover_data(focused)
	if data.is_empty():
		tooltip_panel.visible = false
		current_hover_key = ""
		return
	var hover_key: String = "%s|%s" % [String(data.get("title", "")), String(data.get("facts", ""))]
	if hover_key != current_hover_key:
		current_hover_key = hover_key
		var key: String = String(data.get("icon_key", "chip"))
		tooltip_icon.texture = GameIconRegistry.icon_for(key, 64, _accent_for_key(key))
		tooltip_title.text = String(data.get("title", "STATION ITEM")).to_upper()
		tooltip_description.text = String(data.get("description", "Station command item."))
		tooltip_facts.text = String(data.get("facts", ""))
	tooltip_panel.visible = true
	_position_tooltip()

func _hover_data(control: Control) -> Dictionary:
	if control == null or control == tooltip_panel or tooltip_panel.is_ancestor_of(control):
		return {}
	var candidate: Control = control
	for _depth: int in range(4):
		if candidate is ItemList:
			var list := candidate as ItemList
			var index: int = list.get_item_at_position(list.get_local_mouse_position(), true)
			if index < 0:
				var selected: PackedInt32Array = list.get_selected_items()
				index = selected[0] if not selected.is_empty() else -1
			if index >= 0 and index < list.item_count:
				var metadata: Variant = list.get_item_metadata(index)
				if metadata is Dictionary:
					return metadata as Dictionary
				var text: String = list.get_item_text(index)
				var key: String = GameIconRegistry.semantic_key(text)
				return {"icon_key":key, "title":text, "description":_description_for_key(key, text), "facts":"SELECT FOR DETAILS"}
		if candidate.has_meta("hover_title"):
			return {
				"icon_key":String(candidate.get_meta("icon_key", "chip")),
				"title":String(candidate.get_meta("hover_title", "STATION ITEM")),
				"description":String(candidate.get_meta("hover_description", "Station command item.")),
				"facts":String(candidate.get_meta("hover_facts", ""))
			}
		candidate = candidate.get_parent() as Control
		if candidate == null:
			break
	return {}

func _position_tooltip() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var panel_size: Vector2 = tooltip_panel.size
	var position_value := mouse + Vector2(18.0, 20.0)
	if position_value.x + panel_size.x > viewport_size.x - 12.0:
		position_value.x = mouse.x - panel_size.x - 18.0
	if position_value.y + panel_size.y > viewport_size.y - 12.0:
		position_value.y = viewport_size.y - panel_size.y - 12.0
	position_value.x = clampf(position_value.x, 12.0, maxf(12.0, viewport_size.x - panel_size.x - 12.0))
	position_value.y = clampf(position_value.y, 150.0, maxf(150.0, viewport_size.y - panel_size.y - 12.0))
	tooltip_panel.position = position_value

func _description_for_key(key: String, title: String) -> String:
	if EQUIPMENT_DESCRIPTIONS.has(key):
		return String(EQUIPMENT_DESCRIPTIONS[key])
	if GENERIC_DESCRIPTIONS.has(key):
		return String(GENERIC_DESCRIPTIONS[key])
	var semantic: String = GameIconRegistry.semantic_key(title)
	if EQUIPMENT_DESCRIPTIONS.has(semantic):
		return String(EQUIPMENT_DESCRIPTIONS[semantic])
	if GENERIC_DESCRIPTIONS.has(semantic):
		return String(GENERIC_DESCRIPTIONS[semantic])
	return "Station interface item. Select it to inspect its current level, purpose, requirements, cost, timer, and operational effect."

func _button_facts(full_text: String) -> String:
	var lines: PackedStringArray = full_text.split("\n")
	if lines.size() <= 1:
		return "STATION CONSOLE ACTION"
	var facts: PackedStringArray = PackedStringArray()
	for index: int in range(1, lines.size()):
		var line: String = lines[index].strip_edges()
		if not line.is_empty():
			facts.append(line)
	return "\n".join(facts)

func _accent_for_key(key: String) -> Color:
	match key:
		"threats": return Color("#FF6B82")
		"heal", "med_pods", "diagnostic_scanner", "trauma_console": return Color("#58F0C4")
		"weapons", "weapon_racks", "armor_forge", "ammo_loader", "turret", "rail": return Color("#FFB45C")
		"interrogation", "truth_scanner", "evidence_console", "restraint_table", "research": return Color("#C889FF")
		"moonsteel": return Color("#9AC7DA")
		"helium": return Color("#72F1E0")
		"salvage": return Color("#F1C06B")
		"shield", "interceptor": return Color("#72AFFF")
	return Color("#67E7FF")

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("07131D", 0.985)
	style.border_color = Color("67E7FF", 0.92)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style
