## Concrete ScoreRepository backed by ConfigFile in `user://`.
## Computes match points via ScoreCalculator and persists lifetime statistics.
class_name LocalScoreRepository
extends ScoreRepository

const SECTION_SUMMARY := "summary"
const SECTION_STATS := "difficulty_stats"

var _file_path: String
var _config: ConfigFile
var _total_score: int = 0
var _best_game_score: int = 0
var _current_streak: int = 0
var _best_streak: int = 0
var _stats: Dictionary = {}


## Initializes the score repository and loads existing records from `file_path`.
func _init(file_path: String = "user://scores.cfg") -> void:
	_file_path = file_path
	_config = ConfigFile.new()
	_load_from_disk()


## Returns the cumulative total score across all AI matches.
func get_total_score() -> int:
	return _total_score


## Returns the highest score achieved in a single AI match.
func get_best_game_score() -> int:
	return _best_game_score


## Returns the current consecutive win streak against AI.
func get_current_streak() -> int:
	return _current_streak


## Returns the all-time longest consecutive win streak against AI.
func get_best_streak() -> int:
	return _best_streak


## Returns `{"wins": int, "draws": int, "losses": int}` for the specified `difficulty`.
func get_stats_for_difficulty(difficulty: Domain.Difficulty) -> Dictionary:
	var key := str(int(difficulty))
	if not _stats.has(key):
		return {"wins": 0, "draws": 0, "losses": 0}
	return _stats[key].duplicate()


## Updates win streak, calculates match points, records W/D/L stats, saves to disk,
## and returns the points earned in this match.
func record_ai_match(
	outcome: Domain.Outcome,
	difficulty: Domain.Difficulty,
	moves_played: int
) -> int:
	match outcome:
		Domain.Outcome.WIN:
			_current_streak += 1
			_best_streak = maxi(_best_streak, _current_streak)
		Domain.Outcome.LOSS:
			_current_streak = 0
		Domain.Outcome.DRAW:
			pass

	var points := ScoreCalculator.calculate_points(
		outcome,
		difficulty,
		moves_played,
		_current_streak
	)
	_total_score += points
	_best_game_score = maxi(_best_game_score, points)

	var key := str(int(difficulty))
	var entry: Dictionary = _stats.get(key, {"wins": 0, "draws": 0, "losses": 0})
	match outcome:
		Domain.Outcome.WIN:
			entry["wins"] = int(entry.get("wins", 0)) + 1
		Domain.Outcome.DRAW:
			entry["draws"] = int(entry.get("draws", 0)) + 1
		Domain.Outcome.LOSS:
			entry["losses"] = int(entry.get("losses", 0)) + 1
	_stats[key] = entry

	_save_to_disk()
	return points


## Loads score summary and per-difficulty W/D/L counters from disk.
func _load_from_disk() -> void:
	var err := _config.load(_file_path)
	if err != OK:
		return
	_total_score = int(_config.get_value(SECTION_SUMMARY, "total_score", 0))
	_best_game_score = int(_config.get_value(SECTION_SUMMARY, "best_game_score", 0))
	_current_streak = int(_config.get_value(SECTION_SUMMARY, "current_streak", 0))
	_best_streak = int(_config.get_value(SECTION_SUMMARY, "best_streak", 0))
	_stats = _config.get_value(SECTION_STATS, "table", {})


## Saves score summary and per-difficulty W/D/L counters to disk.
func _save_to_disk() -> void:
	_config.set_value(SECTION_SUMMARY, "total_score", _total_score)
	_config.set_value(SECTION_SUMMARY, "best_game_score", _best_game_score)
	_config.set_value(SECTION_SUMMARY, "current_streak", _current_streak)
	_config.set_value(SECTION_SUMMARY, "best_streak", _best_streak)
	_config.set_value(SECTION_STATS, "table", _stats)
	_config.save(_file_path)
