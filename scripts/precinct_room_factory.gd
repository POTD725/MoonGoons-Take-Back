class_name PrecinctRoomFactory
extends RefCounted

const ROOM_SIZE := Vector3(8.6, 3.8, 7.2)
const THEMES := {
	"ops":{"floor":"#123B5F","wall":"#1B3C58","accent":"#00C8FF"},
	"armory":{"floor":"#45311D","wall":"#3B3028","accent":"#FF9E22"},
	"cells":{"floor":"#2C3540","wall":"#1F2A34","accent":"#5A9DFF"},
	"quarters":{"floor":"#493722","wall":"#3E3328","accent":"#FFD18A"},
	"medbay":{"floor":"#1D574F","wall":"#24464A","accent":"#44FFBF"},
	"chief":{"floor":"#4A321F","wall":"#2E3445","accent":"#FFD447"},
	"interrogation":{"floor":"#321F48","wall":"#281C3C","accent":"#B75CFF"},
	"transfer":{"floor":"#243946","wall":"#202B35","accent":"#3FD0FF"}
}
const ROOM_ART: Dictionary = {
	"ops": preload("res://assets/precinct/rooms/ops_center.svg"),
	"armory": preload("res://assets/precinct/rooms/armory.svg"),
	"cells": preload("res://assets/precinct/rooms/holding_cells.svg"),
	"quarters": preload("res://assets/precinct/rooms/crew_quarters.svg"),
	"medbay": preload("res://assets/precinct/rooms/medbay.svg"),
	"chief": preload("res://assets/precinct/rooms/chief_office.svg"),
	"interrogation": preload("res://assets/precinct/rooms/interrogation.svg"),
	"transfer": preload("res://assets/precinct/rooms/transfer_hall.svg")
}
const ROOM_SKINS: Dictionary = {
	"ops": "command_nexus",
	"armory": "tactical_armory",
	"cells": "evidence_cache",
	"quarters": "patrol_deputy",
	"medbay": "shield_deputy",
	"chief": "builder_drone",
	"interrogation": "cargo_crate",
	"transfer": "wrecked_shuttle"
}
const SIGN_NAMES: Dictionary = {
	"ops": "OPS",
	"armory": "ARMORY",
	"cells": "CELLS",
	"quarters": "QUARTERS",
	"medbay": "MEDBAY",
	"chief": "CHIEF",
	"interrogation": "INTERROG.",
	"transfer": "TRANSFER"
}

static func build_room(room_id:String, room_data:Dictionary) -> Node3D:
	var root := Node3D.new()
	var theme:Dictionary = THEMES.get(room_id, THEMES["ops"])
	var repaired:bool = bool(room_data.get("repaired", false))
	var level:int = int(room_data.get("level", 1))
	root.name = "Room_%s" % room_id
	root.set_meta("room_id", room_id)
	root.set_meta("clickable", true)
	_add_shell(root, theme, repaired)
	_add_room_backdrop(root, room_id, repaired)
	_add_established_skin_display(root, room_id, repaired)
	match room_id:
		"ops": _ops(root, theme, repaired)
		"armory": _armory(root, theme, repaired)
		"cells": _cells(root, theme, repaired)
		"quarters": _quarters(root, theme, repaired)
		"medbay": _medbay(root, theme, repaired)
		"chief": _chief(root, theme, repaired)
		"interrogation": _interrogation(root, theme, repaired)
		"transfer": _transfer(root, theme, repaired)
	_add_label(root, room_id, repaired, level, str(theme["accent"]))
	_add_status_beacon(root, repaired, str(theme["accent"]))
	_add_click_area(root)
	if not repaired:
		_add_damage(root)
	return root

