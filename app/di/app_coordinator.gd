## Coordinates screen navigation and transitions inside the main ScreenContainer without using Autoload singletons.
class_name AppCoordinator
extends RefCounted

## Emitted whenever the coordinator navigates to a new screen route.
signal screen_changed(route_name: String, config: GameModeConfig)

## Route identifier for the Main Menu screen.
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
var _current_route: String = ""
var _current_config: GameModeConfig = null
var _current_screen: Control = null
var _screen_factories: Dictionary = {}


## Initializes the coordinator with the host ScreenContainer node and the AppContainer.
func _init(screen_container: Control, container: AppContainer) -> void:
	_screen_container = screen_container
	_container = container


## Returns the DI container associated with this coordinator.
func get_container() -> AppContainer:
	return _container


## Returns the identifier of the currently active route.
func get_current_route() -> String:
	return _current_route


## Returns the GameModeConfig of the most recently launched game (or null if none).
func get_current_config() -> GameModeConfig:
	return _current_config


## Returns the currently mounted screen Control node inside ScreenContainer.
func get_current_screen() -> Control:
	return _current_screen


## Registers a custom callable factory `func(config: GameModeConfig) -> Control` for a given route name.
func register_screen_factory(route_name: String, factory: Callable) -> void:
	_screen_factories[route_name] = factory


## Starts the application flow by opening the Main Menu screen.
func start() -> void:
	show_main_menu()


## Navigates to the Main Menu screen.
func show_main_menu() -> void:
	_navigate_to(ROUTE_MAIN_MENU, null)


## Navigates to the AI Difficulty and Mark selection screen.
func show_difficulty() -> void:
	_navigate_to(ROUTE_DIFFICULTY, null)


## Navigates to the 3x3 Game screen with the provided match configuration.
func show_game(config: GameModeConfig) -> void:
	_navigate_to(ROUTE_GAME, config)


## Navigates to the High Scores & Statistics screen.
func show_scores() -> void:
	_navigate_to(ROUTE_SCORES, null)


## Navigates to the Settings screen.
func show_settings() -> void:
	_navigate_to(ROUTE_SETTINGS, null)


## Internal helper that replaces the active screen node inside ScreenContainer with a fade transition.
func _navigate_to(route_name: String, config: GameModeConfig) -> void:
	_current_route = route_name
	_current_config = config

	if _screen_container != null:
		for child in _screen_container.get_children():
			_screen_container.remove_child(child)
			child.queue_free()

		var next_screen := _build_screen(route_name, config)
		if next_screen != null:
			_current_screen = next_screen
			_screen_container.add_child(next_screen)
			_animate_screen_entry(next_screen)

	screen_changed.emit(route_name, config)


## Builds the Control node for the requested route using registered factories.
func _build_screen(route_name: String, config: GameModeConfig) -> Control:
	if _screen_factories.has(route_name):
		var factory: Callable = _screen_factories[route_name]
		if factory.is_valid():
			return factory.call(config) as Control
	return null


## Plays a subtle chalkboard fade-in transition on the newly mounted screen when inside the scene tree.
func _animate_screen_entry(screen: Control) -> void:
	if not screen.is_inside_tree():
		return
	screen.modulate.a = 0.0
	var tween := screen.create_tween()
	tween.tween_property(screen, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
