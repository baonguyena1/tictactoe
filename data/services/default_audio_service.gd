## Concrete AudioService that manages AudioStreamPlayers attached to a host Node
## and respects user preferences from SettingsRepository.
class_name DefaultAudioService
extends AudioService

const SOUND_BGM := "res://resources/sounds/bgm_loop.wav"
const SOUND_CHALK := "res://resources/sounds/chalk_write.wav"
const SOUND_WIPE := "res://resources/sounds/board_wipe.wav"
const SOUND_TAP := "res://resources/sounds/tap.wav"
const SOUND_WIN := "res://resources/sounds/win.wav"
const SOUND_WIN_STREAK := "res://resources/sounds/win_streak.wav"
const SOUND_DRAW := "res://resources/sounds/draw.wav"
const SOUND_LOSE := "res://resources/sounds/lose.wav"

var _settings: SettingsRepository
var _bgm_player: AudioStreamPlayer
var _sfx_players: Dictionary = {}
var _rng: RandomNumberGenerator


## Initializes audio players under `host_node` and binds to `settings`.
func _init(host_node: Node, settings: SettingsRepository) -> void:
	_settings = settings
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	if host_node != null:
		_setup_players(host_node)


## Starts or resumes looping background music if enabled in settings.
func play_music() -> void:
	if _bgm_player == null:
		return
	if not _settings.is_music_enabled():
		_bgm_player.stop()
		return
	if not _bgm_player.playing:
		_bgm_player.play()


## Stops the background music.
func stop_music() -> void:
	if _bgm_player != null:
		_bgm_player.stop()


## Plays the chalk writing SFX with slight pitch variation and light haptic feedback.
func play_chalk_write() -> void:
	_play_sfx("chalk", 0.94, 1.06)
	_trigger_haptic(20)


## Plays the chalkboard eraser wipe SFX.
func play_board_wipe() -> void:
	_play_sfx("wipe", 0.96, 1.04)


## Plays the UI button tap SFX.
func play_tap() -> void:
	_play_sfx("tap", 0.96, 1.04)
	_trigger_haptic(10)


## Plays the end-of-match sound effect for `outcome` (WIN, DRAW, or LOSS).
func play_outcome(outcome: Domain.Outcome) -> void:
	match outcome:
		Domain.Outcome.WIN:
			_play_sfx("win", 1.0, 1.0)
			_trigger_haptic(40)
		Domain.Outcome.LOSS:
			_play_sfx("lose", 1.0, 1.0)
		_:
			_play_sfx("draw", 1.0, 1.0)


## Plays a triumphant celebratory fanfare when the player achieves a win streak.
func play_win_streak() -> void:
	_play_sfx("win_streak", 1.0, 1.0)
	_trigger_haptic(60)


## Creates the BGM player and SFX player nodes as children of `host_node`.
func _setup_players(host_node: Node) -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = &"Music" if AudioServer.get_bus_index(&"Music") >= 0 else &"Master"
	_bgm_player.volume_db = -8.0
	var bgm_stream := load(SOUND_BGM) as AudioStreamWAV
	if bgm_stream != null:
		bgm_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		bgm_stream.loop_begin = 0
		bgm_stream.loop_end = int(bgm_stream.get_length() * bgm_stream.mix_rate)
		_bgm_player.stream = bgm_stream
	host_node.add_child(_bgm_player)

	var sfx_map := {
		"chalk": SOUND_CHALK,
		"wipe": SOUND_WIPE,
		"tap": SOUND_TAP,
		"win": SOUND_WIN,
		"win_streak": SOUND_WIN_STREAK,
		"draw": SOUND_DRAW,
		"lose": SOUND_LOSE,
	}
	var sfx_bus := &"SFX" if AudioServer.get_bus_index(&"SFX") >= 0 else &"Master"
	for key in sfx_map.keys():
		var player := AudioStreamPlayer.new()
		player.bus = sfx_bus
		player.volume_db = 1.5
		player.stream = load(sfx_map[key]) as AudioStream
		host_node.add_child(player)
		_sfx_players[key] = player


## Internal helper to play a named SFX with optional random pitch variation.
func _play_sfx(key: String, min_pitch: float, max_pitch: float) -> void:
	if not _settings.is_sfx_enabled():
		return
	var player: AudioStreamPlayer = _sfx_players.get(key)
	if player == null:
		return
	player.pitch_scale = _rng.randf_range(min_pitch, max_pitch)
	player.play()


## Triggers mobile haptic vibration if haptics are enabled in settings.
func _trigger_haptic(duration_ms: int) -> void:
	if _settings.is_haptics_enabled():
		Input.vibrate_handheld(duration_ms)
