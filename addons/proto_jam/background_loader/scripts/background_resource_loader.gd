@abstract
class_name BackgroundResourceLoader
extends RefCounted
## Static utility for loading resources asynchronously.

static var _loading_thread: _ResourceLoaderThread = _ResourceLoaderThread.new()

## Starts the resource loader in the background.
## 
## The thread will be started automatically on the first call to
## [method load_resource_async] but doing so may cause the main thread to stall
## momentarilly. Users are strongly encouraged to call this function early in
## the game, preferably from the main scene's [method Node._ready] function, to
## avoid noticeable delays. This function is indempotent but will generate a
## warning if called twice as this likely indicates a user error to start the
## loader before using it.
static func start(priority: Thread.Priority = Thread.Priority.PRIORITY_NORMAL) -> Error:
	return _loading_thread._start(priority)


## Starts loading a resource in the background.
## 
## Starts the resource loader thread if not already started. Users are strongly
## advised to start the thread using [method start] first to control when the
## thread startup delay will occur.
static func load_async(resource_path: String, resource_type: String) -> AsyncResourceHandle:
	return _loading_thread._queue_resource_for_loading(resource_path, resource_type)


## Shuts down and joins the background loader thread.
## 
## Users [b]MUST[/b] call this before the engine closes, preferably from a
## node's [method Node._notification] function to prevent hangups or crashes
## when closing.
static func stop() -> void:
	_loading_thread._stop()


