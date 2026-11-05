@tool
## Reusable full-screen celebration view providing festive fireworks starbursts, rainbow confetti cannons, and fluttering confetti rain.
class_name CelebrationView
extends Control

var _active_particles: Array[Node] = []
var _active_tweens: Array[Tween] = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Launches celebratory fireworks and confetti across the view.
func start_celebration(with_fireworks: bool = true, with_cannons: bool = true, with_rain: bool = true) -> void:
	clear()
	if not is_inside_tree() or Engine.is_editor_hint():
		return

	if with_rain:
		_spawn_confetti_rain()

	if with_cannons:
		_spawn_confetti_cannons()

	if with_fireworks:
		_trigger_firework_sequence()


## Stops particle emission and cleans up celebration effects after existing particles finish falling.
func stop_celebration() -> void:
	for tw in _active_tweens:
		if is_instance_valid(tw):
			tw.kill()
	_active_tweens.clear()

	for node in _active_particles:
		if is_instance_valid(node) and node is CPUParticles2D:
			(node as CPUParticles2D).emitting = false

	if is_inside_tree():
		var timer := get_tree().create_timer(1.2)
		timer.timeout.connect(clear)
	else:
		clear()


## Instantly removes and frees all active celebration particle nodes and tweens.
func clear() -> void:
	for tw in _active_tweens:
		if is_instance_valid(tw):
			tw.kill()
	_active_tweens.clear()

	for node in _active_particles:
		if is_instance_valid(node):
			node.queue_free()
	_active_particles.clear()


## Spawns two powerful confetti cannons shooting angled plumes of rainbow confetti from bottom corners.
func _spawn_confetti_cannons() -> void:
	var screen_size: Vector2 = get_viewport_rect().size if is_inside_tree() else Vector2(720.0, 1280.0)
	var bottom_y: float = screen_size.y - 40.0

	# Left Cannon (fires toward top-right)
	var cannon_left := CPUParticles2D.new()
	cannon_left.position = Vector2(50.0, bottom_y)
	cannon_left.emitting = false
	cannon_left.one_shot = true
	cannon_left.amount = 36
	cannon_left.lifetime = 2.4
	cannon_left.explosiveness = 0.88
	cannon_left.texture = load(ChalkTheme.TEX_CONFETTI) as Texture2D
	cannon_left.direction = Vector2(0.55, -1.0)
	cannon_left.spread = 26.0
	cannon_left.gravity = Vector2(0.0, 750.0)
	cannon_left.initial_velocity_min = 680.0
	cannon_left.initial_velocity_max = 940.0
	cannon_left.angular_velocity_min = 240.0
	cannon_left.angular_velocity_max = 720.0
	cannon_left.scale_amount_min = 0.55
	cannon_left.scale_amount_max = 1.05
	cannon_left.hue_variation_min = -1.0
	cannon_left.hue_variation_max = 1.0
	add_child(cannon_left)
	cannon_left.emitting = true
	_active_particles.append(cannon_left)

	# Right Cannon (fires toward top-left)
	var cannon_right := CPUParticles2D.new()
	cannon_right.position = Vector2(screen_size.x - 50.0, bottom_y)
	cannon_right.emitting = false
	cannon_right.one_shot = true
	cannon_right.amount = 36
	cannon_right.lifetime = 2.4
	cannon_right.explosiveness = 0.88
	cannon_right.texture = load(ChalkTheme.TEX_CONFETTI) as Texture2D
	cannon_right.direction = Vector2(-0.55, -1.0)
	cannon_right.spread = 26.0
	cannon_right.gravity = Vector2(0.0, 750.0)
	cannon_right.initial_velocity_min = 680.0
	cannon_right.initial_velocity_max = 940.0
	cannon_right.angular_velocity_min = -720.0
	cannon_right.angular_velocity_max = -240.0
	cannon_right.scale_amount_min = 0.55
	cannon_right.scale_amount_max = 1.05
	cannon_right.hue_variation_min = -1.0
	cannon_right.hue_variation_max = 1.0
	add_child(cannon_right)
	cannon_right.emitting = true
	_active_particles.append(cannon_right)


