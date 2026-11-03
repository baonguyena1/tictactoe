@tool
## High Scores & Statistics modal UIFlowPage displaying the trophy laurel, total score, best match score, best streak, and W/D/L breakdown per difficulty.
class_name ScoresView
extends UIFlowPage

@onready var _btn_back: ChalkButton = $SafeMargin/MainColumn/TopRow/BtnBack
@onready var _title_banner: ChalkBanner = $SafeMargin/MainColumn/TitleBanner
@onready var _total_title_label: Label = $SafeMargin/MainColumn/SummaryBox/TotalTitleLabel
@onready var _total_value_label: Label = $SafeMargin/MainColumn/SummaryBox/TotalValueLabel
@onready var _best_game_title_label: Label = $SafeMargin/MainColumn/SummaryBox/SubSummaryRow/BestGameCol/BestGameTitle
@onready var _best_game_value_label: Label = $SafeMargin/MainColumn/SummaryBox/SubSummaryRow/BestGameCol/BestGameValue
@onready var _best_streak_title_label: Label = $SafeMargin/MainColumn/SummaryBox/SubSummaryRow/BestStreakCol/BestStreakTitle
@onready var _best_streak_value_label: Label = $SafeMargin/MainColumn/SummaryBox/SubSummaryRow/BestStreakCol/BestStreakValue
@onready var _section_diff_label: Label = $SafeMargin/MainColumn/SectionDiffLabel

@onready var _name_easy: Label = $SafeMargin/MainColumn/TableBox/RowEasy/Name
@onready var _stats_easy: Label = $SafeMargin/MainColumn/TableBox/RowEasy/Stats

@onready var _name_medium: Label = $SafeMargin/MainColumn/TableBox/RowMedium/Name
@onready var _stats_medium: Label = $SafeMargin/MainColumn/TableBox/RowMedium/Stats

@onready var _name_learning: Label = $SafeMargin/MainColumn/TableBox/RowLearning/Name
@onready var _stats_learning: Label = $SafeMargin/MainColumn/TableBox/RowLearning/Stats

@onready var _name_hard: Label = $SafeMargin/MainColumn/TableBox/RowHard/Name
@onready var _stats_hard: Label = $SafeMargin/MainColumn/TableBox/RowHard/Stats

@onready var _name_unbeatable: Label = $SafeMargin/MainColumn/TableBox/RowUnbeatable/Name
@onready var _stats_unbeatable: Label = $SafeMargin/MainColumn/TableBox/RowUnbeatable/Stats

var _view_model: ScoresViewModel


func _init() -> void:
	is_modal = true


func _ready() -> void:
	_btn_back.pressed.connect(func() -> void:
		if _view_model != null:
			_view_model.on_back_pressed()
	)
	refresh_ui()


## Binds the ScoresViewModel to this view and refreshes all statistics and labels.
func setup(view_model: ScoresViewModel) -> void:
	_view_model = view_model
	if not _view_model.state_changed.is_connected(refresh_ui):
		_view_model.state_changed.connect(refresh_ui)

	if is_inside_tree() and _btn_back != null:
		_btn_back.set_audio_service(_view_model.get_audio_service())
	refresh_ui()


## UIFlowPage lifecycle hook called when the page is shown.
func _on_shown() -> void:
	on_view_will_appear()


## Refreshes statistics and localized labels when the Scores screen appears.
func on_view_will_appear() -> void:
	refresh_ui()


## Updates all score values and per-difficulty W/D/L rows from the ViewModel.
func refresh_ui() -> void:
	if _btn_back == null:
		return

	_btn_back.refresh_content()
	_title_banner.set_banner_text("SCORES_TITLE", ChalkTheme.CHALK_YELLOW, false)

	_total_title_label.label_settings = ChalkTheme.make_label_settings(26, ChalkTheme.CHALK_DIM, true)
	_total_title_label.text = tr("SCORES_TOTAL")

	_total_value_label.label_settings = ChalkTheme.make_label_settings(56, ChalkTheme.CHALK_YELLOW, true)
	var total := _view_model.get_total_score() if _view_model != null else 0
	_total_value_label.text = str(total)

	_best_game_title_label.label_settings = ChalkTheme.make_label_settings(22, ChalkTheme.CHALK_DIM, true)
	_best_game_title_label.text = tr("SCORES_BEST_GAME")

	_best_game_value_label.label_settings = ChalkTheme.make_label_settings(34, ChalkTheme.CHALK_GREEN, true)
	var best_game := _view_model.get_best_game_score() if _view_model != null else 0
	_best_game_value_label.text = str(best_game)

	_best_streak_title_label.label_settings = ChalkTheme.make_label_settings(22, ChalkTheme.CHALK_DIM, true)
	_best_streak_title_label.text = tr("SCORES_BEST_STREAK")

	_best_streak_value_label.label_settings = ChalkTheme.make_label_settings(34, ChalkTheme.CHALK_YELLOW, true)
	var best_streak := _view_model.get_best_streak() if _view_model != null else 0
	_best_streak_value_label.text = str(best_streak)

	_section_diff_label.label_settings = ChalkTheme.make_label_settings(26, ChalkTheme.CHALK_YELLOW, true)
	_section_diff_label.text = tr("SCORES_BY_DIFF")

	_update_row(_name_easy, _stats_easy, Domain.Difficulty.EASY, "DIFF_EASY")
	_update_row(_name_medium, _stats_medium, Domain.Difficulty.MEDIUM, "DIFF_MEDIUM")
	_update_row(_name_learning, _stats_learning, Domain.Difficulty.LEARNING, "DIFF_LEARNING")
	_update_row(_name_hard, _stats_hard, Domain.Difficulty.HARD, "DIFF_HARD")
	_update_row(_name_unbeatable, _stats_unbeatable, Domain.Difficulty.UNBEATABLE, "DIFF_UNBEATABLE")


func _update_row(name_lbl: Label, stat_lbl: Label, diff: Domain.Difficulty, title_key: String) -> void:
	name_lbl.label_settings = ChalkTheme.make_label_settings(26, ChalkTheme.CHALK_WHITE, true)
	name_lbl.text = "%s (×%d)" % [tr(title_key), ScoreCalculator.multiplier(diff)]

	stat_lbl.label_settings = ChalkTheme.make_label_settings(26, ChalkTheme.CHALK_GREEN, true)
	var stats := _view_model.get_stats_for_difficulty(diff) if _view_model != null else {"wins": 0, "draws": 0, "losses": 0}
	stat_lbl.text = "%d  /  %d  /  %d" % [
		int(stats.get("wins", 0)),
		int(stats.get("draws", 0)),
		int(stats.get("losses", 0)),
	]


## Returns the Back ChalkButton for testing.
func get_back_button() -> ChalkButton:
	return _btn_back


## Returns the displayed total score string for testing.
func get_displayed_total_score() -> String:
	return _total_value_label.text
