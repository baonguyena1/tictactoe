## GUT unit test suite for Step 5: DI Container, GameModeConfig, and UIFlow-backed AppCoordinator.
extends GutTest

const TEST_SETTINGS_PATH := "user://test_di_settings.cfg"
const TEST_SCORES_PATH := "user://test_di_scores.json"
const TEST_WEIGHTS_PATH := "user://test_di_weights.json"


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


## Tests GameModeConfig factory methods and opponent mark helper.
func test_game_mode_config() -> void:
	var vs_ai_cfg := GameModeConfig.vs_ai(Domain.Difficulty.HARD, Domain.Mark.O)
	assert_false(vs_ai_cfg.is_two_player, "vs_ai config should not be two-player")
	assert_eq(vs_ai_cfg.difficulty, Domain.Difficulty.HARD, "vs_ai difficulty should be HARD")
	assert_eq(vs_ai_cfg.human_mark, Domain.Mark.O, "vs_ai human_mark should be O")
	assert_eq(vs_ai_cfg.get_ai_mark(), Domain.Mark.X, "AI mark should be X when human is O")

	var two_p_cfg := GameModeConfig.two_players()
	assert_true(two_p_cfg.is_two_player, "two_players config should set is_two_player = true")
	assert_eq(two_p_cfg.human_mark, Domain.Mark.X, "two_players default first mark should be X")


## Tests AppContainer dependency wiring and MoveStrategy factory across difficulties.
func test_app_container() -> void:
	var host := Node.new()
	var settings := LocalSettingsRepository.new(TEST_SETTINGS_PATH)
	var scores := LocalScoreRepository.new(TEST_SCORES_PATH)
	var weights := LocalWeightStore.new(TEST_WEIGHTS_PATH)
	var container := AppContainer.new(host, settings, scores, weights)

	assert_eq(container.settings_repo, settings, "Container should retain injected SettingsRepository")
	assert_eq(container.score_repo, scores, "Container should retain injected ScoreRepository")
	assert_eq(container.weight_store, weights, "Container should retain injected WeightStore")
	assert_true(container.audio_service is DefaultAudioService, "Container should create DefaultAudioService when host node is provided")
	assert_not_null(container.learning_ai, "Container should initialize shared LearningAI instance")

	var easy_ai := container.make_move_strategy(Domain.Difficulty.EASY)
	var unbeatable_ai := container.make_move_strategy(Domain.Difficulty.UNBEATABLE)
	var learning_strategy := container.make_move_strategy(Domain.Difficulty.LEARNING)

	assert_true(easy_ai is MinimaxAI, "EASY strategy should be an instance of MinimaxAI")
	assert_true(unbeatable_ai is MinimaxAI, "UNBEATABLE strategy should be an instance of MinimaxAI")
	assert_eq(learning_strategy, container.learning_ai, "LEARNING strategy should return the shared LearningAI instance")

	var board := Board.new()
	learning_strategy.on_game_started()
	var move := learning_strategy.choose_move(board, Domain.Mark.X)
	assert_true(move >= 0 and move < 9, "LearningAI from container should return a valid move")
	learning_strategy.on_game_ended(Domain.Outcome.WIN)
	assert_gt(container.get_learning_skill_percent(), 0, "LearningAI skill percent should increase after a recorded game")

	container.reset_learning_memory()
	assert_eq(container.get_learning_skill_percent(), 0, "Resetting learning memory should reset skill percent to 0")

	host.free()


