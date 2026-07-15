extends Node
## Dedicated orbital window for missions, resources and hostile fleets. The Police
## Headquarters remains fixed at the center and the main city stays uncluttered.

const SITE_POSITIONS: Dictionary = {
	"asteroid_cinder9":Vector2(-34,-18), "asteroid_iron_choir":Vector2(-43,2), "asteroid_blueglass":Vector2(-32,30),
	"moon_selene":Vector2(0,-39), "moon_mare_vent":Vector2(22,-34), "moon_khepri":Vector2(40,-23),
	"wreck_courier":Vector2(34,23), "wreck_relay":Vector2(43,2), "wreck_carrier":Vector2(30,-14)
}

var precinct: Node
var layer: CanvasLayer
var window: PanelContainer
var map_canvas: OrbitalMapCanvas
var detail_title: Label
var detail_text: Label
var status: Label
var officers: ItemList
var primary_button: Button
var secondary_button: Button
var combat_grid: GridContainer
var filter_buttons: Dictionary = {}
var selected_type := ""
var selected_id := ""
var refresh_clock := 0.0

func _ready() -> void:
	precinct = get_parent()
	call_deferred("_initialize")

func _initialize() -> void:
	for _frame: int in range(20): await get_tree().process_frame
	_build_interface(); _hide_legacy_space_layers(); _connect_signals(); _refresh()

func _process(delta: float) -> void:
	refresh_clock += delta
	if refresh_clock < 0.35: return
	refresh_clock = 0.0
	ResourceHarvest.tick(); SpaceThreats.tick(); PrecinctState.tick()
	if window != null and window.visible: _refresh()

func open_map(filter_mode: String = "all") -> void:
	if window == null: return
	window.visible = true; map_canvas.set_filter(filter_mode); _set_filter_buttons(filter_mode)
	var popup := precinct.get_node_or_null("BuildingContextPopup")
	if popup != null and popup.has_method("close"): popup.call("close")
	_refresh(); MoonGoonsAudio.play("confirm")

func close_map() -> void:
	if window != null: window.visible = false

func _build_interface() -> void:
	layer = CanvasLayer.new(); layer.name = "OrbitalOperationsLayer"; layer.layer = 94; precinct.add_child(layer)
	window = PanelContainer.new(); window.name = "OrbitalOperationsWindow"; window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); window.offset_left=18; window.offset_top=72; window.offset_right=-18; window.offset_bottom=-18; window.visible=false; window.add_theme_stylebox_override("panel",_panel_style()); layer.add_child(window)
	var outer := VBoxContainer.new(); outer.add_theme_constant_override("separation",6); window.add_child(outer)
	var header := HBoxContainer.new(); outer.add_child(header)
	var title := Label.new(); title.text="ORBITAL OPERATIONS MAP  //  BASE-CENTERED COMMAND"; title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; title.add_theme_font_size_override("font_size",20); header.add_child(title)
	for entry: Dictionary in [{"id":"all","label":"ALL"},{"id":"resource","label":"RESOURCES"},{"id":"threat","label":"THREATS"},{"id":"mission","label":"MISSIONS"}]:
		var id := String(entry.id); var button := _small_button(String(entry.label), _set_filter.bind(id)); header.add_child(button); filter_buttons[id]=button
	var close := _small_button("CLOSE",close_map); header.add_child(close)
	var body := HBoxContainer.new(); body.size_flags_vertical=Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation",8); outer.add_child(body)
	map_canvas = OrbitalMapCanvas.new(); map_canvas.custom_minimum_size=Vector2(720,560); map_canvas.size_flags_horizontal=Control.SIZE_EXPAND_FILL; map_canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL; map_canvas.marker_selected.connect(_on_marker_selected); body.add_child(map_canvas)
	var side := PanelContainer.new(); side.custom_minimum_size=Vector2(380,560); side.add_theme_stylebox_override("panel",_side_style()); body.add_child(side)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",7); side.add_child(column)
	detail_title=Label.new(); detail_title.add_theme_font_size_override("font_size",17); detail_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; column.add_child(detail_title)
	detail_text=Label.new(); detail_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; detail_text.custom_minimum_size=Vector2(350,205); detail_text.add_theme_font_size_override("font_size",11); column.add_child(detail_text)
	officers=ItemList.new(); officers.select_mode=ItemList.SELECT_MULTI; officers.custom_minimum_size=Vector2(350,170); officers.visible=false; column.add_child(officers)
	primary_button=_action_button("SELECT A MAP TARGET",_primary_action); column.add_child(primary_button)
	secondary_button=_action_button("SECONDARY ACTION",_secondary_action); secondary_button.visible=false; column.add_child(secondary_button)
	combat_grid=GridContainer.new(); combat_grid.columns=2; combat_grid.add_theme_constant_override("h_separation",5); combat_grid.add_theme_constant_override("v_separation",5); combat_grid.visible=false; column.add_child(combat_grid)
	for action: Dictionary in [{"id":"cannons","label":"FIRE CANNONS"},{"id":"rail_strike","label":"RAIL STRIKE"},{"id":"scan","label":"TACTICAL SCAN"},{"id":"evade","label":"EVADE"},{"id":"retreat","label":"RETREAT"}]:
		var button:=_small_button(String(action.label),_combat_action.bind(String(action.id))); button.custom_minimum_size=Vector2(170,36); combat_grid.add_child(button)
	status=Label.new(); status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; status.custom_minimum_size=Vector2(350,54); status.add_theme_color_override("font_color",Color("7DEAFF")); status.add_theme_font_size_override("font_size",10); column.add_child(status)
	_set_filter_buttons("all")

