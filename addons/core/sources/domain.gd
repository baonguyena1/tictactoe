## Core domain enumerations and value helpers for Tic-Tac-Toe.
class_name Domain
extends RefCounted

## Represents the state of a board cell or a player's piece.
enum Mark {
	NONE = 0,
	X = 1,
	O = 2,
}

## Available AI difficulty levels.
enum Difficulty {
	EASY = 0,
	MEDIUM = 1,
	HARD = 2,
	UNBEATABLE = 3,
	LEARNING = 4,
}

## Match result from a specific player's perspective.
enum Outcome {
	WIN = 0,
	DRAW = 1,
	LOSS = 2,
}


## Returns the opposing player's mark (X -> O, O -> X, NONE -> NONE).
static func opponent(mark: Mark) -> Mark:
	if mark == Mark.X:
		return Mark.O
	if mark == Mark.O:
		return Mark.X
	return Mark.NONE


## Inverts the match outcome to switch between human and AI perspectives
## (e.g., a human WIN becomes an AI LOSS).
static func flip_outcome(outcome: Outcome) -> Outcome:
	match outcome:
		Outcome.WIN:
			return Outcome.LOSS
		Outcome.LOSS:
			return Outcome.WIN
		_:
			return Outcome.DRAW
