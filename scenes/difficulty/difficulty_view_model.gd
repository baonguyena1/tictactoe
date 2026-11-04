## ViewModel for the Difficulty & Mark selection screen allowing the player to choose X (first) or O (second) and one of 5 AI difficulties.
class_name DifficultyViewModel
extends RefCounted

## Emitted when the selected player mark or locale changes.
signal state_changed

var _container: AppContainer
var _coordinator: AppCoordinator
var _selected_mark: Domain.Mark = Domain.Mark.X


## Initializes the DifficultyViewModel with the DI container and navigation coordinator.
func _init(container: AppContainer, coordinator: AppCoordinator) -> void:
	_container = container
	_coordinator = coordinator


## Returns the AudioService instance from the DI container.
func get_audio_service() -> AudioService:
	return _container.audio_service


## Returns the mark currently selected by the human player (`Domain.Mark.X` or `Domain.Mark.O`).
func get_selected_mark() -> Domain.Mark:
	return _selected_mark


## Sets the human player's mark (`Domain.Mark.X` goes first, `Domain.Mark.O` goes second) and notifies the view.
func select_mark(mark: Domain.Mark) -> void:
	if mark != Domain.Mark.X and mark != Domain.Mark.O:
		return
	_selected_mark = mark
	state_changed.emit()


## Returns the score multiplier badge string (e.g. `"×8"`) for the given difficulty.
func get_multiplier_badge(difficulty: Domain.Difficulty) -> String:
	return "×%d" % ScoreCalculator.multiplier(difficulty)


## Starts a Player vs AI match with the chosen `difficulty` and the currently selected `_selected_mark`.
func on_difficulty_selected(difficulty: Domain.Difficulty) -> void:
	_coordinator.show_game_vs_ai(difficulty, _selected_mark)


## Pops the Difficulty screen off the navigation stack to return to the Main Menu.
func on_back_pressed() -> void:
	_coordinator.go_back()