static func _add_shell(root:Node3D, theme:Dictionary, repaired:bool) -> void:
	var floor_color:String = str(theme["floor"])
	var wall_color:String = str(theme["wall"])
	var accent:String = str(theme["accent"])
	root.add_child(_box(Vector3(ROOM_SIZE.x,0.26,ROOM_SIZE.z),Vector3.ZERO,floor_color,0.02))
	root.add_child(_box(Vector3(ROOM_SIZE.x,ROOM_SIZE.y,0.25),Vector3(0,1.9,-3.6),wall_color,0.0))
	root.add_child(_box(Vector3(0.25,ROOM_SIZE.y,ROOM_SIZE.z),Vector3(-4.3,1.9,0),wall_color,0.0))
	root.add_child(_box(Vector3(0.25,ROOM_SIZE.y,ROOM_SIZE.z),Vector3(4.3,1.9,0),wall_color,0.0))
	root.add_child(_box(Vector3(8.0,0.08,0.12),Vector3(0,3.45,-3.42),accent,0.75 if repaired else 0.04))
	for strip_index in range(4):
		root.add_child(_box(Vector3(0.06,0.025,6.5),Vector3(-3.15+float(strip_index)*2.1,0.15,0),accent,0.16 if repaired else 0.01))
	_marker(root,"Door",Vector3(0,0,3.8))
	_marker(root,"Idle",Vector3(-2.8,0,2.2))
	_marker(root,"Center",Vector3(0,0,0.6))

static func _add_room_backdrop(root:Node3D, room_id:String, repaired:bool) -> void:
	var texture:Texture2D = ROOM_ART.get(room_id) as Texture2D
	if texture == null:
		return
	root.add_child(_box(Vector3(8.05,3.28,0.12),Vector3(0,1.82,-3.40),"#05080D",0.0))
	var panel:MeshInstance3D = _texture_panel(texture,Vector2(7.72,3.02),Vector3(0,1.82,-3.325),repaired,0.28)
	panel.name = "RoomArt"
	root.add_child(panel)

static func _add_established_skin_display(root:Node3D, room_id:String, repaired:bool) -> void:
	var skin_name:String = str(ROOM_SKINS.get(room_id,""))
	if skin_name.is_empty():
		return
	var texture:Texture2D = MoonGoonsSkins.get_texture(skin_name)
	if texture == null:
		return
	root.add_child(_box(Vector3(2.28,1.48,0.10),Vector3(2.72,1.62,-3.205),"#07101A",0.0))
	var panel:MeshInstance3D = _texture_panel(texture,Vector2(2.08,1.28),Vector3(2.72,1.62,-3.135),repaired,0.55)
	panel.name = "EstablishedMoonGoonsArt"
	root.add_child(panel)

static func _ops(root:Node3D, theme:Dictionary, repaired:bool) -> void:
	var accent:String = str(theme["accent"])
	for index in range(4):
		var angle:float = TAU*float(index)/4.0
		var console := Node3D.new()
		console.position = Vector3(cos(angle)*2.55,0.55,sin(angle)*1.85-0.2)
		console.rotation.y = -angle+PI*0.5
		console.add_child(_box(Vector3(1.2,0.82,0.65),Vector3.ZERO,"#173C51",0.0))
		console.add_child(_box(Vector3(0.95,0.38,0.05),Vector3(0,0.26,0.36),accent,0.55 if repaired else 0.02))
		root.add_child(console)
		_marker(root,"Job%d"%index,Vector3(cos(angle)*2.95,0,sin(angle)*2.25-0.1))
	root.add_child(_cylinder(1.05,0.18,Vector3(0,0.34,-0.15),"#15364A",0.0))
	var globe := _sphere(0.68,Vector3(0,1.25,-0.15),accent,0.35 if repaired else 0.01)
	globe.transparency = 0.45
	root.add_child(globe)
	_marker(root,"Supervisor",Vector3(0,0,1.55))

static func _armory(root:Node3D, theme:Dictionary, repaired:bool) -> void:
	var accent:String = str(theme["accent"])
	for rack_index in range(4):
		var x:float = -3.05+float(rack_index)*2.03
		root.add_child(_box(Vector3(1.42,2.25,0.55),Vector3(x,1.22,-2.85),"#2B2927",0.0))
		for weapon_index in range(3):
			var weapon := _box(Vector3(0.88,0.12,0.12),Vector3(x,0.55+float(weapon_index)*0.65,-2.5),accent,0.22 if repaired else 0.01)
			weapon.rotation_degrees.z = -14.0
			root.add_child(weapon)
	root.add_child(_box(Vector3(4.1,0.72,1.3),Vector3(0,0.48,0.45),"#5B4933",0.0))
	for index in range(3): _marker(root,"Job%d"%index,Vector3(-2.4+float(index)*2.4,0,1.25))

