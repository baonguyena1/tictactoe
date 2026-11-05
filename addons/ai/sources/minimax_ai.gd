## AI move strategy implementing Easy, Medium, Hard, and Unbeatable difficulties
## using heuristic rules and Minimax with Alpha-Beta pruning.
class_name MinimaxAI
extends MoveStrategy

var _difficulty: Domain.Difficulty
var _rng: RandomNumberGenerator


## Initializes the AI with a target `difficulty` and an optional RNG `seed_value`
## (pass a non-negative seed in unit tests for deterministic behavior).
func _init(difficulty: Domain.Difficulty = Domain.Difficulty.MEDIUM, seed_value: int = -1) -> void:
	_difficulty = difficulty
	_rng = RandomNumberGenerator.new()
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


## Selects the next move index (0..8) for `me` on `board` according to `_difficulty`.
func choose_move(board: Board, me: Domain.Mark) -> int:
	var empty := board.empty_indices()
	if empty.is_empty():
		return -1

	match _difficulty:
		Domain.Difficulty.EASY:
			return _choose_easy(board, me, empty)
		Domain.Difficulty.MEDIUM:
			return _choose_medium(board, me, empty)
		Domain.Difficulty.HARD:
			return _choose_hard(board, me)
		_:
			return _choose_hard(board, me)


## Easy mode: 40% chance to take an immediate win, 30% chance to block an immediate threat, otherwise random.
func _choose_easy(board: Board, me: Domain.Mark, empty: Array[int]) -> int:
	if _rng.randf() < 0.40:
		var win := _find_winning_move(board, me)
		if win >= 0:
			return win
	if _rng.randf() < 0.30:
		var block := _find_winning_move(board, Domain.opponent(me))
		if block >= 0:
			return block
	return empty[_rng.randi_range(0, empty.size() - 1)]


## Medium mode: Always wins immediately -> Always blocks 1-move threat -> Favors center when empty -> Mixes corners & edges to allow fork tactics.
func _choose_medium(board: Board, me: Domain.Mark, empty: Array[int]) -> int:
	var win_now := _find_winning_move(board, me)
	if win_now >= 0:
		return win_now

	var block_now := _find_winning_move(board, Domain.opponent(me))
	if block_now >= 0:
		return block_now

	# On an empty board, always take center (4)
	if board.moves_played() == 0 and board.cell_at(4) == Domain.Mark.NONE:
		return 4

	# If center is available later, take it 50% of the time
	if board.cell_at(4) == Domain.Mark.NONE and _rng.randf() < 0.50:
		return 4

	# Positional choice: 55% corners, 45% edges/any empty cell (enables smart fork wins)
	var corners: Array[int] = []
	for c in [0, 2, 6, 8]:
		if board.cell_at(c) == Domain.Mark.NONE:
			corners.append(c)

	if not corners.is_empty() and _rng.randf() < 0.55:
		return corners[_rng.randi_range(0, corners.size() - 1)]

	return empty[_rng.randi_range(0, empty.size() - 1)]


## Hard mode: Always wins immediately -> Always blocks 1-move threat -> Minimax with Alpha-Beta pruning (never throws game).
func _choose_hard(board: Board, me: Domain.Mark) -> int:
	var win_now := _find_winning_move(board, me)
	if win_now >= 0:
		return win_now

	var block_now := _find_winning_move(board, Domain.opponent(me))
	if block_now >= 0:
		return block_now

	var ranked := ranked_moves(board, me)
	if ranked.is_empty():
		return -1

	# Randomly pick among tied best moves for natural tactical variety
	var best_score: int = ranked[0]["score"]
	var best_moves: Array[int] = []
	for candidate in ranked:
		if candidate["score"] == best_score:
			best_moves.append(candidate["move"])
		else:
			break

	if not best_moves.is_empty():
		return best_moves[_rng.randi_range(0, best_moves.size() - 1)]

	return ranked[0]["move"]


## Evaluates all available moves using Minimax and returns them sorted from best to worst:
## `[{"move": int, "score": int}, ...]`. Equal-scoring moves are shuffled for variety.
func ranked_moves(board: Board, me: Domain.Mark) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var opponent_mark := Domain.opponent(me)

	for idx in board.empty_indices():
		var next_board := board.placing(me, idx)
		var score := _minimax(next_board, opponent_mark, me, 1, -100, 100)
		candidates.append({"move": idx, "score": score})

	# Shuffle before sorting so tied moves are chosen with natural variety
	for i in range(candidates.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := candidates[i]
		candidates[i] = candidates[j]
		candidates[j] = tmp

	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["score"] > b["score"]
	)
	return candidates


## Recursive Minimax search with Alpha-Beta pruning.
## Terminal score: +(10 - depth) if `me` wins, -(10 - depth) if `me` loses, 0 for draw.
func _minimax(
	board: Board,
	turn: Domain.Mark,
	me: Domain.Mark,
	depth: int,
	alpha: int,
	beta: int
) -> int:
	var win_info := board.winner()
	if not win_info.is_empty():
		var winner_mark: Domain.Mark = win_info["mark"]
		return (10 - depth) if winner_mark == me else (depth - 10)

	if board.is_full():
		return 0

	var next_turn := Domain.opponent(turn)
	var cur_alpha := alpha
	var cur_beta := beta

	if turn == me:
		var best := -100
		for idx in board.empty_indices():
			var s := _minimax(board.placing(turn, idx), next_turn, me, depth + 1, cur_alpha, cur_beta)
			best = maxi(best, s)
			cur_alpha = maxi(cur_alpha, best)
			if cur_beta <= cur_alpha:
				break
		return best
	else:
		var best := 100
		for idx in board.empty_indices():
			var s := _minimax(board.placing(turn, idx), next_turn, me, depth + 1, cur_alpha, cur_beta)
			best = mini(best, s)
			cur_beta = mini(cur_beta, best)
			if cur_beta <= cur_alpha:
				break
		return best


## Returns the cell index that gives `mark` an immediate 3-in-a-row win, or -1 if none exists.
func _find_winning_move(board: Board, mark: Domain.Mark) -> int:
	for idx in board.empty_indices():
		var win_info := board.placing(mark, idx).winner()
		if not win_info.is_empty() and win_info["mark"] == mark:
			return idx
	return -1
