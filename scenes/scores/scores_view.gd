@tool
## High Scores & Statistics view displaying the trophy laurel, total score, best match score, best streak, and W/D/L breakdown per difficulty.
class_name ScoresView
extends Control

@onready var _btn_back: ChalkButton = $GodotxSafeArea/ContentMargin/MainColumn/TopRow/BtnBack
@onready var _title_banner: ChalkBanner = $GodotxSafeArea/ContentMargin/MainColumn/TitleBanner
@onready var _total_title_label: Label = $GodotxSafeArea/ContentMargin/MainColumn/SummaryCard/SummaryBox/TotalTitleLabel
@onready var _total_value_label: Label = $GodotxSafeArea/ContentMargin/MainColumn/SummaryCard/SummaryBox/TotalValueLabel
@onready var _best_game_title_label: Label = $GodotxSafeArea/ContentMargin/MainColumn/SummaryCard/SummaryBox/SubSummaryRow/BestGameCol/BestGameTitle
@onready var _best_game_value_label: Label = $GodotxSafeArea/ContentMargin/MainColumn/SummaryCard/SummaryBox/SubSummaryRow/BestGameCol/BestGameValue
@onready var _best_streak_title_label: Label = $GodotxSafeArea/ContentMargin/MainColumn/SummaryCard/SummaryBox/SubSummaryRow/BestStreakCol/BestStreakTitle
@onready var _best_streak_value_label: Label = $GodotxSafeArea/ContentMargin/MainColumn/SummaryCard/SummaryBox/SubSummaryRow/BestStreakCol/BestStreakValue
@onready var _section_diff_label: Label = $GodotxSafeArea/ContentMargin/MainColumn/SectionDiffLabel

# Easy Card
@onready var _name_easy: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardEasy/HBox/LeftCol/Name
@onready var _tag_easy: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardEasy/HBox/LeftCol/Tag
@onready var _wins_easy: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardEasy/HBox/Badges/PillWins/VBox/Value
@onready var _draws_easy: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardEasy/HBox/Badges/PillDraws/VBox/Value
@onready var _losses_easy: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardEasy/HBox/Badges/PillLosses/VBox/Value
@onready var _title_wins_easy: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardEasy/HBox/Badges/PillWins/VBox/Title
@onready var _title_draws_easy: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardEasy/HBox/Badges/PillDraws/VBox/Title
@onready var _title_losses_easy: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardEasy/HBox/Badges/PillLosses/VBox/Title

# Medium Card
@onready var _name_medium: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardMedium/HBox/LeftCol/Name
@onready var _tag_medium: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardMedium/HBox/LeftCol/Tag
@onready var _wins_medium: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardMedium/HBox/Badges/PillWins/VBox/Value
@onready var _draws_medium: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardMedium/HBox/Badges/PillDraws/VBox/Value
@onready var _losses_medium: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardMedium/HBox/Badges/PillLosses/VBox/Value
@onready var _title_wins_medium: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardMedium/HBox/Badges/PillWins/VBox/Title
@onready var _title_draws_medium: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardMedium/HBox/Badges/PillDraws/VBox/Title
@onready var _title_losses_medium: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardMedium/HBox/Badges/PillLosses/VBox/Title

# Hard Card
@onready var _name_hard: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardHard/HBox/LeftCol/Name
@onready var _tag_hard: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardHard/HBox/LeftCol/Tag
@onready var _wins_hard: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardHard/HBox/Badges/PillWins/VBox/Value
@onready var _draws_hard: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardHard/HBox/Badges/PillDraws/VBox/Value
@onready var _losses_hard: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardHard/HBox/Badges/PillLosses/VBox/Value
@onready var _title_wins_hard: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardHard/HBox/Badges/PillWins/VBox/Title
@onready var _title_draws_hard: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardHard/HBox/Badges/PillDraws/VBox/Title
@onready var _title_losses_hard: Label = $GodotxSafeArea/ContentMargin/MainColumn/TableBox/CardHard/HBox/Badges/PillLosses/VBox/Title

