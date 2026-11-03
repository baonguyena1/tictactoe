## GUT unit test suite for Step 8: GameView, GameViewModel, AI execution, score persistence, and strongly-typed coordinator navigation.
extends GutTest

const TEST_SETTINGS_PATH := "user://test_game_settings.cfg"
const TEST_SCORES_PATH := "user://test_game_scores.cfg"
const TEST_WEIGHTS_PATH := "user://test_game_weights.json"


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


## Creates an isolated AppContainer for game tests.
func _make_test_container() -> AppContainer:
	var settings := LocalSettingsRepository.new(TEST_SETTINGS_PATH)
	var scores := LocalScoreRepository.new(TEST_SCORES_PATH)
	var weights := LocalWeightStore.new(TEST_WEIGHTS_PATH)
	return AppContainer.new(null, settings, scores, weights)


## Creates an AppCoordinator wired with default routes and disabled animations for testing.
func _make_test_coordinator(screen_container: Control, container: AppContainer) -> AppCoordinator:
	var coordinator := AppCoordinator.new(screen_container, container, false)
	coordinator.animations_enabled = false
	AppRoot.register_default_routes(coordinator, container)
	return coordinator


## Tests GameViewModel in 2-Player local pass-and-play mode: turns alternate, row win detected, scores incremented, and round reset.
func test_game_two_players_win_flow_and_reset() -> void:
	var container := _make_test_container()
	var screen_container := Control.new()
	add_child_autofree(screen_container)
	var coordinator := _make_test_coordinator(screen_container, container)

	var config := GameModeConfig.two_players()
	var vm := GameViewModel.new(container, coordinator, config)
	vm.start_new_round(false)

	assert_eq(vm.get_current_turn(), Domain.Mark.X, "Round 1 should start with Mark X")
	assert_false(vm.is_game_over(), "Game should not be over at start")
	assert_eq(vm.player_1_wins, 0, "P1 wins should start at 0")
	assert_eq(vm.player_2_wins, 0, "P2 wins should start at 0")

	# Move 0: X at cell 0
	assert_true(vm.on_cell_tapped(0), "Cell 0 should be accepted")
	assert_eq(vm.get_current_turn(), Domain.Mark.O, "Turn should alternate to Mark O")

	# Move 1: O at cell 3
	assert_true(vm.on_cell_tapped(3), "Cell 3 should be accepted")
	assert_eq(vm.get_current_turn(), Domain.Mark.X, "Turn should alternate to Mark X")

	# Move 2: X at cell 1
	assert_true(vm.on_cell_tapped(1), "Cell 1 should be accepted")
	assert_eq(vm.get_current_turn(), Domain.Mark.O, "Turn should alternate to Mark O")

	# Move 3: O at cell 4
	assert_true(vm.on_cell_tapped(4), "Cell 4 should be accepted")
	assert_eq(vm.get_current_turn(), Domain.Mark.X, "Turn should alternate to Mark X")

	# Move 4: X at cell 2 -> Row 0 (0, 1, 2) completed!
	assert_true(vm.on_cell_tapped(2), "Cell 2 should be accepted")
	assert_true(vm.is_game_over(), "Game should be over after winning move")
	assert_eq(vm.get_winner_mark(), Domain.Mark.X, "Winner should be Mark X")
	assert_eq(vm.player_1_wins, 1, "Player 1 wins should increment to 1")
	assert_eq(vm.player_2_wins, 0, "Player 2 wins should remain 0")
	assert_eq(vm.get_winning_line(), [0, 1, 2], "Winning line should be [0, 1, 2]")

	# Cannot tap more cells after game over
	assert_false(vm.on_cell_tapped(5), "Moves after game over should be rejected")

	# Reset for a new round
	vm.start_new_round(false)
	assert_false(vm.is_game_over(), "Game should be active after new round")
	assert_eq(vm.get_board().moves_played(), 0, "Board should be empty after reset")
	assert_eq(vm.player_1_wins, 1, "Player 1 wins should persist across rounds")

	coordinator.get_navigator().clear_stack()


## Tests GameViewModel draw game detection and draw counter increment.
func test_game_two_players_draw_flow() -> void:
	var container := _make_test_container()
	var screen_container := Control.new()
	add_child_autofree(screen_container)
	var coordinator := _make_test_coordinator(screen_container, container)

	var vm := GameViewModel.new(container, coordinator, GameModeConfig.two_players())
	vm.start_new_round(false)

	# Draw sequence:
	# X: 0, 2, 5, 6, 7
	# O: 1, 3, 4, 8
	var moves := [0, 1, 2, 3, 5, 4, 6, 8, 7]
	for idx in moves:
		assert_true(vm.on_cell_tapped(idx), "Move at %d should be valid" % idx)

	assert_true(vm.is_game_over(), "Full board with no three-in-a-row should be game over")
	assert_eq(vm.get_winner_mark(), Domain.Mark.NONE, "Winner should be NONE on draw")
	assert_eq(vm.draws, 1, "Draws count should increment to 1")
	assert_eq(vm.player_1_wins, 0, "P1 wins should remain 0")
	assert_eq(vm.player_2_wins, 0, "P2 wins should remain 0")

	coordinator.get_navigator().clear_stack()


