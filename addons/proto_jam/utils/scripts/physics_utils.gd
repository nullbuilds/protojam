@abstract
class_name PhysicsUtils
extends RefCounted
## Static utilities related to physics.

## Detects if the body described by the physics state is on the floor.
## 
## Detects if a contact with an upwards normal has ocurred. The contact must be
## within [param max_floor_angle] radians of [constant Vector3.UP]. Prefer
## [method CharacterBody3D.is_on_floor]. Use this only when you need to evaluate
## a [RigidBody3D].
## [br][br]
## Contact monitoring [b]MUST[/b] be enabled on the described body with at least
## one contact for this to work. More contacts is highly recommended to account
## for walls, steps, etc.
## 
## @experimental: This function was used in a game for which floor detection was not working on all devices and the root cause could not be identified. Use with caution.
static func is_on_floor(max_floor_angle: float, state: PhysicsDirectBodyState3D) -> bool:
	for contact_index in state.get_contact_count():
		var contact_normal: Vector3 = state.get_contact_local_normal(contact_index)
		var contact_angle: float = Vector3.UP.angle_to(contact_normal)
		if contact_angle < max_floor_angle:
			return true
	
	return false