var _view_model: ScoresViewModel


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
	_title_banner.set_banner_text("SCORES_TITLE", ChalkTheme.CHALK_WHITE, false)

	_total_title_label.label_settings = ChalkTheme.make_label_settings(24, ChalkTheme.CHALK_DIM, true)
	_total_title_label.text = tr("SCORES_TOTAL")

	_total_value_label.label_settings = ChalkTheme.make_label_settings(58, ChalkTheme.CHALK_RED, true)
	var total := _view_model.get_total_score() if _view_model != null else 0
	_total_value_label.text = str(total)

	_best_game_title_label.label_settings = ChalkTheme.make_label_settings(20, ChalkTheme.CHALK_DIM, true)
	_best_game_title_label.text = tr("SCORES_BEST_GAME")

	_best_game_value_label.label_settings = ChalkTheme.make_label_settings(32, ChalkTheme.CHALK_GREEN, true)
	var best_game := _view_model.get_best_game_score() if _view_model != null else 0
	_best_game_value_label.text = str(best_game)

	_best_streak_title_label.label_settings = ChalkTheme.make_label_settings(20, ChalkTheme.CHALK_DIM, true)
	_best_streak_title_label.text = tr("SCORES_BEST_STREAK")

	_best_streak_value_label.label_settings = ChalkTheme.make_label_settings(32, ChalkTheme.CHALK_BLUE, true)
	var best_streak := _view_model.get_best_streak() if _view_model != null else 0
	_best_streak_value_label.text = str(best_streak)

	_section_diff_label.label_settings = ChalkTheme.make_label_settings(24, ChalkTheme.CHALK_WHITE, true)
	_section_diff_label.text = tr("SCORES_BY_DIFF")

	_update_card_row(
		_name_easy, _tag_easy,
		_wins_easy, _draws_easy, _losses_easy,
		_title_wins_easy, _title_draws_easy, _title_losses_easy,
		Domain.Difficulty.EASY, "DIFF_EASY", Color(0.25, 0.60, 0.28, 1.0)
	)
	_update_card_row(
		_name_medium, _tag_medium,
		_wins_medium, _draws_medium, _losses_medium,
		_title_wins_medium, _title_draws_medium, _title_losses_medium,
		Domain.Difficulty.MEDIUM, "DIFF_MEDIUM", Color(0.82, 0.48, 0.12, 1.0)
	)
	_update_card_row(
		_name_hard, _tag_hard,
		_wins_hard, _draws_hard, _losses_hard,
		_title_wins_hard, _title_draws_hard, _title_losses_hard,
		Domain.Difficulty.HARD, "DIFF_HARD", Color(0.82, 0.22, 0.18, 1.0)
	)


func _update_card_row(
	name_lbl: Label,
	tag_lbl: Label,
	wins_val: Label,
	draws_val: Label,
	losses_val: Label,
	wins_title: Label,
	draws_title: Label,
	losses_title: Label,
	diff: Domain.Difficulty,
	title_key: String,
	tag_color: Color
) -> void:
	if name_lbl != null:
		name_lbl.label_settings = ChalkTheme.make_label_settings(26, ChalkTheme.CHALK_WHITE, true)
		name_lbl.text = tr(title_key)

	if tag_lbl != null:
		tag_lbl.label_settings = ChalkTheme.make_label_settings(16, tag_color, true)
		tag_lbl.text = "×%d" % ScoreCalculator.multiplier(diff)

	var wins_text := tr("STAT_WINS") if tr("STAT_WINS") != "STAT_WINS" else "Thắng"
	var draws_text := tr("STAT_DRAWS") if tr("STAT_DRAWS") != "STAT_DRAWS" else "Hòa"
	var losses_text := tr("STAT_LOSSES") if tr("STAT_LOSSES") != "STAT_LOSSES" else "Thua"

	if wins_title != null:
		wins_title.label_settings = ChalkTheme.make_label_settings(14, ChalkTheme.CHALK_GREEN, true)
		wins_title.text = wins_text
	if draws_title != null:
		draws_title.label_settings = ChalkTheme.make_label_settings(14, ChalkTheme.CHALK_DIM, true)
		draws_title.text = draws_text
	if losses_title != null:
		losses_title.label_settings = ChalkTheme.make_label_settings(14, ChalkTheme.CHALK_RED, true)
		losses_title.text = losses_text

	var stats := _view_model.get_stats_for_difficulty(diff) if _view_model != null else {"wins": 0, "draws": 0, "losses": 0}
	if wins_val != null:
		wins_val.label_settings = ChalkTheme.make_label_settings(24, ChalkTheme.CHALK_GREEN, true)
		wins_val.text = str(int(stats.get("wins", 0)))
	if draws_val != null:
		draws_val.label_settings = ChalkTheme.make_label_settings(24, ChalkTheme.CHALK_DIM, true)
		draws_val.text = str(int(stats.get("draws", 0)))
	if losses_val != null:
		losses_val.label_settings = ChalkTheme.make_label_settings(24, ChalkTheme.CHALK_RED, true)
		losses_val.text = str(int(stats.get("losses", 0)))


## Returns the Back ChalkButton for testing.
func get_back_button() -> ChalkButton:
	return _btn_back


## Returns the displayed total score string for testing.
func get_displayed_total_score() -> String:
	return _total_value_label.text
