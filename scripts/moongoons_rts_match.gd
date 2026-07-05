extends Node2D
## MoonGoons RTS skirmish prototype.
## Code-drawn so the project remains playable without external asset dependencies.

const VIEWPORT_SIZE := Vector2(1280.0, 720.0)
const FIELD := Rect2(18.0, 92.0, 938.0, 608.0)
const SIDEBAR := Rect2(974.0, 18.0, 288.0, 684.0)
const NEXUS_POSITION := Vector2(490.0, 430.0)
const SYNDICATE_HIDEOUT_POSITION := Vector2(835.0, 180.0)
const FONT_SMALL := 12
const FONT_MEDIUM := 18
const FONT_LARGE := 32

const WORKER_COST_CREDITS := 50
const DEPUTY_COST_CREDITS := 75
const VANGUARD_COST_CREDITS := 120
const VANGUARD_COST_ALLOY := 35
const RELAY_COST_CREDITS := 65
const RELAY_COST_ALLOY := 20
const ARMORY_COST_CREDITS := 120
const ARMORY_COST_ALLOY := 40
const TURRET_COST_CREDITS := 80
const TURRET_COST_ALLOY := 25

const WORKER_CAPACITY := 1
const DEPUTY_CAPACITY := 1
const VANGUARD_CAPACITY := 2

class ResourceNode:
	var pos: Vector2
	var resource_id: String
	var amount: int
	var max_amount: int
	var pulse := 0.0

	func _init(start_pos: Vector2, initial_resource_id: String, initial_amount: int) -> void:
		pos = start_pos
		resource_id = initial_resource_id
		amount = initial_amount
		max_amount = initial_amount

class Worker:
	var id: String
	var pos: Vector2
	var target: Vector2
	var hp := 55.0
	var selected := false
	var state := "idle"
	var resource_node_index := -1
	var carried_resource := ""
	var carried_amount := 0
	var harvest_clock := 0.0
	var build_structure_id := ""

	func _init(initial_id: String, start_pos: Vector2) -> void:
		id = initial_id
		pos = start_pos
		target = start_pos

class CombatUnit:
	var id: String
	var unit_type: String
	var pos: Vector2
	var target: Vector2
	var hp: float
	var max_hp: float
	var speed: float
	var attack_range: float
	var damage: float
	var cooldown_duration: float
	var cooldown := 0.0
	var command_cost: int
	var selected := false
	var order := "idle"
	var target_enemy_id := ""

	func _init(
		initial_id: String,
		initial_unit_type: String,
		start_pos: Vector2,
		initial_hp: float,
		initial_speed: float,
		initial_attack_range: float,
		initial_damage: float,
		initial_cooldown: float,
		initial_command_cost: int
	) -> void:
		id = initial_id
		unit_type = initial_unit_type
		pos = start_pos
		target = start_pos
		hp = initial_hp
		max_hp = initial_hp
		speed = initial_speed
		attack_range = initial_attack_range
		damage = initial_damage
		cooldown_duration = initial_cooldown
		command_cost = initial_command_cost

class EnemyUnit:
	var id: String
	var unit_type: String
	var pos: Vector2
	var hp: float
	var max_hp: float
	var speed: float
	var attack_range: float
	var damage: float
	var cooldown_duration: float
	var cooldown := 0.0
	var tint: Color

	func _init(
		initial_id: String,
		initial_unit_type: String,
		start_pos: Vector2,
		initial_hp: float,
		initial_speed: float,
		initial_attack_range: float,
		initial_damage: float,
		initial_cooldown: float,
		initial_tint: Color
	) -> void:
		id = initial_id
		unit_type = initial_unit_type
		pos = start_pos
		hp = initial_hp
		max_hp = initial_hp
		speed = initial_speed
		attack_range = initial_attack_range
		damage = initial_damage
		cooldown_duration = initial_cooldown
		tint = initial_tint

class Structure:
	var id: String
	var structure_type: String
	var pos: Vector2
	var hp: float
	var max_hp: float
	var construction_progress := 1.0
	var build_duration := 1.0
	var complete := true
	var completion_announced := false
	var attack_cooldown := 0.0

	func _init(
		initial_id: String,
		initial_structure_type: String,
		start_pos: Vector2,
		initial_max_hp: float,
		initial_build_duration: float = 1.0,
		starts_complete: bool = true
	) -> void:
		id = initial_id
		structure_type = initial_structure_type
		pos = start_pos
		max_hp = initial_max_hp
		hp = initial_max_hp if starts_complete else initial_max_hp * 0.35
		build_duration = initial_build_duration
		complete = starts_complete
		construction_progress = 1.0 if starts_complete else 0.0

var rng := RandomNumberGenerator.new()
var workers: Array[Worker] = []
var combat_units: Array[CombatUnit] = []
var enemy_units: Array[EnemyUnit] = []
var structures: Array[Structure] = []
var resource_nodes: Array[ResourceNode] = []
var crater_positions: Array[Vector2] = []
var crater_radii: Array[float] = []
var star_positions: Array[Vector2] = []
var battle_log: Array[String] = []
var nexus_queue: Array[Dictionary] = []
var armory_queue: Array[Dictionary] = []

var credits := 180
var lunar_alloy := 0
var intel := 0
var command_used := 0
var command_max := 14
var nexus_integrity := 1500.0
var syndicate_hideout_hp := 1600.0
var enemy_spawn_clock := 10.0
var match_clock := 0.0
var next_worker_id := 4
var next_unit_id := 3
var next_enemy_id := 1
var next_structure_id := 1
var build_mode := ""
var attack_move_armed := false
var drag_start := Vector2.ZERO
var drag_current := Vector2.ZERO
var is_dragging := false
var game_over := false
var victory := false
var mission_state := "Establish a lunar economy, build an army, and dismantle the Syndicate hideout."

var train_worker_button := Rect2(994.0, 326.0, 248.0, 42.0)
var train_deputy_button := Rect2(994.0, 374.0, 248.0, 42.0)
var build_relay_button := Rect2(994.0, 422.0, 248.0, 42.0)
var build_armory_button := Rect2(994.0, 470.0, 248.0, 42.0)
var train_vanguard_button := Rect2(994.0, 518.0, 248.0, 42.0)
var build_turret_button := Rect2(994.0, 566.0, 248.0, 42.0)
var restart_button := Rect2(994.0, 616.0, 248.0, 48.0)

func _ready() -> void:
	rng.seed = 20260704
	_build_backdrop()
	_reset_match()