static func _cells(root:Node3D, theme:Dictionary, repaired:bool) -> void:
	var accent:String = str(theme["accent"])
	for cell_index in range(3):
		var x:float = -2.65+float(cell_index)*2.65
		root.add_child(_box(Vector3(2.25,2.9,0.18),Vector3(x,1.52,-1.1),"#15232F",0.0))
		for bar_index in range(6):
			root.add_child(_box(Vector3(0.07,2.45,0.08),Vector3(x-0.92+float(bar_index)*0.37,1.28,0),accent,0.14 if repaired else 0.01))
		root.add_child(_box(Vector3(2.18,0.08,0.08),Vector3(x,2.46,0),accent,0.14 if repaired else 0.01))
		_marker(root,"Cell%d"%cell_index,Vector3(x,0,-0.6))
	_marker(root,"Job0",Vector3(2.9,0,2.15))
	_marker(root,"Job1",Vector3(-2.9,0,2.15))

static func _quarters(root:Node3D, theme:Dictionary, repaired:bool) -> void:
	var accent:String = str(theme["accent"])
	for side_index in range(2):
		var x:float = -2.75 if side_index==0 else 2.75
		for bunk_index in range(2):
			var z:float = -1.7+float(bunk_index)*2.75
			root.add_child(_box(Vector3(2.2,0.32,1.1),Vector3(x,0.43,z),"#607384",0.0))
			root.add_child(_box(Vector3(0.72,0.18,1.03),Vector3(x-0.62,0.69,z),accent,0.05 if repaired else 0.0))
			_marker(root,"Rest%d_%d"%[side_index,bunk_index],Vector3(x,0,z+0.9))
	root.add_child(_box(Vector3(2.1,0.75,1.05),Vector3(0,0.5,0.2),"#4C3C2E",0.0))
	_marker(root,"Job0",Vector3(0,0,1.55))

static func _medbay(root:Node3D, theme:Dictionary, repaired:bool) -> void:
	var accent:String = str(theme["accent"])
	for index in range(3):
		var x:float = -2.55+float(index)*2.55
		root.add_child(_box(Vector3(1.75,0.48,2.65),Vector3(x,0.5,-0.65),"#D7EEF1",0.0))
		root.add_child(_box(Vector3(1.45,0.16,1.1),Vector3(x,0.82,-1.18),accent,0.12 if repaired else 0.01))
		_marker(root,"Bed%d"%index,Vector3(x,0,0.72))
	root.add_child(_box(Vector3(2.3,1.2,0.5),Vector3(0,0.76,-2.95),"#183C43",0.0))
	root.add_child(_box(Vector3(1.55,0.55,0.08),Vector3(0,0.92,-2.66),accent,0.45 if repaired else 0.01))
	_marker(root,"Job0",Vector3(0,0,-1.95))

static func _chief(root:Node3D, theme:Dictionary, repaired:bool) -> void:
	var accent:String = str(theme["accent"])
	root.add_child(_box(Vector3(4.6,0.9,1.65),Vector3(0,0.58,-0.2),"#704F39",0.0))
	root.add_child(_box(Vector3(1.5,0.92,0.48),Vector3(0,1.15,-1.0),"#173C53",0.0))
	root.add_child(_box(Vector3(1.22,0.62,0.08),Vector3(0,1.22,-0.74),accent,0.55 if repaired else 0.02))
	for index in range(3): root.add_child(_cylinder(0.18,0.3,Vector3(-1.0+float(index),1.05,-3.25),"#D6B14A",0.18))
	_marker(root,"Job0",Vector3(0,0,1.35))
	_marker(root,"Visitor",Vector3(0,0,2.45))

static func _interrogation(root:Node3D, theme:Dictionary, repaired:bool) -> void:
	var accent:String = str(theme["accent"])
	root.add_child(_cylinder(1.3,0.28,Vector3(0,0.38,-0.4),"#233B49",0.0))
	root.add_child(_box(Vector3(5.8,0.16,0.14),Vector3(0,2.75,-1.9),"#F4FBFF",0.35 if repaired else 0.01))
	root.add_child(_sphere(0.24,Vector3(0,2.55,-0.45),accent,0.7 if repaired else 0.02))
	_marker(root,"Job0",Vector3(-1.65,0,0.25))
	_marker(root,"Suspect",Vector3(1.65,0,0.25))

