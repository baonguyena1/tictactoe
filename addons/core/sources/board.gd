## Immutable 3x3 Tic-Tac-Toe board value object.
## Any move operation returns a new Board instance without mutating the current board.
class_name Board
extends  RefCounted

## All 8 possible 3-in-a-row winning index combinations (rows, columns, diagonals).
const WIN_LINES: Array[Array] = [
	[0, 1, 2], [3, 4, 5], [6, 7, 8],
	[0, 3, 6], [1, 4, 7], [2, 5, 8],
	[0, 4, 8], [2, 4, 6],
]

const BOARD_SIZE: int = 9

var _cells: PackedInt32Array

## Initializes an empty 9-cell board, or copies an existing 9-cell array if provided.
func _init(initial_cells: PackedInt32Array = PackedInt32Array()) -> void:
	if initial_cells.size() == BOARD_SIZE:
		_cells = initial_cells.duplicate()
	else:
		_cells = PackedInt32Array([0, 0, 0, 0, 0, 0, 0, 0, 0])
		
## Returns the mark (NONE, X, or O) at the given board index (0..8).
func cell_at(index: int) -> Domain.Mark:
	return _cells[index] as Domain.Mark
	
## Returns a list of all unoccupied cell indices (0..8) available for the next move.
func empty_indices() -> Array[int]:
	var result: Array[int] = []
	for i in range(9):
		if _cells[i] == Domain.Mark.NONE:
			result.append(i)
	return result
	
## Returns true if all 9 cells are occupied (no empty cells left).
func is_full() -> bool:
	return not _cells.has(Domain.Mark.NONE)
		
## Returns the total number of moves played so far on this board (0..9).
func moves_played() -> int:
	return BOARD_SIZE - empty_indices().size()

## Places `mark` at `index` and returns a new Board instance, leaving `self` unchanged.
func placing(mark: Domain.Mark, index: int) -> Board:
	assert(index >= 0 and index < BOARD_SIZE, "Cell index out of bounds (expected 0..8).")
	assert(_cells[index] == Domain.Mark.NONE, "Cannot place a mark on an occupied cell.")
	
	var next_cells = _cells.duplicate()
	next_cells[index] = mark
	return Board.new(next_cells)
	
## Checks if either player has achieved a winning line.
## Returns `{"mark": GameTypes.Mark, "line": Array}` if there is a winner, or `{}` if none.
func winner() -> Dictionary:
	for line in WIN_LINES:
		var check := _cells[line[0]]
		if check != Domain.Mark.NONE and check == _cells[line[1]] and check == _cells[line[2]]:
			return {
				"mark": check as Domain.Mark,
				"line": line.duplicate()
			}
		
	return {}

## Encodes the board into a 9-character string (e.g., "X.O..X...") used as a lookup key
## for Minimax memoization and MENACE reinforcement learning weights.
func state_key() -> String:
	var chars := ""
	for cell in _cells:
		match cell:
			Domain.Mark.X:
				chars += "X"
			Domain.Mark.O:
				chars += "O"
			_:
				chars += "."
	return chars
