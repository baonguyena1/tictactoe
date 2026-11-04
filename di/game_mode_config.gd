## Holds configuration for a single Tic-Tac-Toe match (AI vs Human or 2-Player Local).
class_name GameModeConfig
extends RefCounted

## True when two human players share the same device; false when playing against AI.
var is_two_player: bool = false

## Selected AI difficulty level (ignored when is_two_player is true).
var difficulty: Domain.Difficulty = Domain.Difficulty.MEDIUM

## The mark chosen by the human player (Domain.Mark.X goes first, Domain.Mark.O goes second).
var human_mark: Domain.Mark = Domain.Mark.X


## Initializes a new GameModeConfig with explicit mode, difficulty, and human mark.
func _init(
	p_is_two_player: bool = false,
	p_difficulty: Domain.Difficulty = Domain.Difficulty.MEDIUM,
	p_human_mark: Domain.Mark = Domain.Mark.X
) -> void:
	is_two_player = p_is_two_player
	difficulty = p_difficulty
	human_mark = p_human_mark


## Factory helper that creates a configuration for a Player vs AI match.
static func vs_ai(
	p_difficulty: Domain.Difficulty,
	p_human_mark: Domain.Mark = Domain.Mark.X
) -> GameModeConfig:
	return GameModeConfig.new(false, p_difficulty, p_human_mark)


## Factory helper that creates a configuration for a 2-Player local pass-and-play match.
static func two_players() -> GameModeConfig:
	return GameModeConfig.new(true, Domain.Difficulty.EASY, Domain.Mark.X)


## Returns the mark controlled by the AI opponent.
func get_ai_mark() -> Domain.Mark:
	return Domain.opponent(human_mark)
