extends Control
## Non-interactive orbital station frame shared by browser, desktop, and Android.
## It turns the play field into a command-deck schematic with bulkheads, deck
## plating, viewport glass, conduits, airlocks, and station-life-support readouts.

var animation_clock: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	animation_clock += delta
	queue_redraw()

func _draw() -> void:
	var viewport_size: Vector2 = size
	if viewport_size.x < 2.0 or viewport_size.y < 2.0:
		viewport_size = get_viewport_rect().size
	_draw_command_deck(viewport_size)
	_draw_bulkheads(viewport_size)
	_draw_viewports(viewport_size)
	_draw_status_readouts(viewport_size)
	_draw_airlock_markers(viewport_size)

func _draw_command_deck(viewport_size: Vector2) -> void:
	var deck := Rect2(18.0, 146.0, viewport_size.x - 36.0, viewport_size.y - 174.0)
	draw_rect(deck, Color(0.015, 0.04, 0.06, 0.10), true)
	draw_rect(deck, Color("#416B80", 0.72), false, 2.0)
	# Pressure-deck grid and illuminated service conduits.
	var grid_step: float = 52.0
	var x: float = deck.position.x + grid_step
	while x < deck.end.x:
		draw_line(Vector2(x, deck.position.y), Vector2(x, deck.end.y), Color(0.26, 0.55, 0.67, 0.10), 1.0)
		x += grid_step
	var y: float = deck.position.y + grid_step
	while y < deck.end.y:
		draw_line(Vector2(deck.position.x, y), Vector2(deck.end.x, y), Color(0.26, 0.55, 0.67, 0.10), 1.0)
		y += grid_step
	var pulse: float = 0.35 + 0.20 * sin(animation_clock * 1.8)
	draw_line(Vector2(deck.position.x + 26.0, deck.end.y - 18.0), Vector2(deck.end.x - 26.0, deck.end.y - 18.0), Color(0.35, 0.90, 1.0, pulse), 3.0)
	# Central station power bus, intentionally subtle beneath the module view.
	var core := Vector2(deck.get_center().x, deck.get_center().y + 10.0)
	for radius: float in [54.0, 68.0, 82.0]:
		draw_arc(core, radius, 0.0, TAU, 64, Color(0.35, 0.88, 1.0, 0.08 + pulse * 0.08), 2.0)
	for angle_index: int in range(8):
		var angle: float = TAU * float(angle_index) / 8.0
		draw_line(core + Vector2(cos(angle), sin(angle)) * 42.0, core + Vector2(cos(angle), sin(angle)) * 92.0, Color(0.36, 0.80, 0.92, 0.10), 2.0)

func _draw_bulkheads(viewport_size: Vector2) -> void:
	var hull_color := Color("#172A36", 0.96)
	var trim_color := Color("#52798C", 0.92)
	# Port and starboard armored frame.
	draw_rect(Rect2(0.0, 140.0, 18.0, viewport_size.y - 140.0), hull_color, true)
	draw_rect(Rect2(viewport_size.x - 18.0, 140.0, 18.0, viewport_size.y - 140.0), hull_color, true)
	draw_line(Vector2(18.0, 140.0), Vector2(18.0, viewport_size.y), trim_color, 2.0)
	draw_line(Vector2(viewport_size.x - 18.0, 140.0), Vector2(viewport_size.x - 18.0, viewport_size.y), trim_color, 2.0)
	# Upper and lower pressure beams.
	draw_rect(Rect2(0.0, 140.0, viewport_size.x, 11.0), hull_color, true)
	draw_rect(Rect2(0.0, viewport_size.y - 28.0, viewport_size.x, 28.0), hull_color, true)
	draw_line(Vector2(0.0, 151.0), Vector2(viewport_size.x, 151.0), Color("#67E7FF", 0.55), 2.0)
	draw_line(Vector2(0.0, viewport_size.y - 28.0), Vector2(viewport_size.x, viewport_size.y - 28.0), Color("#67E7FF", 0.45), 2.0)
	# Rivets and pressure-lock clamps.
	for index: int in range(18):
		var rivet_x: float = 20.0 + float(index) * maxf(38.0, (viewport_size.x - 40.0) / 18.0)
		draw_circle(Vector2(rivet_x, 145.0), 2.3, Color("#9DB5C0"))
		draw_circle(Vector2(rivet_x, viewport_size.y - 14.0), 2.3, Color("#728D99"))
	for side_x: float in [9.0, viewport_size.x - 9.0]:
		for index: int in range(8):
			var clamp_y: float = 176.0 + float(index) * maxf(48.0, (viewport_size.y - 230.0) / 8.0)
			draw_rect(Rect2(side_x - 4.0, clamp_y, 8.0, 20.0), Color("#456273"), true)