static func _transfer(root:Node3D, theme:Dictionary, repaired:bool) -> void:
	var accent:String = str(theme["accent"])
	root.add_child(_box(Vector3(7.4,0.16,2.2),Vector3(0,0.2,-0.6),"#132C39",0.0))
	for gate_index in range(8):
		root.add_child(_box(Vector3(0.09,2.65,0.09),Vector3(-3.15+float(gate_index)*0.9,1.42,-2.4),accent,0.2 if repaired else 0.01))
	for pad_index in range(3):
		var pad := _cylinder(0.62,0.11,Vector3(-2.1+float(pad_index)*2.1,0.26,1.35),accent,0.22 if repaired else 0.01)
		root.add_child(pad)
		_marker(root,"Job%d"%pad_index,Vector3(-2.1+float(pad_index)*2.1,0,0.65))
	_marker(root,"Exit",Vector3(0,0,4.8))

static func _add_damage(root:Node3D) -> void:
	for index in range(4):
		var spark := _sphere(0.12+float(index)*0.025,Vector3(-2.8+float(index)*1.8,0.45+float(index%2),-1.4+float(index%3)),"#FF5B68",0.45)
		root.add_child(spark)
	var smoke := _sphere(0.55,Vector3(2.8,2.4,-2.6),"#2B2631",0.0)
	smoke.transparency = 0.5
	root.add_child(smoke)

static func _add_label(root:Node3D, room_id:String, repaired:bool, level:int, accent:String) -> void:
	var label := Label3D.new()
	label.name = "RoomLabel"
	label.text = "%s  L%d" % [str(SIGN_NAMES.get(room_id,room_id.to_upper())),level]
	label.position = Vector3(0,3.62,0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label.fixed_size = true
	label.font_size = 18
	label.outline_size = 4
	label.modulate = Color.from_string(accent,Color.CYAN) if repaired else Color("#FF7A96")
	root.add_child(label)

static func _add_status_beacon(root:Node3D, repaired:bool, accent:String) -> void:
	var color:String = accent if repaired else "#FF5B68"
	root.add_child(_cylinder(0.16,0.65,Vector3(3.72,0.48,2.92),"#202733",0.0))
	root.add_child(_sphere(0.24,Vector3(3.72,0.92,2.92),color,0.8 if repaired else 1.0))

static func _add_click_area(root:Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "ClickArea"
	body.set_meta("room_id",root.get_meta("room_id",""))
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(8.4,3.6,7.0)
	shape_node.position = Vector3(0,1.8,0)
	shape_node.shape = shape
	body.add_child(shape_node)
	root.add_child(body)

static func _marker(root:Node3D, marker_name:String, marker_position:Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = marker_name
	marker.position = marker_position
	root.add_child(marker)

static func _texture_panel(texture:Texture2D, size_value:Vector2, position_value:Vector3, repaired:bool, emission:float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.position = position_value
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = Color.WHITE if repaired else Color(0.24,0.25,0.30,1.0)
	material.roughness = 0.72
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if repaired and emission > 0.0:
		material.emission_enabled = true
		material.emission_texture = texture
		material.emission_energy_multiplier = emission
	node.material_override = material
	return node

static func _box(size_value:Vector3, position_value:Vector3, color_hex:String, emission:float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex,emission)
	return node

static func _sphere(radius_value:float, position_value:Vector3, color_hex:String, emission:float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius_value
	mesh.height = radius_value*2.0
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex,emission)
	return node

static func _cylinder(radius_value:float, height_value:float, position_value:Vector3, color_hex:String, emission:float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius_value
	mesh.bottom_radius = radius_value
	mesh.height = height_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = _material(color_hex,emission)
	return node

static func _material(color_hex:String, emission:float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var color := Color.from_string(color_hex,Color.WHITE)
	material.albedo_color = color
	material.roughness = 0.58
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material
