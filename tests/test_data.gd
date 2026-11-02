## Unit test suite for `app/data/` (`LocalSettingsRepository`, `LocalScoreRepository`, `LocalWeightStore`).
## Run inside Godot Editor via File -> Run (Shift+Cmd+X).
@tool
extends EditorScript

const TEST_SETTINGS_PATH := "user://test_settings.cfg"
const TEST_SCORES_PATH := "user://test_scores.cfg"
const TEST_WEIGHTS_PATH := "user://test_menace_weights.json"

var _passed: int = 0
var _failed: int = 0


func _run() -> void:
	_passed = 0
	_failed = 0
	print("==========================================")
	print("Running Unit Tests: app/data (Data Layer)")
	print("==========================================")

	_cleanup_test_files()
	test_local_settings_persistence_and_locale()
	test_local_score_repository_persistence_and_streaks()
	test_local_weight_store_json_int_key_roundtrip()
	_cleanup_test_files()

	print("------------------------------------------")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	print("==========================================")


## Removes temporary test files from `user://`.
func _cleanup_test_files() -> void:
	for path in [TEST_SETTINGS_PATH, TEST_SCORES_PATH, TEST_WEIGHTS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Asserts a boolean condition and logs pass/fail.
func _assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] ", message)
	else:
		_failed += 1
		printerr("  [FAIL] ", message)


## Asserts equality between two values.
func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		_passed += 1
		print("  [PASS] ", message)
	else:
		_failed += 1
		printerr("  [FAIL] %s (expected: %s, got: %s)" % [message, str(expected), str(actual)])


## Verifies that LocalSettingsRepository saves preferences to disk and reloads them accurately.
func test_local_settings_persistence_and_locale() -> void:
	var repo1 := LocalSettingsRepository.new(TEST_SETTINGS_PATH)
	_assert_true(repo1.is_music_enabled(), "Default music_enabled is true")
	_assert_eq(repo1.get_locale(), "vi", "Default locale is vi")

	repo1.set_music_enabled(false)
	repo1.set_sfx_enabled(false)
	repo1.set_haptics_enabled(false)
	repo1.set_locale("en")

	var repo2 := LocalSettingsRepository.new(TEST_SETTINGS_PATH)
	_assert_true(not repo2.is_music_enabled(), "Reloaded music_enabled is false")
	_assert_true(not repo2.is_sfx_enabled(), "Reloaded sfx_enabled is false")
	_assert_true(not repo2.is_haptics_enabled(), "Reloaded haptics_enabled is false")
	_assert_eq(repo2.get_locale(), "en", "Reloaded locale is en")


## Verifies that LocalScoreRepository computes points, tracks streaks, and persists W/D/L stats.
func test_local_score_repository_persistence_and_streaks() -> void:
	var repo1 := LocalScoreRepository.new(TEST_SCORES_PATH)
	# Win 1 on MEDIUM (mult 2) in 5 moves: (100 + 40 + 20) * 2 = 320
	var pts1 := repo1.record_ai_match(Domain.Outcome.WIN, Domain.Difficulty.MEDIUM, 5)
	_assert_eq(pts1, 320, "First win on MEDIUM in 5 moves awards 320 pts")
	_assert_eq(repo1.get_current_streak(), 1, "Current streak is 1")

	# Win 2 on HARD (mult 4) in 7 moves: (100 + 20 + 40) * 4 = 640
	var pts2 := repo1.record_ai_match(Domain.Outcome.WIN, Domain.Difficulty.HARD, 7)
	_assert_eq(pts2, 640, "Second win on HARD in 7 moves awards 640 pts")
	_assert_eq(repo1.get_current_streak(), 2, "Current streak is 2")
	_assert_eq(repo1.get_best_streak(), 2, "Best streak is 2")

	# Loss on UNBEATABLE resets current_streak but preserves best_streak
	repo1.record_ai_match(Domain.Outcome.LOSS, Domain.Difficulty.UNBEATABLE, 6)
	_assert_eq(repo1.get_current_streak(), 0, "Loss resets current_streak to 0")
	_assert_eq(repo1.get_best_streak(), 2, "Best streak remains 2 after loss")

	# Reload from disk and verify totals & difficulty stats
	var repo2 := LocalScoreRepository.new(TEST_SCORES_PATH)
	_assert_eq(repo2.get_total_score(), 960, "Reloaded total_score is 960 (320 + 640)")
	_assert_eq(repo2.get_best_game_score(), 640, "Reloaded best_game_score is 640")
	_assert_eq(repo2.get_stats_for_difficulty(Domain.Difficulty.MEDIUM)["wins"], 1, "MEDIUM wins count is 1")
	_assert_eq(repo2.get_stats_for_difficulty(Domain.Difficulty.UNBEATABLE)["losses"], 1, "UNBEATABLE losses count is 1")


## Verifies that LocalWeightStore saves and reloads MENACE weights with integer move keys intact.
func test_local_weight_store_json_int_key_roundtrip() -> void:
	var store := LocalWeightStore.new(TEST_WEIGHTS_PATH)
	var ai1 := LearningAI.new(store, 123)
	var board := Board.new()

	ai1.on_game_started()
	var move := ai1.choose_move(board, Domain.Mark.X)
	ai1.on_game_ended(Domain.Outcome.WIN)

	# Reload via a second LearningAI instance backed by the same JSON file
	var store2 := LocalWeightStore.new(TEST_WEIGHTS_PATH)
	var ai2 := LearningAI.new(store2, 123)
	_assert_eq(ai2.known_states_count(), 1, "JSON LocalWeightStore restores 1 learned state")
	_assert_eq(
		ai2.bead_count_for(board.state_key(), move),
		LearningAI.INITIAL_BEADS + LearningAI.WIN_DELTA,
		"JSON LocalWeightStore converts string keys back to int and restores bead count (6)"
	)