## Tests AppCoordinator UIFlow navigation stack retention across push, pop, modal present/dismiss, and pop_to_root.
func test_app_coordinator_uiflow_stack() -> void:
	var screen_container := Control.new()
	add_child_autofree(screen_container)
	var settings := LocalSettingsRepository.new(TEST_SETTINGS_PATH)
	var scores := LocalScoreRepository.new(TEST_SCORES_PATH)
	var weights := LocalWeightStore.new(TEST_WEIGHTS_PATH)
	var container := AppContainer.new(null, settings, scores, weights)
	var coordinator := AppCoordinator.new(screen_container, container)

	var creation_counts := {}
	for route in [
		AppCoordinator.ROUTE_MAIN_MENU,
		AppCoordinator.ROUTE_DIFFICULTY,
		AppCoordinator.ROUTE_GAME,
		AppCoordinator.ROUTE_SCORES,
		AppCoordinator.ROUTE_SETTINGS
	]:
		creation_counts[route] = 0
		var captured_route: String = route
		coordinator.register_screen_factory(
			captured_route,
			func(_cfg: GameModeConfig) -> Control:
				creation_counts[captured_route] += 1
				var dummy := UIFlowPage.new()
				dummy.name = "Screen_" + captured_route
				return dummy
		)

	coordinator.start()
	var root_menu_instance := coordinator.get_current_screen()
	assert_eq(coordinator.get_stack_size(), 1, "start() should initialize stack with 1 root screen")
	assert_eq(coordinator.get_current_route(), AppCoordinator.ROUTE_MAIN_MENU, "Root route should be main_menu")
	assert_eq(creation_counts[AppCoordinator.ROUTE_MAIN_MENU], 1, "Main menu should be created exactly once")

	coordinator.push(AppCoordinator.ROUTE_DIFFICULTY, null, false)
	var difficulty_instance := coordinator.get_current_screen()
	assert_eq(coordinator.get_stack_size(), 2, "push(ROUTE_DIFFICULTY) should push onto stack (size = 2)")
	assert_true(is_instance_valid(root_menu_instance), "Underlying Main Menu instance must remain alive in memory when Difficulty is pushed")

	var match_cfg := GameModeConfig.vs_ai(Domain.Difficulty.UNBEATABLE, Domain.Mark.X)
	coordinator.push(AppCoordinator.ROUTE_GAME, match_cfg, false)
	assert_eq(coordinator.get_stack_size(), 3, "push(ROUTE_GAME) should push onto stack (size = 3)")
	assert_eq(coordinator.get_current_route(), AppCoordinator.ROUTE_GAME, "Top route should be game")
	assert_eq(coordinator.get_current_config(), match_cfg, "Top config should match pushed GameModeConfig")

	var popped := coordinator.pop(false)
	assert_true(popped, "pop() should return true when stack size > 1")
	assert_eq(coordinator.get_stack_size(), 2, "Stack size should be 2 after popping Game")
	assert_eq(coordinator.get_current_screen(), difficulty_instance, "Popping should restore the exact same Difficulty screen instance")
	assert_eq(creation_counts[AppCoordinator.ROUTE_DIFFICULTY], 1, "Difficulty screen must NOT be recreated on pop")

	coordinator.present_modal(AppCoordinator.ROUTE_SETTINGS, null, false)
	assert_eq(coordinator.get_stack_size(), 3, "present_modal(ROUTE_SETTINGS) should present modal on top of stack (size = 3)")
	assert_eq(coordinator.get_current_route(), AppCoordinator.ROUTE_SETTINGS, "Top route should be settings")
	coordinator.dismiss_modal(false)
	assert_eq(coordinator.get_stack_size(), 2, "dismiss_modal() should pop modal and restore underlying screen")
	assert_eq(coordinator.get_current_screen(), difficulty_instance, "Underlying Difficulty instance should still be intact")

	coordinator.pop_to_root(false)
	assert_eq(coordinator.get_stack_size(), 1, "pop_to_root() should reduce stack size to 1")
	assert_eq(coordinator.get_current_screen(), root_menu_instance, "pop_to_root() must restore the exact original Main Menu instance")
	assert_eq(creation_counts[AppCoordinator.ROUTE_MAIN_MENU], 1, "Main Menu must NEVER be recreated during push/pop/pop_to_root")
	coordinator.get_navigator().clear_stack()
