## Coordinator backed by the external `UIFlow` navigation framework (`addons/ui_flow`), providing stack-based push/pop/pop_to_root, modal overlays, and slide/fade transitions.
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
var _navigator: UIFlowNavigator
var _scene_resolver: UIFlowSceneResolver
var _screen_factories: Dictionary = {}
var _route_history: Array[Dictionary] = []


## Flag that enables or disables slide transition animations (set to false in synchronous unit tests).
var animations_enabled: bool = true


## Initializes the coordinator with the host ScreenContainer node and the AppContainer, wiring up UIFlowNavigator.
func _init(screen_container: Control, container: AppContainer, p_use_global_uiflow: bool = true) -> void:
	_screen_container = screen_container
	_container = container
	_scene_resolver = UIFlowSceneResolver.new()

	var global_uiflow := _get_global_uiflow() if p_use_global_uiflow else null
	if global_uiflow != null and _screen_container != null and _screen_container.is_inside_tree():
		global_uiflow.set_ui_root(_screen_container)
		_navigator = global_uiflow.Router
	else:
		_navigator = UIFlowNavigator.new()
		_navigator.name = "UIFlowNavigator"
		if _screen_container != null:
			_screen_container.add_child(_navigator)
			_navigator.setup(_screen_container, _scene_resolver)


## Returns the DI container associated with this coordinator.
func get_container() -> AppContainer:
	return _container


## Returns the underlying `UIFlowNavigator` router instance from `addons/ui_flow`.
func get_navigator() -> UIFlowNavigator:
	return _navigator


## Returns the current depth of the UIFlow navigation stack.
func get_stack_size() -> int:
	return _route_history.size()


## Returns the route identifier of the top screen on the navigation stack.
func get_current_route() -> String:
	if _route_history.is_empty():
		return ""
	return _route_history.back()["route"]


## Returns the GameModeConfig of the top screen on the navigation stack (or null if none).
func get_current_config() -> GameModeConfig:
	if _route_history.is_empty():
		return null
	return _route_history.back()["config"]


## Returns the top Control / UIFlowPage instance currently active on the navigation stack.
func get_current_screen() -> Control:
	if _route_history.is_empty():
		return null
	return _route_history.back()["view"]


## Registers a callable factory `func(config: GameModeConfig) -> Control` for a given route name.
func register_screen_factory(route_name: String, factory: Callable) -> void:
	_screen_factories[route_name] = factory


## Starts the navigation flow by setting the Main Menu as the root page on the UIFlow stack.
func start() -> void:
	set_root(ROUTE_MAIN_MENU, null)


## Clears the UIFlow stack and pushes a single root page.
func set_root(route_name: String, config: GameModeConfig = null) -> void:
	if _navigator != null:
		_navigator.clear_stack()
	_route_history.clear()

	var page := _build_uiflow_page(route_name, config, false, false)
	if _navigator != null and page != null:
		_navigator.push_instance(page, config)
	_route_history.push_back({
		"route": route_name,
		"config": config,
		"view": page,
	})
	screen_changed.emit(route_name, config)


## Pushes a new page onto the UIFlow stack with a horizontal slide transition (`UIFlowSlideEffect`).
func push(route_name: String, config: GameModeConfig = null, animated: bool = true) -> void:
	var page := _build_uiflow_page(route_name, config, false, animated)
	if _navigator != null and page != null:
		_navigator.push_instance(page, config)
	_route_history.push_back({
		"route": route_name,
		"config": config,
		"view": page,
	})
	screen_changed.emit(route_name, config)


## Pops the top page off the UIFlow stack and restores the underlying page without recreating it.
func pop(_animated: bool = true) -> bool:
	if _route_history.size() <= 1:
		return false

	_route_history.pop_back()
	if _navigator != null:
		_navigator.pop()

	var top_entry: Dictionary = _route_history.back()
	var top_view: Control = top_entry.get("view", null)
	if top_view != null and top_view.has_method("on_view_will_appear"):
		top_view.call("on_view_will_appear")

	screen_changed.emit(top_entry["route"], top_entry["config"])
	return true