func _process(delta: float) -> void:
	if game_over or victory:
		queue_redraw()
		return
	match_clock += delta
	enemy_spawn_clock -= delta
	_update_resource_nodes(delta)
	_update_workers(delta)
	_update_structures(delta)
	_update_production(delta)
	_update_combat_units(delta)
	_update_enemy_units(delta)
	if enemy_spawn_clock <= 0.0:
		_spawn_enemy_wave()
	if nexus_integrity <= 0.0:
		nexus_integrity = 0.0
		game_over = true
		mission_state = "COMMAND NEXUS LOST // THE SYNDICATE HOLDS THE DISTRICT"
		_log_event("Base lost. The lunar precinct has fallen.")
	elif syndicate_hideout_hp <= 0.0:
		syndicate_hideout_hp = 0.0
		victory = true
		mission_state = "SYNDICATE HIDEOUT DISMANTLED // DISTRICT SECURED"
		_log_event("Enemy command network collapsed. MoonGoons take the district.")
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var cursor := get_global_mouse_position()
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_handle_left_press(cursor)
			else:
				_handle_left_release(cursor)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			_handle_right_click(cursor)
	elif event is InputEventMouseMotion and is_dragging:
		drag_current = get_global_mouse_position()
	elif event is InputEventKey and event.pressed and not event.echo:
		_handle_hotkey(event.keycode)

func _handle_hotkey(keycode: Key) -> void:
	if game_over or victory:
		return
	match keycode:
		KEY_Q:
			_queue_worker()
		KEY_W:
			_queue_deputy()
		KEY_E:
			_begin_build_mode("relay")
		KEY_R:
			_begin_build_mode("armory")
		KEY_T:
			_begin_build_mode("turret")
		KEY_A:
			attack_move_armed = true
			mission_state = "ATTACK-MOVE ARMED // Right-click a location or hostile unit."
		KEY_B:
			build_mode = ""
			mission_state = "Build placement cancelled."
		KEY_G:
			_assign_selected_workers_to_nearest_resource(get_global_mouse_position())

func _handle_left_press(cursor: Vector2) -> void:
	if restart_button.has_point(cursor) and (game_over or victory):
		_reset_match()
		return
	if game_over or victory:
		return
	if train_worker_button.has_point(cursor):
		_queue_worker()
		return
	if train_deputy_button.has_point(cursor):
		_queue_deputy()
		return
	if build_relay_button.has_point(cursor):
		_begin_build_mode("relay")
		return
	if build_armory_button.has_point(cursor):
		_begin_build_mode("armory")
		return
	if train_vanguard_button.has_point(cursor):
		_queue_vanguard()
		return
	if build_turret_button.has_point(cursor):
		_begin_build_mode("turret")
		return
	if not FIELD.has_point(cursor):
		return
	if not build_mode.is_empty():
		_place_structure(cursor)
		return
	drag_start = cursor
	drag_current = cursor
	is_dragging = true

func _handle_left_release(cursor: Vector2) -> void:
	if not is_dragging:
		return
	is_dragging = false
	if drag_start.distance_to(cursor) > 10.0:
		_select_in_rectangle(Rect2(drag_start, cursor - drag_start).abs())
	else:
		_select_single_at(cursor)

func _handle_right_click(cursor: Vector2) -> void:
	if game_over or victory or not FIELD.has_point(cursor):
		return
	var resource_index := _resource_at(cursor)
	if resource_index >= 0 and _selected_worker_count() > 0:
		_assign_selected_workers_to_resource(resource_index)
		return
	var enemy := _enemy_at(cursor)
	if enemy != null:
		_command_selected_combat(enemy.pos, enemy.id, true)
		return
	_command_selected_combat(cursor, "", attack_move_armed)
	attack_move_armed = false
	_command_selected_workers_move(cursor)

func _queue_worker() -> void:
	if not _can_afford(WORKER_COST_CREDITS, 0, WORKER_CAPACITY):
		mission_state = "Need %d Credits and available Command Capacity for a Survey Drone." % WORKER_COST_CREDITS
		return
	_spend(WORKER_COST_CREDITS, 0, WORKER_CAPACITY)
	nexus_queue.append({"unit_type": "worker", "remaining": 4.0})
	_log_event("Survey Drone queued at the Command Nexus.")

func _queue_deputy() -> void:
	if not _can_afford(DEPUTY_COST_CREDITS, 0, DEPUTY_CAPACITY):
		mission_state = "Need %d Credits and available Command Capacity for a Patrol Deputy." % DEPUTY_COST_CREDITS
		return
	_spend(DEPUTY_COST_CREDITS, 0, DEPUTY_CAPACITY)
	nexus_queue.append({"unit_type": "deputy", "remaining": 5.0})
	_log_event("Patrol Deputy queued at the Command Nexus.")

func _queue_vanguard() -> void:
	if not _has_complete_structure("armory"):
		mission_state = "Tactical Armory required before Riot Vanguard production."
		return
	if not _can_afford(VANGUARD_COST_CREDITS, VANGUARD_COST_ALLOY, VANGUARD_CAPACITY):
		mission_state = "Need Credits, Lunar Alloy, and 2 Command Capacity for a Riot Vanguard."
		return
	_spend(VANGUARD_COST_CREDITS, VANGUARD_COST_ALLOY, VANGUARD_CAPACITY)
	armory_queue.append({"unit_type": "vanguard", "remaining": 8.0})
	_log_event("Riot Vanguard queued at the Tactical Armory.")

func _begin_build_mode(next_build_mode: String) -> void:
	if _selected_worker_count() == 0:
		mission_state = "Select at least one Survey Drone before placing a structure."
		return
	build_mode = next_build_mode
	attack_move_armed = false
	mission_state = "Place %s with selected Survey Drones." % _build_display_name(build_mode)

func _place_structure(cursor: Vector2) -> void:
	if not _is_valid_build_position(cursor):
		mission_state = "Invalid build site. Keep structures clear of resource nodes and other buildings."
		return
	var cost := _build_cost(build_mode)
	if not _can_afford(int(cost.get("credits", 0)), int(cost.get("alloy", 0)), 0):
		mission_state = "Insufficient resources for %s." % _build_display_name(build_mode)
		return
	_spend(int(cost.get("credits", 0)), int(cost.get("alloy", 0)), 0)
	var structure := Structure.new(
		"structure_%02d" % next_structure_id,
		build_mode,
		cursor,
		_build_max_hp(build_mode),
		_build_duration(build_mode),
		false
	)
	next_structure_id += 1
	structures.append(structure)
	for worker: Worker in workers:
		if worker.selected:
			worker.state = "build"
			worker.build_structure_id = structure.id
			worker.target = cursor
	build_mode = ""
	mission_state = "%s foundation placed. Builders are en route." % _build_display_name(structure.structure_type)
	_log_event("%s construction begun." % _build_display_name(structure.structure_type))

func _update_resource_nodes(delta: float) -> void:
	for node: ResourceNode in resource_nodes:
		node.pulse += delta

