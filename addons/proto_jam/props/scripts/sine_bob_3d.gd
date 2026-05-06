@tool
class_name SineBob3D
extends Node3D
## Moves its children up and down along the Y axis in 3D space.
## 
## The bob is offset by this node's position in the XZ plane so multiple nodes,
## like coins, do not bob in sync.
## [br][br]
## See
## [url=https://youtube.com/shorts/QiB_p85tjak]this short[/url] for an example.

## The speed at which the node bobs.
@export var speed: float = 2.0

## How far the node bobs in each direction.
## 
## An amplitude of [code]1.0[/code] means the node will move by
## [code]+/-1.0[/code] (ie a travel distance of [code]2.0[/code]).
@export var amplitude: float = 0.25

## How much to shift the bob cycle phase by position on the XZ plane.
## 
## A value of [code]30.0[/code] means the phase between two nodes will be
## shifted by 30 degrees for every meter between them (measured using manhattan
## distance).
@export_range(0.0, 360.0, 0.1, "degrees") var phase_shift: float = 30.0:
	set(value):
		phase_shift = value
		_phase_shift_radians = deg_to_rad(phase_shift)


var _time: float = 0.0
var _phase_shift_radians: float = deg_to_rad(phase_shift)
var _cached_children: Array[Node3D] = []

func _ready() -> void:
	for child in get_children(true):
		_cache_child(child)
	
	child_entered_tree.connect(_cache_child)
	child_exiting_tree.connect(_uncache_child)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		# Don't run in editor as this will mangle the stored position within the
		# scene.
		return
	
	var phase_offset: float = (global_position.z + global_position.x) * _phase_shift_radians
	
	_time += delta
	var bob_offset: float = sin(_time * speed + phase_offset) * amplitude
	
	for child in _cached_children:
		child.position.y = bob_offset


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if _cached_children.is_empty():
		warnings.push_back("At least one Node3D derived child is required for SineBob3D to have an effect. Please add a child node derived from Node3D.")
	
	return warnings


## Caches a Node3D child for bobbing.
## 
## Users should not call this function.
func _cache_child(node: Node) -> void:
	if node is Node3D:
		_cached_children.push_back(node)
		
		if Engine.is_editor_hint():
			update_configuration_warnings()


## Uncaches a Node3D child for bobbing.
## 
## Users should not call this function.
func _uncache_child(node: Node) -> void:
	if node is Node3D:
		_cached_children.erase(node)
		
		if Engine.is_editor_hint():
			update_configuration_warnings()
