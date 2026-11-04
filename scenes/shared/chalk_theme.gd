## Provides chalkboard typography, slanted handwritten fonts, color palette, and shared texture loaders.
class_name ChalkTheme
extends RefCounted

## Primary handwritten font path supporting Vietnamese and English glyphs.
const FONT_PATRICK_HAND := "res://resources/fonts/PatrickHand-Regular.ttf"

## Secondary bold handwritten font path.
const FONT_KALAM_BOLD := "res://resources/fonts/Kalam-Bold.ttf"

## Texture path for the vintage paper background.
const TEX_CHALKBOARD_BG := "res://resources/textures/background.png"

## Texture path for the hand-drawn chalk button frame.
const TEX_BUTTON_FRAME := "res://resources/textures/button_frame.png"

## Texture path for the turn/status ribbon banner.
const TEX_BANNER_TURN := "res://resources/textures/banner_turn.png"

## Texture path for the chalk dust particle speck.
const TEX_DUST_PARTICLE := "res://resources/textures/dust_particle.png"

## Texture path for the play icon.
const TEX_ICON_PLAY := "res://resources/textures/icon_play.png"

## Texture path for the reset/replay icon.
const TEX_ICON_RESET := "res://resources/textures/icon_reset.png"

## Texture path for the close/cancel icon.
const TEX_ICON_CLOSE := "res://resources/textures/icon_close.png"

## Texture path for the exit/back icon.
const TEX_ICON_EXIT := "res://resources/textures/icon_exit.png"

## Default italic slant applied to handwritten chalk labels.
const DEFAULT_SLANT := 0.14

## Deep charcoal ink color for primary text, button labels, and UI elements.
const CHALK_WHITE := Color(0.16, 0.13, 0.11, 1.0)

## Warm terracotta / amber ink color for highlights, titles, multipliers, and badges.
const CHALK_YELLOW := Color(0.76, 0.38, 0.10, 1.0)

## Deep crimson ink color for warnings, losses, or destructive actions.
const CHALK_RED := Color(0.80, 0.18, 0.15, 1.0)

## Deep forest green ink color for wins and active toggles.
const CHALK_GREEN := Color(0.12, 0.48, 0.22, 1.0)

## Deep ink blue color for O marks and secondary player.
const CHALK_BLUE := Color(0.15, 0.32, 0.65, 1.0)

## Muted graphite pencil gray for secondary subtitles and disabled states.
const CHALK_DIM := Color(0.48, 0.42, 0.38, 0.9)

## Subtle warm paper depth shadow behind ink strokes for tactile readability.
const CHALK_SHADOW := Color(0.90, 0.82, 0.70, 0.40)

static var _cached_slanted_font: FontVariation = null
static var _cached_upright_font: FontFile = null


## Returns the base upright handwritten FontFile (`PatrickHand-Regular.ttf`).
static func get_base_font() -> FontFile:
	if _cached_upright_font == null:
		_cached_upright_font = load(FONT_PATRICK_HAND) as FontFile
	return _cached_upright_font


## Returns a FontVariation with a handwritten italic slant (`0.14`) and slight embolden effect.
static func get_chalk_font(slanted: bool = true) -> Font:
	var base := get_base_font()
	if not slanted or base == null:
		return base
	if _cached_slanted_font == null:
		_cached_slanted_font = FontVariation.new()
		_cached_slanted_font.base_font = base
		_cached_slanted_font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-DEFAULT_SLANT, 1.0), Vector2.ZERO)
		_cached_slanted_font.variation_embolden = 0.15
	return _cached_slanted_font


## Creates a configured LabelSettings resource with chalk font, size, color, and crisp ink rendering.
static func make_label_settings(
	font_size: int = 34,
	font_color: Color = CHALK_WHITE,
	slanted: bool = true
) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font = get_chalk_font(slanted)
	settings.font_size = font_size
	settings.font_color = font_color
	return settings
