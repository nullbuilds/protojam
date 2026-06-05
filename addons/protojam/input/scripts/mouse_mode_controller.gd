class_name MouseModeController
extends Node
## Automatically captures or releases the mouse while active.
## 
## This node automatically requests [MouseModeManager] to change to the
## [member Input.mouse_mode] to the desired mode while being processed. This
## allows you to keep the mouse in a desired mode even if it was changed by an
## external factor (like pressing escape in a web build).
## [br][br]
## [b]Note:[/b] For the request to be applied, this node must have the highest
## priority request of all requests received by [MouseModeManager] that frame.
## This node will not make requests while paused or inactive.
## [br][br]
## A common use-case is to put one node in the pause menu with the
## [Node.PROCESS_MODE_WHEN_PAUSED] [member process_mode] to release the mouse
## and another node in the game scene set to capture it with the
## [Node.PROCESS_MODE_PAUSABLE] mode. With this configuration, the mouse will be
## automatically released when the game is paused and re-captured otherwise.

## Whether this node will attempt to change the mouse mode.
## 
## For most situations, this should be left [code]true[/code] so the node will
## automatically set the mode when allowed by its [member process_mode].
@export var active: bool = true

## The request priority.
## 
## Requests with a higher priority take precedence.
@export var priority: int = 1

## The desired mouse mode.
@export var mouse_mode: Input.MouseMode = Input.MouseMode.MOUSE_MODE_CAPTURED

var _mouse_mode_manager: Memoizer = Memoizer.new(_get_mouse_mode_manager)

func _process(_delta: float) -> void:
	if active:
		# Do not try to check mouse mode yourself, doing so can cause
		# flip-flopping between two active nodes since changes are applied the
		# next frame.
		var manager: Node = await _mouse_mode_manager.get_value()
		if is_instance_valid(manager):
			MouseModeManager.request_mode(priority, mouse_mode)
		else:
			push_error("Failed to request mouse mode; MouseModeManager autoload is not present; did you forget to enable the ProtoJam plugin?")


## Fetches the mouse mode manager autoload without referencing its type.
## 
## Users should not call this. Use [MouseModeManager] instead.
func _get_mouse_mode_manager() -> Node:
	if has_node("/root/MouseModeManager"):
		return get_node("/root/MouseModeManager")
	
	return null