func _update_workers(delta: float) -> void:
	for worker: Worker in workers.duplicate():
		match worker.state:
			"to_resource":
				var node := _resource_node(worker.resource_node_index)
				if node == null or node.amount <= 0:
					worker.state = "idle"
					continue
				_move_worker(worker, node.pos, delta)
				if worker.pos.distance_to(node.pos) <= 22.0:
					worker.state = "harvest"
					worker.harvest_clock = 0.0
			"harvest":
				var harvest_node := _resource_node(worker.resource_node_index)
				if harvest_node == null or harvest_node.amount <= 0:
					worker.state = "idle"
					continue
				worker.harvest_clock += delta
				if worker.harvest_clock >= 1.1:
					var gathered := mini(10, harvest_node.amount)
					harvest_node.amount -= gathered
					worker.carried_resource = harvest_node.resource_id
					worker.carried_amount = gathered
					worker.state = "return"
					worker.target = NEXUS_POSITION
			"return":
				_move_worker(worker, NEXUS_POSITION, delta)
				if worker.pos.distance_to(NEXUS_POSITION) <= 58.0:
					_deposit_worker_cargo(worker)
					if _resource_node(worker.resource_node_index) != null and _resource_node(worker.resource_node_index).amount > 0:
						worker.state = "to_resource"
					else:
						worker.state = "idle"
			"build":
				var structure := _structure_by_id(worker.build_structure_id)
				if structure == null or structure.complete:
					worker.state = "idle"
					worker.build_structure_id = ""
					continue
				_move_worker(worker, structure.pos, delta)
				if worker.pos.distance_to(structure.pos) <= 36.0:
					structure.construction_progress += delta / structure.build_duration
					structure.hp = lerpf(structure.max_hp * 0.35, structure.max_hp, clampf(structure.construction_progress, 0.0, 1.0))
			"move":
				_move_worker(worker, worker.target, delta)
			_:
				pass

func _update_structures(delta: float) -> void:
	for structure: Structure in structures:
		structure.attack_cooldown = maxf(0.0, structure.attack_cooldown - delta)
		if not structure.complete and structure.construction_progress >= 1.0:
			structure.complete = true
			structure.hp = structure.max_hp
			if not structure.completion_announced:
				structure.completion_announced = true
				_on_structure_complete(structure)
		if structure.complete and structure.structure_type == "turret":
			var target := _closest_enemy(structure.pos)
			if target != null and structure.pos.distance_to(target.pos) <= 170.0 and structure.attack_cooldown <= 0.0:
				target.hp -= 18.0
				structure.attack_cooldown = 0.7
				if target.hp <= 0.0:
					_remove_enemy(target)

func _update_production(delta: float) -> void:
	_process_queue(nexus_queue, delta, NEXUS_POSITION + Vector2(58.0, 38.0))
	var armory := _first_complete_structure("armory")
	if armory != null:
		_process_queue(armory_queue, delta, armory.pos + Vector2(46.0, 30.0))

func _process_queue(queue: Array[Dictionary], delta: float, spawn_position: Vector2) -> void:
	if queue.is_empty():
		return
	var item: Dictionary = queue[0]
	item["remaining"] = float(item.get("remaining", 0.0)) - delta
	queue[0] = item
	if float(item.get("remaining", 0.0)) > 0.0:
		return
	queue.pop_front()
	var unit_type := String(item.get("unit_type", ""))
	match unit_type:
		"worker":
			_spawn_worker(spawn_position)
		"deputy":
			_spawn_combat_unit("deputy", spawn_position)
		"vanguard":
			_spawn_combat_unit("vanguard", spawn_position)

func _update_combat_units(delta: float) -> void:
	for unit: CombatUnit in combat_units.duplicate():
		unit.cooldown = maxf(0.0, unit.cooldown - delta)
		var targeted_enemy := _enemy_by_id(unit.target_enemy_id)
		var enemy := targeted_enemy if targeted_enemy != null else _closest_enemy(unit.pos)
		if enemy != null and unit.pos.distance_to(enemy.pos) <= unit.attack_range:
			if unit.cooldown <= 0.0:
				enemy.hp -= unit.damage
				unit.cooldown = unit.cooldown_duration
				if enemy.hp <= 0.0:
					_remove_enemy(enemy)
					unit.target_enemy_id = ""
		elif targeted_enemy != null:
			_move_combat_unit(unit, targeted_enemy.pos, delta)
		elif unit.order == "attack_move":
			var enemy_near_destination := _closest_enemy(unit.pos)
			if enemy_near_destination != null and unit.pos.distance_to(enemy_near_destination.pos) <= 220.0:
				_move_combat_unit(unit, enemy_near_destination.pos, delta)
			else:
				_move_combat_unit(unit, unit.target, delta)
		elif unit.order == "move":
			_move_combat_unit(unit, unit.target, delta)
		if unit.pos.distance_to(SYNDICATE_HIDEOUT_POSITION) <= unit.attack_range + 20.0 and enemy_units.is_empty():
			if unit.cooldown <= 0.0:
				syndicate_hideout_hp -= unit.damage
				unit.cooldown = unit.cooldown_duration

func _update_enemy_units(delta: float) -> void:
	for enemy: EnemyUnit in enemy_units.duplicate():
		if enemy.hp <= 0.0:
			_remove_enemy(enemy)
			continue
		enemy.cooldown = maxf(0.0, enemy.cooldown - delta)
		var target_unit := _closest_combat_unit(enemy.pos)
		var target_worker := _closest_worker(enemy.pos)
		var target_distance := INF
		var target_kind := "nexus"
		if target_unit != null:
			target_distance = enemy.pos.distance_to(target_unit.pos)
			target_kind = "combat"
		if target_worker != null and enemy.pos.distance_to(target_worker.pos) < target_distance:
			target_distance = enemy.pos.distance_to(target_worker.pos)
			target_kind = "worker"
		if target_kind == "combat" and target_unit != null:
			if target_distance <= enemy.attack_range:
				if enemy.cooldown <= 0.0:
					target_unit.hp -= enemy.damage
					enemy.cooldown = enemy.cooldown_duration
					if target_unit.hp <= 0.0:
						_remove_combat_unit(target_unit)
			else:
				_move_enemy(enemy, target_unit.pos, delta)
		elif target_kind == "worker" and target_worker != null:
			if target_distance <= enemy.attack_range:
				if enemy.cooldown <= 0.0:
					target_worker.hp -= enemy.damage
					enemy.cooldown = enemy.cooldown_duration
					if target_worker.hp <= 0.0:
						_remove_worker(target_worker)
			else:
				_move_enemy(enemy, target_worker.pos, delta)
		else:
			var nexus_distance := enemy.pos.distance_to(NEXUS_POSITION)
			if nexus_distance <= enemy.attack_range + 36.0:
				if enemy.cooldown <= 0.0:
					nexus_integrity -= enemy.damage
					enemy.cooldown = enemy.cooldown_duration
			else:
				_move_enemy(enemy, NEXUS_POSITION, delta)

