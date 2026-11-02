## Abstract strategy interface for any AI player implementation (Minimax or Self-Learning).
class_name MoveStrategy
extends RefCounted

## Selects the next cell index (0..8) for `me` on the given `board`.
## Returns -1 if no valid move is available.
func choose_move(_board: Board, _me: Domain.Mark) -> int:
	push_error("MoveStrategy.choose_move() must be overridden by subclass.")
	return -1
	
## Called when a new match starts so stateful strategies can reset per-match history.
func on_game_started() -> void:
	pass

## Called when a match ends (`ai_outcome` is from the AI's perspective: WIN, DRAW, or LOSS).
func on_game_ended(_ai_outcome: Domain.Outcome) -> void:
	pass
