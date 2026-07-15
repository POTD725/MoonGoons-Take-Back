extends Control
## Guaranteed browser renderer for the unified Headquarters campus. It presents a
## three-quarter 2D/3D city and forwards touches to the contextual popup.

const PALETTES: Array[Dictionary] = HeadquartersVisualFactory.STYLE_PALETTES
var precinct: Node
var department_rects: Dictionary = {}
var facility_rects: Dictionary = {}
var animation_clock := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	process_mode=Node.PROCESS_MODE_ALWAYS
	visible=OS.has_feature("web")
	if not visible: set_process(false); return
	precinct=get_parent().get_parent()
	var legacy:=precinct.get_node_or_null("PrecinctWebBackdropLayer/PrecinctWebBackdrop") as Control
	if legacy!=null and legacy!=self: legacy.visible=false
	if not HeadquartersProgression.headquarters_changed.is_connected(queue_redraw): HeadquartersProgression.headquarters_changed.connect(queue_redraw)

func _process(delta:float)->void:
	animation_clock+=delta; queue_redraw()

func _gui_input(event:InputEvent)->void:
	if not event is InputEventMouseButton:return
	var mouse:=event as InputEventMouseButton
	if not mouse.pressed or mouse.button_index!=MOUSE_BUTTON_LEFT:return
	for key_value:Variant in department_rects.keys():
		if (department_rects[key_value] as Rect2).has_point(mouse.position):
			_open_department(String(key_value),mouse.position);accept_event();return
	for key_value:Variant in facility_rects.keys():
		if (facility_rects[key_value] as Rect2).has_point(mouse.position):
			_open_facility(String(key_value),mouse.position);accept_event();return

func _draw()->void:
	var viewport_size:=size if size.x>2 else get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO,viewport_size),Color("020711"),true)
	_draw_stars(viewport_size);_draw_horizon(viewport_size)
	department_rects.clear();facility_rects.clear()
	var center:=Vector2(viewport_size.x*0.5,viewport_size.y*0.51)
	var campus_scale:=clampf(minf(viewport_size.x/1280.0,viewport_size.y/720.0),0.72,1.35)
	_draw_roads(center,campus_scale)
	_draw_headquarters(center,campus_scale)
	_draw_facilities(center,campus_scale)
	_draw_activity(center,campus_scale)
	var title_rect:=Rect2(center.x-260*campus_scale,82,520*campus_scale,34)
	_panel(title_rect,Color("061722",0.95),Color("66E9FF"),2)
	draw_string(ThemeDB.fallback_font,title_rect.position+Vector2(8,23),"MOONGOONS PEACEKEEPER CAMPUS  //  TOUCH A BUILDING",HORIZONTAL_ALIGNMENT_CENTER,title_rect.size.x-16,14,Color("E8FAFF"))

func _draw_headquarters(center:Vector2,scale:float)->void:
	var style:=HeadquartersProgression.department_style("chief")
	var palette:=PALETTES[style] as Dictionary
	var base:=Rect2(center-Vector2(250,115)*scale,Vector2(500,230)*scale)
	# Connected main body, facade and raised roof.
	var facade:=Rect2(base.position+Vector2(0,38)*scale,Vector2(base.size.x,base.size.y-38*scale))
	draw_rect(facade,Color(String(palette.body)),true);draw_rect(facade,Color(String(palette.trim)),false,3)
	var roof_offset:=Vector2(24,-24)*scale
	var roof:=PackedVector2Array([base.position+Vector2(0,38)*scale,base.position+roof_offset,Vector2(base.end.x,base.position.y)+roof_offset+Vector2(0,38)*scale,Vector2(base.end.x,base.position.y+38*scale)])
	draw_colored_polygon(roof,Color(String(palette.trim)));draw_polyline(roof,Color(String(palette.glass)),2)
	# Reception entrance.
	var entrance:=Rect2(center+Vector2(-72,78)*scale,Vector2(144,72)*scale)
	draw_rect(entrance,Color(String(palette.dark)),true);draw_rect(entrance,Color(String(palette.glass)),false,3)
	draw_rect(Rect2(entrance.position+Vector2(37,18)*scale,Vector2(70,54)*scale),Color(String(palette.glass),0.78),true)
	# Nine departments shown as connected roof sectors, not separate buildings.
	var departments:=HeadquartersFacilityCatalog.DEPARTMENTS
	for index:int in range(departments.size()):
		var data:=departments[index] as Dictionary;var column:=index%3;var row:=int(index/3)
		var rect:=Rect2(base.position+Vector2(20+column*158,10+row*61)*scale,Vector2(142,49)*scale)
		var accent:=Color(String(data.get("accent",palette.glass)))
		draw_rect(rect,Color(accent,0.23),true);draw_rect(rect,accent,false,2)
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(4,19)*scale,String(data.get("name","DEPARTMENT")).to_upper(),HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-8*scale,int(9*scale+3),Color("ECFAFF"))
		draw_string(ThemeDB.fallback_font,rect.position+Vector2(4,38)*scale,"LEVEL %d"%HeadquartersProgression.department_level(String(data.get("id",""))),HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-8*scale,int(8*scale+2),accent)
		department_rects[String(data.get("id",""))]=rect.grow(4)
	# Tower and scanner rings.
	var tower:=Rect2(center+Vector2(-50,-184)*scale,Vector2(100,92)*scale);draw_rect(tower,Color(String(palette.body)),true);draw_rect(tower,Color(String(palette.glass)),false,3)
	for radius:float in [23,34,45]:draw_arc(center+Vector2(0,-155)*scale,radius*scale,0,TAU,40,Color(String(palette.glass),0.7),2)
	draw_string(ThemeDB.fallback_font,center+Vector2(-175,178)*scale,"POLICE HEADQUARTERS  //  LEVEL %d"%HeadquartersProgression.headquarters_level,HORIZONTAL_ALIGNMENT_CENTER,350*scale,int(12*scale),Color(String(palette.light)))

