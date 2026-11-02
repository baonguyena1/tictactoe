## Headless unit test runner for the `addons/core` domain module.
## Run with: Godot --headless -s res://tests/test_core.gd
@tool
extends EditorScript

var _passed: int = 0
var _failed: int = 0


func _run() -> void:
	_passed = 0
	_failed = 0
	print("==========================================")
	print("Running Unit Tests: addons/core")
	print("==========================================")

	test_domain_opponent_and_flip_outcome()
	test_empty_board_initial_state()
	test_board_immutability_on_placing()
	test_board_all_eight_win_lines()
	test_board_full_draw_and_state_key()
	test_score_calculator_multipliers_and_points()
	test_interfaces_default_contracts()

	print("------------------------------------------")
	print("Results: %d passed, %d failed" % [_passed, _failed])
	print("==========================================")


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


## Tests Domain.opponent() and Domain.flip_outcome().
func test_domain_opponent_and_flip_outcome() -> void:
	_assert_eq(Domain.opponent(Domain.Mark.X), Domain.Mark.O, "Opponent of X is O")
	_assert_eq(Domain.opponent(Domain.Mark.O), Domain.Mark.X, "Opponent of O is X")
	_assert_eq(Domain.opponent(Domain.Mark.NONE), Domain.Mark.NONE, "Opponent of NONE is NONE")

	_assert_eq(Domain.flip_outcome(Domain.Outcome.WIN), Domain.Outcome.LOSS, "Flip WIN -> LOSS")
	_assert_eq(Domain.flip_outcome(Domain.Outcome.LOSS), Domain.Outcome.WIN, "Flip LOSS -> WIN")
	_assert_eq(Domain.flip_outcome(Domain.Outcome.DRAW), Domain.Outcome.DRAW, "Flip DRAW -> DRAW")


## Tests initial state of an empty 3x3 Board.
func test_empty_board_initial_state() -> void:
	var b := Board.new()
	_assert_eq(b.empty_indices().size(), 9, "New board has 9 empty cells")
	_assert_eq(b.moves_played(), 0, "New board has 0 moves played")
	_assert_true(not b.is_full(), "New board is not full")
	_assert_true(b.winner().is_empty(), "New board has no winner")
	_assert_eq(b.state_key(), ".........", "New board state_key is 9 dots")


## Tests that placing a mark creates a new Board without modifying the original board.
func test_board_immutability_on_placing() -> void:
	var b0 := Board.new()
	var b1 := b0.placing(Domain.Mark.X, 4)

	_assert_eq(b0.cell_at(4), Domain.Mark.NONE, "Original board remains unchanged at index 4")
	_assert_eq(b1.cell_at(4), Domain.Mark.X, "New board has X at index 4")
	_assert_eq(b1.moves_played(), 1, "New board reports 1 move played")
	_assert_eq(b1.state_key(), "....X....", "New board state_key reflects center X")


## Tests that all 8 winning lines (3 rows, 3 cols, 2 diagonals) are detected accurately.
func test_board_all_eight_win_lines() -> void:
	for line in Board.WIN_LINES:
		var b := Board.new()
		b = b.placing(Domain.Mark.X, line[0])
		b = b.placing(Domain.Mark.X, line[1])
		b = b.placing(Domain.Mark.X, line[2])
		var win_info := b.winner()
		_assert_true(not win_info.is_empty(), "Detects win on line %s" % [str(line)])
		_assert_eq(win_info.get("mark"), Domain.Mark.X, "Winner mark is X on line %s" % [str(line)])
		_assert_eq(win_info.get("line"), line, "Winning line indices match %s" % [str(line)])


## Tests a full drawn board (no winner, is_full() == true).
func test_board_full_draw_and_state_key() -> void:
	# X O X
	# X O O
	# O X X
	var cells := PackedInt32Array([
		Domain.Mark.X, Domain.Mark.O, Domain.Mark.X,
		Domain.Mark.X, Domain.Mark.O, Domain.Mark.O,
		Domain.Mark.O, Domain.Mark.X, Domain.Mark.X,
	])
	var b := Board.new(cells)
	_assert_true(b.is_full(), "Drawn 9-move board is full")
	_assert_true(b.winner().is_empty(), "Drawn board has no winner")
	_assert_eq(b.state_key(), "XOXOOOX" + "XX".substr(0, 0) if false else "XOXXOOOXX", "Drawn board state_key matches")


## Tests ScoreCalculator multipliers and point formulas across outcomes and streaks.
func test_score_calculator_multipliers_and_points() -> void:
	# Fast win in 5 moves on EASY (mult 1), streak 1:
	# base = 100 + (9 - 5)*10 + min(1*20, 100) = 100 + 40 + 20 = 160
	var pts_easy := ScoreCalculator.calculate_points(Domain.Outcome.WIN, Domain.Difficulty.EASY, 5, 1)
	_assert_eq(pts_easy, 160, "Win in 5 moves on EASY with streak 1 = 160 pts")

	# Draw on UNBEATABLE (mult 8): 30 * 8 = 240
	var pts_draw_unbeatable := ScoreCalculator.calculate_points(Domain.Outcome.DRAW, Domain.Difficulty.UNBEATABLE, 9, 3)
	_assert_eq(pts_draw_unbeatable, 240, "Draw on UNBEATABLE rewards 240 pts")

	# Loss on HARD (mult 4): 0
	var pts_loss := ScoreCalculator.calculate_points(Domain.Outcome.LOSS, Domain.Difficulty.HARD, 6, 0)
	_assert_eq(pts_loss, 0, "Loss always yields 0 pts")

	# Streak cap at 100 (streak = 10 -> bonus capped at 100):
	# moves = 7 -> speed = 20, base = 100 + 20 + 100 = 220, MEDIUM (mult 2) -> 440
	var pts_streak_cap := ScoreCalculator.calculate_points(Domain.Outcome.WIN, Domain.Difficulty.MEDIUM, 7, 10)
	_assert_eq(pts_streak_cap, 440, "Streak bonus caps at 100 (MEDIUM = 440 pts)")


## Tests that interface classes in addons/core/interfaces can be instantiated and extended.
func test_interfaces_default_contracts() -> void:
	var settings := SettingsRepository.new()
	_assert_true(settings.is_music_enabled(), "SettingsRepository default music enabled is true")
	_assert_eq(settings.get_locale(), "vi", "SettingsRepository default locale is vi")
