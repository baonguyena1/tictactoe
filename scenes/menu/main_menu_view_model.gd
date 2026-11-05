## ViewModel for the Main Menu screen managing navigation actions and Self-Learning AI skill percentage display.
class_name MainMenuViewModel
extends RefCounted

## Emitted when view state (such as locale or AI skill percentage) is refreshed.
signal state_changed

var _container: AppContainer
var _coordinator: AppCoordinator


## Initializes the MainMenuViewModel with the DI container and navigation coordinator.
func _init(container: AppContainer, coordinator: AppCoordinator) -> void:
	_container = container
	_coordinator = coordinator


## Returns the AudioService instance from the DI container.
func get_audio_service() -> AudioService:
	return _container.audio_service


## Returns the localized footer string displaying the current Self-Learning AI skill percentage.
func get_ai_skill_footer_text() -> String:
	var pct := _container.get_learning_skill_percent()
	return tr("AI_SKILL_FOOTER").replace("{p}", str(pct))


## Returns the best win streak against AI.
func get_best_streak() -> int:
	if _container != null and _container.score_repo != null:
		return _container.score_repo.get_best_streak()
	return 0


## Returns the cumulative total score.
func get_total_score() -> int:
	if _container != null and _container.score_repo != null:
		return _container.score_repo.get_total_score()
	return 0


## Refreshes state when the Main Menu becomes visible again (e.g. after popping or dismissing Settings).
func refresh() -> void:
	state_changed.emit()


## Navigates to the Difficulty & Mark selection screen for a Player vs AI match.
func on_play_vs_ai_pressed() -> void:
	_coordinator.show_difficulty()


## Navigates directly to the 3x3 Game screen configured for a 2-Player local pass-and-play match.
func on_two_players_pressed() -> void:
	_coordinator.show_game_two_players()


## Presents the High Scores & Statistics modal screen.
func on_scores_pressed() -> void:
	_coordinator.show_scores()


## Presents the Settings modal screen.
func on_settings_pressed() -> void:
	_coordinator.show_settings()
