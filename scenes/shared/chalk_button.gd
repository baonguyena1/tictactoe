@tool
## Reusable chalkboard button featuring a hand-drawn frame texture, optional left icon, slanted chalk label, subtitle, corner rivets, top gloss highlight, optional HOT badge, press bounce animation, and tap SFX.
class_name ChalkButton
extends Control

## Emitted when the user taps or clicks the button.
signal pressed

## Internal helper control drawing 4 decorative rivets/studs at plaque corners.
class RivetsOverlay extends Control:
	var rivet_color: Color = Color(0.20, 0.16, 0.12, 0.35)
	var shine_color: Color = Color(1.0, 1.0, 1.0, 0.35)

	func _draw() -> void:
		if size.x < 140.0 or size.y < 50.0:
			return
		var margin_x := 12.0
		var margin_y := 12.0
		var pts := [
			Vector2(margin_x, margin_y),
			Vector2(size.x - margin_x, margin_y),
			Vector2(margin_x, size.y - margin_y),
			Vector2(size.x - margin_x, size.y - margin_y)
		]
		for pt in pts:
			draw_circle(pt, 3.2, rivet_color)
			draw_circle(pt + Vector2(-0.8, -0.8), 1.2, shine_color)

## Localization key or raw text displayed in the main button label.
@export var text_key: String = ""

## Optional secondary subtitle text displayed below main label (e.g. "5 Cấp độ • Thử thách AI").
@export var subtitle_key: String = ""

## Optional secondary badge text displayed on the right side (e.g. "x8", "ON").
@export var badge_text: String = ""

## Optional top-right corner tag banner (e.g. "HOT 🔥").
@export var tag_text: String = ""

## Optional icon texture displayed to the left of the text label.
@export var icon_texture: Texture2D = null

## Font size used for the primary button label.
@export var font_size: int = 40

## Text color used for the primary button label.
@export var text_color: Color = ChalkTheme.CHALK_WHITE

## Visual style variant: "normal" (parchment), "primary" (amber/gold), "secondary" (chalk blue), "accent" (crimson).
@export_enum("normal", "primary", "secondary", "accent") var button_style: String = "normal"

## When true, gently pulses scale to draw attention as the primary call to action.
@export var is_hero_pulse: bool = false

var _audio_service: AudioService = null
var _base_bg: Panel
var _front_layer: Control
var _card_bg: Panel
var _top_gloss: Panel
var _frame_rect: NinePatchRect
var _rivets_overlay: RivetsOverlay
var _dust_particles: CPUParticles2D
var _margin: MarginContainer
var _hbox: HBoxContainer
var _icon_rect: TextureRect
var _text_vbox: VBoxContainer
var _title_label: Label
var _subtitle_label: Label
var _badge_label: Label
var _tag_badge: PanelContainer
var _tag_label: Label
var _is_pressed_down: bool = false
var _disabled: bool = false
var _pulse_tween: Tween = null


