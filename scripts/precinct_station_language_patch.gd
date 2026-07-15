extends Node
## Replaces ground-city wording with orbital-station language after all runtime
## command and camera controls have been created.

var precinct: Node

const STATION_DECK_DESCRIPTION: String = "Return to the orbital station command deck. Inspect connected modules, pressure corridors, crew activity, damage, room levels, and available station operations."

func _ready() -> void:
	precinct = get_parent()
	call_deferred("_apply_when_ready")

func _apply_when_ready() -> void:
	for _frame: int in range(42):
		await get_tree().process_frame
	_apply_station_language(precinct)

func _apply_station_language(root: Node) -> void:
	if root == null:
		return
	if root is Button:
		var button := root as Button
		match button.text:
			"CITY":
				button.text = "STATION DECK"
				button.custom_minimum_size.x = maxf(button.custom_minimum_size.x, 106.0)
				button.tooltip_text = "Orbital command deck and connected station modules"
				button.set_meta("icon_key", "station_deck")
				button.set_meta("hover_title", "Station Deck")
				button.set_meta("hover_description", STATION_DECK_DESCRIPTION)
				button.set_meta("hover_facts", "ORBITAL PRECINCT OVERVIEW")
			"3/4 CITY":
				button.text = "STATION DECK"
				button.custom_minimum_size.x = maxf(button.custom_minimum_size.x, 92.0)
				button.tooltip_text = "Default three-quarter orbital station view"
				button.set_meta("icon_key", "station_deck")
				button.set_meta("hover_title", "Station Deck Camera")
				button.set_meta("hover_description", "Restore the default three-quarter camera above the orbital station's connected command deck and pressure modules.")
				button.set_meta("hover_facts", "DEFAULT COMMAND CAMERA")
			"CENTER CITY":
				button.text = "CENTER DECK"
			"CITY VIEW":
				button.text = "STATION VIEW"
	if root is Label:
		var label := root as Label
		if label.text == "3/4 CITY":
			label.text = "STATION DECK"
		elif label.text.contains("CITY VIEW"):
			label.text = label.text.replace("CITY VIEW", "STATION DECK")
	for child: Node in root.get_children():
		_apply_station_language(child)
