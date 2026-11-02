## GUT unit test suite for the `addons/core` domain module.
extends GutTest


## Tests Domain.opponent() and Domain.flip_outcome().
func test_domain_opponent_and_flip_outcome() -> void:
	assert_eq(Domain.opponent(Domain.Mark.X), Domain.Mark.O, "Opponent of X is O")
	assert_eq(Domain.opponent(Domain.Mark.O), Domain.Mark.X, "Opponent of O is X")
	assert_eq(Domain.opponent(Domain.Mark.NONE), Domain.Mark.NONE, "Opponent of NONE is NONE")

	assert_eq(Domain.flip_outcome(Domain.Outcome.WIN), Domain.Outcome.LOSS, "Flip WIN -> LOSS")
	assert_eq(Domain.flip_outcome(Domain.Outcome.LOSS), Domain.Outcome.WIN, "Flip LOSS -> WIN")
	assert_eq(Domain.flip_outcome(Domain.Outcome.DRAW), Domain.Outcome.DRAW, "Flip DRAW -> DRAW")


## Tests initial state of an empty 3x3 Board.
func test_empty_board_initial_state() -> void:
	var b := Board.new()
	assert_eq(b.empty_indices().size(), 9, "New board has 9 empty cells")
	assert_eq(b.moves_played(), 0, "New board has 0 moves played")
	assert_false(b.is_full(), "New board is not full")
	assert_true(b.winner().is_empty(), "New board has no winner")
	assert_eq(b.state_key(), ".........", "New board state_key is 9 dots")


## Tests that placing a mark creates a new Board without modifying the original board.
func test_board_immutability_on_placing() -> void:
	var b0 := Board.new()
	var b1 := b0.placing(Domain.Mark.X, 4)

	assert_eq(b0.cell_at(4), Domain.Mark.NONE, "Original board remains unchanged at index 4")
	assert_eq(b1.cell_at(4), Domain.Mark.X, "New board has X at index 4")
	assert_eq(b1.moves_played(), 1, "New board reports 1 move played")
	assert_eq(b1.state_key(), "....X....", "New board state_key reflects center X")


## Tests that all 8 winning lines (3 rows, 3 cols, 2 diagonals) are detected accurately.
func test_board_all_eight_win_lines() -> void:
	for line in Board.WIN_LINES:
		var b := Board.new()
		b = b.placing(Domain.Mark.X, line[0])
		b = b.placing(Domain.Mark.X, line[1])
		b = b.placing(Domain.Mark.X, line[2])
		var win_info := b.winner()
		assert_false(win_info.is_empty(), "Detects win on line %s" % [str(line)])
		assert_eq(win_info.get("mark"), Domain.Mark.X, "Winner mark is X on line %s" % [str(line)])
		assert_eq(win_info.get("line"), line, "Winning line indices match %s" % [str(line)])


## Tests a full drawn board (no winner, is_full() == true).
func test_board_full_draw_and_state_key() -> void:
	var cells := PackedInt32Array([
		Domain.Mark.X, Domain.Mark.O, Domain.Mark.X,
		Domain.Mark.X, Domain.Mark.O, Domain.Mark.O,
		Domain.Mark.O, Domain.Mark.X, Domain.Mark.X,
	])
	var b := Board.new(cells)
	assert_true(b.is_full(), "Drawn 9-move board is full")
	assert_true(b.winner().is_empty(), "Drawn board has no winner")
	assert_eq(b.state_key(), "XOXXOOOXX", "Drawn board state_key matches")


## Tests ScoreCalculator multipliers and point formulas across outcomes and streaks.
func test_score_calculator_multipliers_and_points() -> void:
	var pts_easy := ScoreCalculator.calculate_points(Domain.Outcome.WIN, Domain.Difficulty.EASY, 5, 1)
	assert_eq(pts_easy, 160, "Win in 5 moves on EASY with streak 1 = 160 pts")

	var pts_draw_unbeatable := ScoreCalculator.calculate_points(Domain.Outcome.DRAW, Domain.Difficulty.UNBEATABLE, 9, 3)
	assert_eq(pts_draw_unbeatable, 240, "Draw on UNBEATABLE rewards 240 pts")

	var pts_loss := ScoreCalculator.calculate_points(Domain.Outcome.LOSS, Domain.Difficulty.HARD, 6, 0)
	assert_eq(pts_loss, 0, "Loss always yields 0 pts")

	var pts_streak_cap := ScoreCalculator.calculate_points(Domain.Outcome.WIN, Domain.Difficulty.MEDIUM, 7, 10)
	assert_eq(pts_streak_cap, 440, "Streak bonus caps at 100 (MEDIUM = 440 pts)")


## Tests that interface classes in addons/core/sources/interfaces can be instantiated and extended.
func test_interfaces_default_contracts() -> void:
	var settings := SettingsRepository.new()
	assert_true(settings.is_music_enabled(), "SettingsRepository default music enabled is true")
	assert_eq(settings.get_locale(), "vi", "SettingsRepository default locale is vi")