func _hide_legacy_space_layers() -> void:
	for controller_name: String in ["ResourceHarvestController","SpaceThreatOperations"]:
		var controller := precinct.get_node_or_null(controller_name)
		if controller == null: continue
		for property_name: String in ["panel","toggle","open_button"]:
			var value: Variant = controller.get(property_name)
			if value is Control: (value as Control).visible=false
	var world := precinct.get_node_or_null("LivingPrecinctWorld")
	if world != null:
		for node_name: String in ["ResourceHarvestSites","SyndicateSpaceFleets"]:
			var node := world.get_node_or_null(node_name)
			if node != null: node.visible=false

func _connect_signals() -> void:
	if not ResourceHarvest.resources_changed.is_connected(_refresh): ResourceHarvest.resources_changed.connect(_refresh)
	if not SpaceThreats.threats_changed.is_connected(_refresh): SpaceThreats.threats_changed.connect(_refresh)
	if not SpaceThreats.battle_changed.is_connected(_refresh): SpaceThreats.battle_changed.connect(_refresh)
	if not PrecinctState.state_changed.is_connected(_refresh): PrecinctState.state_changed.connect(_refresh)

func _refresh() -> void:
	if map_canvas==null: return
	var markers: Array[Dictionary]=[]
	for site: Dictionary in ResourceHarvest.site_catalog():
		var site_id:=String(site.get("id","")); var resource_id:=String(site.get("resource","moonsteel"))
		markers.append({"type":"resource","id":site_id,"label":String(site.get("name","SITE")),"position":SITE_POSITIONS.get(site_id,Vector2.ZERO),"color":ResourceHarvest.resource_color(resource_id).to_html(),"locked":bool(site.get("locked",false))})
	for target: Dictionary in SpaceThreats.target_catalog():
		var target_id:=String(target.get("id","")); var site_id:=String(target.get("site_id","")); var base:=SITE_POSITIONS.get(site_id,Vector2.ZERO) as Vector2
		var offset:=Vector2(4.5,-4.5) if int(target_id.hash())%2==0 else Vector2(-4.5,4.5)
		markers.append({"type":"threat","id":target_id,"label":"L%d %s"%[int(target.get("level",1)),String(target.get("commander","SYNDICATE"))],"position":base+offset,"color":"#FF527D","locked":bool(target.get("locked",false))})
	for index:int in range(PrecinctState.patrol_calls.size()):
		var call:=PrecinctState.patrol_calls[index]; var angle:=TAU*float(index)/maxf(3.0,float(PrecinctState.patrol_calls.size()))-PI*0.5
		markers.append({"type":"mission","id":String(call.get("id","")),"label":String(call.get("title","DISTRESS CALL")),"position":Vector2(cos(angle),sin(angle))*(18.0+index*3.0),"color":"#FFE06A","locked":false})
	map_canvas.set_markers(markers)
	if selected_id.is_empty() and not markers.is_empty():
		selected_type=String(markers[0].type); selected_id=String(markers[0].id); map_canvas.select_marker(selected_type,selected_id)
	_refresh_detail()

