class_name NodeSwapper
extends Node
## A node which swaps its child during a screen transition.
## 
## This is the preferred alternative to [method SceneTree.change_scene_to_node].
## To accomplish similar results, create a main scene which handles your
## application's modes and add one instance of this from your main scene and use
## it to swap sub-scenes.
## [br][br]
## [b]Note:[/b] If transitioning while paused, ensure this node's
## [member process_mode] is set accordingly.

## Emitted when a transition completes.
signal transitioned(content: Node)

## Default provider for the transition to use during swaps.
## 
## Can be overriden in the calls to [method transition_to] and
## [method transition_to_scene].
@export var transition_provider: AbstractTransitionProvider = null

# The precense of this node is used to detect whether a transition is actively
# occuring.
var _transition: AbstractTransition = null

## Returns if the node is currently transitioning its content.
func is_transitioning() -> bool:
	return is_instance_valid(_transition)


## Transitions to an arbitrary node.
## 
## [param content_provider] must be a coroutine which accepts no arguments and
## returns the [Node] to transition to or [code]null[/code] if an error occured.
## [param content_ready_callback] is optional and will be called with the newly
## provided node immediately after it is added to the tree.
## [br][br]
## The [param custom_transition_provider] is optional and will be used to
## transition out of the existing content and into the new content instead of
## [member transition_provider]. A transition out will not occur if there is no
## existing content.
## [br][br]
## [b]Note:[/b] A new transition cannot be started while another is still
## in-progress. Use [method is_transitioning] and [signal transitioned] to check
## and wait for the current transition before calling this.
## [br][br]
## Prefer [method transition_to_scene] when transitioning to a [PackedScene].
func transition_to(
		content_provider: Callable,
		content_ready_callback: Callable = Callable(),
		custom_transition_provider: AbstractTransitionProvider = null) -> Error:
	if not content_provider.is_valid():
		push_error("Unable to transition; content_provider is invalid")
		return Error.ERR_INVALID_PARAMETER
	
	var provider: _AbstractContentProvider = _CustomContentProvider.new(content_provider)
	return _transition_to(provider, content_ready_callback, custom_transition_provider)


## Transitions to an instance of the packed scene at [param scene_path].
## 
## The scene file at [param scene_path] will be loaded asynchronously. Once
## loaded, a new instance will be created and [param content_initializer] will
## optionally be called with the new instance as the only argument before adding
## it to the tree. [param content_ready_callback] is optional and will be called
## with the newly instantiated node immediately after it is added to the tree.
## [br][br]
## The [param custom_transition_provider] is optional and will be used to
## transition out of the existing content and into the new content instead of
## [member transition_provider]. A transition out will not occur if there is no
## existing content.
## [br][br]
## [b]Note:[/b] A new transition cannot be started while another is still
## in-progress. Use [method is_transitioning] and [signal transitioned] to check
## and wait for the current transition before calling this.
func transition_to_scene(
		scene_path: String,
		content_initializer: Callable = Callable(),
		content_ready_callback: Callable = Callable(),
		custom_transition_provider: AbstractTransitionProvider = null) -> Error:
	var provider: _AbstractContentProvider = _SceneContentProvider.new(scene_path, content_initializer)
	return _transition_to(provider, content_ready_callback, custom_transition_provider)


## Transitions to the content provided by [param content_provider].
## 
## Users should not call this directly. Use [method transition_to] or
## [method transition_to_scene].
func _transition_to(
		content_provider: _AbstractContentProvider,
		content_ready_callback: Callable,
		custom_transition_provider: AbstractTransitionProvider) -> Error:
	var error: Error = Error.OK
	
	var provider: AbstractTransitionProvider = transition_provider
	if is_instance_valid(custom_transition_provider):
		provider = custom_transition_provider
	
	if not is_instance_valid(provider):
		push_error("Failed to transition; transition_provider is null and a custom provider was not supplied")
		error = Error.ERR_INVALID_PARAMETER
	else:
		error = _setup_transition(provider)
		if Error.OK == error:
			_start_transition(content_provider, content_ready_callback)
	
	return error


## Sets up the transition to use while swapping nodes.
## 
## Users should not call this directly. Use [method transition_to] or
## [method transition_to_scene].
func _setup_transition(provider: AbstractTransitionProvider) -> Error:
	if is_transitioning():
		push_error("Unable to transition; already transitioning")
		return Error.ERR_ALREADY_IN_USE
	
	var transition_node: AbstractTransition = provider.provide()
	if not is_instance_valid(transition_node):
		push_error("Unable to transition; transition provider returned null")
		return Error.FAILED
	
	_transition = transition_node
	add_child(_transition, false, Node.INTERNAL_MODE_BACK)
	return Error.OK