func _spawn_enemy_wave() -> void:
	var elapsed_level := int(match_clock / 45.0)
	var count := 2 + elapsed_level
	for index: int in range(count):
		var spawn := SYNDICATE_HIDEOUT_POSITION + Vector2(rng.randf_range(-30.0, 30.0), rng.randf_range(45.0, 85.0))
		var is_bruiser := elapsed_level >= 2 and index % 3 == 0
		if is_bruiser:
			enemy_units.append(EnemyUnit.new("syn_%03d" % next_enemy_id, "bruiser", spawn, 150.0, 44.0, 72.0, 16.0, 1.0, Color("ff8f54")))
		else:
			enemy_units.append(EnemyUnit.new("syn_%03d" % next_enemy_id, "runner", spawn, 65.0, 62.0, 74.0, 9.0, 0.7, Color("ff5d92")))
		next_enemy_id += 1
	enemy_spawn_clock = maxf(7.0, 14.0 - float(elapsed_level) * 0.6)
	_log_event("Syndicate hideout dispatched %d raiders." % count)

func _spawn_worker(spawn_position: Vector2) -> void:
	var worker := Worker.new("SD-%02d" % next_worker_id, spawn_position)
	next_worker_id += 1
	workers.append(worker)
	_log_event("%s deployed. Assign it to Credits or Lunar Alloy." % worker.id)

func _spawn_combat_unit(unit_type: String, spawn_position: Vector2) -> void:
	var unit: CombatUnit
	if unit_type == "vanguard":
		unit = CombatUnit.new("RV-%02d" % next_unit_id, "vanguard", spawn_position, 240.0, 72.0, 70.0, 27.0, 0.9, VANGUARD_CAPACITY)
		_log_event("%s deployed from the Tactical Armory." % unit.id)
	else:
		unit = CombatUnit.new("PD-%02d" % next_unit_id, "deputy", spawn_position, 110.0, 105.0, 125.0, 16.0, 0.55, DEPUTY_CAPACITY)
		_log_event("%s deployed from the Command Nexus." % unit.id)
	next_unit_id += 1
	combat_units.append(unit)

func _on_structure_complete(structure: Structure) -> void:
	match structure.structure_type:
		"relay":
			command_max += 10
			_log_event("Communications Relay online. Command Capacity +10.")
		"armory":
			_log_event("Tactical Armory online. Riot Vanguard production unlocked.")
		"turret":
			_log_event("Security Turret online. It will engage nearby Syndicate units.")

func _select_single_at(cursor: Vector2) -> void:
	_clear_selection()
	var nearest_worker := _closest_worker(cursor)
	if nearest_worker != null and nearest_worker.pos.distance_to(cursor) <= 20.0:
		nearest_worker.selected = true
		mission_state = "%s selected. Right-click a resource node to gather." % nearest_worker.id
		return
	var nearest_unit := _closest_combat_unit(cursor)
	if nearest_unit != null and nearest_unit.pos.distance_to(cursor) <= 22.0:
		nearest_unit.selected = true
		mission_state = "%s selected. Right-click to move; press A, then right-click to attack-move." % nearest_unit.id
		return
	mission_state = "Select Survey Drones, combat units, or drag a box around a squad."

func _select_in_rectangle(selection_rect: Rect2) -> void:
	_clear_selection()
	var selected_count := 0
	for worker: Worker in workers:
		if selection_rect.has_point(worker.pos):
			worker.selected = true
			selected_count += 1
	for unit: CombatUnit in combat_units:
		if selection_rect.has_point(unit.pos):
			unit.selected = true
			selected_count += 1
	mission_state = "%d lunar units selected." % selected_count if selected_count > 0 else "No lunar units inside selection box."

func _clear_selection() -> void:
	for worker: Worker in workers:
		worker.selected = false
	for unit: CombatUnit in combat_units:
		unit.selected = false

func _assign_selected_workers_to_resource(resource_index: int) -> void:
	var node := _resource_node(resource_index)
	if node == null or node.amount <= 0:
		mission_state = "That resource node is depleted."
		return
	var assigned := 0
	for worker: Worker in workers:
		if worker.selected:
			worker.resource_node_index = resource_index
			worker.state = "to_resource"
			worker.target = node.pos
			assigned += 1
	if assigned > 0:
		mission_state = "%d Survey Drone(s) harvesting %s." % [assigned, _resource_display_name(node.resource_id)]

func _assign_selected_workers_to_nearest_resource(cursor: Vector2) -> void:
	var closest_index := -1
	var closest_distance := INF
	for index: int in range(resource_nodes.size()):
		var node: ResourceNode = resource_nodes[index]
		if node.amount <= 0:
			continue
		var distance := node.pos.distance_squared_to(cursor)
		if distance < closest_distance:
			closest_distance = distance
			closest_index = index
	if closest_index >= 0:
		_assign_selected_workers_to_resource(closest_index)

func _command_selected_combat(destination: Vector2, target_enemy_id: String, is_attack_move: bool) -> void:
	var formation_index := 0
	for unit: CombatUnit in combat_units:
		if unit.selected:
			var offset := Vector2(float((formation_index % 4) * 16 - 24), float((formation_index / 4) * 16 - 16))
			unit.target = destination + offset
			unit.target_enemy_id = target_enemy_id
			unit.order = "attack_move" if is_attack_move else "move"
			formation_index += 1
	if formation_index > 0:
		mission_state = "%d combat unit(s) ordered to %s." % [formation_index, "attack-move" if is_attack_move else "move"]

func _command_selected_workers_move(destination: Vector2) -> void:
	for worker: Worker in workers:
		if worker.selected and worker.state != "build":
			worker.state = "move"
			worker.target = destination

func _deposit_worker_cargo(worker: Worker) -> void:
	if worker.carried_amount <= 0:
		return
	if worker.carried_resource == "credits":
		credits += worker.carried_amount
	elif worker.carried_resource == "lunar_alloy":
		lunar_alloy += worker.carried_amount
	worker.carried_amount = 0
	worker.carried_resource = ""

func _move_worker(worker: Worker, destination: Vector2, delta: float) -> void:
	var difference := destination - worker.pos
	if difference.length() > 1.0:
		worker.pos += difference.normalized() * minf(95.0 * delta, difference.length())

func _move_combat_unit(unit: CombatUnit, destination: Vector2, delta: float) -> void:
	var difference := destination - unit.pos
	if difference.length() > 1.0:
		unit.pos += difference.normalized() * minf(unit.speed * delta, difference.length())

func _move_enemy(enemy: EnemyUnit, destination: Vector2, delta: float) -> void:
	var difference := destination - enemy.pos
	if difference.length() > 1.0:
		enemy.pos += difference.normalized() * minf(enemy.speed * delta, difference.length())

