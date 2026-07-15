extends "res://scripts/precinct_icon_tooltip_controller.gd"
## Godot 4.3-compatible icon decorator.
## Patrol actions and patrol missions use an orbital Peacekeeper spacecraft.

const PATROL_SPACECRAFT: Texture2D = preload("res://assets/ui/patrol_spacecraft.svg")

func _decorate_button(button: Button) -> void:
	if button == null or button.text.strip_edges().is_empty():
		return
	var signature: String = button.text + "|" + button.name
	if String(button.get_meta("icon_hover_signature", "")) == signature:
		return
	var original_tooltip: String = button.tooltip_text.strip_edges()
	var title: String = button.text.get_slice("\n", 0).strip_edges()
	var patrol_control: bool = _is_patrol_text(button.name + " " + title)
	var key: String = "interceptor" if patrol_control else GameIconRegistry.semantic_key(String(button.get_meta("icon_key", button.name + " " + title)))
	var description: String = original_tooltip if not original_tooltip.is_empty() else _description_for_key(key, title)
	if patrol_control and original_tooltip.is_empty():
		description = "Launch a Peacekeeper patrol spacecraft with the selected officers to answer station and orbital distress calls."
	var facts: String = _button_facts(button.text)
	button.icon = PATROL_SPACECRAFT if patrol_control else GameIconRegistry.icon_for(key, 28, _accent_for_key(key))
	button.expand_icon = false
	button.tooltip_text = ""
	button.set_meta("icon_key", key)
	button.set_meta("hover_title", title)
	button.set_meta("hover_description", description)
	button.set_meta("hover_facts", facts)
	button.set_meta("icon_hover_signature", signature)

func _decorate_mission_list(list: ItemList) -> void:
	var tasks: Array[Dictionary] = PrecinctMeta.task_catalog()
	for index: int in range(list.item_count):
		var task: Dictionary = tasks[index] if index < tasks.size() else {}
		var text: String = list.get_item_text(index)
		var group: String = String(task.get("group", text))
		var patrol_mission: bool = _is_patrol_text(group + " " + text)
		var key: String = "interceptor" if patrol_mission else GameIconRegistry.semantic_key(group + " mission")
		var description: String = String(task.get("description", _description_for_key("missions", text)))
		var facts: String = "PROGRESS %d / %d\nREWARD: %d CREDITS + %d INTEL" % [int(task.get("progress", 0)), int(task.get("target", 1)), int(task.get("reward_credits", 0)), int(task.get("reward_intel", 0))]
		list.set_item_icon(index, PATROL_SPACECRAFT if patrol_mission else GameIconRegistry.icon_for(key, 34, _accent_for_key(key)))
		list.set_item_tooltip(index, "%s\n\n%s" % [description, facts])
		list.set_item_tooltip_enabled(index, true)
		list.set_item_metadata(index, {"icon_key":key, "title":String(task.get("name", text)), "description":description, "facts":facts})

func _decorate_generic_list(list: ItemList) -> void:
	for index: int in range(list.item_count):
		var text: String = list.get_item_text(index)
		var patrol_item: bool = _is_patrol_text(text)
		var key: String = "interceptor" if patrol_item else GameIconRegistry.semantic_key(text)
		var description: String = "Peacekeeper patrol spacecraft assignment. Select it to review its officers, destination, readiness, and mission status." if patrol_item else _description_for_key(key, text)
		list.set_item_icon(index, PATROL_SPACECRAFT if patrol_item else GameIconRegistry.icon_for(key, 30, _accent_for_key(key)))
		list.set_item_tooltip(index, description)
		list.set_item_tooltip_enabled(index, true)
		list.set_item_metadata(index, {"icon_key":key, "title":text, "description":description, "facts":"SELECT FOR DETAILS"})

func _is_patrol_text(value: String) -> bool:
	return value.to_lower().contains("patrol")
