@tool
## Main Menu UIFlowPage displaying the chalkboard background, title frame, 4 primary ChalkButtons, and AI skill footer.
class_name MainMenuView
extends UIFlowPage

@onready var _subtitle_label: Label = $SafeMargin/MainColumn/SubtitleLabel
@onready var _edition_label: Label = $SafeMargin/MainColumn/EditionLabel
@onready var _btn_play_ai: ChalkButton = $SafeMargin/MainColumn/BtnPlayAI
@onready var _btn_two_players: ChalkButton = $SafeMargin/MainColumn/BtnTwoPlayers
@onready var _btn_scores: ChalkButton = $SafeMargin/MainColumn/BtnScores
@onready var _btn_settings: ChalkButton = $SafeMargin/MainColumn/BtnSettings
@onready var _skill_footer_label: Label = $SafeMargin/MainColumn/SkillFooterLabel

var _view_model: MainMenuViewModel


## Ensures node references are valid both when running or editing in editor.
func _ready() -> void:
	_btn_play_ai.set_text_color(ChalkTheme.CHALK_YELLOW)
	_btn_play_ai.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.on_play_vs_ai_pressed()
	)
	_btn_two_players.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.on_two_players_pressed()
	)
	_btn_scores.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.on_scores_pressed()
	)
	_btn_settings.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.on_settings_pressed()
	)
	refresh_ui()


## Binds the MainMenuViewModel to this view and refreshes all localized labels and button callbacks.
func setup(view_model: MainMenuViewModel) -> void:
	_view_model = view_model
	if not _view_model.state_changed.is_connected(refresh_ui):
		_view_model.state_changed.connect(refresh_ui)

	if is_inside_tree():
		var audio := _view_model.get_audio_service()
		for btn in [_btn_play_ai, _btn_two_players, _btn_scores, _btn_settings]:
			if btn != null:
				btn.set_audio_service(audio)

	refresh_ui()


## UIFlowPage lifecycle hook called when a covered page above this page is popped/dismissed.
func _on_shown() -> void:
	on_view_will_appear()


## Refreshes localized strings and AI skill percentage whenever the Main Menu appears.
func on_view_will_appear() -> void:
	if _view_model != null:
		_view_model.refresh()
	else:
		refresh_ui()


## Updates all labels and ChalkButtons with the active locale and latest AI skill percentage.
func refresh_ui() -> void:
	if _subtitle_label == null:
		return

	_subtitle_label.label_settings = ChalkTheme.make_label_settings(26, ChalkTheme.CHALK_YELLOW, true)
	_subtitle_label.text = tr("APP_SUBTITLE_CHALK")

	_edition_label.label_settings = ChalkTheme.make_label_settings(24, ChalkTheme.CHALK_DIM, true)
	_edition_label.text = tr("APP_EDITION_CHALK")

	_btn_play_ai.refresh_content()
	_btn_two_players.refresh_content()
	_btn_scores.refresh_content()
	_btn_settings.refresh_content()

	_skill_footer_label.label_settings = ChalkTheme.make_label_settings(24, ChalkTheme.CHALK_GREEN, true)
	if _view_model != null:
		_skill_footer_label.text = _view_model.get_ai_skill_footer_text()
	else:
		_skill_footer_label.text = tr("AI_SKILL_FOOTER").replace("{p}", "0")


## Returns the Play vs AI button for testing or focus handling.
func get_play_ai_button() -> ChalkButton:
	return _btn_play_ai


## Returns the Two Players button for testing or focus handling.
func get_two_players_button() -> ChalkButton:
	return _btn_two_players


## Returns the High Scores button for testing or focus handling.
func get_scores_button() -> ChalkButton:
	return _btn_scores


## Returns the Settings button for testing or focus handling.
func get_settings_button() -> ChalkButton:
	return _btn_settings
