## ViewModel for the 3x3 Game screen managing the Board state, human and AI turns, match scoreboard, score calculation, and Self-Learning AI feedback.
class_name GameViewModel
extends RefCounted

## Emitted whenever the board, turn status, scoreboard, or match outcome changes.
signal state_changed

## Emitted when a mark (`X` or `O`) is placed at `cell_index` (`0..8`) so the view can animate chalk drawing and dust particles.
signal cell_marked(cell_index: int, mark: Domain.Mark)

## Emitted when the board is wiped clean for a new round.
signal board_wiped

## Emitted when the match finishes (`outcome` is from Player 1 / Human perspective; `winning_line` is empty on a draw).
signal match_finished(outcome: Domain.Outcome, winning_line: Array, points_awarded: int)

var _container: AppContainer
var _coordinator: AppCoordinator
var _config: GameModeConfig
var _ai_strategy: MoveStrategy = null
var _board: Board
var _current_turn: Domain.Mark = Domain.Mark.X
var _is_game_over: bool = false
var _is_ai_thinking: bool = false
var _winning_line: Array = []
var _last_outcome: Domain.Outcome = Domain.Outcome.DRAW
var _last_points_awarded: int = 0
var _winner_mark: Domain.Mark = Domain.Mark.NONE

## Session scoreboard counters (`player_1_wins` = Human or X, `player_2_wins` = AI or O, `draws`).
var player_1_wins: int = 0
var player_2_wins: int = 0
var draws: int = 0


## Initializes the GameViewModel with the DI container, navigation coordinator, and match configuration.
func _init(
	container: AppContainer,
	coordinator: AppCoordinator,
	config: GameModeConfig = null
) -> void:
	_container = container
	_coordinator = coordinator
	_config = config if config != null else GameModeConfig.vs_ai(Domain.Difficulty.MEDIUM, Domain.Mark.X)
	if not _config.is_two_player:
		_ai_strategy = _container.make_move_strategy(_config.difficulty)
	_board = Board.new()


## Returns the AudioService instance from the DI container.
func get_audio_service() -> AudioService:
	return _container.audio_service


## Returns the active GameModeConfig for this match.
func get_config() -> GameModeConfig:
	return _config


## Returns the current immutable Board snapshot.
func get_board() -> Board:
	return _board


## Returns the mark whose turn it currently is (`Domain.Mark.X` or `Domain.Mark.O`).
func get_current_turn() -> Domain.Mark:
	return _current_turn


## Returns true if the current round has finished (win or draw).
func is_game_over() -> bool:
	return _is_game_over


## Returns true while the AI is waiting to execute its move.
func is_ai_thinking() -> bool:
	return _is_ai_thinking


## Returns the 3 winning cell indices if a player won, or an empty Array on draw/ongoing.
func get_winning_line() -> Array:
	return _winning_line


## Returns the points earned in the most recently finished AI match.
func get_last_points_awarded() -> int:
	return _last_points_awarded


## Returns the mark of the winner (`Domain.Mark.X`, `Domain.Mark.O`, or `Domain.Mark.NONE` for draw).
func get_winner_mark() -> Domain.Mark:
	return _winner_mark


## Returns the outcome of the most recently finished match from Player 1 / Human perspective.
func get_last_outcome() -> Domain.Outcome:
	return _last_outcome


## Returns the active consecutive win streak against AI.
func get_current_streak() -> int:
	if _container != null and _container.score_repo != null:
		return _container.score_repo.get_current_streak()
	return 0


## Starts or resets a round on the 3x3 board. If AI plays X (human chose O), prepares the AI opening move.
func start_new_round(play_wipe_sound: bool = false) -> void:
	_board = Board.new()
	_current_turn = Domain.Mark.X
	_is_game_over = false
	_is_ai_thinking = false
	_winning_line = []
	_last_points_awarded = 0
	_winner_mark = Domain.Mark.NONE

	if play_wipe_sound:
		_container.audio_service.play_board_wipe()

	if _ai_strategy != null:
		_ai_strategy.on_game_started()

	board_wiped.emit()

	if not _config.is_two_player and _config.get_ai_mark() == Domain.Mark.X:
		_is_ai_thinking = true

	state_changed.emit()


## Handles a human tap on `cell_index` (`0..8`). Returns true if the move was valid and applied.
func on_cell_tapped(cell_index: int) -> bool:
	if _is_game_over or _is_ai_thinking:
		return false
	if cell_index < 0 or cell_index >= 9:
		return false
	if _board.cell_at(cell_index) != Domain.Mark.NONE:
		return false

	_apply_move(cell_index, _current_turn)

	if not _is_game_over and not _config.is_two_player and _current_turn == _config.get_ai_mark():
		_is_ai_thinking = true
		state_changed.emit()

	return true


