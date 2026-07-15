extends CanvasLayer
## Visual alliance research browser with exact Level 1-100 schedules.

const TREE_ART: Texture2D = preload("res://assets/ui/alliance_research_tree.svg")

var root_control: Control
var open_button: Button
var panel: PanelContainer
var branch_buttons: Dictionary = {}
var node_list: ItemList
var schedule_list: ItemList
var resource_label: Label
var branch_jobs_label: Label
var title_label: Label
var detail_label: Label
var requirement_label: Label
var feedback_label: Label
var research_button: Button
var selected_branch: String = "construction"
var selected_node_id: String = "modular_foundry"
var refresh_clock: float = 0.0

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless":
		return
	_build_interface()
	get_tree().scene_changed.connect(_on_scene_changed)
	AllianceResearch.research_changed.connect(_refresh)
	ResourceHarvest.resources_changed.connect(_refresh)
	PrecinctState.state_changed.connect(_refresh)
	_on_scene_changed(get_tree().current_scene)

func _process(delta: float) -> void:
	if root_control == null or not root_control.visible:
		return
	refresh_clock += delta
	if refresh_clock >= 0.5:
		refresh_clock = 0.0
		AllianceResearch.tick()
		_refresh_header()
		_refresh_jobs()

func _build_interface() -> void:
	root_control = Control.new()
	root_control.name = "AllianceResearchUI"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_control)

	open_button = Button.new()
	open_button.text = "ALLIANCE RESEARCH"
	open_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	open_button.position = Vector2(-236.0, 16.0)
	open_button.size = Vector2(220.0, 48.0)
	open_button.pressed.connect(_toggle_panel)
	open_button.add_theme_font_size_override("font_size", 15)
	open_button.add_theme_stylebox_override("normal", _panel_style(Color("10283a"), Color("68e8ff"), 2, 9))
	root_control.add_child(open_button)

	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-600.0, -340.0)
	panel.size = Vector2(1200.0, 680.0)
	panel.visible = false
	panel.add_theme_stylebox_override("panel", _panel_style(Color("06101c", 0.985), Color("6fdff4"), 3, 18))
	root_control.add_child(panel)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 8)
	panel.add_child(shell)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0.0, 58.0)
	header.add_theme_constant_override("separation", 12)
	shell.add_child(header)

	title_label = Label.new()
	title_label.text = "ALLIANCE RESEARCH NETWORK // LEVEL 1 → 100"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 23)
	title_label.add_theme_color_override("font_color", Color("edfaff"))
	header.add_child(title_label)

	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(110.0, 44.0)
	close_button.pressed.connect(_toggle_panel)
	header.add_child(close_button)

	resource_label = Label.new()
	resource_label.custom_minimum_size = Vector2(0.0, 32.0)
	resource_label.add_theme_font_size_override("font_size", 13)
	resource_label.add_theme_color_override("font_color", Color("ffcf78"))
	shell.add_child(resource_label)

	var tabs := HBoxContainer.new()
	tabs.custom_minimum_size = Vector2(0.0, 48.0)
	tabs.add_theme_constant_override("separation", 10)
	shell.add_child(tabs)
	for branch: String in AllianceResearch.BRANCHES:
		var button := Button.new()
		button.text = branch.to_upper()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, 44.0)
		button.pressed.connect(_select_branch.bind(branch))
		branch_buttons[branch] = button
		tabs.add_child(button)

	branch_jobs_label = Label.new()
	branch_jobs_label.custom_minimum_size = Vector2(0.0, 40.0)
	branch_jobs_label.add_theme_font_size_override("font_size", 12)
	branch_jobs_label.add_theme_color_override("font_color", Color("a9c3d3"))
	shell.add_child(branch_jobs_label)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	shell.add_child(content)

	var art_frame := PanelContainer.new()
	art_frame.custom_minimum_size = Vector2(300.0, 460.0)
	art_frame.add_theme_stylebox_override("panel", _panel_style(Color("0a1725"), Color("526d80"), 2, 12))
	content.add_child(art_frame)
	var art := TextureRect.new()
	art.texture = TREE_ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_frame.add_child(art)

	var node_column := VBoxContainer.new()
	node_column.custom_minimum_size = Vector2(370.0, 460.0)
	node_column.add_theme_constant_override("separation", 8)
	content.add_child(node_column)
	var node_heading := Label.new()
	node_heading.text = "RESEARCH NODES"
	node_heading.add_theme_font_size_override("font_size", 16)
	node_column.add_child(node_heading)
	node_list = ItemList.new()
	node_list.custom_minimum_size = Vector2(360.0, 190.0)
	node_list.item_selected.connect(_select_node)
	node_column.add_child(node_list)
	detail_label = Label.new()
	detail_label.custom_minimum_size = Vector2(360.0, 120.0)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size", 12)
	detail_label.add_theme_color_override("font_color", Color("d7e6ef"))
	node_column.add_child(detail_label)
	requirement_label = Label.new()
	requirement_label.custom_minimum_size = Vector2(360.0, 62.0)
	requirement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	requirement_label.add_theme_font_size_override("font_size", 11)
	node_column.add_child(requirement_label)
	research_button = Button.new()
	research_button.text = "BEGIN NEXT LEVEL"
	research_button.custom_minimum_size = Vector2(360.0, 52.0)
	research_button.pressed.connect(_begin_selected)
	node_column.add_child(research_button)
	feedback_label = Label.new()
	feedback_label.custom_minimum_size = Vector2(360.0, 48.0)
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.add_theme_font_size_override("font_size", 10)
	node_column.add_child(feedback_label)

	var schedule_column := VBoxContainer.new()
	schedule_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	schedule_column.add_theme_constant_override("separation", 8)
	content.add_child(schedule_column)
	var schedule_heading := Label.new()
	schedule_heading.text = "COMPLETE LEVEL SCHEDULE // 1–100"
	schedule_heading.add_theme_font_size_override("font_size", 16)
	schedule_column.add_child(schedule_heading)
	schedule_list = ItemList.new()
	schedule_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	schedule_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	schedule_list.custom_minimum_size = Vector2(470.0, 420.0)
	schedule_column.add_child(schedule_list)

	_refresh()