func _can_afford(required_credits: int, required_alloy: int, required_capacity: int) -> bool:
	return credits >= required_credits and lunar_alloy >= required_alloy and command_used + required_capacity <= command_max

func _spend(credit_cost: int, alloy_cost: int, capacity_cost: int) -> void:
	credits -= credit_cost
	lunar_alloy -= alloy_cost
	command_used += capacity_cost

func _build_cost(structure_type: String) -> Dictionary:
	match structure_type:
		"relay":
			return {"credits": RELAY_COST_CREDITS, "alloy": RELAY_COST_ALLOY}
		"armory":
			return {"credits": ARMORY_COST_CREDITS, "alloy": ARMORY_COST_ALLOY}
		"turret":
			return {"credits": TURRET_COST_CREDITS, "alloy": TURRET_COST_ALLOY}
		_:
			return {"credits": 0, "alloy": 0}

func _build_max_hp(structure_type: String) -> float:
	match structure_type:
		"relay":
			return 800.0
		"armory":
			return 1100.0
		"turret":
			return 600.0
		_:
			return 500.0

func _build_duration(structure_type: String) -> float:
	match structure_type:
		"relay":
			return 7.0
		"armory":
			return 10.0
		"turret":
			return 6.0
		_:
			return 5.0

func _build_display_name(structure_type: String) -> String:
	match structure_type:
		"relay":
			return "Communications Relay"
		"armory":
			return "Tactical Armory"
		"turret":
			return "Security Turret"
		_:
			return structure_type.capitalize()

func _resource_display_name(resource_id: String) -> String:
	return "Credits" if resource_id == "credits" else "Lunar Alloy"

func _is_valid_build_position(cursor: Vector2) -> bool:
	if not FIELD.grow(-24.0).has_point(cursor):
		return false
	if cursor.distance_to(NEXUS_POSITION) < 94.0 or cursor.distance_to(SYNDICATE_HIDEOUT_POSITION) < 110.0:
		return false
	for node: ResourceNode in resource_nodes:
		if cursor.distance_to(node.pos) < 56.0:
			return false
	for structure: Structure in structures:
		if cursor.distance_to(structure.pos) < 62.0:
			return false
	return true

func _resource_at(cursor: Vector2) -> int:
	for index: int in range(resource_nodes.size()):
		var node: ResourceNode = resource_nodes[index]
		if cursor.distance_to(node.pos) <= 30.0:
			return index
	return -1

func _enemy_at(cursor: Vector2) -> EnemyUnit:
	for enemy: EnemyUnit in enemy_units:
		if enemy.pos.distance_to(cursor) <= 24.0:
			return enemy
	return null

func _resource_node(index: int) -> ResourceNode:
	if index < 0 or index >= resource_nodes.size():
		return null
	return resource_nodes[index]

func _structure_by_id(structure_id: String) -> Structure:
	for structure: Structure in structures:
		if structure.id == structure_id:
			return structure
	return null

func _first_complete_structure(structure_type: String) -> Structure:
	for structure: Structure in structures:
		if structure.structure_type == structure_type and structure.complete:
			return structure
	return null

func _has_complete_structure(structure_type: String) -> bool:
	return _first_complete_structure(structure_type) != null

func _closest_enemy(origin: Vector2) -> EnemyUnit:
	var result: EnemyUnit = null
	var closest_distance := INF
	for enemy: EnemyUnit in enemy_units:
		var distance := origin.distance_squared_to(enemy.pos)
		if distance < closest_distance:
			closest_distance = distance
			result = enemy
	return result

func _enemy_by_id(enemy_id: String) -> EnemyUnit:
	if enemy_id.is_empty():
		return null
	for enemy: EnemyUnit in enemy_units:
		if enemy.id == enemy_id:
			return enemy
	return null

func _closest_worker(origin: Vector2) -> Worker:
	var result: Worker = null
	var closest_distance := INF
	for worker: Worker in workers:
		var distance := origin.distance_squared_to(worker.pos)
		if distance < closest_distance:
			closest_distance = distance
			result = worker
	return result

func _closest_combat_unit(origin: Vector2) -> CombatUnit:
	var result: CombatUnit = null
	var closest_distance := INF
	for unit: CombatUnit in combat_units:
		var distance := origin.distance_squared_to(unit.pos)
		if distance < closest_distance:
			closest_distance = distance
			result = unit
	return result

func _selected_worker_count() -> int:
	var count := 0
	for worker: Worker in workers:
		if worker.selected:
			count += 1
	return count

func _remove_enemy(enemy: EnemyUnit) -> void:
	if not enemy_units.has(enemy):
		return
	enemy_units.erase(enemy)
	credits += 6
	intel += 1
	_log_event("Syndicate %s neutralized. +6 Credits, +1 Intel." % enemy.unit_type)

func _remove_worker(worker: Worker) -> void:
	if workers.has(worker):
		workers.erase(worker)
		command_used = maxi(0, command_used - WORKER_CAPACITY)
		_log_event("%s destroyed. Command Capacity released." % worker.id)

func _remove_combat_unit(unit: CombatUnit) -> void:
	if combat_units.has(unit):
		combat_units.erase(unit)
		command_used = maxi(0, command_used - unit.command_cost)
		_log_event("%s lost in combat. Command Capacity released." % unit.id)

func _log_event(entry: String) -> void:
	battle_log.push_front(entry)
	if battle_log.size() > 5:
		battle_log.pop_back()

func _reset_match() -> void:
	workers.clear()
	combat_units.clear()
	enemy_units.clear()
	structures.clear()
	resource_nodes.clear()
	battle_log.clear()
	credits = 180
	lunar_alloy = 0
	intel = 0
	command_used = 0
	command_max = 14
	nexus_integrity = 1500.0
	syndicate_hideout_hp = 1600.0
	enemy_spawn_clock = 9.0
	match_clock = 0.0
	next_worker_id = 4
	next_unit_id = 3
	next_enemy_id = 1
	next_structure_id = 1
	build_mode = ""
	attack_move_armed = false
	game_over = false
	victory = false
	mission_state = "Establish a lunar economy, build an army, and dismantle the Syndicate hideout."
	nexus_queue.clear()
	armory_queue.clear()
	_spawn_worker(NEXUS_POSITION + Vector2(-48.0, 38.0))
	_spawn_worker(NEXUS_POSITION + Vector2(-20.0, 52.0))
	_spawn_worker(NEXUS_POSITION + Vector2(12.0, 46.0))
	_spawn_combat_unit("deputy", NEXUS_POSITION + Vector2(42.0, -30.0))
	_spawn_combat_unit("deputy", NEXUS_POSITION + Vector2(64.0, -4.0))
	resource_nodes.append(ResourceNode.new(Vector2(275.0, 225.0), "credits", 420))
	resource_nodes.append(ResourceNode.new(Vector2(355.0, 570.0), "credits", 420))
	resource_nodes.append(ResourceNode.new(Vector2(590.0, 185.0), "credits", 360))
	resource_nodes.append(ResourceNode.new(Vector2(190.0, 470.0), "lunar_alloy", 260))
	resource_nodes.append(ResourceNode.new(Vector2(650.0, 590.0), "lunar_alloy", 260))
	resource_nodes.append(ResourceNode.new(Vector2(720.0, 330.0), "lunar_alloy", 220))
	_log_event("Command Nexus deployed. Survey Drones ready for assignment.")
	_log_event("Syndicate Hideout detected at the northern crater rim.")
	queue_redraw()