## Pops all pages above the root page on the UIFlow stack (`UIFlow.pop_to_root()`).
func pop_to_root(_animated: bool = true) -> void:
	if _route_history.size() <= 1:
		return

	while _route_history.size() > 1:
		_route_history.pop_back()

	if _navigator != null:
		_navigator.pop_to_root()

	var root_entry: Dictionary = _route_history.back()
	var root_view: Control = root_entry.get("view", null)
	if root_view != null and root_view.has_method("on_view_will_appear"):
		root_view.call("on_view_will_appear")

	screen_changed.emit(root_entry["route"], root_entry["config"])


## Presents a modal page over the current screen using UIFlow's `is_modal = true` and vertical slide-up transition.
func present_modal(route_name: String, config: GameModeConfig = null, animated: bool = true) -> void:
	var page := _build_uiflow_page(route_name, config, true, animated)
	if _navigator != null and page != null:
		_navigator.push_instance(page, config)
	_route_history.push_back({
		"route": route_name,
		"config": config,
		"view": page,
	})
	screen_changed.emit(route_name, config)


## Dismisses the currently presented modal page via `UIFlow.pop()`.
func dismiss_modal(animated: bool = true) -> bool:
	return pop(animated)


## Pops the current screen and returns to the previous screen on the navigation stack (Type-Safe alias for `pop`).
func go_back(animated: bool = true) -> bool:
	return pop(animated)


## Navigates back to the Main Menu root screen.
func show_main_menu() -> void:
	if not _route_history.is_empty() and _route_history[0]["route"] == ROUTE_MAIN_MENU:
		pop_to_root(true)
	else:
		set_root(ROUTE_MAIN_MENU, null)


## Pushes the AI Difficulty and Mark selection screen onto the UIFlow stack.
func show_difficulty() -> void:
	push(ROUTE_DIFFICULTY, null, true)


## Pushes the 3x3 Game screen configured for a Player vs AI match with strongly-typed parameters.
func show_game_vs_ai(difficulty: Domain.Difficulty, player_mark: Domain.Mark = Domain.Mark.X) -> void:
	var config := GameModeConfig.vs_ai(difficulty, player_mark)
	push(ROUTE_GAME, config, true)


## Pushes the 3x3 Game screen configured for a 2-Player local pass-and-play match.
func show_game_two_players() -> void:
	var config := GameModeConfig.two_players()
	push(ROUTE_GAME, config, true)


## Pushes the 3x3 Game screen onto the UIFlow stack with the provided match configuration.
func show_game(config: GameModeConfig) -> void:
	push(ROUTE_GAME, config, true)


## Presents the High Scores & Statistics screen modally via UIFlow.
func show_scores() -> void:
	present_modal(ROUTE_SCORES, null, true)


## Presents the Settings screen modally via UIFlow.
func show_settings() -> void:
	present_modal(ROUTE_SETTINGS, null, true)


## Builds the target screen and configures `UIFlowPage` properties (`is_modal`, `enter_effect`, `exit_reverses_enter`).
func _build_uiflow_page(route_name: String, config: GameModeConfig, is_modal_page: bool, animated: bool) -> Control:
	var view: Control = null
	if _screen_factories.has(route_name):
		var factory: Callable = _screen_factories[route_name]
		if factory.is_valid():
			view = factory.call(config) as Control

	if view == null:
		return null

	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	if view is UIFlowPage:
		var flow_page := view as UIFlowPage
		flow_page.is_modal = is_modal_page
		if animated and animations_enabled and _screen_container != null and _screen_container.is_inside_tree():
			var slide := UIFlowSlideEffect.new()
			slide.direction = UIFlowSlideEffect.Direction.DOWN if is_modal_page else UIFlowSlideEffect.Direction.RIGHT
			slide.duration = 0.24
			flow_page.enter_effect = slide
			flow_page.exit_reverses_enter = true

	if view.has_method("on_view_will_appear"):
		view.call("on_view_will_appear")

	return view


## Retrieves the `UIFlow` Autoload singleton from the active SceneTree when running inside the game.
func _get_global_uiflow() -> Node:
	if _screen_container != null and _screen_container.is_inside_tree():
		var tree := _screen_container.get_tree()
		if tree != null and tree.root != null:
			return tree.root.get_node_or_null("UIFlow")
	return null
