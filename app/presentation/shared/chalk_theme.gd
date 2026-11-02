## Provides chalkboard typography, slanted handwritten fonts, color palette, and shared texture loaders.
class_name ChalkTheme
extends RefCounted

## Primary handwritten font path supporting Vietnamese and English glyphs.
const FONT_PATRICK_HAND := "res://app/resources/fonts/PatrickHand-Regular.ttf"

## Secondary bold handwritten font path.
const FONT_KALAM_BOLD := "res://app/resources/fonts/Kalam-Bold.ttf"

## Texture path for the dark green/black chalkboard background.
const TEX_CHALKBOARD_BG := "res://app/resources/textures/chalkboard_bg.png"

## Texture path for the hand-drawn chalk button frame.
const TEX_BUTTON_FRAME := "res://app/resources/textures/button_frame.png"

## Texture path for the turn/status ribbon banner.
const TEX_BANNER_TURN := "res://app/resources/textures/banner_turn.png"

## Texture path for the chalk dust particle speck.
const TEX_DUST_PARTICLE := "res://app/resources/textures/dust_particle.png"

## Texture path for the play icon.
const TEX_ICON_PLAY := "res://app/resources/textures/icon_play.png"

## Texture path for the reset/replay icon.
const TEX_ICON_RESET := "res://app/resources/textures/icon_reset.png"

## Texture path for the close/cancel icon.
const TEX_ICON_CLOSE := "res://app/resources/textures/icon_close.png"

## Texture path for the exit/back icon.
const TEX_ICON_EXIT := "res://app/resources/textures/icon_exit.png"

## Default italic slant applied to handwritten chalk labels.
const DEFAULT_SLANT := 0.14

## Off-white chalk color for primary text and O marks.
const CHALK_WHITE := Color(0.96, 0.96, 0.93, 1.0)

## Warm golden-yellow chalk color for highlights, titles, and X marks.
const CHALK_YELLOW := Color(0.98, 0.84, 0.32, 1.0)

## Soft coral-red chalk color for warnings, losses, or destructive actions.
const CHALK_RED := Color(0.95, 0.45, 0.42, 1.0)

## Soft mint-green chalk color for wins and active toggles.
const CHALK_GREEN := Color(0.55, 0.90, 0.62, 1.0)

## Muted chalk gray for secondary subtitles and disabled states.
const CHALK_DIM := Color(0.75, 0.78, 0.74, 0.78)

## Subtle dark drop shadow behind chalk strokes for legibility on the board.
const CHALK_SHADOW := Color(0.05, 0.08, 0.06, 0.65)

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


## Creates a configured LabelSettings resource with chalk font, size, color, and subtle board shadow.
static func make_label_settings(
	font_size: int = 34,
	font_color: Color = CHALK_WHITE,
	slanted: bool = true
) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font = get_chalk_font(slanted)
	settings.font_size = font_size
	settings.font_color = font_color
	settings.shadow_color = CHALK_SHADOW
	settings.shadow_size = 2
	settings.shadow_offset = Vector2(2.0, 3.0)
	return settings
