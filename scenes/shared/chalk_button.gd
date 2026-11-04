@tool
## Reusable chalkboard button featuring a hand-drawn frame texture, optional left icon, slanted chalk label, right badge text, press bounce animation, and tap SFX.
class_name ChalkButton
extends Control

## Emitted when the user taps or clicks the button.
signal pressed

## Localization key or raw text displayed in the main button label.
@export var text_key: String = ""

## Optional secondary badge text displayed on the right side (e.g. "x8", "ON").
@export var badge_text: String = ""

## Optional icon texture displayed to the left of the text label.
@export var icon_texture: Texture2D = null

## Font size used for the primary button label.
@export var font_size: int = 34

## Text color used for the primary button label.
@export var text_color: Color = ChalkTheme.CHALK_WHITE

var _audio_service: AudioService = null
var _frame_rect: NinePatchRect
var _icon_rect: TextureRect
var _title_label: Label
var _badge_label: Label
var _is_pressed_down: bool = false
var _disabled: bool = false


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
	custom_minimum_size = Vector2(460.0, 92.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_ensure_children()
	refresh_content()


## Configures internal child nodes and refreshes localized text when entering the scene tree.
func _ready() -> void:
	_ensure_children()
	refresh_content()


## Binds an AudioService instance so button taps automatically trigger sound and haptic feedback.
func set_audio_service(audio_service: AudioService) -> void:
	_audio_service = audio_service


## Sets the localization key (or raw text) and immediately updates the displayed label.
func set_text_key(new_text_key: String) -> void:
	text_key = new_text_key
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


## Returns true if the button is currently disabled.
func is_disabled() -> bool:
	return _disabled


## Returns the currently rendered translated string on the primary label.
func get_displayed_text() -> String:
	_ensure_children()
	return _title_label.text


## Re-translates `text_key` via `tr()` and updates the icon, title label, and badge label.
func refresh_content() -> void:
	_ensure_children()
	_title_label.label_settings = ChalkTheme.make_label_settings(font_size, text_color, true)
	_title_label.text = tr(text_key) if not text_key.is_empty() else ""

	_icon_rect.texture = icon_texture
	_icon_rect.visible = icon_texture != null
	_icon_rect.modulate = Color(0.24, 0.20, 0.17, 0.95)

	_badge_label.text = badge_text
	_badge_label.visible = not badge_text.is_empty()
	if _badge_label.label_settings == null:
		_badge_label.label_settings = ChalkTheme.make_label_settings(font_size - 4, ChalkTheme.CHALK_YELLOW, true)


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


## Builds the internal TextureRect and HBoxContainer hierarchy if not already created.
func _ensure_children() -> void:
	if _frame_rect != null:
		return

	# Support nodes already existing from scene (.tscn)
	_frame_rect = get_node_or_null("FrameRect") as NinePatchRect
	if _frame_rect != null:
		_frame_rect.self_modulate = Color(0.24, 0.20, 0.17, 0.95)
	if _frame_rect == null:
		_frame_rect = NinePatchRect.new()
		_frame_rect.name = "FrameRect"
		_frame_rect.texture = load(ChalkTheme.TEX_BUTTON_FRAME) as Texture2D
		_frame_rect.patch_margin_left = 32
		_frame_rect.patch_margin_right = 32
		_frame_rect.patch_margin_top = 16
		_frame_rect.patch_margin_bottom = 16
		_frame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_frame_rect.self_modulate = Color(0.24, 0.20, 0.17, 0.95)
		add_child(_frame_rect)

	var margin := get_node_or_null("ContentMargin") as MarginContainer
	if margin == null:
		margin = MarginContainer.new()
		margin.name = "ContentMargin"
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 36)
		margin.add_theme_constant_override("margin_right", 36)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		add_child(margin)

	var hbox := margin.get_node_or_null("ContentRow") as HBoxContainer
	if hbox == null:
		hbox = HBoxContainer.new()
		hbox.name = "ContentRow"
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 16)
		margin.add_child(hbox)

	_icon_rect = hbox.get_node_or_null("IconRect") as TextureRect
	if _icon_rect == null:
		_icon_rect = TextureRect.new()
		_icon_rect.name = "IconRect"
		_icon_rect.custom_minimum_size = Vector2(40.0, 40.0)
		_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon_rect.visible = false
		hbox.add_child(_icon_rect)

	_title_label = hbox.get_node_or_null("TitleLabel") as Label
	if _title_label == null:
		_title_label = Label.new()
		_title_label.name = "TitleLabel"
		_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(_title_label)

	_badge_label = hbox.get_node_or_null("BadgeLabel") as Label
	if _badge_label == null:
		_badge_label = Label.new()
		_badge_label.name = "BadgeLabel"
		_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_badge_label.visible = false
		hbox.add_child(_badge_label)


## Shrinks the button slightly when pressed down.
func _animate_press_down() -> void:
	pivot_offset = size * 0.5
	if not is_inside_tree():
		scale = Vector2(0.96, 0.96)
		return
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.96, 0.96), 0.06)


## Restores the button scale if the pointer leaves without completing a tap.
func _animate_release() -> void:
	pivot_offset = size * 0.5
	if not is_inside_tree():
		scale = Vector2.ONE
		return
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)


## Plays a tactile scale bounce animation when a tap completes.
func _animate_bounce() -> void:
	pivot_offset = size * 0.5
	if not is_inside_tree():
		scale = Vector2.ONE
		return
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(self, "scale", Vector2(1.03, 1.03), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.07)
