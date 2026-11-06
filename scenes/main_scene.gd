@tool
## Composition root attached to the main MainScene scene that initializes DI, registers screen factories, and starts navigation.
class_name MainScene
extends Control

## Reference to the child container where active screens are mounted.
@onready var screen_container: Control = $ScreenContainer

## Reference to the child Node that hosts AudioStreamPlayer instances.
@onready var audio_host: Node = $AudioService

## Application-wide dependency injection container.
var container: AppContainer

## Application-wide UIFlow-backed screen navigation coordinator.
var coordinator: AppCoordinator


## Initializes repositories, services, DI container, and coordinator when the scene enters the tree.
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	container = AppContainer.new(audio_host)
	coordinator = AppCoordinator.new(screen_container, container)
	register_default_routes(coordinator, container)
	container.audio_service.play_music()
	coordinator.start()
	call_deferred("_ensure_music_started")


func _ensure_music_started() -> void:
	if container != null and container.audio_service != null:
		container.audio_service.play_music()


## Registers screen factories for MainMenu, Difficulty, Scores, and Settings (and Game when available) on `p_coordinator`.
static func register_default_routes(p_coordinator: AppCoordinator, p_container: AppContainer) -> void:
	p_coordinator.register_screen_factory(
		AppCoordinator.ROUTE_MAIN_MENU,
		func(_cfg: GameModeConfig) -> Control:
			var scene := preload("res://scenes/menu/main_menu_view.tscn") as PackedScene
			var view := scene.instantiate() as MainMenuView
			var vm := MainMenuViewModel.new(p_container, p_coordinator)
			view.setup(vm)
			return view
	)

	p_coordinator.register_screen_factory(
		AppCoordinator.ROUTE_DIFFICULTY,
		func(_cfg: GameModeConfig) -> Control:
			var scene := preload("res://scenes/difficulty/difficulty_view.tscn") as PackedScene
			var view := scene.instantiate() as DifficultyView
			var vm := DifficultyViewModel.new(p_container, p_coordinator)
			view.setup(vm)
			return view
	)

	p_coordinator.register_screen_factory(
		AppCoordinator.ROUTE_SCORES,
		func(_cfg: GameModeConfig) -> Control:
			var scene := preload("res://scenes/scores/scores_view.tscn") as PackedScene
			var view := scene.instantiate() as ScoresView
			var vm := ScoresViewModel.new(p_container, p_coordinator)
			view.setup(vm)
			return view
	)

	p_coordinator.register_screen_factory(
		AppCoordinator.ROUTE_SETTINGS,
		func(_cfg: GameModeConfig) -> Control:
			var scene := preload("res://scenes/settings/settings_view.tscn") as PackedScene
			var view := scene.instantiate() as SettingsView
			var vm := SettingsViewModel.new(p_container, p_coordinator)
			view.setup(vm)
			return view
	)

	p_coordinator.register_screen_factory(
		AppCoordinator.ROUTE_GAME,
		func(cfg: GameModeConfig) -> Control:
			var scene := preload("res://scenes/game/game_view.tscn") as PackedScene
			var view := scene.instantiate() as GameView
			var vm := GameViewModel.new(p_container, p_coordinator, cfg)
			view.setup(vm)
			return view
	)
