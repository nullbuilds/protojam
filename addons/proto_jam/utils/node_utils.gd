@tool
@abstract
class_name NodeUtils
extends RefCounted
## Utilities for common node operations.

## Similar to [method SceneTree.quit] but notifies nodes that the program is
## closing before it actually does.
## 
## To prevent crashes, this will do nothing in web builds.
## 
## [b]Note:[/b] this will do nothing when the [MainLoop] is not a [SceneTree].
static func quit_gracefully(exit_code: int = 0) -> void:
	if OS.has_feature("web"):
		push_warning("Quit called from a web build; ignoring")
		return
	
	var tree: SceneTree = get_tree()
	if null != tree:
		# Notify nodes of the closure
		tree.root.propagate_notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		
		# Must be deferred or else the game will close immediately without
		# giving time for the notification to be handled.
		tree.quit.call_deferred(exit_code)
	else:
		push_error("Failed to quit; main loop is not a tree")


## Returns a reference to the [SceneTree].
##
## Similar to [method Node.get_tree] but is able to obtain a reference to the
## [SceneTree] from anywhere. Returns [code]null[/code] if the [MainLoop]
## implementation is not a [Scenetree].
## [br][br]
## Users should avoid this function wherever possible and instead use
## [method Node.get_tree] or inject references to the tree as arguments. There
## are [i]very few[/i] good reasons to obtain the tree from outside a [Node] as
## Godot intends. Doing so is likely a sign you've done something really bad.
static func get_tree() -> SceneTree:
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop is SceneTree:
		return main_loop
	
	push_error("Failed to access SceneTree; main loop is not a tree")
	return null


## Queues a free of all direct children to the given [param node].
static func free_all_children(node: Node) -> void:
	for child in node.get_children(true):
		child.queue_free()


## Connects a callback to the given signal of all descendants.
## 
## Recursively searches [param node]'s children for all those of [param type]
## with a signal named [param signal_name]. The [param callable] will be
## connected to all matching signals using the provided [param flags]. See
## [enum Object.ConnectFlags] for more information on connection flags.
## [br][br]
## [param type] may be left empty to connect all signals matching
## [param signal_name] regardless of node type.
## [br][br]
## This method can be used as an alternative to a signal bus. For example, to
## have a game state node find and connect gameplay signals from descedents it
## didn't directly create (ex nodes created by a level scene file); however, it
## is preferable to connect signals directly if you have a reference to the
## given node.
## [br][br]
## Usage:
## [codeblock]
## class_name Game
## extends Node
## 
## func _ready() -> void:
##     var level: Node = await _load_level()
##     add_child(level, false, Node.INTERNAL_MODE_FRONT)
##     
##     NodeUtils.connect_descendant_signal(self, "Player", "killed", _lose_game, ConnectFlags.CONNECT_ONE_SHOT)
##     NodeUtils.connect_descendant_signal(self, "Goal", "reached", _win_game, ConnectFlags.CONNECT_ONE_SHOT)
##     NodeUtils.connect_descendant_signal(self, "", "treasure_collected", _update_score)
## [/codeblock]
static func connect_descendant_signal(node: Node, type: String,
		signal_name: String, callable: Callable, flags: int = 0) -> int:
	var connections: int = 0
	
	for child in node.find_children("*", type):
		if child.has_signal(signal_name):
			child.connect(signal_name, callable, flags)
			connections += 1
	
	return connections


## Focuses the first focussable [Control] under [param node].
## 
## Recursively searches [param node]'s children for the first [Control],
## internal or otherwise, that can be focussed and makes it the focus.
## [br][br]
## This function should only be used when focus has been lost unexpectedly and
## needs to be re-obtained for accessibility or the exact node that should have
## focus is not known. When possible, explitly call [method Control.grab_focus]
## on a node for better performance and consistency.
static func focus_first_available(node: Node) -> bool:
	for child in node.get_children(true):
		if child is Control:
			if Control.FocusMode.FOCUS_ALL == child.get_focus_mode_with_override():
				child.grab_focus()
				return true
		
		if focus_first_available(child):
			return true
	
	return false
