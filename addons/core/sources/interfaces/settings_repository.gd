## Abstract repository interface for reading and persisting user preferences.
class_name SettingsRepository
extends RefCounted


## Returns true if background music is enabled.
func is_music_enabled() -> bool:
	return true


## Enables or disables background music and persists the setting.
func set_music_enabled(_enabled: bool) -> void:
	pass


## Returns true if sound effects (chalk writing, button taps) are enabled.
func is_sfx_enabled() -> bool:
	return true


## Enables or disables sound effects and persists the setting.
func set_sfx_enabled(_enabled: bool) -> void:
	pass


## Returns true if device vibration / haptic feedback is enabled.
func is_haptics_enabled() -> bool:
	return true


## Enables or disables haptic feedback and persists the setting.
func set_haptics_enabled(_enabled: bool) -> void:
	pass


## Returns the active language locale code ("vi" or "en").
func get_locale() -> String:
	return "en"


## Updates and persists the active language locale code ("vi" or "en").
func set_locale(_locale: String) -> void:
	pass
