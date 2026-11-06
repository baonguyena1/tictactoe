## Application screen coordinator managing clean view mounting and smooth screen transitions via SceneTransition.
class_name AppCoordinator
extends RefCounted

## Emitted whenever the coordinator navigates to a new screen route.
signal screen_changed(route_name: String, config: GameModeConfig)

## Route identifier for the Main Menu root screen.
const ROUTE_MAIN_MENU := "main_menu"

## Route identifier for the Difficulty & Mark selection screen.
const ROUTE_DIFFICULTY := "difficulty"

## Route identifier for the active 3x3 Game screen.
const ROUTE_GAME := "game"

## Route identifier for the High Scores & Statistics screen.
const ROUTE_SCORES := "scores"

## Route identifier for the Settings screen.
const ROUTE_SETTINGS := "settings"

var _screen_container: Control
var _container: AppContainer
var _screen_factories: Dictionary = {}
var _route_history: Array[Dictionary] = []
var _active_view: Control = null

## Flag that enables or disables transition animations (set to false in unit tests).
var animations_enabled: bool = true


## Initializes the coordinator with the host ScreenContainer node and AppContainer.
func _init(screen_container: Control, container: AppContainer, _p_legacy_param: bool = true) -> void:
	_screen_container = screen_container
	_container = container


## Returns the DI container associated with this coordinator.
func get_container() -> AppContainer:
	return _container


## Returns the current depth of the navigation history stack.
func get_stack_size() -> int:
	return _route_history.size()


## Returns the route identifier of the currently active screen.
func get_current_route() -> String:
	if _route_history.is_empty():
		return ""
	return _route_history.back()["route"]


## Returns the GameModeConfig of the active screen (or null if none).
func get_current_config() -> GameModeConfig:
	if _route_history.is_empty():
		return null
	return _route_history.back()["config"]


## Returns the Control instance currently mounted on the screen container.
func get_current_screen() -> Control:
	return _active_view


## Registers a callable factory `func(config: GameModeConfig) -> Control` for a given route name.
func register_screen_factory(route_name: String, factory: Callable) -> void:
	_screen_factories[route_name] = factory


## Starts navigation by mounting the Main Menu as the root screen.
func start() -> void:
	set_root(ROUTE_MAIN_MENU, null)


## Clears navigation history and mounts a single root page.
func set_root(route_name: String, config: GameModeConfig = null) -> void:
	_route_history.clear()
	_route_history.push_back({
		"route": route_name,
		"config": config,
	})
	_apply_route_change(false)


## Pushes a new screen route onto the navigation history and transitions smoothly.
func push(route_name: String, config: GameModeConfig = null, animated: bool = true) -> void:
	_route_history.push_back({
		"route": route_name,
		"config": config,
	})
	_apply_route_change(animated)


## Pops the current screen from history and transitions back to the previous screen.
func pop(animated: bool = true) -> bool:
	if _route_history.size() <= 1:
		return false
	_route_history.pop_back()
	_apply_route_change(animated)
	return true


## Pops all screens above the root screen and transitions back to root.
func pop_to_root(animated: bool = true) -> void:
	if _route_history.size() <= 1:
		return
	_route_history = [_route_history[0]]
	_apply_route_change(animated)


## Presents a screen over navigation history (mapped to smooth transition push).
func present_modal(route_name: String, config: GameModeConfig = null, animated: bool = true) -> void:
	push(route_name, config, animated)


## Dismisses a presented modal (mapped to pop).
func dismiss_modal(animated: bool = true) -> bool:
	return pop(animated)


## Pops the current screen and returns to the previous screen (Type-safe alias for pop).
func go_back(animated: bool = true) -> bool:
	return pop(animated)


## Navigates back to the Main Menu root screen.
func show_main_menu() -> void:
	if not _route_history.is_empty() and _route_history[0]["route"] == ROUTE_MAIN_MENU:
		pop_to_root(true)
	else:
		set_root(ROUTE_MAIN_MENU, null)


## Pushes the AI Difficulty and Mark selection screen.
func show_difficulty() -> void:
	push(ROUTE_DIFFICULTY, null, true)


## Pushes the 3x3 Game screen configured for a Player vs AI match.
func show_game_vs_ai(difficulty: Domain.Difficulty, player_mark: Domain.Mark = Domain.Mark.X) -> void:
	var config := GameModeConfig.vs_ai(difficulty, player_mark)
	push(ROUTE_GAME, config, true)


## Pushes the 3x3 Game screen configured for a 2-Player local match.
func show_game_two_players() -> void:
	var config := GameModeConfig.two_players()
	push(ROUTE_GAME, config, true)


## Pushes the 3x3 Game screen with custom match configuration.
func show_game(config: GameModeConfig) -> void:
	push(ROUTE_GAME, config, true)


## Pushes the High Scores & Statistics screen.
func show_scores() -> void:
	push(ROUTE_SCORES, null, true)


## Pushes the Settings screen.
func show_settings() -> void:
	push(ROUTE_SETTINGS, null, true)


## Applies the current route change instantaneously without any latency or black screen.
func _apply_route_change(_animated: bool = false) -> void:
	if _route_history.is_empty():
		return
	var entry: Dictionary = _route_history.back()
	var route_name: String = entry["route"]
	var config: GameModeConfig = entry["config"]

	_mount_screen(route_name, config)
	screen_changed.emit(route_name, config)


## Instantiates the target screen, unmounts and frees the old screen, and mounts the new one.
func _mount_screen(route_name: String, config: GameModeConfig) -> Control:
	if not _screen_factories.has(route_name):
		return null
	var factory: Callable = _screen_factories[route_name]
	if not factory.is_valid():
		return null

	# Cleanly free old view from memory to release RAM and avoid overlapping render layers
	if _active_view != null and is_instance_valid(_active_view):
		if _active_view.get_parent() == _screen_container:
			_screen_container.remove_child(_active_view)
		_active_view.queue_free()
		_active_view = null

	var view := factory.call(config) as Control
	if view == null:
		return null

	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	if _screen_container != null and _screen_container.is_inside_tree():
		_screen_container.add_child(view)

	if view.has_method("on_view_will_appear"):
		view.call("on_view_will_appear")

	_active_view = view
	return view


## Retrieves the global SceneTransition Autoload singleton from the scene tree.
func _get_transition_manager() -> SceneTransitionManager:
	if _screen_container != null and _screen_container.is_inside_tree():
		var tree := _screen_container.get_tree()
		if tree != null and tree.root != null:
			return tree.root.get_node_or_null("SceneTransition") as SceneTransitionManager
	return null