func _draw_viewports(viewport_size: Vector2) -> void:
	# Narrow observation ports above the command deck prove the precinct is inside a station.
	var port_width: float = minf(250.0, viewport_size.x * 0.22)
	for left_side: bool in [true, false]:
		var x: float = 20.0 if left_side else viewport_size.x - port_width - 20.0
		var rect := Rect2(x, 10.0, port_width, 70.0)
		draw_rect(rect, Color("#020711"), true)
		draw_rect(rect, Color("#507A90"), false, 3.0)
		for star_index: int in range(18):
			var star_x: float = rect.position.x + 8.0 + fmod(float(star_index * 37 + (3 if left_side else 19)), rect.size.x - 16.0)
			var star_y: float = rect.position.y + 8.0 + fmod(float(star_index * 23 + 7), rect.size.y - 16.0)
			var blink: float = 0.45 + 0.40 * sin(animation_clock * 1.2 + float(star_index))
			draw_circle(Vector2(star_x, star_y), 0.8 + float(star_index % 3) * 0.35, Color(0.75, 0.91, 1.0, blink))
		# Passing moon/planet horizon in the starboard observation port.
		if not left_side:
			draw_arc(Vector2(rect.end.x - 18.0, rect.end.y + 22.0), 76.0, PI, TAU, 48, Color("#728AA3", 0.55), 10.0)
	# Station identification plate.
	var title_rect := Rect2(viewport_size.x * 0.5 - 250.0, 13.0, 500.0, 60.0)
	draw_rect(title_rect, Color("#071722", 0.96), true)
	draw_rect(title_rect, Color("#67E7FF", 0.82), false, 2.0)
	draw_string(ThemeDB.fallback_font, title_rect.position + Vector2(8.0, 24.0), "MOONGOONS TAKE BACK", HORIZONTAL_ALIGNMENT_CENTER, title_rect.size.x - 16.0, 18, Color("#EAFBFF"))
	draw_string(ThemeDB.fallback_font, title_rect.position + Vector2(8.0, 47.0), "ORBITAL PEACEKEEPER STATION // COMMAND DECK 07", HORIZONTAL_ALIGNMENT_CENTER, title_rect.size.x - 16.0, 11, Color("#79DFF5"))

func _draw_status_readouts(viewport_size: Vector2) -> void:
	var level: int = 1
	var credits: int = 0
	if is_instance_valid(StationProgression):
		level = int(StationProgression.station_level)
	if is_instance_valid(PrecinctState):
		credits = int(PrecinctState.credits)
	var status: String = "HULL: NOMINAL   O2: 100%%   GRAVITY: 0.92G   REACTOR: STABLE   STATION LEVEL: %d   CREDITS: %d" % [level, credits]
	draw_string(ThemeDB.fallback_font, Vector2(22.0, viewport_size.y - 9.0), status, HORIZONTAL_ALIGNMENT_LEFT, viewport_size.x - 44.0, 10, Color("#9FEAF6"))
	var pulse: float = 0.50 + 0.45 * sin(animation_clock * 2.4)
	draw_circle(Vector2(viewport_size.x - 30.0, viewport_size.y - 14.0), 4.0, Color(0.30, 1.0, 0.72, pulse))

func _draw_airlock_markers(viewport_size: Vector2) -> void:
	var y_center: float = viewport_size.y * 0.58
	for side: int in [-1, 1]:
		var x: float = 18.0 if side < 0 else viewport_size.x - 18.0
		var direction: float = 1.0 if side < 0 else -1.0
		var points := PackedVector2Array([
			Vector2(x, y_center - 34.0),
			Vector2(x + direction * 24.0, y_center - 20.0),
			Vector2(x + direction * 24.0, y_center + 20.0),
			Vector2(x, y_center + 34.0)
		])
		draw_polyline(points, Color("#67E7FF", 0.72), 3.0)
		var label: String = "PORT AIRLOCK" if side < 0 else "STARBOARD AIRLOCK"
		var label_x: float = 28.0 if side < 0 else viewport_size.x - 168.0
		draw_string(ThemeDB.fallback_font, Vector2(label_x, y_center - 42.0), label, HORIZONTAL_ALIGNMENT_LEFT, 140.0, 9, Color("#7FCFE0"))
