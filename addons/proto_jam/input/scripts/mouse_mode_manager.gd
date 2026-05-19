extends Node
## Autoload for arbitrating control of [member Input.mouse_mode].

# Whether a request has been made this frame.
var _has_request: bool = false

# The highest priority request seen this frame.
var _highest_priority: int = Vector2i.MIN.x

# The highest priority mode requested this frame.
var _highest_priority_mode: Input.MouseMode = Input.MouseMode.MOUSE_MODE_VISIBLE

# Mutex gating access to the manager to ensure thread-safety.
var _mutex: Mutex = Mutex.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if _has_request:
		_change_mouse_mode()


## Batches a request to change the mouse mode.
## 
## Requests are batched per frame and only the request with the highest
## [param priority] that frame is executed. To maintain the same mode, callers
## should keep making requests with the same priority every frame or else a
## lower priority request may take over.
func request_mode(priority: int, mode: Input.MouseMode) -> void:
	_mutex.lock()
	
	# Don't just check priority, also check if there's an existing request for
	# the off-chance a request with minimum priority is made
	if _has_request and priority == _highest_priority:
		push_warning("Mouse mode manager ignored priority %d request to change mode to %d; a request with that priority was already submitted this cycle" % [priority, mode])
	elif priority > _highest_priority:
		_has_request = true
		_highest_priority = priority
		_highest_priority_mode = mode
	
	_mutex.unlock()


## Changes the mouse mode to the highest priority mode requested this frame.
## 
## Users should not call this directly. Use [method request_mode] instead.
func _change_mouse_mode() -> void:
	# Shouldn't happen but protect against improper calls to be safe
	if not _has_request:
		return
	
	_mutex.lock()
	
	if Input.mouse_mode != _highest_priority_mode:
		Input.mouse_mode = _highest_priority_mode
	
	# Reset state for next frame
	_has_request = false
	_highest_priority = Vector2i.MIN.x
	_highest_priority_mode = Input.MouseMode.MOUSE_MODE_VISIBLE
	
	_mutex.unlock()
