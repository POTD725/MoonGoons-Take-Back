class_name GameIconRegistry
extends RefCounted
## Runtime SVG icon library for every station command, upgrade, mission, resource,
## threat, officer action, research node, and future catalog entry.

static var _cache: Dictionary = {}

static func icon_for(key: String, size: int = 32, accent: Color = Color("#67E7FF")) -> Texture2D:
	var normalized: String = _normalize(key)
	var cache_key: String = "%s:%d:%s" % [normalized, size, accent.to_html(false)]
	if _cache.has(cache_key):
		return _cache[cache_key] as Texture2D
	var image := Image.new()
	var error: Error = image.load_svg_from_string(_svg(normalized, size, accent), 1.0)
	if error != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_cache[cache_key] = texture
	return texture

static func semantic_key(raw_key: String) -> String:
	var key: String = _normalize(raw_key)
	var rules: Array[Dictionary] = [
		{"terms":["command_table"], "kind":"command_table"},
		{"terms":["dispatch_console"], "kind":"dispatch_console"},
		{"terms":["holo_map", "holo-map"], "kind":"holo_map"},
		{"terms":["weapon_racks", "weapon rack"], "kind":"weapon_racks"},
		{"terms":["armor_forge", "armor forge"], "kind":"armor_forge"},
		{"terms":["ammo_loader", "ammo loader"], "kind":"ammo_loader"},
		{"terms":["cell_locks", "cell door lock"], "kind":"cell_locks"},
		{"terms":["security_scanner"], "kind":"security_scanner"},
		{"terms":["intake_terminal"], "kind":"intake_terminal"},
		{"terms":["bunks", "crew bunk"], "kind":"bunks"},
		{"terms":["mess_station", "mess station"], "kind":"mess_station"},
		{"terms":["morale_console", "morale console"], "kind":"morale_console"},
		{"terms":["med_pods", "medical pod"], "kind":"med_pods"},
		{"terms":["diagnostic_scanner"], "kind":"diagnostic_scanner"},
		{"terms":["trauma_console"], "kind":"trauma_console"},
		{"terms":["command_desk", "chief's command desk"], "kind":"command_desk"},
		{"terms":["strategy_wall"], "kind":"strategy_wall"},
		{"terms":["authority_uplink"], "kind":"authority_uplink"},
		{"terms":["truth_scanner"], "kind":"truth_scanner"},
		{"terms":["evidence_console"], "kind":"evidence_console"},
		{"terms":["restraint_table"], "kind":"restraint_table"},
		{"terms":["airlock_gate", "transfer airlock"], "kind":"airlock_gate"},
		{"terms":["prisoner_scanner"], "kind":"prisoner_scanner"},
		{"terms":["transport_console"], "kind":"transport_console"},
		{"terms":["station deck", "command_city", "city"], "kind":"station_deck"},
		{"terms":["mission", "task", "objective"], "kind":"missions"},
		{"terms":["dispatch", "deploy", "patrol"], "kind":"dispatch"},
		{"terms":["officer", "crew", "personnel"], "kind":"officers"},
		{"terms":["equipment", "item", "gear"], "kind":"equipment"},
		{"terms":["resource", "harvest", "extract"], "kind":"resources"},
		{"terms":["threat", "syndicate", "marauder", "fleet", "engage"], "kind":"threats"},
		{"terms":["side ops", "side_ops"], "kind":"side_ops"},
		{"terms":["research", "technology"], "kind":"research"},
		{"terms":["repair", "engine"], "kind":"repair"},
		{"terms":["upgrade", "level"], "kind":"upgrade"},
		{"terms":["train"], "kind":"train"},
		{"terms":["heal", "medical"], "kind":"heal"},
		{"terms":["post", "assign"], "kind":"assign"},
		{"terms":["moonsteel", "ore"], "kind":"moonsteel"},
		{"terms":["helium-3", "helium"], "kind":"helium"},
		{"terms":["quantum salvage", "salvage", "wreck"], "kind":"salvage"},
		{"terms":["turret", "point defense"], "kind":"turret"},
		{"terms":["shield"], "kind":"shield"},
		{"terms":["rail"], "kind":"rail"},
		{"terms":["interceptor"], "kind":"interceptor"},
		{"terms":["interrogation", "guilt", "confession"], "kind":"interrogation"},
		{"terms":["weapon"], "kind":"weapons"},
		{"terms":["close", "cancel", "back"], "kind":"close"},
		{"terms":["previous", "turn l", "left"], "kind":"previous"},
		{"terms":["next", "turn r", "right"], "kind":"next"},
		{"terms":["cutaway"], "kind":"cutaway"},
		{"terms":["map"], "kind":"map"},
		{"terms":["zoom +", "zoom in"], "kind":"zoom_in"},
		{"terms":["zoom -", "zoom out"], "kind":"zoom_out"}
	]
	for rule: Dictionary in rules:
		for term_value: Variant in rule.get("terms", []):
			if key.contains(String(term_value)):
				return String(rule.get("kind", "chip"))
	return key if _known_symbol(key) else "chip_%d" % absi(key.hash() % 12)

