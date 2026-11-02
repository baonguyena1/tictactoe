## GUT unit test suite for `app/data/` (`LocalSettingsRepository`, `LocalScoreRepository`, `LocalWeightStore`).
extends GutTest

const TEST_SETTINGS_PATH := "user://test_settings.cfg"
const TEST_SCORES_PATH := "user://test_scores.cfg"
const TEST_WEIGHTS_PATH := "user://test_menace_weights.json"


## Cleans up temporary test files before each test.
func before_each() -> void:
	_cleanup_test_files()


## Cleans up temporary test files after each test.
func after_each() -> void:
	_cleanup_test_files()


## Removes temporary test files from `user://`.
func _cleanup_test_files() -> void:
	for path in [TEST_SETTINGS_PATH, TEST_SCORES_PATH, TEST_WEIGHTS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Verifies that LocalSettingsRepository saves preferences to disk and reloads them accurately.
func test_local_settings_persistence_and_locale() -> void:
	var repo1 := LocalSettingsRepository.new(TEST_SETTINGS_PATH)
	assert_true(repo1.is_music_enabled(), "Default music_enabled is true")
	assert_eq(repo1.get_locale(), "vi", "Default locale is vi")

	repo1.set_music_enabled(false)
	repo1.set_sfx_enabled(false)
	repo1.set_haptics_enabled(false)
	repo1.set_locale("en")

	var repo2 := LocalSettingsRepository.new(TEST_SETTINGS_PATH)
	assert_false(repo2.is_music_enabled(), "Reloaded music_enabled is false")
	assert_false(repo2.is_sfx_enabled(), "Reloaded sfx_enabled is false")
	assert_false(repo2.is_haptics_enabled(), "Reloaded haptics_enabled is false")
	assert_eq(repo2.get_locale(), "en", "Reloaded locale is en")


## Verifies that LocalScoreRepository computes points, tracks streaks, and persists W/D/L stats.
func test_local_score_repository_persistence_and_streaks() -> void:
	var repo1 := LocalScoreRepository.new(TEST_SCORES_PATH)
	var pts1 := repo1.record_ai_match(Domain.Outcome.WIN, Domain.Difficulty.MEDIUM, 5)
	assert_eq(pts1, 320, "First win on MEDIUM in 5 moves awards 320 pts")
	assert_eq(repo1.get_current_streak(), 1, "Current streak is 1")

	var pts2 := repo1.record_ai_match(Domain.Outcome.WIN, Domain.Difficulty.HARD, 7)
	assert_eq(pts2, 640, "Second win on HARD in 7 moves awards 640 pts")
	assert_eq(repo1.get_current_streak(), 2, "Current streak is 2")
	assert_eq(repo1.get_best_streak(), 2, "Best streak is 2")

	repo1.record_ai_match(Domain.Outcome.LOSS, Domain.Difficulty.UNBEATABLE, 6)
	assert_eq(repo1.get_current_streak(), 0, "Loss resets current_streak to 0")
	assert_eq(repo1.get_best_streak(), 2, "Best streak remains 2 after loss")

	var repo2 := LocalScoreRepository.new(TEST_SCORES_PATH)
	assert_eq(repo2.get_total_score(), 960, "Reloaded total_score is 960 (320 + 640)")
	assert_eq(repo2.get_best_game_score(), 640, "Reloaded best_game_score is 640")
	assert_eq(repo2.get_stats_for_difficulty(Domain.Difficulty.MEDIUM)["wins"], 1, "MEDIUM wins count is 1")
	assert_eq(repo2.get_stats_for_difficulty(Domain.Difficulty.UNBEATABLE)["losses"], 1, "UNBEATABLE losses count is 1")


## Verifies that LocalWeightStore saves and reloads MENACE weights with integer move keys intact.
func test_local_weight_store_json_int_key_roundtrip() -> void:
	var store := LocalWeightStore.new(TEST_WEIGHTS_PATH)
	var ai1 := LearningAI.new(store, 123)
	var board := Board.new()

	ai1.on_game_started()
	var move := ai1.choose_move(board, Domain.Mark.X)
	ai1.on_game_ended(Domain.Outcome.WIN)

	var store2 := LocalWeightStore.new(TEST_WEIGHTS_PATH)
	var ai2 := LearningAI.new(store2, 123)
	assert_eq(ai2.known_states_count(), 1, "JSON LocalWeightStore restores 1 learned state")
	assert_eq(
		ai2.bead_count_for(board.state_key(), move),
		LearningAI.INITIAL_BEADS + LearningAI.WIN_DELTA,
		"JSON LocalWeightStore converts string keys back to int and restores bead count (6)"
	)
