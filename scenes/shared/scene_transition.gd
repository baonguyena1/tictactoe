## Global scene transition manager handling smooth screen fades ("Fade to Black") via Tween.
class_name SceneTransitionManager
extends CanvasLayer

## Emitted when the screen has fully faded to black.
signal fade_in_completed

## Emitted when the curtain has completely faded out and the new scene is visible.
signal fade_out_completed

@onready var overlay: ColorRect = $ColorRect

var _is_transitioning: bool = false


func _ready() -> void:
	layer = 100
	if overlay != null:
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.color = Color.BLACK
		overlay.modulate.a = 0.0


## Returns true if a transition animation is currently playing.
func is_transitioning() -> bool:
	return _is_transitioning


## Standard tutorial implementation: Smoothly fades to black, changes scene file, and fades back in.
func fade_to(target_scene: String, duration: float = 0.3) -> void:
	change_scene_to_file(target_scene, duration)


## Standard Godot scene file change with Fade to Black.
func change_scene_to_file(target_scene: String, duration: float = 0.3) -> void:
	transition_to(func() -> void: get_tree().change_scene_to_file(target_scene), duration)


## Standard Godot packed scene change with Fade to Black.
func change_scene_to_packed(target_scene: PackedScene, duration: float = 0.3) -> void:
	transition_to(func() -> void: get_tree().change_scene_to_packed(target_scene), duration)


## Smoothly fades out the screen to black (curtain closes), calls `action`, and fades back in (curtain opens).
func transition_to(action: Callable, duration: float = 0.3) -> void:
	if _is_transitioning:
		if action.is_valid():
			action.call()
		return

	_is_transitioning = true

	if overlay != null:
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	if duration <= 0.001:
		if action.is_valid():
			action.call()
		if overlay != null:
			overlay.modulate.a = 0.0
			overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_is_transitioning = false
		return

	# 1. Fade to Black (curtain closes over duration)
	var t_in := create_tween()
	t_in.tween_property(overlay, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await t_in.finished
	overlay.modulate.a = 1.0
	fade_in_completed.emit()

	# 2. Execute swap/load action while completely hidden in 100% black
	if action.is_valid():
		action.call()

	# 3. Wait 2 frames to ensure the new scene is fully loaded and drawn before unveiling
	if is_inside_tree():
		await get_tree().process_frame
		await get_tree().process_frame

	# 4. Fade from Black (curtain opens over duration)
	var t_out := create_tween()
	t_out.tween_property(overlay, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t_out.finished
	overlay.modulate.a = 0.0

	if overlay != null:
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
	fade_out_completed.emit()
