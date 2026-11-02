## Concrete WeightStore that serializes MENACE state-action weights to a JSON file in `user://`.
class_name LocalWeightStore
extends WeightStore

var _file_path: String


## Initializes the JSON weight store at `file_path`.
func _init(file_path: String = "user://menace_weights.json") -> void:
	_file_path = file_path


## Reads and parses the JSON weight file, converting inner move keys back to `int`.
func load_weights() -> Dictionary:
	if not FileAccess.file_exists(_file_path):
		return {}

	var file := FileAccess.open(_file_path, FileAccess.READ)
	if file == null:
		return {}

	var raw_text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	var result: Dictionary = {}
	var raw_dict: Dictionary = parsed
	for state_key in raw_dict.keys():
		var inner_raw: Variant = raw_dict[state_key]
		if typeof(inner_raw) == TYPE_DICTIONARY:
			var clean_table: Dictionary = {}
			var inner_dict: Dictionary = inner_raw
			for move_key in inner_dict.keys():
				clean_table[int(str(move_key))] = int(inner_dict[move_key])
			result[String(state_key)] = clean_table
	return result


## Serializes `weights` to JSON and writes it to `_file_path`.
func save_weights(weights: Dictionary) -> void:
	var file := FileAccess.open(_file_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(weights))
	file.close()


## Deletes the stored weights file or overwrites it with an empty JSON object.
func clear_weights() -> void:
	save_weights({})
