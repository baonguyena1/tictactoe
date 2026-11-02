## Composition root attached to the main AppRoot scene that initializes DI and starts navigation.
class_name AppRoot
extends Control

## Reference to the child container where active screens are mounted.
@onready var screen_container: Control = $ScreenContainer

## Reference to the child Node that hosts AudioStreamPlayer instances.
@onready var audio_host: Node = $AudioService

## Application-wide dependency injection container (owned by AppRoot, no global singleton).
var container: AppContainer

## Application-wide screen navigation coordinator.
var coordinator: AppCoordinator


## Initializes repositories, services, DI container, and coordinator when the scene enters the tree.
func _ready() -> void:
	container = AppContainer.new(audio_host)
	coordinator = AppCoordinator.new(screen_container, container)
	container.audio_service.play_music()
	coordinator.start()
