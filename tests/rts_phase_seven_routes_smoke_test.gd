extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_validate_route_rules()
	_validate_route_controller()
	if failures.is_empty():
		print("MoonGoons Take Back Phase Seven route-control smoke test passed.")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)

func _validate_route_rules() -> void:
	var file: FileAccess = FileAccess.open("res://data/rts_phase_seven_navigation.json", FileAccess.READ)
	if file == null:
		failures.append("Phase Seven navigation rules file could not be opened for route checks.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		failures.append("Phase Seven navigation rules file is not valid JSON for route checks.")
		return
	var rules: Dictionary = parsed as Dictionary
	var navigation: Dictionary = rules.get("navigation", {}) as Dictionary
	var queue_rules: Dictionary = navigation.get("route_queue", {}) as Dictionary
	if int(queue_rules.get("max_waypoints", 0)) < 2:
		failures.append("Route queue must allow at least two waypoints.")
	if float(queue_rules.get("arrival_radius", 0.0)) <= 0.0:
		failures.append("Route queue arrival radius must be positive.")
	if String(queue_rules.get("queue_modifier", "")) != "Ctrl + right-click":
		failures.append("Route queue modifier must remain Ctrl + right-click.")
	if String(queue_rules.get("queued_attack_move_modifier", "")) != "Ctrl + Shift + right-click":
		failures.append("Queued attack-move modifier must remain Ctrl + Shift + right-click.")

func _validate_route_controller() -> void:
	var route_script: Script = load("res://scripts/moongoons_rts_phase_seven_routes.gd") as Script
	if route_script == null:
		failures.append("Phase Seven queued-route controller could not be loaded.")
		return
	var controller: Node = route_script.new() as Node
	if controller == null:
		failures.append("Phase Seven queued-route controller could not be instantiated.")
		return
	for method_name: String in ["_queue_selected_route_command", "_advance_route_if_arrived", "_route_arrival_radius"]:
		if not controller.has_method(method_name):
			failures.append("Phase Seven queued-route controller is missing %s." % method_name)
	controller.free()
