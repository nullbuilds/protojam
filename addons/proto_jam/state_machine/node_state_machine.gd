class_name NodeStateMachine
extends Node
## A node-based state machine.

## Defines the update mode for the state machine.
enum UpdateMode {
	## The state machine ticks in [method Node._process].
	PROCESS,
	
	## The state machine ticks in [method Node._physics_process].
	PHYSICS_PROCESS,
	
	## The state machine only ticks when [method NodeStateMachine.tick] is
	## called.
	MANUAL,
}

## Sets when the state machine ticks.
@export var update_mode: UpdateMode = UpdateMode.PROCESS

var _current_state: AbstractNodeState = null
var _next_state: AbstractNodeState = null

func _process(delta: float) -> void:
	if UpdateMode.PROCESS == update_mode:
		_execute(delta)
	

func _physics_process(delta: float) -> void:
	if UpdateMode.PHYSICS_PROCESS == update_mode:
		_execute(delta)


## Manually ticks the state machine.
## 
## Does nothing unless [member update_mode] is [enum UpdateMode.MANUAL].
func tick(delta: float) -> void:
	if UpdateMode.MANUAL == update_mode:
		_execute(delta)
	else:
		push_warning("Failed to manually tick state machine \"%s\"; update mode is not MANUAL" % get_path())


## Changes to the given state.
## 
## The transition will not occur until the next update tick. During the update
## tick:[br]
## 1. The running state will have its [method AbstractNodeState.exit] function
## called.[br]
## 2. The new state will have its [method AbstractNodeState.enter] function
## called.[br]
## 3. The new state will have its [method AbstractNodeState.execute] function
## called.[br]
func change_state(new_state: AbstractNodeState) -> void:
	if not _can_run_state(new_state):
		push_error("Failed to transition to state \"%s\"; state is not valid" % [new_state, self.get_path()])
	else:
		_next_state = new_state


## Gets the currently executing state.
## 
## Returns [code]null[/code] when there is no current state.
func get_current_state() -> AbstractNodeState:
	return _current_state


## Executes the state machine.
## [br][br]
## Users should not call this function directly. 
func _execute(delta: float) -> void:
	if null != _next_state:
		# A null current state is normal and shouldn't result in an error
		if null != _current_state:
			if _can_run_state(_current_state):
				_current_state.exit(self)
			else:
				# There's no guarantee the state has a path yet so print the instance
				push_error("State machine \"%s\" failed to exit current state; state \"%s\" is not runnable" % [get_path(), _current_state])
			
		if _can_run_state(_next_state):
			_next_state.enter(self)
			_current_state = _next_state
			_next_state = null
		else:
			# There's no guarantee the state has a path yet so print the instance
			push_error("State machine \"%s\" failed to enter next state; state \"%s\" is not runnable" % [get_path(), _next_state])
	
	# A null current state is normal and shouldn't result in an error
	if null != _current_state:
		if _can_run_state(_current_state):
			_current_state.execute(self, delta)
		else:
			# There's no guarantee the state has a path yet so print the instance
			push_error("State machine \"%s\" failed to execute current state; state \"%s\" is not runnable" % [get_path(), _current_state])


## Checks if the state is runnable.
## 
## Also pushes errors when the state is not runnable.
## [br][br]
## Users should not call this function directly.
func _can_run_state(state: AbstractNodeState) -> bool:
	if not is_instance_valid(state):
		# There's no guarantee the state has a path yet so print the instance
		push_error("State machine \"%s\" is unable to run state \"%s\"; state instance is not valid" % [get_path(), state])
		return false
	elif not state.is_inside_tree():
		# There's no guarantee the state has a path yet so print the instance
		push_error("State machine \"%s\" is unable to run state \"%s\"; state is not inside the tree" % [get_path(), state])
		return false
	elif not is_ancestor_of(state):
		# Print the state path instead of instance for easier debugging
		push_error("State machine \"%s\" is unable to run state \"%s\"; state is not a descendant of the state machine" % [get_path(), state.get_path()])
		return false
	
	return true