static func _normalize(value: String) -> String:
	return value.strip_edges().to_lower().replace("\n", " ").replace("-", "_")

static func _known_symbol(key: String) -> bool:
	return key in [
		"command_table", "dispatch_console", "holo_map", "weapon_racks", "armor_forge", "ammo_loader",
		"cell_locks", "security_scanner", "intake_terminal", "bunks", "mess_station", "morale_console",
		"med_pods", "diagnostic_scanner", "trauma_console", "command_desk", "strategy_wall", "authority_uplink",
		"truth_scanner", "evidence_console", "restraint_table", "airlock_gate", "prisoner_scanner", "transport_console",
		"station_deck", "missions", "dispatch", "officers", "equipment", "resources", "threats", "side_ops", "research",
		"repair", "upgrade", "train", "heal", "assign", "moonsteel", "helium", "salvage", "turret", "shield",
		"rail", "interceptor", "interrogation", "weapons", "close", "previous", "next", "cutaway", "map", "zoom_in", "zoom_out"
	]

static func _svg(raw_key: String, size: int, accent: Color) -> String:
	var kind: String = semantic_key(raw_key)
	var line: String = "#%s" % accent.to_html(false)
	var warm: String = "#FFD36A"
	var danger: String = "#FF6B82"
	var symbol: String = _symbol(kind, line, warm, danger)
	return "<svg xmlns='http://www.w3.org/2000/svg' width='%d' height='%d' viewBox='0 0 64 64'>" % [size, size] + \
		"<rect x='2' y='2' width='60' height='60' rx='12' fill='#071722' stroke='#365E72' stroke-width='3'/>" + \
		"<path d='M9 18H4V9h9M51 9h9v9M60 46v9h-9M13 55H4v-9' fill='none' stroke='%s' stroke-width='2' opacity='.7'/>" % line + \
		symbol + "</svg>"

