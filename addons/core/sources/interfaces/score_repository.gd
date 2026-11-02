## Abstract repository interface for reading and persisting player scores and match statistics.
class_name ScoreRepository
extends RefCounted


## Returns the cumulative total score across all AI matches.
func get_total_score() -> int:
	return 0


## Returns the highest score achieved in a single AI match.
func get_best_game_score() -> int:
	return 0


## Returns the current consecutive win streak against AI.
func get_current_streak() -> int:
	return 0


## Returns the all-time longest consecutive win streak against AI.
func get_best_streak() -> int:
	return 0


## Returns match counts `{ "wins": int, "draws": int, "losses": int }` for a given difficulty.
func get_stats_for_difficulty(_difficulty: Domain.Difficulty) -> Dictionary:
	return {"wins": 0, "draws": 0, "losses": 0}


## Records a finished AI match, updates streak and totals, and returns the points earned.
func record_ai_match(_outcome: Domain.Outcome, _difficulty: Domain.Difficulty, _moves_played: int) -> int:
	push_error("ScoreRepository.record_ai_match() must be overridden.")
	return 0
