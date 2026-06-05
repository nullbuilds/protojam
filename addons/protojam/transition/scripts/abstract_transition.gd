@abstract
class_name AbstractTransition
extends Node
## A visual transition meant to obsucure and reveal something behind it.
## 
## * Transitioning [b]in[/b] means to go from fully obscured (ex loading screen)
##   to fully visible (ex gameplay)[br]
## * Transitioning [b]out[/b] means to go from fully visible (ex gameplay) to
##   fully obscured (ex a loading screen)
## [br][br]
## Users should override [method _start_transition_in] and
## [method _start_transition_out] to implement their custom transitions and call
## [method _end_transition_in] and [method _end_transition_out] respectively to
## end their transitions. Transitions should always create themselves in the out
## state for consistency.

## The current state of the transition.
enum TransitionState {
	## The transition is finished and not obscuring the content.
	FINISHED_IN,
	
	## The transition is finished and fully obscuring the content.
	FINISHED_OUT,
	
	## Transitioning from not obscuring content to obscuring content.
	TRANSITIONING_OUT,
	
	## Transitioning from obscuring content to not obscuring content.
	TRANSITIONING_IN,
}

## Emitted when a transition in is complete.
## 
## Custom implementations should call [method _end_transition_in] to signal this
## instead.
signal transitioned_in()

## Emitted when a transition out is complete.
## 
## Custom implementations should call [method _end_transition_out] to signal
## this instead.
signal transitioned_out()

## The current state of the transition.
## 
## Users should not typically set this directly. Use [method _end_transition_in]
## or [method _end_transition_out] instead.
var _state: TransitionState = TransitionState.FINISHED_OUT

## Starts a transition in.
## 
## Setting [param reset] will force the transition to start from the beginning
## regardless of current state; otherwise, an error will be returned if
## currently transitioning out or a warning if already transitioned/ing in. 
## [br][br]
## [b]Note:[/b] Custom implementations should not override this. Use
## [method _start_transition_in] instead.
func transition_in(reset: bool = false) -> Error:
	if not reset:
		match _state:
			TransitionState.TRANSITIONING_OUT:
				push_error("Failed to start transition in; transition \"%s\" is currently transitioning out" % get_path())
				return Error.ERR_BUSY
			TransitionState.FINISHED_IN:
				push_warning("Unable to start transition in; transition \"%s\" is already transitioned in" % get_path())
				return Error.OK
			TransitionState.TRANSITIONING_IN:
				push_warning("Unable to start transition in; transition \"%s\" is already transitioning in" % get_path())
				return Error.OK
	
	_state = TransitionState.TRANSITIONING_IN
	_start_transition_in()
	return Error.OK


## Starts a transition out.
## 
## Setting [param reset] will force the transition to start from the beginning
## regardless of current state; otherwise, an error will be returned if
## currently transitioning in or a warning
## if already transitioned/ing out.
## [br][br]
## [b]Note:[/b] Custom implementations should not override this. Use
## [method _start_transition_out] instead.
func transition_out(reset: bool = false) -> Error:
	if not reset:
		match _state:
			TransitionState.TRANSITIONING_IN:
				push_error("Failed to start transition out; transition \"%s\" is currently transitioning in" % get_path())
				return Error.ERR_BUSY
			TransitionState.FINISHED_OUT:
				push_warning("Unable to start transition out; transition \"%s\" is already transitioned out" % get_path())
				return Error.OK
			TransitionState.TRANSITIONING_OUT:
				push_warning("Unable to start transition out; transition \"%s\" is already transitioning out" % get_path())
				return Error.OK
	
	_state = TransitionState.TRANSITIONING_OUT
	_start_transition_out()
	return Error.OK


## Returns if this transition is currently transitioning.
func is_transitioning() -> bool:
	return _state in [TransitionState.TRANSITIONING_IN, TransitionState.TRANSITIONING_OUT]


## Indicates a transition in is complete.
## 
## Custom implementations should call this when fully transitioned in to signal
## the transition is complete.
## [br][br]
## [b]Note:[/b] Users should not override this function.
func _end_transition_in() -> void:
	_state = TransitionState.FINISHED_IN
	
	# Deferred to ensure users can't accidentically emit this signal immediately
	# from _start_transition_in before callers can connect to it.
	transitioned_in.emit.call_deferred()


## Indicates a transition out is complete.
## 
## Custom implementations should call this when fully transitioned out to signal
## the transition is complete.
## [br][br]
## [b]Note:[/b] Users should not override this function.
func _end_transition_out() -> void:
	_state = TransitionState.FINISHED_OUT
	
	# Deferred to ensure users can't accidentically emit this signal immediately
	# from _start_transition_out before callers can connect to it.
	transitioned_out.emit.call_deferred()


## Starts the transition in.
## 
## Custom implementations should override this function to start a transition
## in. The transition should always start from fully transitioned out.
## [br][br]
## [b]Note:[/b] Be sure to call [method end_transition_in] when the transition
## is over.
@abstract
func _start_transition_in() -> void


## Starts the transition out.
## 
## Custom implementations should override this function to start a transition
## out. The transition should always start from fully transitioned in.
## [br][br]
## [b]Note:[/b] Be sure to call [method end_transition_out] when the transition
## is over.
@abstract
func _start_transition_out() -> void