func _draw_facilities(center:Vector2,scale:float)->void:
	for facility_data:Dictionary in HeadquartersFacilityCatalog.FACILITIES:
		var facility_id:=String(facility_data.get("id",""));var world_pos:=facility_data.get("position",Vector2.ZERO) as Vector2
		var screen:=center+Vector2(world_pos.x*13.2,world_pos.y*7.3)*scale
		var rect:=Rect2(screen-Vector2(63,37)*scale,Vector2(126,74)*scale)
		_draw_facility(facility_id,rect,facility_data,scale)
		facility_rects[facility_id]=rect.grow(5)

func _draw_facility(facility_id:String,rect:Rect2,data:Dictionary,scale:float)->void:
	var style:=HeadquartersProgression.facility_style(facility_id);var palette:=PALETTES[style] as Dictionary;var accent:=Color(String(data.get("accent",palette.glass)))
	var facade:=Rect2(rect.position+Vector2(0,15)*scale,Vector2(rect.size.x,rect.size.y-15*scale));draw_rect(facade,Color(String(palette.body)),true);draw_rect(facade,accent,false,2)
	var roof_offset:=Vector2(10,-10)*scale;var roof:=PackedVector2Array([rect.position+Vector2(0,15)*scale,rect.position+roof_offset,Vector2(rect.end.x,rect.position.y)+roof_offset+Vector2(0,15)*scale,Vector2(rect.end.x,rect.position.y+15*scale)])
	draw_colored_polygon(roof,Color(String(palette.trim)));draw_polyline(roof,accent,1.5)
	# Identity glyphs keep all facility types visually distinct.
	var c:=rect.get_center()+Vector2(0,-4)*scale
	match facility_id:
		"research_center":
			for radius:float in [8,14,20]:draw_arc(c,radius*scale,0,TAU,32,accent,2)
		"guard_academy":
			draw_rect(Rect2(c-Vector2(3,15)*scale,Vector2(6,30)*scale),accent,true);draw_rect(Rect2(c-Vector2(15,3)*scale,Vector2(30,6)*scale),accent,true)
		"biker_garage":
			draw_circle(c+Vector2(-16,8)*scale,9*scale,accent,false,3);draw_circle(c+Vector2(16,8)*scale,9*scale,accent,false,3);draw_line(c+Vector2(-16,8)*scale,c+Vector2(0,-8)*scale,accent,3);draw_line(c+Vector2(0,-8)*scale,c+Vector2(16,8)*scale,accent,3)
		"marksman_range":
			for radius:float in [5,11,17]:draw_circle(c,radius*scale,accent,false,2);draw_line(c-Vector2(24,0)*scale,c+Vector2(24,0)*scale,accent,2)
		"robotics_bay":
			draw_rect(Rect2(c-Vector2(19,15)*scale,Vector2(38,30)*scale),Color(String(palette.dark)),true);draw_circle(c+Vector2(-9,-2)*scale,4*scale,accent);draw_circle(c+Vector2(9,-2)*scale,4*scale,accent)
		"hospital":
			draw_rect(Rect2(c-Vector2(4,18)*scale,Vector2(8,36)*scale),accent,true);draw_rect(Rect2(c-Vector2(18,4)*scale,Vector2(36,8)*scale),accent,true)
		"crime_lab":
			for x:float in [-14,0,14]:draw_circle(c+Vector2(x,0)*scale,7*scale,accent);draw_line(c+Vector2(-14,0)*scale,c+Vector2(14,0)*scale,accent,2)
		"storage_depot":
			for x:float in [-18,0,18]:draw_rect(Rect2(c+Vector2(x-7,-9)*scale,Vector2(14,18)*scale),accent if x==0 else Color(String(palette.dark)),true)
		"vehicle_depot":
			draw_rect(Rect2(c-Vector2(24,9)*scale,Vector2(48,18)*scale),Color(String(palette.dark)),true);draw_circle(c+Vector2(-17,11)*scale,6*scale,accent);draw_circle(c+Vector2(17,11)*scale,6*scale,accent)
	var label_rect:=Rect2(rect.position+Vector2(3,rect.size.y-21*scale),Vector2(rect.size.x-6,18*scale));draw_string(ThemeDB.fallback_font,label_rect.position+Vector2(2,13)*scale,String(data.get("name",facility_id)).to_upper(),HORIZONTAL_ALIGNMENT_CENTER,label_rect.size.x-4*scale,int(8*scale+2),Color("F0FAFF"))
	draw_string(ThemeDB.fallback_font,rect.position+Vector2(4,13)*scale,"L%d"%HeadquartersProgression.facility_level(facility_id),HORIZONTAL_ALIGNMENT_LEFT,30*scale,int(9*scale+2),accent)

