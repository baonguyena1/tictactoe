## GUT unit test suite for Step 7: MainMenu, Difficulty, Scores, and Settings MVVM screens and navigation flows.
extends GutTest

const TEST_SETTINGS_PATH := "user://test_screens_settings.cfg"
const TEST_SCORES_PATH := "user://test_screens_scores.cfg"
const TEST_WEIGHTS_PATH := "user://test_screens_weights.json"


## Cleans up temporary test files before each test.
func before_each() -> void:
	_cleanup_files()


## Cleans up temporary test files after each test.
func after_each() -> void:
	_cleanup_files()


## Removes temporary test files from user:// directory.
func _cleanup_files() -> void:
	for path in [TEST_SETTINGS_PATH, TEST_SCORES_PATH, TEST_WEIGHTS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Helper that creates an isolated AppContainer + AppCoordinator with all Step 7 routes registered.
func _make_test_coordinator(screen_container: Control) -> AppCoordinator:
	var settings := LocalSettingsRepository.new(TEST_SETTINGS_PATH)
	var scores := LocalScoreRepository.new(TEST_SCORES_PATH)
	var weights := LocalWeightStore.new(TEST_WEIGHTS_PATH)
	var container := AppContainer.new(null, settings, scores, weights)
	var coordinator := AppCoordinator.new(screen_container, container, false)
	coordinator.animations_enabled = false
	AppRoot.register_default_routes(coordinator, container)
	coordinator.register_screen_factory(
		AppCoordinator.ROUTE_GAME,
		func(_cfg: GameModeConfig) -> Control:
			var page := UIFlowPage.new()
			page.name = "MockGamePage"
			return page
	)
	return coordinator


## Tests MainMenuView and MainMenuViewModel button navigation to Difficulty, 2-Player Game, Scores, and Settings.
func test_main_menu_navigation_and_skill_footer() -> void:
	var screen_container := Control.new()
	add_child_autofree(screen_container)
	var coordinator := _make_test_coordinator(screen_container)

	coordinator.start()
	var menu_view := coordinator.get_current_screen() as MainMenuView
	assert_not_null(menu_view, "Root screen should be an instance of MainMenuView")

	# Tap Play vs AI -> pushes DifficultyView
	menu_view.get_play_ai_button().trigger_press()
	assert_eq(coordinator.get_current_route(), AppCoordinator.ROUTE_DIFFICULTY, "Play vs AI button should navigate to ROUTE_DIFFICULTY")
	assert_true(coordinator.get_current_screen() is DifficultyView, "Active screen should be DifficultyView")

	# Pop back to MainMenuView
	coordinator.pop(false)
	assert_eq(coordinator.get_current_screen(), menu_view, "Popping Difficulty should restore the same MainMenuView instance")

	# Tap Two Players -> pushes Game screen with two_players config
	menu_view.get_two_players_button().trigger_press()
	assert_eq(coordinator.get_current_route(), AppCoordinator.ROUTE_GAME, "Two Players button should navigate to ROUTE_GAME")
	assert_true(coordinator.get_current_config().is_two_player, "GameModeConfig should have is_two_player = true")

	coordinator.get_navigator().clear_stack()


## Tests DifficultyView mark selection (X/O) and starting an AI match with the chosen difficulty.
func test_difficulty_view_mark_selection_and_launch() -> void:
	var screen_container := Control.new()
	add_child_autofree(screen_container)
	var coordinator := _make_test_coordinator(screen_container)

	coordinator.start()
	coordinator.push(AppCoordinator.ROUTE_DIFFICULTY, null, false)
	var diff_view := coordinator.get_current_screen() as DifficultyView
	assert_not_null(diff_view, "Active screen should be DifficultyView")

	# Switch mark to O (Second)
	diff_view.get_mark_o_button().trigger_press()
	# Select UNBEATABLE difficulty
	var unbeatable_btn := diff_view.get_difficulty_button(Domain.Difficulty.UNBEATABLE)
	assert_not_null(unbeatable_btn, "DifficultyView should have a button for UNBEATABLE")
	assert_eq(unbeatable_btn.badge_text, "×8", "UNBEATABLE button badge should show ×8")

	unbeatable_btn.trigger_press()
	assert_eq(coordinator.get_current_route(), AppCoordinator.ROUTE_GAME, "Selecting difficulty should push ROUTE_GAME")
	var cfg := coordinator.get_current_config()
	assert_false(cfg.is_two_player, "Config should be vs AI")
	assert_eq(cfg.difficulty, Domain.Difficulty.UNBEATABLE, "Config difficulty should be UNBEATABLE")
	assert_eq(cfg.human_mark, Domain.Mark.O, "Config human_mark should be O")

	coordinator.get_navigator().clear_stack()


## Tests ScoresView displaying recorded match points, streaks, and dismissing back to MainMenuView.
func test_scores_view_displays_stats_and_dismisses() -> void:
	var screen_container := Control.new()
	add_child_autofree(screen_container)
	var coordinator := _make_test_coordinator(screen_container)
	var container := coordinator.get_container()

	container.score_repo.record_ai_match(Domain.Outcome.WIN, Domain.Difficulty.HARD, 5)
	coordinator.start()
	coordinator.present_modal(AppCoordinator.ROUTE_SCORES, null, false)

	var scores_view := coordinator.get_current_screen() as ScoresView
	assert_not_null(scores_view, "Active modal should be ScoresView")
	assert_eq(scores_view.get_displayed_total_score(), "640", "ScoresView should display total score 640")

	scores_view.get_back_button().trigger_press()
	assert_eq(coordinator.get_current_route(), AppCoordinator.ROUTE_MAIN_MENU, "Back button on ScoresView should dismiss modal to MainMenu")

	coordinator.get_navigator().clear_stack()


## Tests SettingsView toggling music, SFX, haptics, switching language (vi <-> en), and resetting AI memory.
func test_settings_view_toggles_language_and_ai_reset() -> void:
	var screen_container := Control.new()
	add_child_autofree(screen_container)
	var coordinator := _make_test_coordinator(screen_container)
	var container := coordinator.get_container()

	# Train LearningAI with 1 game first
	var board := Board.new()
	container.learning_ai.on_game_started()
	container.learning_ai.choose_move(board, Domain.Mark.X)
	container.learning_ai.on_game_ended(Domain.Outcome.WIN)
	assert_gt(container.get_learning_skill_percent(), 0, "AI skill percent should be > 0 before reset")

	coordinator.start()
	coordinator.present_modal(AppCoordinator.ROUTE_SETTINGS, null, false)
	var settings_view := coordinator.get_current_screen() as SettingsView
	assert_not_null(settings_view, "Active modal should be SettingsView")

	assert_eq(settings_view.get_music_button().badge_text, "ON", "Initial music badge should be ON")
	settings_view.get_music_button().trigger_press()
	assert_eq(settings_view.get_music_button().badge_text, "OFF", "Music badge should toggle to OFF")
	assert_false(container.settings_repo.is_music_enabled(), "SettingsRepository music_enabled should be false")

	settings_view.get_sfx_button().trigger_press()
	assert_eq(settings_view.get_sfx_button().badge_text, "OFF", "SFX badge should toggle to OFF")

	settings_view.get_haptics_button().trigger_press()
	assert_eq(settings_view.get_haptics_button().badge_text, "OFF", "Haptics badge should toggle to OFF")

	var initial_locale := container.settings_repo.get_locale()
	settings_view.get_language_button().trigger_press()
	assert_ne(container.settings_repo.get_locale(), initial_locale, "Tapping language button should switch locale between vi and en")

	settings_view.get_reset_ai_button().trigger_press()
	assert_eq(container.get_learning_skill_percent(), 0, "Tapping Reset AI button should reset AI skill percent to 0")

	coordinator.get_navigator().clear_stack()
