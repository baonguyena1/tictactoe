## Abstract storage interface for persisting and loading MENACE reinforcement learning weights.
class_name WeightStore
extends RefCounted


## Loads the learned state-action weight dictionary `{ state_key: { cell_index: bead_count } }`.
func load_weights() -> Dictionary:
	return {}


## Persists the updated state-action weight dictionary.
func save_weights(_weights: Dictionary) -> void:
	pass


## Clears all stored weights from persistence.
func clear_weights() -> void:
	pass