func _build_backdrop() -> void:
	star_positions.clear()
	crater_positions.clear()
	crater_radii.clear()
	for _index: int in range(48):
		star_positions.append(Vector2(rng.randf_range(0.0, VIEWPORT_SIZE.x), rng.randf_range(0.0, 88.0)))
	for _index: int in range(34):
		crater_positions.append(Vector2(rng.randf_range(FIELD.position.x + 12.0, FIELD.end.x - 12.0), rng.randf_range(FIELD.position.y + 12.0, FIELD.end.y - 12.0)))
		crater_radii.append(rng.randf_range(10.0, 34.0))

func _draw() -> void:
	_draw_space()
	_draw_field()
	_draw_world()
	_draw_sidebar()
	_draw_banner()
	if is_dragging:
		_draw_selection_box()
	if game_over or victory:
		_draw_end_overlay()

func _draw_space() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("06101c"))
	draw_rect(Rect2(0.0, 0.0, VIEWPORT_SIZE.x, 92.0), Color("0b1a31"))
	for star: Vector2 in star_positions:
		draw_circle(star, 1.2, Color("a7caff", 0.72))

func _draw_field() -> void:
	draw_style_box(_panel_style(Color("162736"), Color("385c78"), 2, 14), FIELD)
	draw_rect(FIELD.grow(-3.0), Color("1c2b36"))
	for index: int in range(crater_positions.size()):
		var crater_position: Vector2 = crater_positions[index]
		var radius: float = crater_radii[index]
		draw_circle(crater_position, radius, Color("0b151e", 0.50))
		draw_arc(crater_position, radius * 0.78, 0.0, TAU, 24, Color("5d6e77", 0.20), 1.0)
	for x: float in range(FIELD.position.x + 24.0, FIELD.end.x, 48.0):
		draw_line(Vector2(x, FIELD.position.y + 8.0), Vector2(x, FIELD.end.y - 8.0), Color("72a4b7", 0.06), 1.0)
	for y: float in range(FIELD.position.y + 24.0, FIELD.end.y, 48.0):
		draw_line(Vector2(FIELD.position.x + 8.0, y), Vector2(FIELD.end.x - 8.0, y), Color("72a4b7", 0.06), 1.0)

func _draw_world() -> void:
	_draw_syndicate_hideout()
	_draw_command_nexus()
	for node: ResourceNode in resource_nodes:
		_draw_resource_node(node)
	for structure: Structure in structures:
		_draw_structure(structure)
	for enemy: EnemyUnit in enemy_units:
		_draw_enemy(enemy)
	for worker: Worker in workers:
		_draw_worker(worker)
	for unit: CombatUnit in combat_units:
		_draw_combat_unit(unit)
	if not build_mode.is_empty():
		_draw_build_ghost()