func _on_marker_selected(marker_type:String,marker_id:String)->void:
	selected_type=marker_type; selected_id=marker_id; _refresh_detail(); MoonGoonsAudio.play("click")

func _refresh_detail()->void:
	officers.visible=false; secondary_button.visible=false; combat_grid.visible=false; primary_button.visible=true
	match selected_type:
		"resource": _refresh_resource_detail()
		"threat": _refresh_threat_detail()
		"mission": _refresh_mission_detail()
		_: detail_title.text="SELECT AN ORBITAL TARGET"; detail_text.text="Headquarters is fixed at map center. Choose a resource field, Syndicate fleet, or distress mission."; primary_button.visible=false

func _refresh_resource_detail()->void:
	var site:=_find_by_id(ResourceHarvest.site_catalog(),selected_id)
	if site.is_empty(): selected_id=""; return
	var resource_id:=String(site.get("resource","moonsteel")); var threatened:=bool(site.get("threatened",false))
	detail_title.text=String(site.get("name","RESOURCE SITE")).to_upper()
	detail_text.text="%s  //  %s\nRESOURCE: %s\nSITE LEVEL %d  |  RISK %d\nRESERVE %d / %d  |  PROJECTED YIELD %d\nSTATE: %s\n\nBALANCES: ORE %d  |  HE-3 %d  |  Q-SALV %d"%[String(site.get("location","SPACE")),String(site.get("kind","SITE")).to_upper(),ResourceHarvest.resource_name(resource_id),int(site.get("level",1)),int(site.get("risk",1)),int(site.get("reserve",0)),int(site.get("max_reserve",0)),int(site.get("yield",0)),"THREATENED BY %s"%String(site.get("threat_commander","SYNDICATE")) if threatened else "READY",ResourceHarvest.resource_amount("moonsteel"),ResourceHarvest.resource_amount("helium3"),ResourceHarvest.resource_amount("quantum_salvage")]
	primary_button.text="DISPATCH HARVESTER\nYIELD: %d  |  TIME: %ds"%[int(site.get("yield",0)),ResourceHarvest.harvest_duration(ResourceHarvest.get_site(selected_id))]; primary_button.disabled=bool(site.get("locked",false)) or threatened
	secondary_button.visible=true; secondary_button.text="UPGRADE EXTRACTION SITE TO LEVEL %d"%(int(site.get("level",1))+1); secondary_button.disabled=bool(site.get("locked",false))

func _refresh_threat_detail()->void:
	var target:=_find_by_id(SpaceThreats.target_catalog(),selected_id)
	if target.is_empty(): selected_id=""; return
	var active:Dictionary=SpaceThreats.active_battle; var engaged:=String(active.get("target_id",""))==selected_id
	detail_title.text="%s  //  LEVEL %d"%[String(target.get("title","SYNDICATE FLEET")).to_upper(),int(target.get("level",1))]
	var battle_text:=""
	if engaged: battle_text="\n\nACTIVE BATTLE\nENEMY %d/%d  |  SHIELD %d/%d  |  HULL %d/%d\n%s"%[int(active.get("enemy_hp",0)),int(active.get("enemy_max_hp",0)),int(active.get("player_shield",0)),int(active.get("player_max_shield",0)),int(active.get("player_hull",0)),int(active.get("player_max_hull",0)),String(active.get("log","Engagement active"))]
	detail_text.text="COMMANDER: %s\nCLASS: %s  |  SHIPS: %s\nDIFFICULTY: %s\nPOWER %d  |  DEFENSE %d\nREWARD: %d CREDITS, %d INTEL, %d %s%s"%[String(target.get("commander","UNKNOWN")),String(target.get("class","CRIMINAL")),String(target.get("ship","FLEET")),String(target.get("difficulty_name","STANDARD")),int(target.get("power",0)),int(target.get("defense",0)),int(target.get("credits",0)),int(target.get("intel",0)),int(target.get("resource_reward",0)),String(target.get("resource","RESOURCE")).to_upper(),battle_text]
	primary_button.text="ENGAGE TARGET"; primary_button.disabled=bool(target.get("locked",false)) or bool(target.get("defeated",false)) or (not SpaceThreats.active_battle.is_empty() and not engaged)
	combat_grid.visible=engaged; primary_button.visible=not engaged

