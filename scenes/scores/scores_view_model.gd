## ViewModel for the High Scores & Statistics modal screen exposing total score, best game score, streaks, and per-difficulty W/D/L records.
class_name ScoresViewModel
extends RefCounted

## Emitted when scores or locale state are refreshed.
signal state_changed

var _container: AppContainer
var _coordinator: AppCoordinator


## Initializes the ScoresViewModel with the DI container and navigation coordinator.
func _init(container: AppContainer, coordinator: AppCoordinator) -> void:
	_container = container
	_coordinator = coordinator


## Returns the AudioService instance from the DI container.
func get_audio_service() -> AudioService:
	return _container.audio_service


## Returns the cumulative total score across all AI matches.
func get_total_score() -> int:
	return _container.score_repo.get_total_score()


## Returns the highest score achieved in a single AI match.
func get_best_game_score() -> int:
	return _container.score_repo.get_best_game_score()


## Returns the all-time longest consecutive win streak against AI.
func get_best_streak() -> int:
	return _container.score_repo.get_best_streak()


## Returns `{"wins": int, "draws": int, "losses": int}` for the specified `difficulty`.
func get_stats_for_difficulty(difficulty: Domain.Difficulty) -> Dictionary:
	return _container.score_repo.get_stats_for_difficulty(difficulty)


## Refreshes scores data and notifies observers.
func refresh() -> void:
	state_changed.emit()


## Dismisses the High Scores modal screen via `AppCoordinator.dismiss_modal()`.
func on_back_pressed() -> void:
	_coordinator.dismiss_modal()
