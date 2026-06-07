@abstract
class_name AbstractNodeState
extends Node
## Defines an abstract node-based state to be executed by a [NodeStateMachine].

## Returns the name of the state for use when debugging.
## 
## Users override this function to return the name of their state.
func get_state_name() -> String:
	return "<undefined>"


## Called when the state is first transitioned to.
## 
## Users should override this function to perform any desired setup behavior for
## the state.
## [br][br]
## This function should not be called directly. Use a [NodeStateMachine]
## instead.
@warning_ignore("unused_parameter")
func enter(state_machine: NodeStateMachine) -> void:
	pass


## Called when the state is updated.
## 
## Users should override this function to perform any desired behavior for the
## state. This should generally be used instead of [method Node._process] or
## [method Node._physics_process] as those will run every frame regardless of
## whether this state is currently active.
## [br][br]
## This function should not be called directly. Use a [NodeStateMachine]
## instead.
@warning_ignore("unused_parameter")
func execute(state_machine: NodeStateMachine, delta: float) -> void:
	pass


## Called when the state is transitioned out.
## 
## Users should override this function to perform any desired teardown behavior
## for the state.
## [br][br]
## This function should not be called directly. Use a [NodeStateMachine]
## instead.
@warning_ignore("unused_parameter")
func exit(state_machine: NodeStateMachine) -> void:
	pass
