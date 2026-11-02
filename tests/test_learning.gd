## Unit test suite for `addons/learning` (`WeightStore` and `LearningAI`).
## Run inside Godot Editor via File -> Run (Shift+Cmd+X).
@tool
extends EditorScript

var _passed: int = 0
var _failed: int = 0


## In-memory WeightStore double for isolated unit testing.
class MemoryWeightStore extends WeightStore:
	var stored: Dictionary = {}

	func load_weights() -> Dictionary:
		return stored.duplicate(true)

	func save_weights(weights: Dictionary) -> void:
		stored = weights.duplicate(true)

	func clear_weights() -> void:
		stored.clear()


func _run() -> void:
	_passed = 0
	_failed = 0
	print("==========================================")
	print("Running Unit Tests: addons/learning (LearningAI)")
	print("==========================================")

	test_initial_move_creates_state_entry()
	test_win_rewards_played_moves()
	test_loss_penalizes_but_never_drops_below_one()
	test_weights_persisted_and_reloaded_from_store()
	test_reset_memory_clears_states_and_store()
	test_skill_percent_tracks_non_losing_rate()

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


## Verifies that choosing a move on an unseen board initializes the state table with INITIAL_BEADS.
func test_initial_move_creates_state_entry() -> void:
	var store := MemoryWeightStore.new()
	var ai := LearningAI.new(store, 42)
	var board := Board.new()

	ai.on_game_started()
	var move := ai.choose_move(board, Domain.Mark.X)

	_assert_true(move >= 0 and move < 9, "Chosen move is a valid cell index (0..8)")
	_assert_eq(ai.known_states_count(), 1, "AI records 1 known board state after first move")
	_assert_eq(ai.bead_count_for(board.state_key(), move), LearningAI.INITIAL_BEADS, "Initial bead count is INITIAL_BEADS (3)")


## Verifies that winning a match increases the bead count of played moves by WIN_DELTA (+3).
func test_win_rewards_played_moves() -> void:
	var store := MemoryWeightStore.new()
	var ai := LearningAI.new(store, 42)
	var board := Board.new()
	var key := board.state_key()

	ai.on_game_started()
	var move := ai.choose_move(board, Domain.Mark.X)
	ai.on_game_ended(Domain.Outcome.WIN)

	var expected := LearningAI.INITIAL_BEADS + LearningAI.WIN_DELTA
	_assert_eq(ai.bead_count_for(key, move), expected, "Winning move beads increased from 3 to 6")


## Verifies that repeated losses decrease bead counts by LOSS_DELTA (-1) but clamp at minimum 1.
func test_loss_penalizes_but_never_drops_below_one() -> void:
	var store := MemoryWeightStore.new()
	var ai := LearningAI.new(store, 99)
	# Board with only 1 empty cell (index 8) so AI must always pick index 8
	var cells := PackedInt32Array([
		Domain.Mark.X, Domain.Mark.O, Domain.Mark.X,
		Domain.Mark.O, Domain.Mark.X, Domain.Mark.O,
		Domain.Mark.O, Domain.Mark.X, Domain.Mark.NONE,
	])
	var board := Board.new(cells)
	var key := board.state_key()

	for _i in range(5):
		ai.on_game_started()
		var move := ai.choose_move(board, Domain.Mark.O)
		_assert_eq(move, 8, "Only empty cell 8 is chosen")
		ai.on_game_ended(Domain.Outcome.LOSS)

	_assert_eq(ai.bead_count_for(key, 8), 1, "Bead count never drops below 1 even after 5 losses")


## Verifies that weights saved into WeightStore are restored when a new LearningAI is initialized.
func test_weights_persisted_and_reloaded_from_store() -> void:
	var store := MemoryWeightStore.new()
	var ai1 := LearningAI.new(store, 7)
	var board := Board.new()

	ai1.on_game_started()
	var move := ai1.choose_move(board, Domain.Mark.X)
	ai1.on_game_ended(Domain.Outcome.WIN)

	# Create a second AI instance sharing the same store
	var ai2 := LearningAI.new(store, 7)
	_assert_eq(ai2.known_states_count(), 1, "Reloaded AI restores 1 known state from store")
	_assert_eq(
		ai2.bead_count_for(board.state_key(), move),
		LearningAI.INITIAL_BEADS + LearningAI.WIN_DELTA,
		"Reloaded AI preserves updated bead count (6)"
	)


## Verifies that reset_memory() wipes both in-memory weights and the backing store.
func test_reset_memory_clears_states_and_store() -> void:
	var store := MemoryWeightStore.new()
	var ai := LearningAI.new(store, 11)
	var board := Board.new()

	ai.on_game_started()
	ai.choose_move(board, Domain.Mark.X)
	ai.on_game_ended(Domain.Outcome.DRAW)
	_assert_eq(ai.known_states_count(), 1, "Has 1 state before reset")

	ai.reset_memory()
	_assert_eq(ai.known_states_count(), 0, "Has 0 states after reset_memory()")
	_assert_true(store.load_weights().is_empty(), "Backing WeightStore is also empty after reset")


## Verifies that skill_percent() reflects the non-loss percentage across recent matches.
func test_skill_percent_tracks_non_losing_rate() -> void:
	var store := MemoryWeightStore.new()
	var ai := LearningAI.new(store, 21)
	var board := Board.new()

	# Record 3 wins/draws and 1 loss -> 3/4 = 75%
	for outcome in [Domain.Outcome.WIN, Domain.Outcome.DRAW, Domain.Outcome.WIN, Domain.Outcome.LOSS]:
		ai.on_game_started()
		ai.choose_move(board, Domain.Mark.X)
		ai.on_game_ended(outcome)

	_assert_eq(ai.skill_percent(), 75, "3 non-losses out of 4 games = 75% skill")
