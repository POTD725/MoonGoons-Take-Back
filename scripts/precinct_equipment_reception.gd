extends "res://scripts/precinct_equipment_state.gd"
## Adds the public-facing Reception equipment catalog while preserving the tested
## room equipment progression and save format.

const RECEPTION_ITEMS: Array[Dictionary] = [
	{"id":"intake_desk","name":"Intake Desk","effect":"Civilian report and case intake speed","base_cost":65},
	{"id":"visitor_scanner","name":"Visitor Scanner","effect":"Entrance screening and contraband detection","base_cost":75},
	{"id":"case_terminal","name":"Case Filing Terminal","effect":"Mission intake, evidence routing, and dispatch handoff","base_cost":80}
]

func room_items(room_id: String) -> Array[Dictionary]:
	if room_id != "reception":
		return super.room_items(room_id)
	var result: Array[Dictionary] = []
	for raw_item: Dictionary in RECEPTION_ITEMS:
		var item: Dictionary = raw_item.duplicate(true)
		var item_id: String = String(item.get("id", ""))
		var level: int = item_level(room_id, item_id)
		item["level"] = level
		item["cap"] = int(PrecinctState.get_room(room_id).get("level", 1))
		item["upgrade_cost"] = upgrade_cost(room_id, item_id)
		result.append(item)
	return result

func upgrade_cost(room_id: String, item_id: String) -> int:
	if room_id != "reception":
		return super.upgrade_cost(room_id, item_id)
	var item: Dictionary = _catalog_item(room_id, item_id)
	if item.is_empty():
		return 0
	return int(item.get("base_cost", 70)) + item_level(room_id, item_id) * 40

func total_item_count() -> int:
	return super.total_item_count() + RECEPTION_ITEMS.size()

func _initialize_levels() -> void:
	super._initialize_levels()
	for item: Dictionary in RECEPTION_ITEMS:
		var item_key: String = _key("reception", String(item.get("id", "")))
		if not item_levels.has(item_key):
			item_levels[item_key] = 1

func _catalog_item(room_id: String, item_id: String) -> Dictionary:
	if room_id != "reception":
		return super._catalog_item(room_id, item_id)
	for item: Dictionary in RECEPTION_ITEMS:
		if String(item.get("id", "")) == item_id:
			return item
	return {}
