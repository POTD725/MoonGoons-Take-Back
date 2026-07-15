extends Node
## Persists one of five visual styles for every room equipment item.

signal style_changed(room_id: String, item_id: String, variant: int)

const SAVE_PATH: String = "user://moongoons_equipment_styles.json"
const VARIANT_NAMES: Array[String] = [
	"AUTHORITY",
	"INDUSTRIAL",
	"TACTICAL",
	"ORBITAL",
	"PROTOTYPE"
]

var item_styles: Dictionary = {}

func _ready() -> void:
	load_state()

func variant_name(variant: int) -> String:
	return VARIANT_NAMES[clampi(variant, 1, 5) - 1]

func item_variant(room_id: String, item_id: String) -> int:
	return clampi(int(item_styles.get(_key(room_id, item_id), 1)), 1, 5)

func set_item_variant(room_id: String, item_id: String, variant: int) -> void:
	var resolved: int = clampi(variant, 1, 5)
	item_styles[_key(room_id, item_id)] = resolved
	save_state()
	style_changed.emit(room_id, item_id, resolved)

func reset_state() -> void:
	item_styles.clear()
	save_state()

func save_state() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"item_styles": item_styles}))

func load_state() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return false
	item_styles = Dictionary((parsed as Dictionary).get("item_styles", {}))
	return true

func _key(room_id: String, item_id: String) -> String:
	return "%s:%s" % [room_id, item_id]