## Spawns drifting, fluttering rainbow confetti falling from the top edge of the screen.
func _spawn_confetti_rain() -> void:
	var screen_size: Vector2 = get_viewport_rect().size if is_inside_tree() else Vector2(720.0, 1280.0)
	var rain := CPUParticles2D.new()
	rain.position = Vector2(screen_size.x * 0.5, -20.0)
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(screen_size.x * 0.5, 10.0)
	rain.amount = 45
	rain.lifetime = 3.2
	rain.texture = load(ChalkTheme.TEX_CONFETTI) as Texture2D
	rain.direction = Vector2(0.0, 1.0)
	rain.spread = 22.0
	rain.gravity = Vector2(0.0, 260.0)
	rain.initial_velocity_min = 70.0
	rain.initial_velocity_max = 190.0
	rain.angular_velocity_min = 140.0
	rain.angular_velocity_max = 480.0
	rain.scale_amount_min = 0.45
	rain.scale_amount_max = 0.90
	rain.hue_variation_min = -1.0
	rain.hue_variation_max = 1.0
	rain.explosiveness = 0.0
	rain.one_shot = false
	add_child(rain)
	rain.emitting = true
	_active_particles.append(rain)


## Triggers a sequential barrage of vibrant firework starbursts across the view.
func _trigger_firework_sequence() -> void:
	if not is_inside_tree():
		return
	var screen_size: Vector2 = get_viewport_rect().size if is_inside_tree() else Vector2(720.0, 1280.0)
	var cx: float = screen_size.x * 0.5

	var tw := create_tween()
	_active_tweens.append(tw)

	# Firework 1: Warm Golden Amber burst (upper-left)
	tw.tween_callback(func() -> void:
		if is_inside_tree():
			_spawn_firework_burst(Vector2(cx - 180.0, 260.0), Color(1.0, 0.84, 0.20, 1.0))
	)
	tw.tween_interval(0.20)

	# Firework 2: Radiant Crimson Coral burst (upper-right)
	tw.tween_callback(func() -> void:
		if is_inside_tree():
			_spawn_firework_burst(Vector2(cx + 180.0, 230.0), Color(1.0, 0.32, 0.42, 1.0))
	)
	tw.tween_interval(0.22)

	# Firework 3: Emerald Sky Cyan burst (top center)
	tw.tween_callback(func() -> void:
		if is_inside_tree():
			_spawn_firework_burst(Vector2(cx, 170.0), Color(0.24, 0.90, 0.65, 1.0))
	)
	tw.tween_interval(0.26)

	# Firework 4: Majestic Violet Gold finale burst (center-above card)
	tw.tween_callback(func() -> void:
		if is_inside_tree():
			_spawn_firework_burst(Vector2(cx - 60.0, 320.0), Color(0.85, 0.42, 1.0, 1.0))
			_spawn_firework_burst(Vector2(cx + 70.0, 310.0), Color(1.0, 0.88, 0.30, 1.0))
	)


## Spawns a radial burst of firework sparkle stars at `burst_pos`.
func _spawn_firework_burst(burst_pos: Vector2, burst_color: Color) -> CPUParticles2D:
	var firework := CPUParticles2D.new()
	firework.position = burst_pos
	firework.emitting = false
	firework.one_shot = true
	firework.amount = 26
	firework.lifetime = 1.3
	firework.explosiveness = 0.94
	firework.texture = load(ChalkTheme.TEX_SPARKLE_STAR) as Texture2D
	firework.direction = Vector2(0.0, -1.0)
	firework.spread = 180.0
	firework.gravity = Vector2(0.0, 160.0)
	firework.initial_velocity_min = 180.0
	firework.initial_velocity_max = 380.0
	firework.damping_min = 45.0
	firework.damping_max = 75.0
	firework.scale_amount_min = 0.40
	firework.scale_amount_max = 0.85
	firework.angular_velocity_min = -180.0
	firework.angular_velocity_max = 180.0
	firework.color = burst_color
	add_child(firework)
	firework.emitting = true
	_active_particles.append(firework)
	return firework