func _on_scene_changed(scene: Node) -> void:
	if root_control == null:
		return
	var allowed: bool = scene != null and scene.name == "LivingPrecinct"
	root_control.visible = allowed
	if not allowed:
		panel.visible = false

func _toggle_panel() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		MoonGoonsAudio.play("confirm")
		_refresh()
	else:
		MoonGoonsAudio.play("click")

func _select_branch(branch: String) -> void:
	selected_branch = branch
	var entries: Array[Dictionary] = AllianceResearch.node_catalog(branch)
	if not entries.is_empty():
		selected_node_id = String(entries[0].get("id", ""))
	MoonGoonsAudio.play("click")
	_refresh()

func _select_node(index: int) -> void:
	if index < 0 or index >= node_list.item_count:
		return
	selected_node_id = String(node_list.get_item_metadata(index))
	MoonGoonsAudio.play("click")
	_refresh_details()
	_refresh_schedule()

func _begin_selected() -> void:
	var result: Dictionary = AllianceResearch.begin_research(selected_node_id)
	feedback_label.text = String(result.get("message", ""))
	feedback_label.add_theme_color_override("font_color", Color("72ead5") if bool(result.get("ok", false)) else Color("ff8f86"))
	MoonGoonsAudio.play("dispatch" if bool(result.get("ok", false)) else "error")
	_refresh()

func _refresh() -> void:
	if root_control == null:
		return
	_refresh_header()
	_refresh_tabs()
	_refresh_nodes()
	_refresh_details()
	_refresh_schedule()
	_refresh_jobs()

func _refresh_header() -> void:
	resource_label.text = "ALLIANCE RESOURCES // %d Credits   •   %d Moonsteel   •   %d Helium-3   •   %d Quantum Salvage" % [
		PrecinctState.credits,
		ResourceHarvest.resource_amount("moonsteel"),
		ResourceHarvest.resource_amount("helium3"),
		ResourceHarvest.resource_amount("quantum_salvage")
	]

func _refresh_tabs() -> void:
	for branch_value: Variant in branch_buttons.keys():
		var branch: String = String(branch_value)
		var button: Button = branch_buttons[branch] as Button
		button.disabled = branch == selected_branch
		button.add_theme_color_override("font_color", _branch_color(branch))