## Executes the pending AI move on the board (called by GameView after a short natural thinking delay, or immediately in unit tests).
func execute_ai_turn() -> int:
	if _is_game_over or _config.is_two_player or _ai_strategy == null:
		_is_ai_thinking = false
		return -1
	var ai_mark := _config.get_ai_mark()
	if _current_turn != ai_mark:
		_is_ai_thinking = false
		return -1

	_is_ai_thinking = false
	var chosen_cell := _ai_strategy.choose_move(_board, ai_mark)
	if chosen_cell >= 0 and _board.cell_at(chosen_cell) == Domain.Mark.NONE:
		_apply_move(chosen_cell, ai_mark)
	return chosen_cell


## Returns the localized turn status text for the top ChalkBanner.
func get_turn_banner_text() -> String:
	if _is_game_over:
		return tr("RESULT_MATCH_FINISHED")
	var mark_str := "X" if _current_turn == Domain.Mark.X else "O"
	if _config.is_two_player:
		return tr("GAME_TURN_MARK").replace("{m}", mark_str)
	if _is_ai_thinking or _current_turn == _config.get_ai_mark():
		return tr("GAME_AI_THINKING")
	return tr("GAME_YOUR_TURN").replace("{m}", mark_str)


## Returns the localized title for the result overlay modal (`YOU WIN!`, `AI WINS!`, `X WINS!`, or `IT'S A DRAW!`).
func get_result_title_text() -> String:
	if _winner_mark == Domain.Mark.NONE:
		return tr("RESULT_DRAW")
	if _config.is_two_player:
		var m := "X" if _winner_mark == Domain.Mark.X else "O"
		return tr("RESULT_MARK_WINS").replace("{m}", m)
	if _winner_mark == _config.human_mark:
		return tr("RESULT_YOU_WIN")
	return tr("RESULT_AI_WINS")


## Returns the localized points breakdown string for the result overlay (e.g. `"+320 points (×2)"`).
func get_result_points_text() -> String:
	if _config.is_two_player:
		return ""
	var mult := ScoreCalculator.multiplier(_config.difficulty)
	return tr("RESULT_POINTS").replace("{pts}", str(_last_points_awarded)).replace("{mult}", str(mult))


## Pops back to the previous screen (or Main Menu) via the coordinator.
func on_back_to_menu_pressed() -> void:
	_coordinator.show_main_menu()


## Internal helper that places `mark` at `cell_index`, plays chalk SFX, and checks for win or draw.
func _apply_move(cell_index: int, mark: Domain.Mark) -> void:
	_board = _board.placing(mark, cell_index)
	_container.audio_service.play_chalk_write()
	cell_marked.emit(cell_index, mark)

	var win_info := _board.winner()
	if not win_info.is_empty():
		_winner_mark = win_info["mark"] as Domain.Mark
		_winning_line = win_info["line"]
		_finish_match(_winner_mark)
		return

	if _board.is_full():
		_winner_mark = Domain.Mark.NONE
		_winning_line = []
		_finish_match(Domain.Mark.NONE)
		return

	_current_turn = Domain.opponent(_current_turn)
	state_changed.emit()


## Finalizes the match, updates session counters, persists AI match scores and MENACE learning weights, and emits `match_finished`.
func _finish_match(winner: Domain.Mark) -> void:
	_is_game_over = true
	_is_ai_thinking = false
	_last_points_awarded = 0

	if _config.is_two_player:
		if winner == Domain.Mark.X:
			player_1_wins += 1
			_last_outcome = Domain.Outcome.WIN
		elif winner == Domain.Mark.O:
			player_2_wins += 1
			_last_outcome = Domain.Outcome.LOSS
		else:
			draws += 1
			_last_outcome = Domain.Outcome.DRAW
		_container.audio_service.play_outcome(Domain.Outcome.WIN if winner != Domain.Mark.NONE else Domain.Outcome.DRAW)
	else:
		if winner == Domain.Mark.NONE:
			draws += 1
			_last_outcome = Domain.Outcome.DRAW
		elif winner == _config.human_mark:
			player_1_wins += 1
			_last_outcome = Domain.Outcome.WIN
		else:
			player_2_wins += 1
			_last_outcome = Domain.Outcome.LOSS

		_last_points_awarded = _container.score_repo.record_ai_match(
			_last_outcome,
			_config.difficulty,
			_board.moves_played()
		)
		if _ai_strategy != null:
			var ai_outcome := Domain.flip_outcome(_last_outcome)
			_ai_strategy.on_game_ended(ai_outcome)

		_container.audio_service.play_outcome(_last_outcome)

	state_changed.emit()
	match_finished.emit(_last_outcome, _winning_line, _last_points_awarded)
