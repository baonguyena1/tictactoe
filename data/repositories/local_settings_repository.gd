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
var _has_custom_locale: bool = false
var _locale: String = "en"


## Determines the default locale based on the device's system settings.
## Returns "vi" if the device language is Vietnamese; otherwise defaults to "en".
static func get_device_default_locale() -> String:
	var lang := OS.get_locale_language().to_lower().strip_edges()
	var raw_loc := OS.get_locale().to_lower().strip_edges()
	if lang == "vi" or raw_loc.begins_with("vi"):
		return "vi"
	return "en"


## Initializes the repository, loads saved preferences from `file_path`, and applies the locale.
func _init(file_path: String = "user://settings.cfg") -> void:
	_file_path = file_path
	_config = ConfigFile.new()
	_locale = get_device_default_locale()
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
	_locale = locale if (locale == "vi" or locale == "en") else get_device_default_locale()
	_has_custom_locale = true
	TranslationServer.set_locale(_locale)
	_save_to_disk()


## Reads settings from `_file_path` if the file exists.
func _load_from_disk() -> void:
	var err := _config.load(_file_path)
	if err != OK:
		_locale = get_device_default_locale()
		return
	_music_enabled = bool(_config.get_value(SECTION, "music_enabled", true))
	_sfx_enabled = bool(_config.get_value(SECTION, "sfx_enabled", true))
	_haptics_enabled = bool(_config.get_value(SECTION, "haptics_enabled", true))
	_has_custom_locale = bool(_config.get_value(SECTION, "has_custom_locale", false))
	if _has_custom_locale:
		var saved_loc := String(_config.get_value(SECTION, "locale", ""))
		if saved_loc == "vi" or saved_loc == "en":
			_locale = saved_loc
		else:
			_locale = get_device_default_locale()
	else:
		_locale = get_device_default_locale()


## Writes current settings to `_file_path`.
func _save_to_disk() -> void:
	_config.set_value(SECTION, "music_enabled", _music_enabled)
	_config.set_value(SECTION, "sfx_enabled", _sfx_enabled)
	_config.set_value(SECTION, "haptics_enabled", _haptics_enabled)
	_config.set_value(SECTION, "has_custom_locale", _has_custom_locale)
	_config.set_value(SECTION, "locale", _locale)
	_config.save(_file_path)
