## Concrete SettingsRepository backed by Godot's ConfigFile in `user://`.
## Automatically synchronizes the active locale with Godot's TranslationServer.
class_name LocalSettingsRepository
extends SettingsRepository

const SECTION := "settings"

var _file_path: String
var _config: ConfigFile
var _music_enabled: bool = true
var _sfx_enabled: bool = true
var _haptics_enabled: bool = true
var _locale: String = "vi"


## Initializes the repository, loads saved preferences from `file_path`, and applies the locale.
func _init(file_path: String = "user://settings.cfg") -> void:
	_file_path = file_path
	_config = ConfigFile.new()
	_load_from_disk()
	TranslationServer.set_locale(_locale)


## Returns true if background music is enabled.
func is_music_enabled() -> bool:
	return _music_enabled


## Enables or disables background music and saves to disk.
func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	_save_to_disk()


## Returns true if sound effects are enabled.
func is_sfx_enabled() -> bool:
	return _sfx_enabled


## Enables or disables sound effects and saves to disk.
func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled
	_save_to_disk()


## Returns true if haptic vibration is enabled.
func is_haptics_enabled() -> bool:
	return _haptics_enabled


## Enables or disables haptic vibration and saves to disk.
func set_haptics_enabled(enabled: bool) -> void:
	_haptics_enabled = enabled
	_save_to_disk()


## Returns the active language locale ("vi" or "en").
func get_locale() -> String:
	return _locale


## Sets the active language locale ("vi" or "en"), updates TranslationServer, and saves to disk.
func set_locale(locale: String) -> void:
	_locale = locale
	TranslationServer.set_locale(_locale)
	_save_to_disk()


## Reads settings from `_file_path` if the file exists.
func _load_from_disk() -> void:
	var err := _config.load(_file_path)
	if err != OK:
		return
	_music_enabled = bool(_config.get_value(SECTION, "music_enabled", true))
	_sfx_enabled = bool(_config.get_value(SECTION, "sfx_enabled", true))
	_haptics_enabled = bool(_config.get_value(SECTION, "haptics_enabled", true))
	_locale = String(_config.get_value(SECTION, "locale", "vi"))


## Writes current settings to `_file_path`.
func _save_to_disk() -> void:
	_config.set_value(SECTION, "music_enabled", _music_enabled)
	_config.set_value(SECTION, "sfx_enabled", _sfx_enabled)
	_config.set_value(SECTION, "haptics_enabled", _haptics_enabled)
	_config.set_value(SECTION, "locale", _locale)
	_config.save(_file_path)
