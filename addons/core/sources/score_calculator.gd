## Pure domain service that computes match points based on outcome, difficulty, speed, and win streak.
class_name ScoreCalculator
extends RefCounted

## Returns the score multiplier associated with the selected AI difficulty.
static func multiplier(difficulty: Domain.Difficulty) -> int:
	match difficulty:
		Domain.Difficulty.EASY:
			return 1
		Domain.Difficulty.MEDIUM:
			return 2
		Domain.Difficulty.LEARNING:
			return 3
		Domain.Difficulty.HARD:
			return 4
		Domain.Difficulty.UNBEATABLE:
			return 8
		_:
			return 1


## Calculates the final score earned in a single match against the AI.
## Formula: (base_points + speed_bonus + streak_bonus) * difficulty_multiplier.
static func calculate_points(
	outcome: Domain.Outcome,
	difficulty: Domain.Difficulty,
	moves_played: int,
	current_streak: int
) -> int:
	var base := 0
	match outcome:
		Domain.Outcome.WIN:
			var speed_bonus := maxi(0, (9 - moves_played) * 10)
			var streak_bonus := mini(current_streak * 20, 100)
			base = 100 + speed_bonus + streak_bonus
		Domain.Outcome.DRAW:
			base = 30
		Domain.Outcome.LOSS:
			base = 0
	return base * multiplier(difficulty)
