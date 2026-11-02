## Abstract service interface for playing background music and sound effects.
class_name AudioService
extends RefCounted


## Starts or resumes the looping background music if music is enabled.
func play_music() -> void:
	pass


## Pauses or stops the background music.
func stop_music() -> void:
	pass


## Plays the chalk writing sound effect when a player places X or O.
func play_chalk_write() -> void:
	pass


## Plays the chalkboard eraser wipe sound effect when resetting the board.
func play_board_wipe() -> void:
	pass


## Plays the UI button tap sound effect.
func play_tap() -> void:
	pass


## Plays the end-of-match sound effect corresponding to `outcome` (WIN, DRAW, or LOSS).
func play_outcome(_outcome: Domain.Outcome) -> void:
	pass
