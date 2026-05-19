@tool
class_name SineBob3D
extends Node
## Moves a target node up and down along the Y axis in 3D space.
## 
## The bob is offset by the target's position on the XZ plane so multiple nodes,
## like coins, do not bob in sync.
## [br][br]
## See
## [url=https://youtube.com/shorts/QiB_p85tjak]this short[/url] for an example.

## The speed at which the target bobs.
@export var speed: float = 2.0

## How far the target bobs in each direction.
## 
## An amplitude of [code]1.0[/code] means the target will move by
## [code]+/-1.0[/code] (ie a travel distance of [code]2.0[/code]).
@export var amplitude: float = 0.25

## How much to shift the bob cycle phase by position on the XZ plane.
## 
## A value of [code]PI[/code] means the phase between two target will be
## shifted by 180 degrees for every meter between them (measured using manhattan
## distance).
@export_range(0.0, 360.0, 0.1, "radians_as_degrees") var phase_shift: float = PI / 6.0:
	set(value):
		phase_shift = value


## The [Node3D] to be bobbed.
@export var target: Node3D = null:
	set(value):
		target = value
		
		if Engine.is_editor_hint():
			update_configuration_warnings()
			if null != target:
				var reset_target: Callable = func() -> void:
					target = null
					update_configuration_warnings()
				
				if not target.tree_exited.is_connected(reset_target):
					target.tree_exited.connect(reset_target)


var _time: float = 0.0

func _process(delta: float) -> void:
	# Don't run in editor as this will mangle the stored position within the
	# scene.
	if not Engine.is_editor_hint() and is_instance_valid(target):
		_bob_target(delta)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if not is_instance_valid(target):
		warnings.push_back("A target is required for SineBob3D to have an effect. Please define a target.")
	
	return warnings


## 
func _bob_target(delta: float) -> void:
	var target_position: Vector3 = target.global_position
	var phase_offset: float = (target_position.z + target_position.x) * phase_shift
	
	_time += delta
	var bob_offset: float = sin(_time * speed + phase_offset) * amplitude
	target.position.y = bob_offset