## Initializes the button with optional text key, icon texture, and audio service.
func _init(
	p_text_key: String = "",
	p_icon: Texture2D = null,
	p_audio_service: AudioService = null,
	p_badge_text: String = ""
) -> void:
	if not p_text_key.is_empty():
		text_key = p_text_key
	if p_icon != null:
		icon_texture = p_icon
	if p_audio_service != null:
		_audio_service = p_audio_service
	if not p_badge_text.is_empty():
		badge_text = p_badge_text
	custom_minimum_size = Vector2(200.0, 74.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_ensure_children()
	refresh_content()


## Configures minimum size dynamically to prevent 2-line buttons or icons from overflowing.
func _get_minimum_size() -> Vector2:
	var min_w: float = custom_minimum_size.x
	var min_h: float = custom_minimum_size.y
	if not subtitle_key.is_empty():
		min_h = maxf(min_h, 96.0)
		min_w = maxf(min_w, 360.0)
	elif not text_key.is_empty():
		min_h = maxf(min_h, 64.0)
		min_w = maxf(min_w, 140.0)
	else:
		min_w = maxf(min_w, 56.0)
		min_h = maxf(min_h, 56.0)
	return Vector2(min_w, min_h)


## Configures internal child nodes and refreshes localized text when entering the scene tree.
func _ready() -> void:
	_ensure_children()
	refresh_content()
	if is_hero_pulse and not Engine.is_editor_hint():
		_start_hero_pulse()


## Binds an AudioService instance so button taps automatically trigger sound and haptic feedback.
func set_audio_service(audio_service: AudioService) -> void:
	_audio_service = audio_service


## Sets the localization key (or raw text) and immediately updates the displayed label.
func set_text_key(new_text_key: String) -> void:
	text_key = new_text_key
	refresh_content()


## Sets the subtitle key (or raw text) and updates visibility and minimum size.
func set_subtitle_key(new_subtitle_key: String) -> void:
	subtitle_key = new_subtitle_key
	refresh_content()


## Sets the top-right tag text (e.g. "HOT 🔥").
func set_tag_text(new_tag: String) -> void:
	tag_text = new_tag
	refresh_content()


## Sets the optional right-side badge string (such as a score multiplier or toggle state).
func set_badge_text(new_badge: String, badge_color: Color = ChalkTheme.CHALK_YELLOW) -> void:
	badge_text = new_badge
	_ensure_children()
	_badge_label.text = badge_text
	_badge_label.visible = not badge_text.is_empty()
	_badge_label.label_settings = ChalkTheme.make_label_settings(font_size - 4, badge_color, true)


## Sets the primary label text color and refreshes the label settings.
func set_text_color(new_color: Color) -> void:
	text_color = new_color
	refresh_content()


## Sets the optional left icon texture and updates its visibility.
func set_icon_texture(new_icon: Texture2D) -> void:
	icon_texture = new_icon
	refresh_content()


## Enables or disables user interaction and dims the visual appearance when disabled.
func set_disabled(disabled: bool) -> void:
	_disabled = disabled
	modulate.a = 0.48 if _disabled else 1.0
	mouse_default_cursor_shape = Control.CURSOR_ARROW if _disabled else Control.CURSOR_POINTING_HAND
	if _dust_particles != null:
		_dust_particles.emitting = not _disabled


## Returns true if the button is currently disabled.
func is_disabled() -> bool:
	return _disabled


## Returns the currently rendered translated string on the primary label.
func get_displayed_text() -> String:
	_ensure_children()
	return _title_label.text


## Re-translates `text_key` via `tr()` and updates the icon, title label, subtitle, and badge label.
func refresh_content() -> void:
	_ensure_children()

	var is_icon_only := text_key.is_empty() and subtitle_key.is_empty() and icon_texture != null
	var is_compact := size.x < 110.0 or custom_minimum_size.x < 110.0

	# Dynamically ensure button height is generous when subtitle is present
	if not subtitle_key.is_empty():
		if custom_minimum_size.y < 96.0:
			custom_minimum_size.y = 96.0
	update_minimum_size()

	_apply_theme_colors()

	# Adjust margins based on icon-only or text button
	if _margin != null:
		if is_icon_only or is_compact:
			_margin.add_theme_constant_override("margin_left", 8)
			_margin.add_theme_constant_override("margin_right", 8)
			_margin.add_theme_constant_override("margin_top", 4)
			_margin.add_theme_constant_override("margin_bottom", 4)
		else:
			_margin.add_theme_constant_override("margin_left", 16)
			_margin.add_theme_constant_override("margin_right", 16)
			_margin.add_theme_constant_override("margin_top", 4)
			_margin.add_theme_constant_override("margin_bottom", 4)

	# Text box visibility
	if _text_vbox != null:
		_text_vbox.visible = not is_icon_only

	_title_label.text = tr(text_key) if not text_key.is_empty() else ""

	if not subtitle_key.is_empty():
		_subtitle_label.text = tr(subtitle_key)
		_subtitle_label.visible = true
	else:
		_subtitle_label.text = ""
		_subtitle_label.visible = false

	if _icon_rect != null:
		_icon_rect.texture = icon_texture
		_icon_rect.visible = icon_texture != null
		if is_compact or is_icon_only:
			_icon_rect.custom_minimum_size = Vector2(36.0, 36.0)
		else:
			_icon_rect.custom_minimum_size = Vector2(44.0, 44.0)

	_badge_label.text = badge_text
	_badge_label.visible = not badge_text.is_empty()
	if _badge_label.label_settings == null:
		var badge_col := Color(0.99, 0.98, 0.96, 0.95) if button_style != "normal" else ChalkTheme.CHALK_DIM
		_badge_label.label_settings = ChalkTheme.make_label_settings(font_size - 4, badge_col, true)

	if not tag_text.is_empty():
		_tag_label.text = tr(tag_text) if tr(tag_text) != tag_text else tag_text
		_tag_badge.visible = true
	else:
		_tag_badge.visible = false


## Updates 3D bevel base, face card background, gloss highlight, rivets, text, and icon colors.
func _apply_theme_colors() -> void:
	var face_color := Color(0.99, 0.98, 0.95, 0.96)
	var bevel_color := Color(0.80, 0.74, 0.65, 1.0)
	var rim_color := Color(0.20, 0.16, 0.12, 0.26)
	var effective_text_color := text_color
	var title_outline_size := 0
	var title_outline_color := Color.TRANSPARENT
	var title_shadow_color := ChalkTheme.CHALK_SHADOW
	var title_shadow_offset := Vector2(0, 1.5)
	var subtitle_color := ChalkTheme.CHALK_DIM
	var gloss_alpha := 0.14
	var rivet_tint := Color(0.20, 0.16, 0.12, 0.28)

	match button_style:
		"primary":
			face_color = Color(0.84, 0.24, 0.20, 1.0)
			bevel_color = Color(0.62, 0.15, 0.12, 1.0)
			rim_color = Color(0.50, 0.12, 0.10, 0.5)
			effective_text_color = Color(0.99, 0.98, 0.96, 1.0)
			title_outline_size = 2
			title_outline_color = Color(0.48, 0.10, 0.08, 0.9)
			title_shadow_color = Color(0.38, 0.08, 0.06, 0.5)
			title_shadow_offset = Vector2(0, 2.0)
			subtitle_color = Color(1.0, 0.92, 0.92, 0.92)
			gloss_alpha = 0.20
			rivet_tint = Color(0.48, 0.10, 0.08, 0.45)
		"secondary":
			face_color = Color(0.22, 0.46, 0.74, 1.0)
			bevel_color = Color(0.14, 0.30, 0.52, 1.0)
			rim_color = Color(0.10, 0.22, 0.40, 0.5)
			effective_text_color = Color(0.99, 0.98, 0.96, 1.0)
			title_outline_size = 2
			title_outline_color = Color(0.12, 0.26, 0.44, 0.9)
			title_shadow_color = Color(0.10, 0.22, 0.38, 0.5)
			title_shadow_offset = Vector2(0, 2.0)
			subtitle_color = Color(0.90, 0.94, 1.0, 0.92)
			gloss_alpha = 0.18
			rivet_tint = Color(0.12, 0.26, 0.44, 0.45)
		"accent":
			face_color = Color(0.72, 0.16, 0.14, 1.0)
			bevel_color = Color(0.52, 0.10, 0.08, 1.0)
			rim_color = Color(0.40, 0.08, 0.06, 0.5)
			effective_text_color = Color(0.99, 0.98, 0.96, 1.0)
			title_outline_size = 2
			title_outline_color = Color(0.42, 0.08, 0.06, 0.9)
			title_shadow_color = Color(0.32, 0.06, 0.04, 0.5)
			title_shadow_offset = Vector2(0, 2.0)
			subtitle_color = Color(1.0, 0.90, 0.90, 0.92)
			gloss_alpha = 0.20
			rivet_tint = Color(0.44, 0.08, 0.06, 0.45)

	if _base_bg != null:
		var base_style := StyleBoxFlat.new()
		base_style.bg_color = bevel_color
		base_style.corner_radius_top_left = 18
		base_style.corner_radius_top_right = 18
		base_style.corner_radius_bottom_right = 18
		base_style.corner_radius_bottom_left = 18
		base_style.shadow_color = Color(0.15, 0.12, 0.08, 0.18)
		base_style.shadow_size = 5
		base_style.shadow_offset = Vector2(0, 4)
		_base_bg.add_theme_stylebox_override("panel", base_style)

	if _card_bg != null:
		var face_style := StyleBoxFlat.new()
		face_style.bg_color = face_color
		face_style.border_width_left = 2
		face_style.border_width_top = 2
		face_style.border_width_right = 2
		face_style.border_width_bottom = 2
		face_style.border_color = rim_color
		face_style.corner_radius_top_left = 18
		face_style.corner_radius_top_right = 18
		face_style.corner_radius_bottom_right = 18
		face_style.corner_radius_bottom_left = 18
		_card_bg.add_theme_stylebox_override("panel", face_style)

	if _top_gloss != null:
		var gloss_style := StyleBoxFlat.new()
		gloss_style.bg_color = Color(1.0, 1.0, 1.0, gloss_alpha)
		gloss_style.corner_radius_top_left = 16
		gloss_style.corner_radius_top_right = 16
		gloss_style.corner_radius_bottom_right = 6
		gloss_style.corner_radius_bottom_left = 6
		_top_gloss.add_theme_stylebox_override("panel", gloss_style)

	if _rivets_overlay != null:
		_rivets_overlay.rivet_color = rivet_tint
		_rivets_overlay.shine_color = Color(1.0, 1.0, 1.0, 0.40)
		_rivets_overlay.queue_redraw()

	# When subtitle exists, keep title font comfortable so everything fits inside button borders
	var effective_font_size := mini(font_size, 36) if not subtitle_key.is_empty() else font_size

	if _title_label != null:
		_title_label.label_settings = ChalkTheme.make_label_settings(
			effective_font_size,
			effective_text_color,
			true,
			title_outline_size,
			title_outline_color,
			2 if title_shadow_color.a > 0.0 else 0,
			title_shadow_color,
			title_shadow_offset
		)

	if _subtitle_label != null:
		_subtitle_label.label_settings = ChalkTheme.make_label_settings(
			19,
			subtitle_color,
			true
		)

	# Full vibrant colors for colorful quest icons/marks; tint monochrome white glyphs only on parchment
	if _icon_rect != null:
		if icon_texture != null:
			var path := icon_texture.resource_path
			if path.contains("quest_") or path.contains("mark_") or path.contains("ai_face"):
				_icon_rect.modulate = Color.WHITE
			elif button_style == "normal":
				_icon_rect.modulate = Color(0.24, 0.20, 0.17, 0.95)
			else:
				_icon_rect.modulate = Color.WHITE
		else:
			_icon_rect.modulate = Color.WHITE


## Starts a gentle breathing heartbeat animation on this button.
func _start_hero_pulse() -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	pivot_offset = size * 0.5
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "scale", Vector2(1.026, 1.026), 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_interval(0.8)


## Programmatically triggers a button press (used by UI actions and unit tests).
func trigger_press() -> void:
	if _disabled:
		return
	if _audio_service != null:
		_audio_service.play_tap()
	_animate_bounce()
	pressed.emit()


## Handles mouse and touch input events on the button surface.
func _gui_input(event: InputEvent) -> void:
	if _disabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_is_pressed_down = true
			_animate_press_down()
			accept_event()
		elif _is_pressed_down:
			_is_pressed_down = false
			var local_pos: Vector2 = event.position
			if Rect2(Vector2.ZERO, size).has_point(local_pos):
				trigger_press()
			else:
				_animate_release()
			accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_dust_bounds()
		pivot_offset = size * 0.5
		if _rivets_overlay != null:
			_rivets_overlay.queue_redraw()
	elif what == NOTIFICATION_ENTER_TREE:
		if is_hero_pulse and not Engine.is_editor_hint():
			_start_hero_pulse()
	elif what == NOTIFICATION_EXIT_TREE:
		if _pulse_tween != null and _pulse_tween.is_valid():
			_pulse_tween.kill()


func _update_dust_bounds() -> void:
	if _dust_particles != null:
		_dust_particles.position = size * 0.5
		_dust_particles.emission_rect_extents = Vector2(maxf(size.x * 0.38, 20.0), maxf(size.y * 0.28, 10.0))


## Builds the internal nodes and layer hierarchy if not already created.
func _ensure_children() -> void:
	if _frame_rect != null:
		return

	# 3D Bevel Base plate at the bottom
	_base_bg = get_node_or_null("BaseBg") as Panel
	if _base_bg == null:
		_base_bg = Panel.new()
		_base_bg.name = "BaseBg"
		_base_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		_base_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_base_bg)

	# Raised Front Face Layer (depresses by 5px on press down)
	_front_layer = get_node_or_null("FrontLayer") as Control
	if _front_layer == null:
		_front_layer = Control.new()
		_front_layer.name = "FrontLayer"
		_front_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_front_layer.offset_bottom = -5.0
		_front_layer.clip_contents = true
		_front_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_front_layer)
	else:
		_front_layer.clip_contents = true

	# Card face background inside front layer
	_card_bg = _front_layer.get_node_or_null("CardBg") as Panel
	if _card_bg == null:
		_card_bg = Panel.new()
		_card_bg.name = "CardBg"
		_card_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		_card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_front_layer.add_child(_card_bg)

	# Top Gloss / Highlight Strip (adds 3D carved plaque depth)
	_top_gloss = _front_layer.get_node_or_null("TopGloss") as Panel
	if _top_gloss == null:
		_top_gloss = Panel.new()
		_top_gloss.name = "TopGloss"
		_top_gloss.set_anchors_preset(Control.PRESET_FULL_RECT)
		_top_gloss.anchor_bottom = 0.46
		_top_gloss.offset_left = 4.0
		_top_gloss.offset_top = 3.0
		_top_gloss.offset_right = -4.0
		_top_gloss.offset_bottom = 0.0
		_top_gloss.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_front_layer.add_child(_top_gloss)

	# Hand-drawn chalk frame texture
	_frame_rect = _front_layer.get_node_or_null("FrameRect") as NinePatchRect
	if _frame_rect == null:
		_frame_rect = NinePatchRect.new()
		_frame_rect.name = "FrameRect"
		_frame_rect.texture = load(ChalkTheme.TEX_BUTTON_FRAME) as Texture2D
		_frame_rect.patch_margin_left = 24
		_frame_rect.patch_margin_right = 24
		_frame_rect.patch_margin_top = 16
		_frame_rect.patch_margin_bottom = 16
		_frame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_frame_rect.self_modulate = Color(0.24, 0.20, 0.17, 0.95)
		_front_layer.add_child(_frame_rect)

	# 4 Corner Rivets / Studs
	_rivets_overlay = _front_layer.get_node_or_null("RivetsOverlay") as RivetsOverlay
	if _rivets_overlay == null:
		_rivets_overlay = RivetsOverlay.new()
		_rivets_overlay.name = "RivetsOverlay"
		_rivets_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		_rivets_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_front_layer.add_child(_rivets_overlay)

	# Ambient floating chalk dust particles on button surface
	_dust_particles = _front_layer.get_node_or_null("DustParticles") as CPUParticles2D
	if _dust_particles == null:
		_dust_particles = CPUParticles2D.new()
		_dust_particles.name = "DustParticles"
		_dust_particles.texture = load(ChalkTheme.TEX_DUST_PARTICLE) as Texture2D
		_dust_particles.amount = 5
		_dust_particles.lifetime = 2.4
		_dust_particles.preprocess = 1.0
		_dust_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		_dust_particles.emission_rect_extents = Vector2(maxf(size.x * 0.38, 20.0), maxf(size.y * 0.28, 10.0))
		_dust_particles.direction = Vector2(0.1, -1.0)
		_dust_particles.spread = 45.0
		_dust_particles.gravity = Vector2(0.0, -8.0)
		_dust_particles.initial_velocity_min = 4.0
		_dust_particles.initial_velocity_max = 12.0
		_dust_particles.scale_amount_min = 0.10
		_dust_particles.scale_amount_max = 0.28
		_dust_particles.color = Color(0.68, 0.54, 0.42, 0.30)
		_dust_particles.position = size * 0.5
		_front_layer.add_child(_dust_particles)

	_margin = _front_layer.get_node_or_null("ContentMargin") as MarginContainer
	if _margin == null:
		_margin = MarginContainer.new()
		_margin.name = "ContentMargin"
		_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_margin.add_theme_constant_override("margin_left", 16)
		_margin.add_theme_constant_override("margin_right", 16)
		_margin.add_theme_constant_override("margin_top", 4)
		_margin.add_theme_constant_override("margin_bottom", 4)
		_front_layer.add_child(_margin)

	_hbox = _margin.get_node_or_null("ContentRow") as HBoxContainer
	if _hbox == null:
		_hbox = HBoxContainer.new()
		_hbox.name = "ContentRow"
		_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		_hbox.add_theme_constant_override("separation", 12)
		_margin.add_child(_hbox)

	# Clean up any legacy IconEmblem panel if present
	var old_emblem := _hbox.get_node_or_null("IconEmblem")
	if old_emblem != null:
		_hbox.remove_child(old_emblem)
		old_emblem.queue_free()

	# Natural, borderless icon directly in the row
	_icon_rect = _hbox.get_node_or_null("IconRect") as TextureRect
	if _icon_rect == null:
		_icon_rect = TextureRect.new()
		_icon_rect.name = "IconRect"
		_icon_rect.custom_minimum_size = Vector2(42.0, 42.0)
		_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hbox.add_child(_icon_rect)
		_hbox.move_child(_icon_rect, 0)
	else:
		_icon_rect.custom_minimum_size = Vector2(42.0, 42.0)
		_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	_text_vbox = _hbox.get_node_or_null("TextVBox") as VBoxContainer
	if _text_vbox == null:
		_text_vbox = VBoxContainer.new()
		_text_vbox.name = "TextVBox"
		_text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_text_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		_text_vbox.add_theme_constant_override("separation", -4)
		_hbox.add_child(_text_vbox)

	_title_label = _text_vbox.get_node_or_null("TitleLabel") as Label
	if _title_label == null:
		_title_label = Label.new()
		_title_label.name = "TitleLabel"
		_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_title_label.clip_text = true
		_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_text_vbox.add_child(_title_label)
	else:
		_title_label.clip_text = true
		_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	_subtitle_label = _text_vbox.get_node_or_null("SubtitleLabel") as Label
	if _subtitle_label == null:
		_subtitle_label = Label.new()
		_subtitle_label.name = "SubtitleLabel"
		_subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_subtitle_label.clip_text = true
		_subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_subtitle_label.visible = false
		_text_vbox.add_child(_subtitle_label)
	else:
		_subtitle_label.clip_text = true
		_subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	_badge_label = _hbox.get_node_or_null("BadgeLabel") as Label
	if _badge_label == null:
		_badge_label = Label.new()
		_badge_label.name = "BadgeLabel"
		_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_badge_label.visible = false
		_hbox.add_child(_badge_label)

	# Optional top-right tag badge (e.g. HOT 🔥) - fits completely inside top right
	_tag_badge = _front_layer.get_node_or_null("TagBadge") as PanelContainer
	if _tag_badge == null:
		_tag_badge = PanelContainer.new()
		_tag_badge.name = "TagBadge"
		_tag_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tag_badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_tag_badge.anchor_left = 1.0
		_tag_badge.anchor_right = 1.0
		_tag_badge.anchor_top = 0.0
		_tag_badge.anchor_bottom = 0.0
		_tag_badge.offset_left = -84.0
		_tag_badge.offset_top = 4.0
		_tag_badge.offset_right = -6.0
		_tag_badge.offset_bottom = 28.0

		var tag_style := StyleBoxFlat.new()
		tag_style.bg_color = Color(0.88, 0.22, 0.18, 1.0)
		tag_style.border_width_left = 1
		tag_style.border_width_top = 1
		tag_style.border_width_right = 1
		tag_style.border_width_bottom = 1
		tag_style.border_color = Color(1.0, 0.88, 0.40, 0.95)
		tag_style.corner_radius_top_left = 8
		tag_style.corner_radius_top_right = 8
		tag_style.corner_radius_bottom_right = 8
		tag_style.corner_radius_bottom_left = 8
		tag_style.shadow_color = Color(0.15, 0.10, 0.08, 0.25)
		tag_style.shadow_size = 4
		tag_style.shadow_offset = Vector2(0, 2)
		_tag_badge.add_theme_stylebox_override("panel", tag_style)

		var tag_margin := MarginContainer.new()
		tag_margin.name = "TagMargin"
		tag_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag_margin.add_theme_constant_override("margin_left", 8)
		tag_margin.add_theme_constant_override("margin_right", 8)
		tag_margin.add_theme_constant_override("margin_top", 1)
		tag_margin.add_theme_constant_override("margin_bottom", 1)
		_tag_badge.add_child(tag_margin)

		_tag_label = Label.new()
		_tag_label.name = "TagLabel"
		_tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_tag_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_tag_label.label_settings = ChalkTheme.make_label_settings(18, Color(1, 1, 1, 1), true)
		tag_margin.add_child(_tag_label)

		_front_layer.add_child(_tag_badge)
	else:
		_tag_badge.offset_left = -84.0
		_tag_badge.offset_top = 4.0
		_tag_badge.offset_right = -6.0
		_tag_badge.offset_bottom = 28.0
		_tag_label = _tag_badge.find_child("TagLabel", true, false) as Label

	_apply_theme_colors()


## Depresses the 3D button face down onto the base bevel.
func _animate_press_down() -> void:
	pivot_offset = size * 0.5
	if _front_layer != null and is_inside_tree():
		var tween := create_tween()
		tween.tween_property(_front_layer, "position:y", 5.0, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	elif _front_layer != null:
		_front_layer.position.y = 5.0


## Restores the raised 3D button position when pointer releases or leaves.
func _animate_release() -> void:
	pivot_offset = size * 0.5
	if _front_layer != null and is_inside_tree():
		var tween := create_tween()
		tween.tween_property(_front_layer, "position:y", 0.0, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif _front_layer != null:
		_front_layer.position.y = 0.0


## Tactile mechanical bounce with chalk dust puff on tap completion.
func _animate_bounce() -> void:
	pivot_offset = size * 0.5
	if _dust_particles != null:
		_dust_particles.restart()
	if _front_layer != null and is_inside_tree():
		var tween := create_tween()
		tween.tween_property(_front_layer, "position:y", 5.0, 0.04)
		tween.tween_property(_front_layer, "position:y", -2.0, 0.07)
		tween.tween_property(_front_layer, "position:y", 0.0, 0.05)
	elif _front_layer != null:
		_front_layer.position.y = 0.0
