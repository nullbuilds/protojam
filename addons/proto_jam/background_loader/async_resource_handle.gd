class_name AsyncResourceHandle
extends RefCounted
## Handle used to check the progress of a background loading request.
## 
## Users should not create instances directly. Instead, use
## [method BackgroundResourceLoader.load_async] to obtain a handle.

## Emitted when the loading results are ready.
##
## A value of [code]true[/code] indicates the resource successfully loaded.
signal ready(success: bool)

## The status of the request.
enum Status {
	## The request has not yet started.
	PENDING,
	
	## The resource is currently loading.
	LOADING,
	
	## The resource is loaded and usable.
	LOADED,
	
	## The resource failed to load.
	FAILED,
}

var _resource_path: String = ""
var _resource_type: String = ""
var _status: Status = Status.PENDING
var _progress: float = 0.0

## Initializes a new resource handle.
## 
## Users should not call this function directly. Instead, use
## [method BackgroundResourceLoader.load_async] to obtain a handle.
func _init(resource_path: String, resource_type: String) -> void:
	_resource_path = resource_path
	_resource_type = resource_type


## Returns whether the resource load results is ready.
func is_ready() -> bool:
	return Status.LOADED == _status or Status.FAILED == _status


## Returns the loading progress ratio.
## 
## This value is intended purely for driving UI elements and should not be used
## to make any decisions as it is not guaranteed to reflect the loading status
## accurately.
func get_progress() -> float:
	return _progress


## Returns the request status.
func get_status() -> Status:
	return _status


## Returns the path to the requested resource.
func get_path() -> String:
	return _resource_path


## Returns the type string of the requested resource.
func get_type() -> String:
	return _resource_type


## Gets the loaded resource.
## 
## Callers should [code]await[/code] [signal ready] to determine if it is
## safe to call this. Calling before the resource is ready or if it failed
## to load will return [code]null[/code].
func get_resource() -> Resource:
	if Status.LOADED == _status:
		return ResourceLoader.load_threaded_get(_resource_path)
	else:
		var status: String = Status.find_key(_status)
		push_error("Attempted to get resource \"%s\" when it wasn't loaded; was \"%s\"" % [_resource_path, status])
		return null


## Updates the handle's internal state.
## 
## Users should not call this function directly. Use
## [method BackgroundResourceLoader.load_async] to obtain a handle that
## updates its state automatically.
func _update_status(status: Status, progress: float) -> void:
	var valid_transition: bool = false
	match _status:
		Status.PENDING, Status.LOADING:
			valid_transition = Status.PENDING != status
	
	if valid_transition:
		_status = status
		_progress = progress
	
		if Status.LOADED == status:
			_progress = 1.0
			ready.emit(true)
		elif Status.FAILED == status:
			_progress = 0.0
			ready.emit(false)
	else:
		var old_status: String = Status.find_key(_status)
		var new_status: String = Status.find_key(status)
		push_error("Failed to update resource handle for \"%s\"; invalid state transition; cannot transition from \"%s\" to \"%s\"" % [_resource_path, old_status, new_status])
