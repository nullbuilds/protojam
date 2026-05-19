class_name PackedSceneDeathEffectProvider
extends AbstractDeathEffectProvider
## Spawns a packed scene on death.

## The scene to spawn.
@export var scene: PackedScene = null

func provide(_owner: Node) -> Node:
	var effect: Node = null
	if is_instance_valid(scene):
		# A PackedScene is used rather than async loading to avoid spawn delays
		# when a node dies. Delaying the effect spawn for async loading could
		# have undesirable consequences for gameplay.
		effect = scene.instantiate()
	else:
		push_warning("Unable to provide death effect; scene is not valid")
	
	return effect