static func _symbol(kind: String, line: String, warm: String, danger: String) -> String:
	match kind:
		"command_table": return "<ellipse cx='32' cy='35' rx='20' ry='8' fill='#173749' stroke='%s' stroke-width='3'/><path d='M18 35v12m28-12v12M22 47h20' stroke='%s' stroke-width='3'/><circle cx='32' cy='23' r='7' fill='none' stroke='%s' stroke-width='3'/><path d='M32 16V9' stroke='%s' stroke-width='3'/>" % [line, line, warm, line]
		"dispatch_console": return "<path d='M15 45h34l-4-22H19z' fill='#173749' stroke='%s' stroke-width='3'/><rect x='23' y='27' width='18' height='9' rx='2' fill='%s' opacity='.65'/><path d='M27 45v7m10-7v7M46 17c5 3 7 7 7 12M18 17c-5 3-7 7-7 12' fill='none' stroke='%s' stroke-width='3'/>" % [line, line, warm]
		"holo_map": return "<circle cx='32' cy='31' r='16' fill='none' stroke='%s' stroke-width='3'/><path d='M16 31h32M32 15c6 6 6 26 0 32M32 15c-6 6-6 26 0 32' fill='none' stroke='%s' stroke-width='2'/><path d='M20 52h24' stroke='%s' stroke-width='4'/>" % [line, line, warm]
		"weapon_racks": return "<path d='M18 49L44 15M20 16l25 33' stroke='%s' stroke-width='5'/><path d='M13 45l10 7M41 52l10-7M15 19l9-7M40 12l9 7' stroke='%s' stroke-width='3'/>" % [line, warm]
		"armor_forge": return "<path d='M32 12l18 7v13c0 12-8 19-18 23-10-4-18-11-18-23V19z' fill='#173749' stroke='%s' stroke-width='3'/><path d='M24 38l16-16M20 26l18 18' stroke='%s' stroke-width='4'/>" % [line, warm]
		"ammo_loader": return "<path d='M17 16h30v32H17z' fill='#173749' stroke='%s' stroke-width='3'/><path d='M24 22v18m8-18v18m8-18v18' stroke='%s' stroke-width='5'/><path d='M20 48h24' stroke='%s' stroke-width='4'/>" % [line, warm, line]
		"cell_locks": return "<rect x='17' y='28' width='30' height='25' rx='4' fill='#173749' stroke='%s' stroke-width='3'/><path d='M23 28v-7c0-12 18-12 18 0v7' fill='none' stroke='%s' stroke-width='4'/><circle cx='32' cy='40' r='4' fill='%s'/><path d='M32 44v5' stroke='%s' stroke-width='3'/>" % [line, line, warm, warm]
		"security_scanner", "diagnostic_scanner", "truth_scanner", "prisoner_scanner": return "<path d='M17 16v32M47 16v32M17 20h8M39 20h8M17 44h8M39 44h8' stroke='%s' stroke-width='4'/><path d='M22 27h20M22 33h20M22 39h20' stroke='%s' stroke-width='2' opacity='.8'/><circle cx='32' cy='33' r='7' fill='none' stroke='%s' stroke-width='3'/>" % [line, line, warm]
		"intake_terminal": return "<rect x='18' y='13' width='28' height='38' rx='3' fill='#173749' stroke='%s' stroke-width='3'/><path d='M25 12h14v7H25zM24 27h16M24 34h16M24 41h10' fill='none' stroke='%s' stroke-width='3'/><path d='M39 40l4 4 7-9' fill='none' stroke='%s' stroke-width='3'/>" % [line, line, warm]
		"bunks": return "<path d='M15 18v35M49 18v35M15 28h34M15 45h34' stroke='%s' stroke-width='4'/><path d='M19 22h12v6H19zM19 39h12v6H19z' fill='%s'/>" % [line, warm]
		"mess_station": return "<circle cx='32' cy='34' r='14' fill='#173749' stroke='%s' stroke-width='3'/><path d='M15 15v17M11 15v9h8v-9M49 15v37M44 15v16c0 6 10 6 10 0V15' fill='none' stroke='%s' stroke-width='3'/><circle cx='32' cy='34' r='5' fill='%s'/>" % [line, line, warm]
		"morale_console": return "<rect x='14' y='17' width='36' height='31' rx='5' fill='#173749' stroke='%s' stroke-width='3'/><circle cx='25' cy='29' r='3' fill='%s'/><circle cx='39' cy='29' r='3' fill='%s'/><path d='M23 38c5 6 13 6 18 0' fill='none' stroke='%s' stroke-width='3'/>" % [line, warm, warm, line]
		"med_pods": return "<rect x='15' y='21' width='34' height='29' rx='14' fill='#173749' stroke='%s' stroke-width='3'/><path d='M32 24v23M22 35h20' stroke='%s' stroke-width='5'/><path d='M20 18h24' stroke='%s' stroke-width='3'/>" % [line, warm, line]
		"trauma_console", "heal": return "<rect x='13' y='18' width='38' height='30' rx='4' fill='#173749' stroke='%s' stroke-width='3'/><path d='M20 35h7l4-10 6 18 4-8h6' fill='none' stroke='%s' stroke-width='3'/><path d='M32 11v9M27 15h10' stroke='%s' stroke-width='4'/>" % [line, warm, line]
		"command_desk": return "<path d='M13 29h38v18H13zM18 47v7m28-7v7' fill='#173749' stroke='%s' stroke-width='3'/><path d='M32 11l3 7 8 1-6 5 2 8-7-4-7 4 2-8-6-5 8-1z' fill='%s'/>" % [line, warm]
		"strategy_wall": return "<rect x='10' y='12' width='44' height='36' rx='4' fill='#173749' stroke='%s' stroke-width='3'/><circle cx='20' cy='25' r='4' fill='%s'/><circle cx='34' cy='20' r='4' fill='%s'/><circle cx='44' cy='36' r='4' fill='%s'/><path d='M23 24l7-3 11 12M20 29l8 11 12-3' stroke='%s' stroke-width='2'/><path d='M25 52h14' stroke='%s' stroke-width='4'/>" % [line, warm, line, warm, line]
		"authority_uplink": return "<path d='M32 12v39M23 51h18M26 37h12M28 28h8' stroke='%s' stroke-width='4'/><circle cx='32' cy='13' r='5' fill='%s'/><path d='M22 18c-8 7-8 18 0 25M42 18c8 7 8 18 0 25' fill='none' stroke='%s' stroke-width='3'/>" % [line, warm, line]
		"evidence_console": return "<path d='M13 20h18l5 6h15v25H13z' fill='#173749' stroke='%s' stroke-width='3'/><circle cx='34' cy='36' r='8' fill='none' stroke='%s' stroke-width='3'/><path d='M40 42l8 8' stroke='%s' stroke-width='4'/>" % [line, warm, warm]
		"restraint_table": return "<path d='M12 35h40v10H12zM18 45v9m28-9v9' fill='#173749' stroke='%s' stroke-width='3'/><circle cx='22' cy='27' r='6' fill='none' stroke='%s' stroke-width='4'/><circle cx='42' cy='27' r='6' fill='none' stroke='%s' stroke-width='4'/><path d='M28 27h8' stroke='%s' stroke-width='3'/>" % [line, warm, warm, line]
		"airlock_gate": return "<path d='M15 53V13h34v40M22 53V21h20v32' fill='#173749' stroke='%s' stroke-width='3'/><path d='M32 21v32M26 37h3M35 37h3' stroke='%s' stroke-width='3'/><circle cx='47' cy='18' r='4' fill='%s'/>" % [line, line, warm]
		"transport_console": return "<path d='M12 40l9-16h24l8 16-9 7H21z' fill='#173749' stroke='%s' stroke-width='3'/><path d='M25 24l7-10 7 10M20 40h24' stroke='%s' stroke-width='3'/><circle cx='23' cy='48' r='4' fill='%s'/><circle cx='43' cy='48' r='4' fill='%s'/>" % [line, warm, warm, warm]
		"station_deck": return "<path d='M12 43l20-29 20 29-20 9z' fill='#173749' stroke='%s' stroke-width='3'/><path d='M20 40h24M25 31h14M32 18v31' stroke='%s' stroke-width='2'/><circle cx='32' cy='36' r='5' fill='%s'/>" % [line, line, warm]
		"missions": return "<path d='M16 12h32v40H16z' fill='#173749' stroke='%s' stroke-width='3'/><path d='M23 23h18M23 32h18M23 41h11' stroke='%s' stroke-width='3'/><path d='M39 40l4 4 8-10' fill='none' stroke='%s' stroke-width='3'/>" % [line, line, warm]
		"dispatch": return "<path d='M12 42l20-26 20 26M20 42h24' fill='none' stroke='%s' stroke-width='4'/><circle cx='32' cy='31' r='5' fill='%s'/><path d='M32 13V7M15 20l-6-4M49 20l6-4' stroke='%s' stroke-width='3'/>" % [line, warm, line]
		"officers": return "<circle cx='32' cy='22' r='9' fill='%s'/><path d='M16 52c2-15 10-21 16-21s14 6 16 21' fill='#173749' stroke='%s' stroke-width='3'/><path d='M27 39h10v8H27z' fill='%s'/>" % [warm, line, line]
		"equipment": return "<path d='M16 20h32v31H16z' fill='#173749' stroke='%s' stroke-width='3'/><path d='M24 20v-7h16v7M22 30h20M22 39h20' stroke='%s' stroke-width='3'/><circle cx='32' cy='47' r='3' fill='%s'/>" % [line, line, warm]
		"resources": return "<path d='M18 14l14-7 14 7 6 16-20 27-20-27z' fill='#173749' stroke='%s' stroke-width='3'/><path d='M18 14l14 16 14-16M12 30h40M32 30v27' stroke='%s' stroke-width='2'/><circle cx='32' cy='30' r='4' fill='%s'/>" % [line, line, warm]
		"threats": return "<path d='M32 8l24 44H8z' fill='#311722' stroke='%s' stroke-width='4'/><path d='M32 22v15' stroke='%s' stroke-width='5'/><circle cx='32' cy='45' r='3' fill='%s'/>" % [danger, danger, warm]
		"side_ops": return "<path d='M18 14l8 8-5 5-8-8M46 50l-9-9 5-5 9 9M22 42l20-20' fill='none' stroke='%s' stroke-width='5'/><circle cx='32' cy='32' r='6' fill='%s'/>" % [line, warm]
		"research": return "<circle cx='32' cy='31' r='10' fill='#173749' stroke='%s' stroke-width='3'/><path d='M32 8v9M32 45v11M8 31h14M42 31h14M15 14l10 10M39 39l10 10M49 14L39 24M25 39L15 49' stroke='%s' stroke-width='3'/><circle cx='32' cy='31' r='4' fill='%s'/>" % [line, line, warm]
		"repair": return "<path d='M14 16l12 12-8 8L6 24c-1 10 7 18 17 16l19 19 9-9-19-19c2-10-6-18-18-15z' fill='#173749' stroke='%s' stroke-width='3'/><circle cx='46' cy='51' r='3' fill='%s'/>" % [line, warm]
		"upgrade": return "<path d='M32 8l17 19H39v25H25V27H15z' fill='#173749' stroke='%s' stroke-width='3'/><path d='M32 15v29' stroke='%s' stroke-width='4'/><circle cx='32' cy='50' r='4' fill='%s'/>" % [line, line, warm]
		"train": return "<path d='M10 22l22-11 22 11-22 11z' fill='#173749' stroke='%s' stroke-width='3'/><path d='M18 28v13c8 7 20 7 28 0V28M54 22v18' fill='none' stroke='%s' stroke-width='3'/><circle cx='54' cy='44' r='3' fill='%s'/>" % [line, line, warm]
		"assign": return "<circle cx='23' cy='22' r='8' fill='%s'/><path d='M10 48c2-12 7-18 13-18s11 6 13 18' fill='#173749' stroke='%s' stroke-width='3'/><path d='M36 33h17M46 25l8 8-8 8' fill='none' stroke='%s' stroke-width='4'/>" % [warm, line, line]
		"moonsteel": return "<path d='M18 12h28l8 18-22 24L10 30z' fill='#243B49' stroke='%s' stroke-width='3'/><path d='M18 12l14 18 14-18M10 30h44' stroke='%s' stroke-width='2'/>" % [line, warm]
		"helium": return "<circle cx='32' cy='32' r='18' fill='#173749' stroke='%s' stroke-width='3'/><circle cx='26' cy='28' r='5' fill='%s'/><circle cx='39' cy='35' r='6' fill='%s'/><path d='M20 48h24' stroke='%s' stroke-width='3'/>" % [line, warm, line, line]
		"salvage": return "<path d='M12 39l9-20 13 7 10-13 8 23-18 16z' fill='#173749' stroke='%s' stroke-width='3'/><path d='M21 19l13 33M44 13L28 48M12 39l40-3' stroke='%s' stroke-width='2'/><circle cx='34' cy='31' r='4' fill='%s'/>" % [line, line, warm]
		"turret": return "<path d='M19 49h26M24 49l3-15h10l3 15M22 34h20V24H22z' fill='#173749' stroke='%s' stroke-width='3'/><path d='M32 24V13M26 17l6-4 6 4' stroke='%s' stroke-width='4'/><circle cx='32' cy='29' r='3' fill='%s'/>" % [line, line, warm]
		"shield": return "<path d='M32 9l19 8v14c0 13-8 21-19 25-11-4-19-12-19-25V17z' fill='#173749' stroke='%s' stroke-width='3'/><path d='M20 32h24M32 18v28' stroke='%s' stroke-width='3'/><circle cx='32' cy='32' r='5' fill='%s'/>" % [line, line, warm]
		"rail": return "<path d='M10 35h44M18 28h28M24 21h16' stroke='%s' stroke-width='5'/><path d='M44 17l10 18-10 18' fill='none' stroke='%s' stroke-width='3'/><circle cx='16' cy='35' r='5' fill='%s'/>" % [line, warm, warm]
		"interceptor": return "<path d='M8 34l18-7 6-16 6 16 18 7-18 6-6 14-6-14z' fill='#173749' stroke='%s' stroke-width='3'/><circle cx='32' cy='32' r='5' fill='%s'/>" % [line, warm]
		"interrogation": return "<path d='M11 32c10-18 32-18 42 0-10 18-32 18-42 0z' fill='#173749' stroke='%s' stroke-width='3'/><circle cx='32' cy='32' r='8' fill='%s'/><path d='M32 14V8M49 20l5-4M15 20l-5-4' stroke='%s' stroke-width='3'/>" % [line, warm, line]
		"weapons": return "<path d='M12 48l34-34M17 16l31 31' stroke='%s' stroke-width='5'/><circle cx='32' cy='32' r='6' fill='%s'/><path d='M9 43l12 12M43 55l12-12' stroke='%s' stroke-width='3'/>" % [line, warm, warm]
		"close": return "<path d='M17 17l30 30M47 17L17 47' stroke='%s' stroke-width='6'/>" % danger
		"previous": return "<path d='M42 13L20 32l22 19' fill='none' stroke='%s' stroke-width='6'/>" % line
		"next": return "<path d='M22 13l22 19-22 19' fill='none' stroke='%s' stroke-width='6'/>" % line
		"cutaway": return "<path d='M12 18h40v31H12z' fill='#173749' stroke='%s' stroke-width='3'/><path d='M32 18v31M12 34h40M38 25h9M38 41h9' stroke='%s' stroke-width='2'/><path d='M17 24l10 10-10 10' fill='none' stroke='%s' stroke-width='3'/>" % [line, line, warm]
		"map": return "<path d='M10 17l14-6 16 6 14-6v36l-14 6-16-6-14 6z' fill='#173749' stroke='%s' stroke-width='3'/><path d='M24 11v36M40 17v36' stroke='%s' stroke-width='2'/><circle cx='34' cy='31' r='4' fill='%s'/>" % [line, line, warm]
		"zoom_in": return "<circle cx='28' cy='28' r='15' fill='#173749' stroke='%s' stroke-width='3'/><path d='M39 39l13 13M28 20v16M20 28h16' stroke='%s' stroke-width='4'/>" % [line, warm]
		"zoom_out": return "<circle cx='28' cy='28' r='15' fill='#173749' stroke='%s' stroke-width='3'/><path d='M39 39l13 13M20 28h16' stroke='%s' stroke-width='4'/>" % [line, warm]
		_:
			var variant: int = absi(kind.hash()) % 6
			return "<path d='M14 18h36v30H14z' fill='#173749' stroke='%s' stroke-width='3'/><circle cx='%d' cy='%d' r='7' fill='%s'/><path d='M20 25h24M20 41h24' stroke='%s' stroke-width='2'/>" % [line, 24 + variant * 3, 28 + (variant % 3) * 4, warm, line]