## Internal thread for loading resources.
## 
## Users should not access this class directly. See
## [method BackgroundResourceLoader.load_async] instead.
class _ResourceLoaderThread extends Thread:
	# Posted to indicate a command is ready for processing
	var _command_semaphore: Semaphore = Semaphore.new()
	
	# Locked to protect the thread parameters
	var _parameter_mutex: Mutex = Mutex.new()
	
	# Thread parameters
	var _exit: bool = false
	var _pending_resources: Array[AsyncResourceHandle] = []
	
	## Starts the resource loader in the background.
	## 
	## Users should not call this function directly. See
	## [method BackgroundResourceLoader.start] instead.
	func _start(priority: Priority = Priority.PRIORITY_NORMAL) -> Error:
		if is_started():
			push_warning("Unable to start async resource loader thread; thread was already started")
			return Error.ERR_ALREADY_IN_USE
		
		start(_load_resources, priority)
		return Error.OK
	
	
	## Shuts down and joins the background loader thread.
	## 
	## Users should not call this function directly. See
	## [method BackgroundResourceLoader.stop] instead.
	func _stop() -> void:
		if not is_started():
			push_warning("Unable to stop async resource loader thread; the thread hasn't been started yet")
			return
		
		# Update parameters and send stop command
		_parameter_mutex.lock()
		_exit = true
		_pending_resources.clear()
		_parameter_mutex.unlock()
		
		_command_semaphore.post()
		
		wait_to_finish()
	
	
	## Queues a resource to load in the background.
	## 
	## Users should not call this function directly. See
	## [method BackgroundResourceLoader.load_async] instead.
	func _queue_resource_for_loading(resource_path: String,
			resource_type: String) -> AsyncResourceHandle:
		if not is_started():
			push_warning("Attempted to load a resource in the background without first calling start; starting now")
			var error: Error = _start()
			if Error.OK != error:
				push_error("Failed to queue \"%s\" for loading; failed to start resource loader thread; error code %d" % [resource_path, error])
				return null
		
		# Create a new resource handle and start it pending
		var handle: AsyncResourceHandle = AsyncResourceHandle.new(resource_path, resource_type)
		_parameter_mutex.lock()
		_pending_resources.push_back(handle)
		_parameter_mutex.unlock()
		
		_command_semaphore.post()
		
		return handle
	
	
	## Main loop to load and monitor resources.
	## 
	## Users should not call this function directly. See
	## [method BackgroundResourceLoader.load_async] instead.
	func _load_resources() -> void:
		# Resources being actively tracked (ie not done loading yet)
		var loading_resources: Array[AsyncResourceHandle] = []
		
		while true:
			# Current command parameters
			var has_new_command: bool = false
			var exit: bool = false
			var pending_resources: Array[AsyncResourceHandle] = []
			
			# If there's no loading resources to monitor, wait for a command;
			# otherwise, check for a new command but don't wait for it.
			if loading_resources.is_empty():
				print("Background resource loader waiting; no resources to monitor or commands to execute")
				_command_semaphore.wait()
				has_new_command = true
			else:
				has_new_command = _command_semaphore.try_wait()
			
			# Grab new command parameters, if any
			if has_new_command:
				_parameter_mutex.lock()
				exit = _exit
				pending_resources = _pending_resources.duplicate()
				_pending_resources.clear()
				_parameter_mutex.unlock()
				print("Background resource loader running; new command received")
			else:
				# TODO find a way to await one frame if there isn't a new
				# command so polling of the ResourceLoader is only done once per
				# frame as it recommends
				pass
			
			# Exit immediately if commanded
			if exit:
				print("Background resource loader terminating; exit command acknowledged")
				return
			
			# Start loading any pending resources
			var started_resources: Array[AsyncResourceHandle] = \
					_start_loading_resources(pending_resources)
			loading_resources.append_array(started_resources)
			
			# Monitor progress of loading resources
			var loaded_resource: Array[AsyncResourceHandle] = \
					_monitor_pending_resources(loading_resources)
			BaseUtils.remove_all(loading_resources, loaded_resource)
	
	
	## Starts loading the given resources.
	## 
	## Users should not call this function directly. See
	## [method BackgroundResourceLoader.load_async] instead.
	func _start_loading_resources(resources: Array[AsyncResourceHandle]) -> Array[AsyncResourceHandle]:
		var loading_resources: Array[AsyncResourceHandle] = []
		for resource in resources:
			var path: String = resource.get_path()
			var type: String = resource.get_type()
			print("Background resource loader starting load of \"%s\"" % path)
			var error: Error = ResourceLoader.load_threaded_request(path, type)
			if Error.OK == error:
				loading_resources.push_back(resource)
			else:
				push_error("Failed to load resource \"%s\" as type \"%s\"; failed with error code %d" % [path, type, error])
				# Update deferred so the update and its resulting signal happen
				# on the main thread. Also ensures callers have had a chance to
				# connect to the signal after calling load_async.
				resource._update_status.call_deferred(AsyncResourceHandle.Status.FAILED, 0.0)
		
		return loading_resources
	
	
	## Updates the loading status of each resource.
	## 
	## Users should not call this function directly. See
	## [method BackgroundResourceLoader.load_async] instead.
	func _monitor_pending_resources(resources: Array[AsyncResourceHandle]) -> Array[AsyncResourceHandle]:
		var ready: Array[AsyncResourceHandle] = []
		for resource in resources:
			var path: String = resource.get_path()
			var type: String = resource.get_type()
			var progress_array: Array = []
			var thread_status: ResourceLoader.ThreadLoadStatus = \
					ResourceLoader.load_threaded_get_status(path, progress_array)
			
			var progress_ratio: float = 0.0
			var new_status: AsyncResourceHandle.Status = AsyncResourceHandle.Status.FAILED
			
			match(thread_status):
				ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
					progress_ratio = progress_array.front() if not progress_array.is_empty() else 0.0
					new_status = AsyncResourceHandle.Status.LOADING
				ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
					print("Background resource loader finished load of \"%s\"" % path)
					progress_ratio = 1.0
					new_status = AsyncResourceHandle.Status.LOADED
					ready.push_back(resource)
				ResourceLoader.ThreadLoadStatus.THREAD_LOAD_FAILED:
					push_error("Failed to load resource \"%s\"; loading failed" % path)
					progress_ratio = 0.0
					new_status = AsyncResourceHandle.Status.FAILED
					ready.push_back(resource)
				ResourceLoader.ThreadLoadStatus.THREAD_LOAD_INVALID_RESOURCE:
					push_error("Failed to load resource \"%s\" as \"%s\"; invalid resource" % [path, type])
					progress_ratio = 0.0
					new_status = AsyncResourceHandle.Status.FAILED
					ready.push_back(resource)
			
			# Update deferred so the update and its resulting signal happen on
			# the main thread. Also ensures callers have had a chance to connect
			# to the signal after calling load_async.
			resource._update_status.call_deferred(new_status, progress_ratio)
		
		return ready