func _refresh_mission_detail()->void:
	var call:=_find_by_id(PrecinctState.patrol_calls,selected_id)
	if call.is_empty(): selected_id=""; return
	detail_title.text=String(call.get("title","DISTRESS CALL")).to_upper()
	var remaining:=maxi(0,int(call.get("expires_at",0))-int(Time.get_unix_time_from_system()))
	detail_text.text="SECTOR: %s\nDIFFICULTY %d\nENEMY HP %d  |  POWER %d\nREWARD %d CREDITS + EVIDENCE + INTEL\nEXPIRES IN %d SECONDS\n\nSelect up to three available officers."%[String(call.get("sector","UNKNOWN")),int(call.get("difficulty",1)),int(call.get("enemy_hp",0)),int(call.get("enemy_power",0)),int(call.get("reward",0)),remaining]
	officers.visible=true; officers.clear()
	for officer:Dictionary in PrecinctState.officers:
		var available:=PrecinctState.officer_available(officer); officers.add_item("%s  //  %s  //  PWR %d%s"%[String(officer.get("name","OFFICER")),String(officer.get("class","GUARD")),int(officer.get("power",0)),"" if available else "  //  BUSY"]); officers.set_item_disabled(officers.item_count-1,not available)
	primary_button.text="DEPLOY SELECTED OFFICERS"; primary_button.disabled=false

func _primary_action()->void:
	var result:Dictionary={}
	match selected_type:
		"resource": result=ResourceHarvest.begin_harvest(selected_id)
		"threat": result=SpaceThreats.begin_battle(selected_id)
		"mission":
			var ids:Array[String]=[]
			for index:int in range(officers.item_count):
				if officers.is_selected(index) and index<PrecinctState.officers.size(): ids.append(String(PrecinctState.officers[index].get("id","")))
			result=PrecinctState.begin_patrol(selected_id,ids)
			if bool(result.get("ok",false)): close_map()
	status.text=String(result.get("message","")); _refresh()

func _secondary_action()->void:
	if selected_type=="resource":
		var result:=ResourceHarvest.upgrade_site(selected_id); status.text=String(result.get("message","")); _refresh()

func _combat_action(action:String)->void:
	var result:=SpaceThreats.battle_action(action); status.text=String(result.get("message","")); _refresh()

func _set_filter(filter_mode:String)->void:
	map_canvas.set_filter(filter_mode); _set_filter_buttons(filter_mode)

func _set_filter_buttons(active:String)->void:
	for key_value:Variant in filter_buttons.keys(): (filter_buttons[key_value] as Button).disabled=String(key_value)==active

func _find_by_id(source:Array[Dictionary],id_value:String)->Dictionary:
	for entry:Dictionary in source:
		if String(entry.get("id",""))==id_value:return entry
	return {}

func _action_button(text_value:String,callback:Callable)->Button:
	var button:=Button.new(); button.text=text_value; button.custom_minimum_size=Vector2(350,58); button.alignment=HORIZONTAL_ALIGNMENT_LEFT; button.add_theme_font_size_override("font_size",11); button.pressed.connect(callback); _style_button(button); return button
func _small_button(text_value:String,callback:Callable)->Button:
	var button:=Button.new(); button.text=text_value; button.custom_minimum_size=Vector2(82,34); button.add_theme_font_size_override("font_size",10); button.pressed.connect(callback); _style_button(button); return button
func _style_button(button:Button)->void:
	button.add_theme_stylebox_override("normal",_outline(Color("091722"),Color("47788D")));button.add_theme_stylebox_override("hover",_outline(Color("102B3A"),Color("6DEBFF")));button.add_theme_stylebox_override("pressed",_outline(Color("173B4D"),Color("9AF4FF")));button.add_theme_stylebox_override("disabled",_outline(Color("090D12"),Color("293943")))
func _panel_style()->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color("040D16",0.985);style.border_color=Color("4EDBF4");style.set_border_width_all(2);style.set_corner_radius_all(8);style.set_content_margin_all(8);return style
func _side_style()->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color("071722",0.96);style.border_color=Color("345E72");style.set_border_width_all(1);style.set_corner_radius_all(5);style.set_content_margin_all(9);return style
func _outline(fill:Color,border:Color)->StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=fill;style.border_color=border;style.set_border_width_all(1);style.set_corner_radius_all(4);style.set_content_margin_all(5);return style