func _refresh_nodes() -> void:
	node_list.clear()
	var entries: Array[Dictionary] = AllianceResearch.node_catalog(selected_branch)
	var selected_index: int = 0
	for index: int in range(entries.size()):
		var entry: Dictionary = entries[index]
		var node_id: String = String(entry.get("id", ""))
		var current_level: int = int(entry.get("level", 1))
		var active_text: String = " • RESEARCHING" if bool(entry.get("active", false)) else ""
		node_list.add_item("%s   LEVEL %d/100%s" % [String(entry.get("name", "Research")), current_level, active_text])
		node_list.set_item_metadata(index, node_id)
		if node_id == selected_node_id:
			selected_index = index
	if node_list.item_count > 0:
		node_list.select(selected_index)

func _refresh_details() -> void:
	if not AllianceResearch.NODES.has(selected_node_id):
		return
	var definition: Dictionary = AllianceResearch.NODES[selected_node_id] as Dictionary
	var current_level: int = AllianceResearch.level(selected_node_id)
	var target_level: int = mini(AllianceResearch.MAX_LEVEL, current_level + 1)
	var quote: Dictionary = AllianceResearch.level_quote(selected_node_id, target_level)
	var parent_id: String = String(definition.get("parent", ""))
	var parent_text: String = "ROOT NODE"
	if not parent_id.is_empty():
		parent_text = "%s • GAP %d" % [AllianceResearch.node_name(parent_id), int(definition.get("gap", 0))]
	detail_label.text = "%s
Branch: %s
Current Level: %d / 100
Prerequisite: %s

%s

NEXT: %s" % [
		String(definition.get("name", "Research")),
		selected_branch.capitalize(), current_level, parent_text,
		String(definition.get("benefit", "")),
		AllianceResearch.quote_text(quote)
	]
	var requirement: Dictionary = AllianceResearch.prerequisite_status(selected_node_id, target_level)
	requirement_label.text = String(requirement.get("message", ""))
	requirement_label.add_theme_color_override("font_color", Color("7fe9d5") if bool(requirement.get("ok", false)) else Color("ff9b83"))
	research_button.disabled = current_level >= AllianceResearch.MAX_LEVEL or AllianceResearch.active_jobs.has(selected_branch)
	research_button.text = "MAXIMUM LEVEL REACHED" if current_level >= AllianceResearch.MAX_LEVEL else "BEGIN LEVEL %d" % target_level

func _refresh_schedule() -> void:
	schedule_list.clear()
	var schedule: Array[Dictionary] = AllianceResearch.level_schedule(selected_node_id)
	var current_level: int = AllianceResearch.level(selected_node_id)
	for quote: Dictionary in schedule:
		var target: int = int(quote.get("target_level", 1))
		var marker: String = "✓" if target <= current_level else "•"
		var costs: Dictionary = quote.get("costs", {}) as Dictionary
		var line: String
		if target == 1:
			line = "%s L001  STARTING LEVEL" % marker
		else:
			line = "%s L%03d  %s  |  %d CR  %d MS  %d HE-3  %d QS" % [
				marker, target, AllianceResearch.format_duration(int(quote.get("seconds", 0))),
				int(quote.get("credits", 0)), int(costs.get("moonsteel", 0)),
				int(costs.get("helium3", 0)), int(costs.get("quantum_salvage", 0))
			]
		schedule_list.add_item(line)
	if current_level > 1:
		schedule_list.ensure_current_is_visible()

func _refresh_jobs() -> void:
	var parts: Array[String] = []
	for branch: String in AllianceResearch.BRANCHES:
		var job: Dictionary = AllianceResearch.active_job(branch)
		if job.is_empty():
			parts.append("%s: READY" % branch.to_upper())
		else:
			parts.append("%s: %s L%d • %s LEFT" % [
				branch.to_upper(),
				AllianceResearch.node_name(String(job.get("node_id", ""))),
				int(job.get("target_level", 1)),
				AllianceResearch.format_duration(AllianceResearch.seconds_left(branch))
			])
	branch_jobs_label.text = "     ".join(parts)

func _branch_color(branch: String) -> Color:
	match branch:
		"construction": return Color("ffc66f")
		"technology": return Color("68e8ff")
		_: return Color("ff779e")

func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style