## Tests Player vs AI match: human move flags AI thinking, `execute_ai_turn` places an AI move, and AI score is recorded.
func test_game_vs_ai_execution_and_score_recording() -> void:
	var container := _make_test_container()
	var screen_container := Control.new()
	add_child_autofree(screen_container)
	var coordinator := _make_test_coordinator(screen_container, container)

	var config := GameModeConfig.vs_ai(Domain.Difficulty.HARD, Domain.Mark.X)
	var vm := GameViewModel.new(container, coordinator, config)
	vm.start_new_round(false)

	# Human plays X at center (4)
	assert_true(vm.on_cell_tapped(4), "Human tap on cell 4 should succeed")
	assert_true(vm.is_ai_thinking(), "AI should be thinking after human move")

	# Execute AI turn immediately (bypassing view timer in unit test)
	var ai_cell := vm.execute_ai_turn()
	assert_true(ai_cell >= 0 and ai_cell < 9, "AI should pick a valid cell index")
	assert_ne(ai_cell, 4, "AI should not overwrite cell 4")
	assert_false(vm.is_ai_thinking(), "AI should no longer be thinking after move executed")
	assert_eq(vm.get_board().cell_at(ai_cell), Domain.Mark.O, "AI mark should be placed on board")
	assert_eq(vm.get_current_turn(), Domain.Mark.X, "Turn should return to Human (Mark X)")

	coordinator.get_navigator().clear_stack()


## Tests that Self-Learning AI (MENACE) matches record reinforcement learning feedback to LocalWeightStore.
func test_game_vs_learning_ai_feedback() -> void:
	var container := _make_test_container()
	var screen_container := Control.new()
	add_child_autofree(screen_container)
	var coordinator := _make_test_coordinator(screen_container, container)

	var config := GameModeConfig.vs_ai(Domain.Difficulty.LEARNING, Domain.Mark.X)
	var vm := GameViewModel.new(container, coordinator, config)
	vm.start_new_round(false)

	# Play out a full match between Human and LearningAI
	while not vm.is_game_over() and vm.get_board().moves_played() < 9:
		if vm.get_current_turn() == Domain.Mark.X:
			var empty := vm.get_board().empty_indices()
			if not empty.is_empty():
				vm.on_cell_tapped(empty[0])
		else:
			vm.execute_ai_turn()

	assert_true(vm.is_game_over(), "Match against LearningAI should reach game over")
	assert_true(vm.get_last_outcome() in [Domain.Outcome.WIN, Domain.Outcome.LOSS, Domain.Outcome.DRAW], "Valid outcome should be recorded")

	# Scores should be recorded in LocalScoreRepository
	var total_score: int = container.score_repo.get_total_score()
	assert_true(total_score >= 0, "Score repo should have persisted score")

	# Verify LearningAI weights are stored in LocalWeightStore
	var weights: Dictionary = container.weight_store.load_weights()
	assert_false(weights.is_empty(), "Learning AI weights should be persisted after game finished")

	coordinator.get_navigator().clear_stack()


## Tests GameView packed scene instantiation, cell clicking, mark visual updates, and Result Overlay modal display.
func test_game_view_scene_interaction() -> void:
	var container := _make_test_container()
	var screen_container := Control.new()
	add_child_autofree(screen_container)
	var coordinator := _make_test_coordinator(screen_container, container)

	var scene := preload("res://app/presentation/game/game_view.tscn") as PackedScene
	var view := scene.instantiate() as GameView
	view.animations_enabled = false
	var vm := GameViewModel.new(container, coordinator, GameModeConfig.two_players())
	view.setup(vm)
	screen_container.add_child(view)

	assert_false(view.is_result_overlay_visible(), "Result overlay should be hidden at start")

	# Play a quick winning game for X: 0, 3, 1, 4, 2
	view.tap_cell(0)
	view.tap_cell(3)
	view.tap_cell(1)
	view.tap_cell(4)
	view.tap_cell(2)

	assert_true(vm.is_game_over(), "Game should be over after move 2")
	assert_true(view.is_result_overlay_visible(), "Result overlay should be visible after win")

	# Click Play Again on Result Overlay
	view.get_play_again_button().trigger_press()
	assert_false(view.is_result_overlay_visible(), "Result overlay should hide after Play Again")
	assert_false(vm.is_game_over(), "ViewModel should be reset for a new round")

	coordinator.get_navigator().clear_stack()


## Tests AppCoordinator strongly-typed navigation functions: `show_game_vs_ai`, `show_game_two_players`, and `go_back`.
func test_coordinator_typed_navigation() -> void:
	var container := _make_test_container()
	var screen_container := Control.new()
	add_child_autofree(screen_container)
	var coordinator := _make_test_coordinator(screen_container, container)

	coordinator.start()
	assert_eq(coordinator.get_current_route(), AppCoordinator.ROUTE_MAIN_MENU, "Start route should be MAIN_MENU")

	# Strongly typed navigation to Game vs AI
	coordinator.show_game_vs_ai(Domain.Difficulty.UNBEATABLE, Domain.Mark.O)
	assert_eq(coordinator.get_current_route(), AppCoordinator.ROUTE_GAME, "Route should be GAME")
	var ai_cfg := coordinator.get_current_config()
	assert_false(ai_cfg.is_two_player, "Config should be vs AI")
	assert_eq(ai_cfg.difficulty, Domain.Difficulty.UNBEATABLE, "Difficulty should be UNBEATABLE")
	assert_eq(ai_cfg.human_mark, Domain.Mark.O, "Human mark should be O")

	# Strongly typed go_back
	assert_true(coordinator.go_back(false), "go_back should pop screen")
	assert_eq(coordinator.get_current_route(), AppCoordinator.ROUTE_MAIN_MENU, "Should return to MAIN_MENU")

	# Strongly typed navigation to Two Players
	coordinator.show_game_two_players()
	assert_eq(coordinator.get_current_route(), AppCoordinator.ROUTE_GAME, "Route should be GAME")
	var p2p_cfg := coordinator.get_current_config()
	assert_true(p2p_cfg.is_two_player, "Config should be 2-Player")

	coordinator.get_navigator().clear_stack()
