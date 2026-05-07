class_name Game
extends Node
## Example game implementation.
## 
## Your game class should handle the game state for a single play session and be
## as self-contained as possible to avoid leaking state that is not easily
## reset.

## Emitted when the game is over.
signal game_over()

## Coroutine to load and start a level.
func start(level_path: String) -> void:
	if Error.OK != await _load_level(level_path):
		# Crashing the game for a failed level is usually bad UX, gracefully
		# return to the menu instead.
		game_over.emit()


## Coroutine to load a level asynchronously.
func _load_level(level_path: String) -> Error:
	var handle: AsyncResourceHandle = BackgroundResourceLoader.load_async(level_path, "PackedScene")
	if null == handle:
		push_error("Failed to load level \"%s\"; loading failed" % level_path)
		return Error.FAILED
	
	var successfully_loaded: bool = await handle.ready
	if not successfully_loaded:
		push_error("Failed to load level \"%s\"; loading failed" % level_path)
		return Error.FAILED
	
	var level_scene: PackedScene = handle.get_resource()
	var level: Node = level_scene.instantiate()
	add_child(level)
	return Error.OK
