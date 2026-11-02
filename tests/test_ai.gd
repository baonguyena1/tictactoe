## Headless unit test runner for the `addons/ai` module (`MinimaxAI`).
## Run with: Godot --headless -s res://tests/test_ai.gd
@tool
extends EditorScript

var _passed: int = 0
var _failed: int = 0


func _run() -> void:
	_passed = 0
	_failed = 0
	print("==========================================")
	print("Running Unit Tests: addons/ai (MinimaxAI)")
	print("==========================================")

	test_immediate_win_taken()
	test_immediate_threat_blocked()
	test_medium_prefers_center_on_empty_board()
	test_unbeatable_vs_unbeatable_always_draws()
	test_unbeatable_never_loses_as_x_or_o()
	test_easy_can_be_beaten_by_unbeatable()

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


## Tests that Medium and Unbeatable AI immediately take a winning 3-in-a-row move.
func test_immediate_win_taken() -> void:
	# O O .
	# X X .
	# . . .
	var cells := PackedInt32Array([
		Domain.Mark.O, Domain.Mark.O, Domain.Mark.NONE,
		Domain.Mark.X, Domain.Mark.X, Domain.Mark.NONE,
		Domain.Mark.NONE, Domain.Mark.NONE, Domain.Mark.NONE,
	])
	var board := Board.new(cells)
	var medium_ai := MinimaxAI.new(Domain.Difficulty.MEDIUM, 42)
	var unbeatable_ai := MinimaxAI.new(Domain.Difficulty.UNBEATABLE, 42)

	_assert_eq(medium_ai.choose_move(board, Domain.Mark.O), 2, "MEDIUM AI takes immediate winning move at cell 2")
	_assert_eq(unbeatable_ai.choose_move(board, Domain.Mark.O), 2, "UNBEATABLE AI takes immediate winning move at cell 2")


## Tests that Medium and Unbeatable AI block an opponent's immediate winning threat.
func test_immediate_threat_blocked() -> void:
	# X X .
	# . O .
	# . . .
	var cells := PackedInt32Array([
		Domain.Mark.X, Domain.Mark.X, Domain.Mark.NONE,
		Domain.Mark.NONE, Domain.Mark.O, Domain.Mark.NONE,
		Domain.Mark.NONE, Domain.Mark.NONE, Domain.Mark.NONE,
	])
	var board := Board.new(cells)
	var medium_ai := MinimaxAI.new(Domain.Difficulty.MEDIUM, 42)
	var unbeatable_ai := MinimaxAI.new(Domain.Difficulty.UNBEATABLE, 42)

	_assert_eq(medium_ai.choose_move(board, Domain.Mark.O), 2, "MEDIUM AI blocks X threat at cell 2")
	_assert_eq(unbeatable_ai.choose_move(board, Domain.Mark.O), 2, "UNBEATABLE AI blocks X threat at cell 2")


## Tests that Medium AI takes the center cell (4) when available and no threats exist.
func test_medium_prefers_center_on_empty_board() -> void:
	var board := Board.new()
	var medium_ai := MinimaxAI.new(Domain.Difficulty.MEDIUM, 10)
	_assert_eq(medium_ai.choose_move(board, Domain.Mark.X), 4, "MEDIUM AI takes center cell 4 on empty board")


## Tests that two Unbeatable AIs playing against each other always end in a draw.
func test_unbeatable_vs_unbeatable_always_draws() -> void:
	var ai_x := MinimaxAI.new(Domain.Difficulty.UNBEATABLE, 101)
	var ai_o := MinimaxAI.new(Domain.Difficulty.UNBEATABLE, 202)
	var draws := 0

	for _match_idx in range(10):
		var board := Board.new()
		var turn := Domain.Mark.X
		while board.winner().is_empty() and not board.is_full():
			var move := ai_x.choose_move(board, turn) if turn == Domain.Mark.X else ai_o.choose_move(board, turn)
			board = board.placing(turn, move)
			turn = Domain.opponent(turn)
		if board.winner().is_empty():
			draws += 1

	_assert_eq(draws, 10, "10 matches of UNBEATABLE vs UNBEATABLE all end in DRAW")


## Simulates 200 matches of UNBEATABLE AI against a random opponent (100 as X, 100 as O)
## and verifies 0 losses.
func test_unbeatable_never_loses_as_x_or_o() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	var ai := MinimaxAI.new(Domain.Difficulty.UNBEATABLE, 777)
	var ai_losses := 0

	for i in range(200):
		var ai_mark := Domain.Mark.X if i < 100 else Domain.Mark.O
		var board := Board.new()
		var turn := Domain.Mark.X

		while board.winner().is_empty() and not board.is_full():
			var move := -1
			if turn == ai_mark:
				move = ai.choose_move(board, ai_mark)
			else:
				var empty := board.empty_indices()
				move = empty[rng.randi_range(0, empty.size() - 1)]
			board = board.placing(turn, move)
			turn = Domain.opponent(turn)

		var win_info := board.winner()
		if not win_info.is_empty() and win_info["mark"] != ai_mark:
			ai_losses += 1

	_assert_eq(ai_losses, 0, "UNBEATABLE AI has 0 losses across 200 matches (both X and O)")


## Verifies that EASY AI is beatable (Unbeatable AI wins majority of games against Easy AI).
func test_easy_can_be_beaten_by_unbeatable() -> void:
	var easy_ai := MinimaxAI.new(Domain.Difficulty.EASY, 123)
	var pro_ai := MinimaxAI.new(Domain.Difficulty.UNBEATABLE, 456)
	var pro_wins := 0

	for _i in range(30):
		var board := Board.new()
		var turn := Domain.Mark.X
		while board.winner().is_empty() and not board.is_full():
			var move := pro_ai.choose_move(board, turn) if turn == Domain.Mark.X else easy_ai.choose_move(board, turn)
			board = board.placing(turn, move)
			turn = Domain.opponent(turn)
		var win_info := board.winner()
		if not win_info.is_empty() and win_info["mark"] == Domain.Mark.X:
			pro_wins += 1

	_assert_true(pro_wins >= 20, "UNBEATABLE AI beats EASY AI in at least 20/30 matches (won %d/30)" % [pro_wins])
