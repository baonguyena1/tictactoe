## GUT unit test suite for Step 6: Shared Chalkboard UI Components (ChalkTheme, ChalkButton, ChalkBanner, AnimatedChalkBg).
extends GutTest


## Tests ChalkTheme font loading, slanted FontVariation, and LabelSettings creation.
func test_chalk_theme() -> void:
	var base_font := ChalkTheme.get_base_font()
	assert_not_null(base_font, "ChalkTheme.get_base_font() should load PatrickHand-Regular.ttf")

	var slanted_font := ChalkTheme.get_chalk_font(true)
	assert_true(slanted_font is FontVariation, "ChalkTheme.get_chalk_font(true) should return a slanted FontVariation")

	var label_settings := ChalkTheme.make_label_settings(36, ChalkTheme.CHALK_YELLOW, true)
	assert_not_null(label_settings, "ChalkTheme.make_label_settings() should return a valid LabelSettings")
	assert_eq(label_settings.font_size, 36, "LabelSettings font_size should match requested size")
	assert_eq(label_settings.font_color, ChalkTheme.CHALK_YELLOW, "LabelSettings font_color should match requested color")


## Tests ChalkButton label updates, badge updates, disabled state, and press signal emission.
func test_chalk_button() -> void:
	var play_icon := load(ChalkTheme.TEX_ICON_PLAY) as Texture2D
	var btn := ChalkButton.new("MENU_PLAY_AI", play_icon, null, "x8")
	assert_false(btn.get_displayed_text().is_empty(), "ChalkButton should display translated or raw text")
	assert_eq(btn.badge_text, "x8", "ChalkButton should retain initial badge text")

	var press_count: Array[int] = [0]
	btn.pressed.connect(func() -> void:
		press_count[0] += 1
	)

	btn.trigger_press()
	assert_eq(press_count[0], 1, "ChalkButton.trigger_press() should emit pressed signal when enabled")

	btn.set_disabled(true)
	assert_true(btn.is_disabled(), "ChalkButton.is_disabled() should be true after set_disabled(true)")
	btn.trigger_press()
	assert_eq(press_count[0], 1, "Disabled ChalkButton should not emit pressed signal")

	btn.set_disabled(false)
	btn.set_text_key("MENU_SETTINGS")
	assert_false(btn.get_displayed_text().is_empty(), "ChalkButton.set_text_key() should update displayed text")
	btn.free()


## Tests ChalkBanner text rendering and dynamic updates.
func test_chalk_banner() -> void:
	var banner := ChalkBanner.new("GAME_YOUR_TURN", ChalkTheme.CHALK_YELLOW)
	assert_false(banner.get_displayed_text().is_empty(), "ChalkBanner should render initial text")

	banner.set_banner_text("GAME_AI_THINKING", ChalkTheme.CHALK_WHITE, false)
	assert_eq(banner.text_color, ChalkTheme.CHALK_WHITE, "ChalkBanner.set_banner_text() should update text color")
	banner.free()


## Tests AnimatedChalkBg child layers and chalk dust particle configuration.
func test_animated_chalk_bg() -> void:
	var bg := AnimatedChalkBg.new()
	assert_eq(bg.get_child_count(), 3, "AnimatedChalkBg should contain 3 layers (background texture, doodle layer, dust particles)")

	var particles := bg.get_dust_particles()
	assert_true(particles != null and particles.emitting, "AnimatedChalkBg chalk dust CPUParticles2D should be emitting")
	bg.free()
