## Full-screen chalkboard background with animated corner chalk doodles (X, O, #) and floating chalk dust particles.
class_name AnimatedChalkBg
extends Control

var _bg_rect: TextureRect
var _doodle_layer: Control
var _dust_particles: CPUParticles2D
var _elapsed: float = 0.0


## Initializes the full-screen background control and builds its visual layers.
func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_children()


## Ensures background layers exist and enables per-frame doodle animation when in the tree.
func _ready() -> void:
	_ensure_children()
	set_process(true)


## Advances the doodle draw/erase cycle and triggers a redraw of the corner chalk sketches.
func _process(delta: float) -> void:
	_elapsed += delta
	if _doodle_layer != null:
		_doodle_layer.queue_redraw()


## Returns the internal CPUParticles2D node emitting floating chalk dust specks.
func get_dust_particles() -> CPUParticles2D:
	_ensure_children()
	return _dust_particles


## Creates the chalkboard TextureRect, custom doodle drawing layer, and CPUParticles2D emitter.
func _ensure_children() -> void:
	if _bg_rect != null:
		return

	_bg_rect = TextureRect.new()
	_bg_rect.name = "ChalkboardTexture"
	_bg_rect.texture = load(ChalkTheme.TEX_CHALKBOARD_BG) as Texture2D
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	_doodle_layer = Control.new()
	_doodle_layer.name = "DoodleLayer"
	_doodle_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_doodle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_doodle_layer.draw.connect(_on_draw_doodles)
	add_child(_doodle_layer)

	_dust_particles = CPUParticles2D.new()
	_dust_particles.name = "ChalkDustParticles"
	_dust_particles.position = Vector2(360.0, 640.0)
	_dust_particles.amount = 22
	_dust_particles.lifetime = 5.5
	_dust_particles.preprocess = 2.0
	_dust_particles.texture = load(ChalkTheme.TEX_DUST_PARTICLE) as Texture2D
	_dust_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_dust_particles.emission_rect_extents = Vector2(340.0, 600.0)
	_dust_particles.direction = Vector2(0.2, -1.0)
	_dust_particles.spread = 180.0
	_dust_particles.gravity = Vector2(0.0, -4.0)
	_dust_particles.initial_velocity_min = 4.0
	_dust_particles.initial_velocity_max = 14.0
	_dust_particles.scale_amount_min = 0.15
	_dust_particles.scale_amount_max = 0.42
	_dust_particles.color = Color(0.96, 0.96, 0.92, 0.24)
	_dust_particles.emitting = true
	add_child(_dust_particles)


## Renders faint hand-drawn X, O, and mini-grid (#) chalk doodles in the corners that gently fade in and out.
func _on_draw_doodles() -> void:
	var view_size := _doodle_layer.size
	if view_size.x <= 10.0 or view_size.y <= 10.0:
		view_size = Vector2(720.0, 1280.0)

	var alpha_top_left := 0.08 + 0.06 * (0.5 + 0.5 * sin(_elapsed * 1.1))
	var alpha_top_right := 0.08 + 0.06 * (0.5 + 0.5 * sin(_elapsed * 0.9 + 1.5))
	var alpha_bottom_left := 0.07 + 0.06 * (0.5 + 0.5 * sin(_elapsed * 1.3 + 3.0))
	var alpha_bottom_right := 0.08 + 0.06 * (0.5 + 0.5 * sin(_elapsed * 1.0 + 4.2))

	_draw_chalk_x(Vector2(86.0, 120.0), 26.0, Color(0.98, 0.84, 0.32, alpha_top_left))
	_draw_chalk_o(Vector2(view_size.x - 92.0, 145.0), 28.0, Color(0.96, 0.96, 0.93, alpha_top_right))
	_draw_mini_grid(Vector2(95.0, view_size.y - 140.0), 34.0, Color(0.96, 0.96, 0.93, alpha_bottom_left))
	_draw_chalk_x(Vector2(view_size.x - 88.0, view_size.y - 125.0), 24.0, Color(0.98, 0.84, 0.32, alpha_bottom_right))


## Draws a stylized chalk X doodle centered at `center`.
func _draw_chalk_x(center: Vector2, radius: float, color: Color) -> void:
	_doodle_layer.draw_line(
		center + Vector2(-radius, -radius),
		center + Vector2(radius, radius),
		color,
		3.5,
		true
	)
	_doodle_layer.draw_line(
		center + Vector2(radius, -radius),
		center + Vector2(-radius, radius),
		color,
		3.5,
		true
	)


## Draws a stylized chalk O doodle centered at `center`.
func _draw_chalk_o(center: Vector2, radius: float, color: Color) -> void:
	_doodle_layer.draw_arc(center, radius, 0.0, TAU, 32, color, 3.5, true)


## Draws a faint miniature '#' tic-tac-toe grid doodle centered at `center`.
func _draw_mini_grid(center: Vector2, half_size: float, color: Color) -> void:
	var third := half_size * 0.36
	_doodle_layer.draw_line(center + Vector2(-third, -half_size), center + Vector2(-third, half_size), color, 2.5, true)
	_doodle_layer.draw_line(center + Vector2(third, -half_size), center + Vector2(third, half_size), color, 2.5, true)
	_doodle_layer.draw_line(center + Vector2(-half_size, -third), center + Vector2(half_size, -third), color, 2.5, true)
	_doodle_layer.draw_line(center + Vector2(-half_size, third), center + Vector2(half_size, third), color, 2.5, true)
