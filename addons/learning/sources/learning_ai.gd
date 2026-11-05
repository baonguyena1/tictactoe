## Self-learning AI based on Donald Michie's MENACE reinforcement learning algorithm.
## Learns from every match by rewarding winning/drawing moves and penalizing losing moves.
class_name LearningAI
extends MoveStrategy

## Initial number of beads placed for each empty cell in an unseen board state.
const INITIAL_BEADS: int = 3

## Bead adjustment deltas applied after a match finishes (from AI perspective).
const WIN_DELTA: int = 3
const DRAW_DELTA: int = 1
const LOSS_DELTA: int = -1

## Maximum number of recent match outcomes tracked to compute `skill_percent()`.
const MAX_RECENT_HISTORY: int = 20

var _store: WeightStore
var _weights: Dictionary
var _episode_history: Array[Dictionary] = []
var _recent_outcomes: Array[Domain.Outcome] = []
var _rng: RandomNumberGenerator


## Initializes the self-learning AI with a `WeightStore` dependency and optional RNG seed.
func _init(store: WeightStore, seed_value: int = -1) -> void:
	_store = store
	_weights = _store.load_weights().duplicate(true)
	_rng = RandomNumberGenerator.new()
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


## Clears the current match move history when a new game starts.
func on_game_started() -> void:
	_episode_history.clear()


## Chooses a move on `board` using weighted random sampling over the bead counts for `board.state_key()`,
## augmented with basic tactical reflex (wins immediately if possible, blocks 1-move threats).
func choose_move(board: Board, me: Domain.Mark) -> int:
	var empty := board.empty_indices()
	if empty.is_empty():
		return -1

	# Rule 1: Immediate win opportunity
	var win_move := _find_winning_move(board, me)
	if win_move >= 0:
		_record_move(board, win_move)
		return win_move

	# Rule 2: Immediate opponent win block (85% chance to defend against blunder)
	var opponent := Domain.opponent(me)
	var block_move := _find_winning_move(board, opponent)
	if block_move >= 0 and _rng.randf() < 0.85:
		_record_move(board, block_move)
		return block_move

	# Rule 3: Use weighted bead sampling from learned state table
	var key := board.state_key()
	var state_table: Dictionary = _ensure_state_table(key, empty)

	var total_beads := 0
	for move_idx in empty:
		total_beads += int(state_table.get(move_idx, INITIAL_BEADS))

	var pick := _rng.randi_range(0, maxi(total_beads, 1) - 1)
	var chosen_move := empty[0]

	for move_idx in empty:
		var count := int(state_table.get(move_idx, INITIAL_BEADS))
		if pick < count:
			chosen_move = move_idx
			break
		pick -= count

	_episode_history.append({"key": key, "move": chosen_move})
	return chosen_move


func _record_move(board: Board, move_idx: int) -> void:
	var key := board.state_key()
	_ensure_state_table(key, board.empty_indices())
	_episode_history.append({"key": key, "move": move_idx})


## Finds a winning move for `mark` if one exists on `board`, or returns -1 if none.
func _find_winning_move(board: Board, mark: Domain.Mark) -> int:
	for idx in board.empty_indices():
		var candidate := board.placing(mark, idx)
		var win := candidate.winner()
		if not win.is_empty() and win.get("mark") == mark:
			return idx
	return -1


## Updates bead counts for all moves played in the finished match and persists them via `_store`.
func on_game_ended(ai_outcome: Domain.Outcome) -> void:
	var delta := DRAW_DELTA
	match ai_outcome:
		Domain.Outcome.WIN:
			delta = WIN_DELTA
		Domain.Outcome.LOSS:
			delta = LOSS_DELTA
		_:
			delta = DRAW_DELTA

	for step in _episode_history:
		var key: String = step["key"]
		var move_idx: int = step["move"]
		if _weights.has(key):
			var table: Dictionary = _weights[key]
			var old_beads := int(table.get(move_idx, INITIAL_BEADS))
			table[move_idx] = maxi(1, old_beads + delta)

	_episode_history.clear()

	_recent_outcomes.append(ai_outcome)
	if _recent_outcomes.size() > MAX_RECENT_HISTORY:
		_recent_outcomes.pop_front()

	_store.save_weights(_weights)


## Returns the number of unique board states currently stored in memory.
func known_states_count() -> int:
	return _weights.size()


## Returns the bead count for a specific `move_idx` in `state_key` (useful for inspection & unit tests).
func bead_count_for(state_key: String, move_idx: int) -> int:
	if not _weights.has(state_key):
		return INITIAL_BEADS
	var table: Dictionary = _weights[state_key]
	return int(table.get(move_idx, INITIAL_BEADS))


## Computes an estimated AI skill percentage (0..100) from recent non-losing outcomes
## and the number of explored board states.
func skill_percent() -> int:
	if _recent_outcomes.is_empty():
		return mini(100, int(_weights.size() * 100.0 / 300.0))

	var non_losses := 0
	for outcome in _recent_outcomes:
		if outcome != Domain.Outcome.LOSS:
			non_losses += 1
	return int(round(non_losses * 100.0 / _recent_outcomes.size()))


## Resets all learned weights and recent match history back to a blank state.
func reset_memory() -> void:
	_weights.clear()
	_episode_history.clear()
	_recent_outcomes.clear()
	_store.clear_weights()


## Returns the mutable `{ move_idx: bead_count }` dictionary for `key`, initializing it if unseen.
func _ensure_state_table(key: String, empty: Array[int]) -> Dictionary:
	if not _weights.has(key):
		var fresh_table: Dictionary = {}
		for idx in empty:
			fresh_table[idx] = INITIAL_BEADS
		_weights[key] = fresh_table
	return _weights[key]
