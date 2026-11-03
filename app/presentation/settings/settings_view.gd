@tool
## Settings modal UIFlowPage providing ChalkButtons to toggle Music, SFX, Vibration, Language (Tiếng Việt / English), and Reset Self-Learning AI Memory.
class_name SettingsView
extends UIFlowPage

@onready var _btn_back: ChalkButton = $SafeMargin/MainColumn/TopRow/BtnBack
@onready var _title_banner: ChalkBanner = $SafeMargin/MainColumn/TitleBanner
@onready var _btn_music: ChalkButton = $SafeMargin/MainColumn/OptionsBox/BtnMusic
@onready var _btn_sfx: ChalkButton = $SafeMargin/MainColumn/OptionsBox/BtnSFX
@onready var _btn_haptics: ChalkButton = $SafeMargin/MainColumn/OptionsBox/BtnHaptics
@onready var _btn_language: ChalkButton = $SafeMargin/MainColumn/OptionsBox/BtnLanguage
@onready var _btn_reset_ai: ChalkButton = $SafeMargin/MainColumn/OptionsBox/BtnResetAI
@onready var _ai_skill_label: Label = $SafeMargin/MainColumn/AISkillLabel

var _view_model: SettingsViewModel


func _init() -> void:
	is_modal = true


func _ready() -> void:
	_btn_back.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.on_back_pressed()
	)
	_btn_music.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.toggle_music()
	)
	_btn_sfx.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.toggle_sfx()
	)
	_btn_haptics.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.toggle_haptics()
	)
	_btn_language.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.toggle_language()
	)
	_btn_reset_ai.set_text_color(ChalkTheme.CHALK_RED)
	_btn_reset_ai.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.reset_ai_memory()
	)
	refresh_ui()


## Binds the SettingsViewModel to this view and refreshes all toggle states and localized labels.
func setup(view_model: SettingsViewModel) -> void:
	_view_model = view_model
	if not _view_model.state_changed.is_connected(refresh_ui):
		_view_model.state_changed.connect(refresh_ui)

	if is_inside_tree() and _btn_back != null:
		var audio := _view_model.get_audio_service()
		for btn in [_btn_back, _btn_music, _btn_sfx, _btn_haptics, _btn_language, _btn_reset_ai]:
			if btn != null:
				btn.set_audio_service(audio)

	refresh_ui()


## UIFlowPage lifecycle hook called when the page is shown.
func _on_shown() -> void:
	on_view_will_appear()


## Refreshes toggle badges and localized strings when the Settings screen appears.
func on_view_will_appear() -> void:
	refresh_ui()


## Updates all ChalkButton labels, ON/OFF badges, language label, and AI skill percentage.
func refresh_ui() -> void:
	if _btn_back == null:
		return

	_btn_back.refresh_content()
	_title_banner.set_banner_text("SET_TITLE", ChalkTheme.CHALK_YELLOW, false)

	var music_on := _view_model.is_music_enabled() if _view_model != null else true
	var sfx_on := _view_model.is_sfx_enabled() if _view_model != null else true
	var haptics_on := _view_model.is_haptics_enabled() if _view_model != null else true
	var locale := _view_model.get_locale() if _view_model != null else "vi"
	var skill_pct := _view_model.get_learning_skill_percent() if _view_model != null else 0

	_btn_music.refresh_content()
	_btn_music.set_badge_text(
		"ON" if music_on else "OFF",
		ChalkTheme.CHALK_GREEN if music_on else ChalkTheme.CHALK_RED
	)

	_btn_sfx.refresh_content()
	_btn_sfx.set_badge_text(
		"ON" if sfx_on else "OFF",
		ChalkTheme.CHALK_GREEN if sfx_on else ChalkTheme.CHALK_RED
	)

	_btn_haptics.refresh_content()
	_btn_haptics.set_badge_text(
		"ON" if haptics_on else "OFF",
		ChalkTheme.CHALK_GREEN if haptics_on else ChalkTheme.CHALK_RED
	)

	_btn_language.refresh_content()
	var lang_display := tr("SET_LANG_VI") if locale == "vi" else tr("SET_LANG_EN")
	_btn_language.set_badge_text(lang_display, ChalkTheme.CHALK_YELLOW)

	_btn_reset_ai.refresh_content()

	_ai_skill_label.label_settings = ChalkTheme.make_label_settings(24, ChalkTheme.CHALK_GREEN, true)
	_ai_skill_label.text = tr("AI_SKILL_FOOTER").replace("{p}", str(skill_pct))


## Returns the Back ChalkButton for testing.
func get_back_button() -> ChalkButton:
	return _btn_back


## Returns the Music toggle ChalkButton for testing.
func get_music_button() -> ChalkButton:
	return _btn_music


## Returns the SFX toggle ChalkButton for testing.
func get_sfx_button() -> ChalkButton:
	return _btn_sfx


## Returns the Haptics toggle ChalkButton for testing.
func get_haptics_button() -> ChalkButton:
	return _btn_haptics


## Returns the Language toggle ChalkButton for testing.
func get_language_button() -> ChalkButton:
	return _btn_language


## Returns the Reset AI Memory ChalkButton for testing.
func get_reset_ai_button() -> ChalkButton:
	return _btn_reset_ai
