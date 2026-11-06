@tool
## Difficulty & Mark selection view where the player picks X (First) or O (Second) and selects Easy, Medium, or Hard difficulty.
class_name DifficultyView
extends Control

@onready var _btn_back: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/TopRow/BtnBack
@onready var _title_banner: ChalkBanner = $GodotxSafeArea/ContentMargin/MainColumn/TitleBanner
@onready var _you_play_label: Label = $GodotxSafeArea/ContentMargin/MainColumn/YouPlayLabel
@onready var _btn_mark_x: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/MarkRow/BtnMarkX
@onready var _btn_mark_o: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/MarkRow/BtnMarkO

@onready var _btn_easy: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/ListBox/BtnEasy
@onready var _btn_medium: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/ListBox/BtnMedium
@onready var _btn_hard: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/ListBox/BtnHard
@onready var _btn_learning: ChalkButton = get_node_or_null("GodotxSafeArea/ContentMargin/MainColumn/ListBox/BtnLearning") as ChalkButton
@onready var _btn_unbeatable: ChalkButton = get_node_or_null("GodotxSafeArea/ContentMargin/MainColumn/ListBox/BtnUnbeatable") as ChalkButton

var _view_model: DifficultyViewModel


func _ready() -> void:
	_btn_back.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.on_back_pressed()
	)
	_btn_mark_x.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.select_mark(Domain.Mark.X)
	)
	_btn_mark_o.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.select_mark(Domain.Mark.O)
	)

	_btn_easy.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.on_difficulty_selected(Domain.Difficulty.EASY)
	)
	_btn_medium.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.on_difficulty_selected(Domain.Difficulty.MEDIUM)
	)
	_btn_hard.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.on_difficulty_selected(Domain.Difficulty.HARD)
	)
	if _btn_learning != null:
		_btn_learning.pressed.connect(func() -> void:
			if _view_model != null:
				_view_model.on_difficulty_selected(Domain.Difficulty.LEARNING)
		)
	if _btn_unbeatable != null:
		_btn_unbeatable.pressed.connect(func() -> void:
			if _view_model != null:
				_view_model.on_difficulty_selected(Domain.Difficulty.UNBEATABLE)
		)
	refresh_ui()


## Binds the DifficultyViewModel to this view and refreshes all localized labels and button callbacks.
func setup(view_model: DifficultyViewModel) -> void:
	_view_model = view_model
	if not _view_model.state_changed.is_connected(refresh_ui):
		_view_model.state_changed.connect(refresh_ui)

	if is_inside_tree():
		var audio := _view_model.get_audio_service()
		for btn in [_btn_back, _btn_mark_x, _btn_mark_o, _btn_easy, _btn_medium, _btn_hard, _btn_learning, _btn_unbeatable]:
			if btn != null:
				btn.set_audio_service(audio)

	refresh_ui()


## UIFlowPage lifecycle hook called when a covered page above this page is popped/dismissed.
func _on_shown() -> void:
	on_view_will_appear()


## Refreshes localized strings and selected mark state when the screen appears.
func on_view_will_appear() -> void:
	refresh_ui()


## Updates all labels, mark selection highlights, and difficulty buttons.
func refresh_ui() -> void:
	if _btn_back == null:
		return

	_btn_back.refresh_content()
	_title_banner.set_banner_text("DIFF_TITLE", ChalkTheme.CHALK_WHITE, false)
	_you_play_label.label_settings = ChalkTheme.make_label_settings(26, ChalkTheme.CHALK_WHITE, true)
	_you_play_label.text = tr("DIFF_YOU_PLAY")

	var selected_mark := _view_model.get_selected_mark() if _view_model != null else Domain.Mark.X
	var is_x := selected_mark == Domain.Mark.X

	_btn_mark_x.set_text_key("X " + tr("DIFF_FIRST"))
	_btn_mark_x.set_text_color(ChalkTheme.CHALK_RED if is_x else ChalkTheme.CHALK_DIM)
	_btn_mark_x.modulate = Color.WHITE if is_x else Color(0.68, 0.68, 0.68, 0.85)

	_btn_mark_o.set_text_key("O " + tr("DIFF_SECOND"))
	_btn_mark_o.set_text_color(ChalkTheme.CHALK_BLUE if not is_x else ChalkTheme.CHALK_DIM)
	_btn_mark_o.modulate = Color.WHITE if not is_x else Color(0.68, 0.68, 0.68, 0.85)

	_update_diff_item(_btn_easy, Domain.Difficulty.EASY, "DIFF_EASY", "DIFF_EASY_SUB")
	_update_diff_item(_btn_medium, Domain.Difficulty.MEDIUM, "DIFF_MEDIUM", "DIFF_MEDIUM_SUB")
	_update_diff_item(_btn_hard, Domain.Difficulty.HARD, "DIFF_HARD", "DIFF_HARD_SUB", "DIFF_HARD_TAG")
	if _btn_learning != null:
		_update_diff_item(_btn_learning, Domain.Difficulty.LEARNING, "DIFF_LEARNING", "")
	if _btn_unbeatable != null:
		_update_diff_item(_btn_unbeatable, Domain.Difficulty.UNBEATABLE, "DIFF_UNBEATABLE", "")


func _update_diff_item(btn: ChalkButton, diff: Domain.Difficulty, title_key: String, subtitle_key: String = "", tag_str: String = "") -> void:
	if btn == null:
		return
	btn.set_text_key(title_key)
	if not subtitle_key.is_empty():
		btn.set_subtitle_key(subtitle_key)
	if not tag_str.is_empty():
		btn.set_tag_text(tag_str)
	var badge := _view_model.get_multiplier_badge(diff) if _view_model != null else ("×%d" % ScoreCalculator.multiplier(diff))
	btn.set_badge_text(badge)
	btn.refresh_content()


## Returns the Back ChalkButton for testing.
func get_back_button() -> ChalkButton:
	return _btn_back


## Returns the Mark X selector ChalkButton for testing.
func get_mark_x_button() -> ChalkButton:
	return _btn_mark_x


## Returns the Mark O selector ChalkButton for testing.
func get_mark_o_button() -> ChalkButton:
	return _btn_mark_o


## Returns the ChalkButton corresponding to a specific `Domain.Difficulty`.
func get_difficulty_button(difficulty: Domain.Difficulty) -> ChalkButton:
	match difficulty:
		Domain.Difficulty.EASY: return _btn_easy
		Domain.Difficulty.MEDIUM: return _btn_medium
		Domain.Difficulty.LEARNING: return _btn_learning if _btn_learning != null else _btn_medium
		Domain.Difficulty.HARD: return _btn_hard
		Domain.Difficulty.UNBEATABLE: return _btn_unbeatable if _btn_unbeatable != null else _btn_hard
	return null
