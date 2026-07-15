extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var equipment: Node = root.get_node_or_null("PrecinctEquipment")
	_expect(equipment != null, "Precinct equipment service is available")
	if equipment == null:
		quit(1)
		return

	var rooms: Array[String] = ["ops", "armory", "cells", "quarters", "medbay", "chief", "interrogation", "transfer"]
	var icon_ids: Dictionary = {}
	var described_items: int = 0
	for room_id: String in rooms:
		var items: Array = equipment.call("room_items", room_id) as Array
		_expect(items.size() == 3, "%s exposes three illustrated equipment items" % room_id.capitalize())
		for item_value: Variant in items:
			var item: Dictionary = item_value as Dictionary
			var icon_id: String = String(item.get("icon", ""))
			var description: String = String(item.get("description", ""))
			_expect(not icon_id.is_empty(), "%s has an explicit picture-icon ID" % String(item.get("name", "Equipment")))
			_expect(description.length() >= 40, "%s has a useful hover description" % String(item.get("name", "Equipment")))
			icon_ids[icon_id] = true
			if description.length() >= 40:
				described_items += 1
	_expect(icon_ids.size() == 24, "All twenty-four room upgrades have distinct picture-icon IDs")
	_expect(described_items == 24, "All twenty-four room upgrades have full descriptions")

	var semantic_checks: Dictionary = {
		"CITY":"station_deck",
		"MISSIONS":"missions",
		"DISPATCH":"dispatch",
		"OFFICERS":"officers",
		"UPGRADE STATION":"upgrade",
		"MOONSTEEL ORE":"moonsteel",
		"HELIUM-3":"helium",
		"QUANTUM SALVAGE":"salvage",
		"SYNDICATE FLEET":"threats",
		"TRUTH SCANNER":"truth_scanner"
	}
	for label_value: Variant in semantic_checks.keys():
		var label: String = String(label_value)
		var expected: String = String(semantic_checks[label])
		_expect(GameIconRegistry.semantic_key(label) == expected, "%s resolves to the correct semantic icon" % label)
		_expect(GameIconRegistry.icon_for(label, 32) != null, "%s generates a runtime SVG picture" % label)

	var scene: PackedScene = load("res://scenes/LivingPrecinct.tscn") as PackedScene
	_expect(scene != null, "Living orbital precinct scene loads with the station interface")
	if scene != null:
		var instance: Node = scene.instantiate()
		root.add_child(instance)
		for _frame: int in range(58):
			await process_frame
		_expect(instance.has_node("StationBoardFrameLayer/StationBoardFrame"), "Orbital station board frame is attached")
		_expect(instance.has_node("StationIconHoverController"), "Global icon and hover controller is attached")
		_expect(instance.has_node("StationLanguagePatch"), "Station terminology patch is attached")
		var hover_card: PanelContainer = instance.get_node_or_null("StationHoverCardLayer/StationHoverCard") as PanelContainer
		_expect(hover_card != null, "Station-console hover card is created")
		var deck_button: Button = instance.find_child("Command_city", true, false) as Button
		_expect(deck_button != null, "Station Deck command exists")
		if deck_button != null:
			_expect(deck_button.text == "STATION DECK", "Ground-city language is replaced by Station Deck")
			_expect(deck_button.icon != null, "Station Deck command has a picture icon")
			_expect(String(deck_button.get_meta("hover_description", "")).length() >= 30, "Station Deck command has a hover description")
		var progression_ui: Node = instance.get_node_or_null("PrecinctProgressionUI")
		var equipment_list: ItemList = progression_ui.get("equipment_list") as ItemList if progression_ui != null else null
		_expect(equipment_list != null and equipment_list.item_count == 3, "Selected station module shows three equipment rows")
		if equipment_list != null and equipment_list.item_count > 0:
			_expect(equipment_list.get_item_icon(0) != null, "Equipment rows display picture icons")
			var metadata: Variant = equipment_list.get_item_metadata(0)
			_expect(metadata is Dictionary and String((metadata as Dictionary).get("description", "")).length() >= 40, "Equipment row exposes detailed hover-card metadata")
		var view_controls: Node = instance.get_node_or_null("HybridViewControlsLayer/HybridViewControls")
		_expect(view_controls != null, "Station Deck, Cutaway, and Tactical Map controls exist")
		var station_view_button: Button = _find_button_with_text(view_controls, "STATION DECK")
		_expect(station_view_button != null and station_view_button.icon != null, "Station camera control has its own picture icon")
		instance.queue_free()
		await process_frame

	if failures == 0:
		print("SUCCESS: Station Deck icons, descriptions, and hover cards passed.")
	else:
		push_error("FAILED: %d station icon/hover check(s) failed." % failures)
	quit(failures)

func _find_button_with_text(root_node: Node, wanted_text: String) -> Button:
	if root_node == null:
		return null
	if root_node is Button and (root_node as Button).text == wanted_text:
		return root_node as Button
	for child: Node in root_node.get_children():
		var found: Button = _find_button_with_text(child, wanted_text)
		if found != null:
			return found
	return null

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
