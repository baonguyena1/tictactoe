## Unit test suite for Step 5: DI Container, GameModeConfig, and AppCoordinator.
@tool
extends EditorScript

const TEST_SETTINGS_PATH := "user://test_di_settings.cfg"
const TEST_SCORES_PATH := "user://test_di_scores.json"
const TEST_WEIGHTS_PATH := "user://test_di_weights.json"

var _passed: int = 0
var _failed: int = 0


## Entry point executed in Godot Editor via File -> Run (Cmd+Shift+X).
func _run() -> void:
	_passed = 0
	_failed = 0
	print("========================================")
	print("Running DI & Coordinator Unit Tests...")
	print("========================================")
	_cleanup_files()
	_test_game_mode_config()
	_test_app_container()
	_test_app_coordinator()
	_cleanup_files()
	print("========================================")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	print("========================================")


## Asserts that a boolean condition is true and logs any failure.
func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("FAIL: " + message)


## Removes temporary test files from user:// directory.
func _cleanup_files() -> void:
	for path in [TEST_SETTINGS_PATH, TEST_SCORES_PATH, TEST_WEIGHTS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Tests GameModeConfig factory methods and opponent mark helper.
func _test_game_mode_config() -> void:
	var vs_ai_cfg := GameModeConfig.vs_ai(Domain.Difficulty.HARD, Domain.Mark.O)
	_assert(not vs_ai_cfg.is_two_player, "vs_ai config should not be two-player")
	_assert(vs_ai_cfg.difficulty == Domain.Difficulty.HARD, "vs_ai difficulty should be HARD")
	_assert(vs_ai_cfg.human_mark == Domain.Mark.O, "vs_ai human_mark should be O")
	_assert(vs_ai_cfg.get_ai_mark() == Domain.Mark.X, "AI mark should be X when human is O")

	var two_p_cfg := GameModeConfig.two_players()
	_assert(two_p_cfg.is_two_player, "two_players config should set is_two_player = true")
	_assert(two_p_cfg.human_mark == Domain.Mark.X, "two_players default first mark should be X")


## Tests AppContainer dependency wiring and MoveStrategy factory across difficulties.
func _test_app_container() -> void:
	var host := Node.new()
	var settings := LocalSettingsRepository.new(TEST_SETTINGS_PATH)
	var scores := LocalScoreRepository.new(TEST_SCORES_PATH)
	var weights := LocalWeightStore.new(TEST_WEIGHTS_PATH)
	var container := AppContainer.new(host, settings, scores, weights)

	_assert(container.settings_repo == settings, "Container should retain injected SettingsRepository")
	_assert(container.score_repo == scores, "Container should retain injected ScoreRepository")
	_assert(container.weight_store == weights, "Container should retain injected WeightStore")
	_assert(container.audio_service is DefaultAudioService, "Container should create DefaultAudioService when host node is provided")
	_assert(container.learning_ai != null, "Container should initialize shared LearningAI instance")

	var easy_ai := container.make_move_strategy(Domain.Difficulty.EASY)
	var unbeatable_ai := container.make_move_strategy(Domain.Difficulty.UNBEATABLE)
	var learning_strategy := container.make_move_strategy(Domain.Difficulty.LEARNING)

	_assert(easy_ai is MinimaxAI, "EASY strategy should be an instance of MinimaxAI")
	_assert(unbeatable_ai is MinimaxAI, "UNBEATABLE strategy should be an instance of MinimaxAI")
	_assert(learning_strategy == container.learning_ai, "LEARNING strategy should return the shared LearningAI instance")

	var board := Board.new()
	var move := learning_strategy.choose_move(board, Domain.Mark.X)
	_assert(move >= 0 and move < 9, "LearningAI from container should return a valid move")
	learning_strategy.on_game_finished(Domain.Outcome.WIN)
	_assert(container.get_learning_skill_percent() > 0.0, "LearningAI skill percent should increase after a recorded game")

	container.reset_learning_memory()
	_assert(is_equal_approx(container.get_learning_skill_percent(), 0.0), "Resetting learning memory should reset skill percent to 0")

	host.free()


## Tests AppCoordinator route switching, screen factory mounting, and cleanup.
func _test_app_coordinator() -> void:
	var screen_container := Control.new()
	var settings := LocalSettingsRepository.new(TEST_SETTINGS_PATH)
	var scores := LocalScoreRepository.new(TEST_SCORES_PATH)
	var weights := LocalWeightStore.new(TEST_WEIGHTS_PATH)
	var container := AppContainer.new(null, settings, scores, weights)
	var coordinator := AppCoordinator.new(screen_container, container)

	for route in [
		AppCoordinator.ROUTE_MAIN_MENU,
		AppCoordinator.ROUTE_DIFFICULTY,
		AppCoordinator.ROUTE_GAME,
		AppCoordinator.ROUTE_SCORES,
		AppCoordinator.ROUTE_SETTINGS
	]:
		var captured_route: String = route
		coordinator.register_screen_factory(
			captured_route,
			func(_cfg: GameModeConfig) -> Control:
				var dummy := Control.new()
				dummy.name = "Screen_" + captured_route
				return dummy
		)

	coordinator.start()
	_assert(coordinator.get_current_route() == AppCoordinator.ROUTE_MAIN_MENU, "start() should navigate to ROUTE_MAIN_MENU")
	_assert(screen_container.get_child_count() == 1, "ScreenContainer should have exactly 1 active screen child")
	_assert(coordinator.get_current_screen().name == "Screen_main_menu", "Active screen should be Screen_main_menu")

	coordinator.show_difficulty()
	_assert(coordinator.get_current_route() == AppCoordinator.ROUTE_DIFFICULTY, "show_difficulty() should navigate to ROUTE_DIFFICULTY")
	_assert(screen_container.get_child_count() == 1, "Previous screen should be removed before mounting difficulty screen")
	_assert(coordinator.get_current_screen().name == "Screen_difficulty", "Active screen should be Screen_difficulty")

	var match_cfg := GameModeConfig.vs_ai(Domain.Difficulty.UNBEATABLE, Domain.Mark.X)
	coordinator.show_game(match_cfg)
	_assert(coordinator.get_current_route() == AppCoordinator.ROUTE_GAME, "show_game() should navigate to ROUTE_GAME")
	_assert(coordinator.get_current_config() == match_cfg, "Coordinator should store the active GameModeConfig")
	_assert(coordinator.get_current_screen().name == "Screen_game", "Active screen should be Screen_game")

	coordinator.show_scores()
	_assert(coordinator.get_current_route() == AppCoordinator.ROUTE_SCORES, "show_scores() should navigate to ROUTE_SCORES")

	coordinator.show_settings()
	_assert(coordinator.get_current_route() == AppCoordinator.ROUTE_SETTINGS, "show_settings() should navigate to ROUTE_SETTINGS")

	for child in screen_container.get_children():
		screen_container.remove_child(child)
		child.free()
	screen_container.free()