func _draw_roads(center:Vector2,scale:float)->void:
	for facility_data:Dictionary in HeadquartersFacilityCatalog.FACILITIES:
		var pos:=facility_data.get("position",Vector2.ZERO) as Vector2;var screen:=center+Vector2(pos.x*13.2,pos.y*7.3)*scale
		draw_line(center,screen,Color("25495D"),18*scale);draw_line(center,screen,Color("5CDDF5",0.42),2*scale)

func _draw_activity(center:Vector2,scale:float)->void:
	for index:int in range(12):
		var progress:=fmod(animation_clock*(0.035+index*0.003)+index*0.087,1.0);var angle:=TAU*progress+index*0.7;var radius:=Vector2(190+index%3*35,95+index%4*14)*scale;var position:=center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y)
		var color:=Color("72E8FF") if index<7 else Color("FFD16A");draw_circle(position,3.5*scale,Color("02060A"));draw_circle(position+Vector2(0,-1)*scale,2.3*scale,color)
	# Patrol shuttle.
	var shuttle:=center+Vector2(cos(animation_clock*0.18)*310,sin(animation_clock*0.18)*145)*scale;draw_colored_polygon(PackedVector2Array([shuttle+Vector2(18,0)*scale,shuttle+Vector2(-12,-8)*scale,shuttle+Vector2(-6,0)*scale,shuttle+Vector2(-12,8)*scale]),Color("77E8FF"))

func _draw_stars(viewport_size:Vector2)->void:
	for index:int in range(100):
		var x:=fmod(float(index*127+31),viewport_size.x);var y:=fmod(float(index*73+19),maxf(1,viewport_size.y-70))+70;var pulse:=0.2+0.22*sin(animation_clock+index*0.5);draw_circle(Vector2(x,y),0.7+(index%3)*0.35,Color(0.7,0.9,1,pulse))
func _draw_horizon(viewport_size:Vector2)->void:
	var y:=viewport_size.y-72;draw_colored_polygon(PackedVector2Array([Vector2(0,y),Vector2(viewport_size.x*.18,y-32),Vector2(viewport_size.x*.38,y-8),Vector2(viewport_size.x*.58,y-44),Vector2(viewport_size.x*.78,y-12),Vector2(viewport_size.x,y-35),Vector2(viewport_size.x,viewport_size.y),Vector2(0,viewport_size.y)]),Color("151E2B"))
func _open_department(id:String,position:Vector2)->void:
	var popup:=precinct.get_node_or_null("BuildingContextPopup");if popup!=null:popup.call("open_department",id,position)
func _open_facility(id:String,position:Vector2)->void:
	var popup:=precinct.get_node_or_null("BuildingContextPopup");if popup!=null:popup.call("open_facility",id,position)
func _panel(rect:Rect2,fill:Color,border:Color,width:float)->void:
	draw_rect(rect,fill,true);draw_rect(rect,border,false,width)
