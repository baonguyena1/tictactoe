## Dependency injection container that wires repositories, services, and AI strategies without global singletons.
class_name AppContainer
extends RefCounted

## Repository managing user preferences (music, SFX, vibration, language).
var settings_repo: SettingsRepository

## Repository managing high scores, streaks, and per-difficulty match statistics.
var score_repo: ScoreRepository

## Persistent weight store backing the MENACE Self-Learning AI.
var weight_store: WeightStore

## Shared Self-Learning AI instance so learned weights stay warm in memory across matches.
var learning_ai: LearningAI

## Audio and haptic service bound to the scene tree.
var audio_service: AudioService


## Initializes the container with explicit repository and service instances (or creates default local implementations).
func _init(
	p_audio_host: Node = null,
	p_settings_repo: SettingsRepository = null,
	p_score_repo: ScoreRepository = null,
	p_weight_store: WeightStore = null,
	p_audio_service: AudioService = null
) -> void:
	settings_repo = p_settings_repo if p_settings_repo != null else LocalSettingsRepository.new()
	score_repo = p_score_repo if p_score_repo != null else LocalScoreRepository.new()
	weight_store = p_weight_store if p_weight_store != null else LocalWeightStore.new()
	learning_ai = LearningAI.new(weight_store)
	if p_audio_service != null:
		audio_service = p_audio_service
	elif p_audio_host != null:
		audio_service = DefaultAudioService.new(p_audio_host, settings_repo)
	else:
		audio_service = AudioService.new()


## Factory method that returns the appropriate MoveStrategy for the requested difficulty level.
func make_move_strategy(difficulty: Domain.Difficulty, seed_value: int = -1) -> MoveStrategy:
	if difficulty == Domain.Difficulty.LEARNING:
		return learning_ai
	return MinimaxAI.new(difficulty, seed_value)


## Returns the current Self-Learning AI skill percentage in the range [0.0, 100.0].
func get_learning_skill_percent() -> float:
	return learning_ai.get_skill_level_percent()


## Resets all learned MENACE weights in memory and on disk.
func reset_learning_memory() -> void:
	learning_ai.reset_memory()