## Starts the transition to new content.
## 
## Users should not call this directly. Use [method transition_to] or
## [method transition_to_scene].
func _start_transition(
		content_provider: _AbstractContentProvider,
		content_ready_callback: Callable) -> void:
	var transition_in: Callable = _swap_content.bind(
				content_provider, content_ready_callback)
	
	# Start transition out animation or start transitioning immediately if
	# there's nothing to transition from
	if _has_content():
		_transition.transitioned_out.connect(transition_in, CONNECT_ONE_SHOT)
		_transition.transition_out(true)
	else:
		# Do not await this, we want to let this run in the background
		transition_in.call()


## Finalizes the transition.
## 
## Users should not call this directly. Use [method transition_to] or
## [method transition_to_scene].
func _end_transition(content: Node) -> void:
	_transition.queue_free()
	_transition = null
	
	transitioned.emit(content)


## Starts transitioning in new content.
## 
## Users should not call this directly. Use [method transition_to] or
## [method transition_to_scene].
func _swap_content(
		content_provider: _AbstractContentProvider,
		content_ready_callback: Callable) -> void:
	_remove_content()
	
	var content: Node = await _add_content(content_provider, content_ready_callback)
	
	_transition.transitioned_in.connect(_end_transition.bind(content), CONNECT_ONE_SHOT)
	_transition.transition_in()


## Removes existing content.
## 
## Users should not call this directly. Use [method transition_to] or
## [method transition_to_scene].
func _remove_content() -> void:
	# Remove old content, but do not remove transition node
	for child in get_children(true):
		if child != _transition:
			child.queue_free()


## Coroutine to add new content.
## 
## Users should not call this directly. Use [method transition_to] or
## [method transition_to_scene].
func _add_content(
		content_provider: _AbstractContentProvider,
		content_ready_callback: Callable) -> Node:
	# This really is a coroutine, Godot can't detect abstract coroutines
	@warning_ignore("redundant_await")
	var content: Node = await content_provider.provide()
	if is_instance_valid(content):
		# Add content and wait for it to become presentable
		add_child(content)
	
	if content_ready_callback.is_valid():
		await content_ready_callback.call(content)
	
	return content


## Tests if this node has content.
## 
## Users should not call this directly. 
func _has_content() -> bool:
	for child in get_children(true):
		if child != _transition:
			return true
	
	return false


## Provides an instance of a node of varying type.
## 
## Optionally initializes the node after construction by passing the new
## node to the provided intializer function.
@abstract class _AbstractContentProvider extends RefCounted:
	## Coroutine to provide an instance of a node.
	## 
	## Custom implementations should override this to construct or otherwise return
	## an instance of a node of their chosen type.
	@abstract
	func provide() -> Node


## Provides an instane of a node by making a call to an initializer coroutine.
class _CustomContentProvider extends _AbstractContentProvider:
	var _initializer: Callable = Callable()
	
	## Construct a new provider.
	## 
	## The [param initializer] is a coroutine which must accept no arguments and
	## return either a constructed [Node] or null.
	## [br][br]
	## [b]Note:[/b] Users must call this function from their own init function.
	func _init(initializer: Callable) -> void:
		_initializer = initializer
	
	
	func provide() -> Node:
		if not _initializer.is_valid():
			push_error("Failed to transition to node; initializer is not valid")
			return null
		
		var content: Node = await _initializer.call()
		return content


## Provides an instance of a packed scene by loading it asynchronously.
class _SceneContentProvider extends _AbstractContentProvider:
	var _scene_path: String = ""
	var _initializer: Callable = Callable()
	
	## Construct a new provider.
	## 
	## The [param initializer] is an optional coroutine which will be called
	## after constructing the node with a reference to it to perform post
	## construction initialization.
	## [br][br]
	## [b]Note:[/b] Users must call this function from their own init function.
	func _init(scene_path: String, initializer: Callable = Callable()) -> void:
		_initializer = initializer
		_scene_path = scene_path
	
	
	func provide() -> Node:
		var handle: AsyncResourceHandle = BackgroundResourceLoader.load_async(_scene_path, "PackedScene")
		if null == handle:
			push_error("Failed to transition to scene \"%s\"; loading failed" % _scene_path)
			return null
		
		var successfully_loaded: bool = await handle.ready
		if not successfully_loaded:
			push_error("Failed to transition to scene \"%s\"; loading failed" % _scene_path)
			return null
		
		var content_scene: PackedScene = handle.get_resource()
		var content: Node = content_scene.instantiate()
		
		if _initializer.is_valid():
			await _initializer.call(content)
		
		return content
