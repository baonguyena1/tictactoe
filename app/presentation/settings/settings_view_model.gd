## ViewModel for the Settings modal screen managing Music, SFX, Vibration, Language (vi/en), and Self-Learning AI memory reset.
class_name SettingsViewModel
extends RefCounted

## Emitted whenever any setting (music, SFX, haptics, locale, or AI memory) is updated.
signal state_changed

var _container: AppContainer
var _coordinator: AppCoordinator


## Initializes the SettingsViewModel with the DI container and navigation coordinator.
func _init(container: AppContainer, coordinator: AppCoordinator) -> void:
	_container = container
	_coordinator = coordinator


## Returns the AudioService instance from the DI container.
func get_audio_service() -> AudioService:
	return _container.audio_service


## Returns true if background music is currently enabled.
func is_music_enabled() -> bool:
	return _container.settings_repo.is_music_enabled()


## Returns true if sound effects are currently enabled.
func is_sfx_enabled() -> bool:
	return _container.settings_repo.is_sfx_enabled()


## Returns true if mobile haptic vibration is currently enabled.
func is_haptics_enabled() -> bool:
	return _container.settings_repo.is_haptics_enabled()


## Returns the currently active locale code (`"vi"` or `"en"`).
func get_locale() -> String:
	return _container.settings_repo.get_locale()


## Returns the current Self-Learning AI skill percentage (`0..100`).
func get_learning_skill_percent() -> int:
	return _container.get_learning_skill_percent()


## Toggles background music on/off, updates the AudioService playback state, and emits `state_changed`.
func toggle_music() -> void:
	var next := not is_music_enabled()
	_container.settings_repo.set_music_enabled(next)
	if next:
		_container.audio_service.play_music()
	else:
		_container.audio_service.stop_music()
	state_changed.emit()


## Toggles sound effects on/off and emits `state_changed`.
func toggle_sfx() -> void:
	var next := not is_sfx_enabled()
	_container.settings_repo.set_sfx_enabled(next)
	state_changed.emit()


## Toggles haptic vibration on/off and emits `state_changed`.
func toggle_haptics() -> void:
	var next := not is_haptics_enabled()
	_container.settings_repo.set_haptics_enabled(next)
	state_changed.emit()


## Toggles the active language between Vietnamese (`"vi"`) and English (`"en"`), immediately updating TranslationServer.
func toggle_language() -> void:
	var next_locale := "en" if get_locale() == "vi" else "vi"
	set_locale(next_locale)


## Sets the active language to `locale` (`"vi"` or `"en"`) and emits `state_changed`.
func set_locale(locale: String) -> void:
	_container.settings_repo.set_locale(locale)
	state_changed.emit()


## Clears all learned MENACE weights in memory and on disk and emits `state_changed`.
func reset_ai_memory() -> void:
	_container.reset_learning_memory()
	state_changed.emit()


## Dismisses the Settings modal screen via `AppCoordinator.dismiss_modal()`.
func on_back_pressed() -> void:
	_coordinator.dismiss_modal()