func _draw_command_nexus() -> void:
	var nexus_color := Color("62e7ff")
	draw_circle(NEXUS_POSITION, 58.0, Color(nexus_color, 0.13))
	draw_circle(NEXUS_POSITION, 48.0, Color("0c2031"))
	for angle: float in [0.0, PI * 0.5, PI, PI * 1.5]:
		var endpoint := NEXUS_POSITION + Vector2(cos(angle), sin(angle)) * 39.0
		draw_line(NEXUS_POSITION, endpoint, Color(nexus_color, 0.75), 5.0)
	draw_circle(NEXUS_POSITION, 21.0, nexus_color)
	draw_circle(NEXUS_POSITION, 10.0, Color("ecffff"))
	_draw_health_bar(NEXUS_POSITION + Vector2(-34.0, -74.0), nexus_integrity / 1500.0, Color("75f2bd"), 68.0)
	draw_string(ThemeDB.fallback_font, NEXUS_POSITION + Vector2(-62.0, 83.0), "COMMAND NEXUS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SMALL, Color("cbeeff"))

func _draw_syndicate_hideout() -> void:
	var color := Color("ff6f92")
	draw_circle(SYNDICATE_HIDEOUT_POSITION, 58.0, Color(color, 0.13))
	draw_circle(SYNDICATE_HIDEOUT_POSITION, 44.0, Color("38172a"))
	draw_rect(Rect2(SYNDICATE_HIDEOUT_POSITION - Vector2(29.0, 21.0), Vector2(58.0, 42.0)), Color("762743"))
	draw_line(SYNDICATE_HIDEOUT_POSITION + Vector2(-38.0, -30.0), SYNDICATE_HIDEOUT_POSITION + Vector2(38.0, 30.0), color, 4.0)
	draw_line(SYNDICATE_HIDEOUT_POSITION + Vector2(-38.0, 30.0), SYNDICATE_HIDEOUT_POSITION + Vector2(38.0, -30.0), color, 4.0)
	_draw_health_bar(SYNDICATE_HIDEOUT_POSITION + Vector2(-36.0, -70.0), syndicate_hideout_hp / 1600.0, color, 72.0)
	draw_string(ThemeDB.fallback_font, SYNDICATE_HIDEOUT_POSITION + Vector2(-66.0, 79.0), "SYNDICATE HIDEOUT", HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SMALL, Color("ffd6df"))

func _draw_resource_node(node: ResourceNode) -> void:
	if node.amount <= 0:
		draw_circle(node.pos, 19.0, Color("26333a"))
		draw_string(ThemeDB.fallback_font, node.pos + Vector2(-28.0, 39.0), "DEPLETED", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("8ca0a9"))
		return
	var color := Color("ffd46e") if node.resource_id == "credits" else Color("ad95ff")
	var radius := 19.0 + sin(node.pulse * 3.0) * 1.5
	draw_circle(node.pos, radius + 8.0, Color(color, 0.10))
	draw_circle(node.pos, radius, color.darkened(0.43))
	draw_polygon(PackedVector2Array([node.pos + Vector2(0.0, -15.0), node.pos + Vector2(15.0, 2.0), node.pos + Vector2(2.0, 16.0), node.pos + Vector2(-14.0, 5.0)]), PackedColorArray([color]))
	var amount_label := "%s %d" % ["C" if node.resource_id == "credits" else "A", node.amount]
	draw_string(ThemeDB.fallback_font, node.pos + Vector2(-28.0, 41.0), amount_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, color)

func _draw_structure(structure: Structure) -> void:
	var color := Color("8edcff")
	match structure.structure_type:
		"relay":
			color = Color("91a4ff")
		"armory":
			color = Color("7ef5d0")
		"turret":
			color = Color("ffdd75")
	var alpha := 1.0 if structure.complete else 0.55
	if structure.structure_type == "relay":
		draw_circle(structure.pos, 25.0, Color(color, 0.12 * alpha))
		draw_rect(Rect2(structure.pos - Vector2(12.0, 12.0), Vector2(24.0, 24.0)), Color(color, alpha), true)
		draw_line(structure.pos + Vector2(-24.0, 0.0), structure.pos + Vector2(24.0, 0.0), Color(color, alpha), 2.0)
	elif structure.structure_type == "armory":
		draw_rect(Rect2(structure.pos - Vector2(28.0, 20.0), Vector2(56.0, 40.0)), Color(color.darkened(0.45), alpha), true)
		draw_rect(Rect2(structure.pos - Vector2(22.0, 14.0), Vector2(44.0, 18.0)), Color(color, alpha), true)
		draw_line(structure.pos + Vector2(-34.0, 23.0), structure.pos + Vector2(34.0, 23.0), Color(color, alpha), 2.0)
	else:
		draw_circle(structure.pos, 19.0, Color(color.darkened(0.45), alpha))
		draw_line(structure.pos, structure.pos + Vector2(28.0, -18.0), Color(color, alpha), 5.0)
	_draw_health_bar(structure.pos + Vector2(-25.0, -38.0), structure.hp / structure.max_hp, color, 50.0)
	if not structure.complete:
		draw_rect(Rect2(structure.pos + Vector2(-25.0, 31.0), Vector2(50.0, 4.0)), Color("081119"))
		draw_rect(Rect2(structure.pos + Vector2(-24.0, 32.0), Vector2(48.0 * clampf(structure.construction_progress, 0.0, 1.0), 2.0)), color)
	draw_string(ThemeDB.fallback_font, structure.pos + Vector2(-42.0, 51.0), _build_display_name(structure.structure_type), HORIZONTAL_ALIGNMENT_LEFT, 86.0, 10, Color("d3ecfb"))

func _draw_worker(worker: Worker) -> void:
	if worker.selected:
		draw_arc(worker.pos, 19.0, 0.0, TAU, 20, Color("9aefff"), 2.0)
	draw_circle(worker.pos, 13.0, Color("285069"))
	draw_circle(worker.pos, 8.0, Color("bdefff"))
	draw_line(worker.pos + Vector2(-6.0, 5.0), worker.pos + Vector2(8.0, -8.0), Color("6ce9ff"), 2.0)
	if worker.carried_amount > 0:
		var cargo_color := Color("ffd46e") if worker.carried_resource == "credits" else Color("ad95ff")
		draw_circle(worker.pos + Vector2(11.0, 10.0), 5.0, cargo_color)
	_draw_health_bar(worker.pos + Vector2(-14.0, -22.0), worker.hp / 55.0, Color("76f2c0"), 28.0)
	draw_string(ThemeDB.fallback_font, worker.pos + Vector2(-15.0, 29.0), worker.id, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, Color("cff5ff"))

func _draw_combat_unit(unit: CombatUnit) -> void:
	var body_color := Color("68e4ff") if unit.unit_type == "deputy" else Color("7ef5d0")
	if unit.selected:
		draw_arc(unit.pos, 22.0, 0.0, TAU, 20, Color("e5ffff"), 2.0)
	if unit.unit_type == "vanguard":
		draw_rect(Rect2(unit.pos - Vector2(14.0, 14.0), Vector2(28.0, 28.0)), body_color.darkened(0.30), true)
		draw_line(unit.pos + Vector2(-10.0, -2.0), unit.pos + Vector2(13.0, -2.0), body_color, 4.0)
	else:
		draw_circle(unit.pos, 14.0, Color("254d74"))
		draw_circle(unit.pos, 9.0, body_color)
		draw_line(unit.pos + Vector2(-5.0, 2.0), unit.pos + Vector2(14.0, -7.0), Color("ecffff"), 2.6)
	_draw_health_bar(unit.pos + Vector2(-17.0, -27.0), unit.hp / unit.max_hp, Color("75f2bd"), 34.0)
	draw_string(ThemeDB.fallback_font, unit.pos + Vector2(-18.0, 31.0), unit.id, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("d8f7ff"))

func _draw_enemy(enemy: EnemyUnit) -> void:
	draw_circle(enemy.pos, 15.0, Color(enemy.tint, 0.18))
	if enemy.unit_type == "bruiser":
		draw_rect(Rect2(enemy.pos - Vector2(13.0, 13.0), Vector2(26.0, 26.0)), enemy.tint.darkened(0.35), true)
		draw_line(enemy.pos + Vector2(-10.0, 0.0), enemy.pos + Vector2(14.0, 0.0), enemy.tint, 4.0)
	else:
		draw_circle(enemy.pos, 10.0, enemy.tint.darkened(0.25))
		draw_line(enemy.pos + Vector2(-7.0, -6.0), enemy.pos + Vector2(8.0, 6.0), Color("fff0f4"), 2.0)
	_draw_health_bar(enemy.pos + Vector2(-15.0, -23.0), enemy.hp / enemy.max_hp, enemy.tint, 30.0)

func _draw_build_ghost() -> void:
	var cursor := get_global_mouse_position()
	if not FIELD.has_point(cursor):
		return
	var valid := _is_valid_build_position(cursor)
	var color := Color("7ef5d0") if valid else Color("ff7892")
	draw_circle(cursor, 32.0, Color(color, 0.12))
	draw_arc(cursor, 32.0, 0.0, TAU, 28, color, 1.5)
	draw_string(ThemeDB.fallback_font, cursor + Vector2(-48.0, -42.0), "PLACE %s" % _build_display_name(build_mode).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 100.0, 10, color)

func _draw_selection_box() -> void:
	var selection_rect := Rect2(drag_start, drag_current - drag_start).abs()
	draw_rect(selection_rect, Color("99efff", 0.12), true)
	draw_rect(selection_rect, Color("99efff", 0.86), false, 1.5)

func _draw_sidebar() -> void:
	draw_style_box(_panel_style(Color("102038"), Color("365d7d"), 2, 14), SIDEBAR)
	draw_string(ThemeDB.fallback_font, Vector2(994.0, 52.0), "LUNAR RTS COMMAND", HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_MEDIUM, Color("a9e2ff"))
	draw_string(ThemeDB.fallback_font, Vector2(994.0, 74.0), "BUILD // HARVEST // PRODUCE // STRIKE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color("7899b6"))
	_draw_stat_card(Rect2(994.0, 91.0, 118.0, 62.0), "CREDITS", str(credits), Color("ffd36f"))
	_draw_stat_card(Rect2(1124.0, 91.0, 118.0, 62.0), "LUNAR ALLOY", str(lunar_alloy), Color("b29bff"))
	_draw_stat_card(Rect2(994.0, 164.0, 118.0, 62.0), "CAPACITY", "%d/%d" % [command_used, command_max], Color("7ef5d0"))
	_draw_stat_card(Rect2(1124.0, 164.0, 118.0, 62.0), "INTEL", str(intel), Color("7ee7ff"))
	draw_string(ThemeDB.fallback_font, Vector2(994.0, 250.0), "PRODUCTION", HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SMALL, Color("a2bfd6"))
	draw_string(ThemeDB.fallback_font, Vector2(994.0, 270.0), _queue_status(), HORIZONTAL_ALIGNMENT_LEFT, 248.0, 11, Color("d1e1ed"))
	draw_string(ThemeDB.fallback_font, Vector2(994.0, 298.0), "BUILD / TRAIN ACTIONS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SMALL, Color("a2bfd6"))
	_draw_action_button(train_worker_button, "Q  TRAIN SURVEY DRONE", "%d Credits // 1 Capacity" % WORKER_COST_CREDITS, false)
	_draw_action_button(train_deputy_button, "W  TRAIN PATROL DEPUTY", "%d Credits // 1 Capacity" % DEPUTY_COST_CREDITS, false)
	_draw_action_button(build_relay_button, "E  BUILD COMMS RELAY", "%d Credits / %d Alloy // +10 Capacity" % [RELAY_COST_CREDITS, RELAY_COST_ALLOY], build_mode == "relay")
	_draw_action_button(build_armory_button, "R  BUILD TACTICAL ARMORY", "%d Credits / %d Alloy // unlocks Vanguard" % [ARMORY_COST_CREDITS, ARMORY_COST_ALLOY], build_mode == "armory")
	var vanguard_detail := "%d Credits / %d Alloy // 2 Capacity" % [VANGUARD_COST_CREDITS, VANGUARD_COST_ALLOY]
	if not _has_complete_structure("armory"):
		vanguard_detail = "Requires completed Tactical Armory"
	_draw_action_button(train_vanguard_button, "F  TRAIN RIOT VANGUARD", vanguard_detail, false)
	_draw_action_button(build_turret_button, "T  BUILD SECURITY TURRET", "%d Credits / %d Alloy" % [TURRET_COST_CREDITS, TURRET_COST_ALLOY], build_mode == "turret")
	if game_over or victory:
		_draw_action_button(restart_button, "REDEPLOY RTS MATCH", "Start a fresh lunar operation", false)
	else:
		draw_string(ThemeDB.fallback_font, Vector2(994.0, 638.0), "A: attack-move   G: gather nearest resource   B: cancel build", HORIZONTAL_ALIGNMENT_LEFT, 248.0, 10, Color("7e9eb7"))
		draw_string(ThemeDB.fallback_font, Vector2(994.0, 664.0), "Enemy wave in %0.0fs // Left-drag: squad selection" % enemy_spawn_clock, HORIZONTAL_ALIGNMENT_LEFT, 248.0, 10, Color("8fb0c7"))

func _queue_status() -> String:
	var nexus_text := "Nexus idle" if nexus_queue.is_empty() else "Nexus: %s %0.1fs" % [String(nexus_queue[0].get("unit_type", "")), float(nexus_queue[0].get("remaining", 0.0))]
	var armory_text := "Armory idle" if armory_queue.is_empty() else "Armory: %s %0.1fs" % [String(armory_queue[0].get("unit_type", "")), float(armory_queue[0].get("remaining", 0.0))]
	return "%s // %s" % [nexus_text, armory_text]

func _draw_stat_card(rect: Rect2, label: String, value: String, color: Color) -> void:
	draw_style_box(_panel_style(Color("142940"), Color(color, 0.36), 1, 8), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(9.0, 20.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("a5bfce"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(9.0, 49.0), value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 23, color)

func _draw_action_button(rect: Rect2, title: String, detail: String, active: bool) -> void:
	var fill := Color("1b5261") if active else Color("162f4b")
	var border := Color("7ef5d0") if active else Color("4f80a8")
	draw_style_box(_panel_style(fill, border, 2, 8), rect)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(11.0, 18.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("ecf8ff"))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(11.0, 34.0), detail, HORIZONTAL_ALIGNMENT_LEFT, 226.0, 10, Color("aec7d8"))

func _draw_banner() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(22.0, 42.0), "MOONGOONS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_LARGE, Color("e4f7ff"))
	draw_string(ThemeDB.fallback_font, Vector2(22.0, 66.0), "TAKE BACK // REAL-TIME LUNAR SKIRMISH", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color("7eb9db"))
	draw_string(ThemeDB.fallback_font, Vector2(372.0, 38.0), "MISSION STATUS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color("83a7c1"))
	draw_string(ThemeDB.fallback_font, Vector2(372.0, 62.0), mission_state, HORIZONTAL_ALIGNMENT_LEFT, 565.0, 15, Color("dcecf9"))

func _draw_end_overlay() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEWPORT_SIZE), Color("020812", 0.78))
	var title := "DISTRICT SECURED" if victory else "COMMAND NEXUS LOST"
	var color := Color("7ef5d0") if victory else Color("ff7892")
	draw_style_box(_panel_style(Color("10283d"), color, 3, 16), Rect2(240.0, 220.0, 690.0, 260.0))
	draw_string(ThemeDB.fallback_font, Vector2(320.0, 306.0), title, HORIZONTAL_ALIGNMENT_CENTER, 530.0, 40, color)
	draw_string(ThemeDB.fallback_font, Vector2(315.0, 348.0), mission_state, HORIZONTAL_ALIGNMENT_CENTER, 540.0, 16, Color("edf8ff"))
	draw_string(ThemeDB.fallback_font, Vector2(315.0, 390.0), "Workers: %d     Army: %d     Intel: %d     Capacity: %d/%d" % [workers.size(), combat_units.size(), intel, command_used, command_max], HORIZONTAL_ALIGNMENT_CENTER, 540.0, 15, Color("b7d2e5"))
	draw_string(ThemeDB.fallback_font, Vector2(315.0, 432.0), "Use REDEPLOY RTS MATCH to build a new lunar war machine.", HORIZONTAL_ALIGNMENT_CENTER, 540.0, 15, Color("8db1c7"))

func _draw_health_bar(top_left: Vector2, fraction: float, color: Color, width: float) -> void:
	draw_rect(Rect2(top_left, Vector2(width, 4.0)), Color("071119"))
	draw_rect(Rect2(top_left + Vector2(1.0, 1.0), Vector2((width - 2.0) * clampf(fraction, 0.0, 1.0), 2.0)), color)

func _panel_style(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	return box
