## Reusable chalkboard status ribbon banner (`banner_turn.png`) with centered handwritten chalk text.
class_name ChalkBanner
extends Control

## Localization key or raw text displayed inside the banner.
@export var text_key: String = ""

## Font size for the banner label.
@export var font_size: int = 32

## Text color for the banner label.
@export var text_color: Color = ChalkTheme.CHALK_YELLOW

var _bg_rect: TextureRect
var _label: Label


## Initializes the banner with an optional initial localization key or raw string.
func _init(p_text_key: String = "", p_color: Color = ChalkTheme.CHALK_YELLOW) -> void:
	if not p_text_key.is_empty():
		text_key = p_text_key
	text_color = p_color
	custom_minimum_size = Vector2(440.0, 78.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ensure_children()
	refresh_content()


## Ensures child nodes exist and updates text when entering the scene tree.
func _ready() -> void:
	_ensure_children()
	refresh_content()


## Updates the banner's text (translation key or literal string) and optional color, with a subtle pulse animation.
func set_banner_text(new_text: String, new_color: Color = text_color, animate_pulse: bool = true) -> void:
	text_key = new_text
	text_color = new_color
	refresh_content()
	if animate_pulse and is_inside_tree():
		pivot_offset = size * 0.5
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.08)
		tween.tween_property(self, "scale", Vector2.ONE, 0.10)


## Returns the currently rendered banner string.
func get_displayed_text() -> String:
	_ensure_children()
	return _label.text


## Re-renders the label text using `tr(text_key)` and applies the current chalk font settings.
func refresh_content() -> void:
	_ensure_children()
	_label.label_settings = ChalkTheme.make_label_settings(font_size, text_color, true)
	_label.text = tr(text_key) if not text_key.is_empty() else ""


## Creates the internal TextureRect and centered Label if not already present.
func _ensure_children() -> void:
	if _bg_rect != null:
		return

	_bg_rect = TextureRect.new()
	_bg_rect.name = "BannerTexture"
	_bg_rect.texture = load(ChalkTheme.TEX_BANNER_TURN) as Texture2D
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	_label = Label.new()
	_label.name = "BannerLabel"
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
