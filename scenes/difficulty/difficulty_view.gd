@tool
## Difficulty & Mark selection UIFlowPage where the player picks X (First) or O (Second) and selects one of the 5 AI difficulty levels.
class_name DifficultyView
extends UIFlowPage

@onready var _btn_back: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/TopRow/BtnBack
@onready var _title_banner: ChalkBanner = $GodotxSafeArea/ContentMargin/MainColumn/TitleBanner
@onready var _you_play_label: Label = $GodotxSafeArea/ContentMargin/MainColumn/YouPlayLabel
@onready var _btn_mark_x: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/MarkRow/BtnMarkX
@onready var _btn_mark_o: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/MarkRow/BtnMarkO

@onready var _btn_easy: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/ListBox/ItemEasy/BtnEasy
@onready var _desc_easy: Label = $GodotxSafeArea/ContentMargin/MainColumn/ListBox/ItemEasy/DescEasy

@onready var _btn_medium: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/ListBox/ItemMedium/BtnMedium
@onready var _desc_medium: Label = $GodotxSafeArea/ContentMargin/MainColumn/ListBox/ItemMedium/DescMedium

@onready var _btn_learning: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/ListBox/ItemLearning/BtnLearning
@onready var _desc_learning: Label = $GodotxSafeArea/ContentMargin/MainColumn/ListBox/ItemLearning/DescLearning

@onready var _btn_hard: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/ListBox/ItemHard/BtnHard
@onready var _desc_hard: Label = $GodotxSafeArea/ContentMargin/MainColumn/ListBox/ItemHard/DescHard

@onready var _btn_unbeatable: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/ListBox/ItemUnbeatable/BtnUnbeatable
@onready var _desc_unbeatable: Label = $GodotxSafeArea/ContentMargin/MainColumn/ListBox/ItemUnbeatable/DescUnbeatable

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
	_btn_learning.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.on_difficulty_selected(Domain.Difficulty.LEARNING)
	)
	_btn_hard.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.on_difficulty_selected(Domain.Difficulty.HARD)
	)
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
		for btn in [_btn_back, _btn_mark_x, _btn_mark_o, _btn_easy, _btn_medium, _btn_learning, _btn_hard, _btn_unbeatable]:
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
	_title_banner.set_banner_text("DIFF_TITLE", ChalkTheme.CHALK_YELLOW, false)
	_you_play_label.label_settings = ChalkTheme.make_label_settings(26, ChalkTheme.CHALK_WHITE, true)
	_you_play_label.text = tr("DIFF_YOU_PLAY")

	var selected_mark := _view_model.get_selected_mark() if _view_model != null else Domain.Mark.X
	var is_x := selected_mark == Domain.Mark.X

	_btn_mark_x.set_text_key("X " + tr("DIFF_FIRST"))
	_btn_mark_x.set_text_color(ChalkTheme.CHALK_YELLOW if is_x else ChalkTheme.CHALK_DIM)
	_btn_mark_x.modulate = Color.WHITE if is_x else Color(0.68, 0.68, 0.68, 0.85)

	_btn_mark_o.set_text_key("O " + tr("DIFF_SECOND"))
	_btn_mark_o.set_text_color(ChalkTheme.CHALK_YELLOW if not is_x else ChalkTheme.CHALK_DIM)
	_btn_mark_o.modulate = Color.WHITE if not is_x else Color(0.68, 0.68, 0.68, 0.85)

	_update_diff_item(_btn_easy, _desc_easy, Domain.Difficulty.EASY, "DIFF_EASY", "DIFF_EASY_DESC", ChalkTheme.CHALK_GREEN)
	_update_diff_item(_btn_medium, _desc_medium, Domain.Difficulty.MEDIUM, "DIFF_MEDIUM", "DIFF_MEDIUM_DESC", ChalkTheme.CHALK_WHITE)
	_update_diff_item(_btn_learning, _desc_learning, Domain.Difficulty.LEARNING, "DIFF_LEARNING", "DIFF_LEARNING_DESC", ChalkTheme.CHALK_YELLOW)
	_update_diff_item(_btn_hard, _desc_hard, Domain.Difficulty.HARD, "DIFF_HARD", "DIFF_HARD_DESC", ChalkTheme.CHALK_YELLOW)
	_update_diff_item(_btn_unbeatable, _desc_unbeatable, Domain.Difficulty.UNBEATABLE, "DIFF_UNBEATABLE", "DIFF_UNBEATABLE_DESC", ChalkTheme.CHALK_RED)


func _update_diff_item(btn: ChalkButton, desc: Label, diff: Domain.Difficulty, title_key: String, desc_key: String, color: Color) -> void:
	btn.set_text_key(title_key)
	btn.set_text_color(color)
	var badge := _view_model.get_multiplier_badge(diff) if _view_model != null else ("×%d" % ScoreCalculator.multiplier(diff))
	btn.set_badge_text(badge, color)
	desc.label_settings = ChalkTheme.make_label_settings(20, ChalkTheme.CHALK_DIM, true)
	desc.text = tr(desc_key)


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
		Domain.Difficulty.LEARNING: return _btn_learning
		Domain.Difficulty.HARD: return _btn_hard
		Domain.Difficulty.UNBEATABLE: return _btn_unbeatable
	return null
