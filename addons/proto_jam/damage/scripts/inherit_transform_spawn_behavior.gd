class_name InheritTransformSpawnBehavior
extends AbstractSpawnBehavior
## Spawn behavior causing the spawned node to inherit some, or all, of its
## owner's transform.
## 
## Works with both 2D and 3D nodes.

## Whether to spawn the node with a top-level transform or not.
@export var top_level: bool = true

## The translation axes to inherit from the owner when spawned.
@export_flags("X", "Y", "Z") var inherited_translation_axes: int = 7

## The rotation axes to inherit from the owner when spawned.
@export_flags("X", "Y", "Z") var inherited_rotation_axes: int = 7

func apply(spawned_node: Node, owner: Node) -> void:
	if spawned_node is Node3D:
		_prepare_3d_node(spawned_node, owner)
	elif spawned_node is Node2D:
		_prepare_2d_node(spawned_node, owner)


## Prepares a 3D-based node.
## 
## users should not call this directly. See [method provide] instead.
func _prepare_3d_node(spawned_node: Node3D, owner: Node) -> void:
	var spawned_node_position: Vector3 = Vector3.ZERO
	var spawned_node_rotation: Vector3 = Vector3.ZERO
	
	if owner is Node3D:
		var owner_position: Vector3 = Vector3.ZERO
		var owner_rotation: Vector3 = Vector3.ZERO
		
		if top_level:
			owner_position = owner.global_position
			owner_rotation = owner.global_rotation
		else:
			owner_position = owner.position
			owner_rotation = owner.rotation
		
		var translation_mask: Vector3 = _get_vector3_mask(inherited_translation_axes)
		spawned_node_position = owner_position * translation_mask
		
		var rotation_mask: Vector3 = _get_vector3_mask(inherited_rotation_axes)
		spawned_node_rotation = owner_rotation * rotation_mask
	else:
		push_warning("Unable to inherit transform for 3D node; owner is not 3D")
	
	spawned_node.top_level = top_level
	spawned_node.position = spawned_node_position
	spawned_node.rotation = spawned_node_rotation


## Prepares a 2D-based node.
## 
## users should not call this directly. See [method provide] instead.
func _prepare_2d_node(spawned_node: Node2D, owner: Node) -> void:
	var spawned_node_position: Vector2 = Vector2.ZERO
	var spawned_node_rotation: float = 0.0
	
	if owner is Node2D:
		var owner_position: Vector2 = Vector2.ZERO
		var owner_rotation: float = 0.0
		
		if top_level:
			owner_position = owner.global_position
			owner_rotation = owner.global_rotation
		else:
			owner_position = owner.position
			owner_rotation = owner.rotation
		
		var translation_mask: Vector2 = _get_vector2_mask(inherited_translation_axes)
		spawned_node_position = owner_position * translation_mask
		
		var rotation_mask: float = _get_axis_flag(inherited_rotation_axes, 2)
		spawned_node_rotation = owner_rotation * rotation_mask
	else:
		push_warning("Unable to inherit transform for 2D node; owner is not 2D")
	
	spawned_node.top_level = top_level
	spawned_node.position = spawned_node_position
	spawned_node.rotation = spawned_node_rotation


## Returns a vector whose axes are 1 or 0 depending on the given bitfield.
## 
## Users should not call this directly.
static func _get_vector2_mask(inherited_axes: int) -> Vector2:
	var inherit_x: bool = _get_axis_flag(inherited_axes, 0)
	var inherit_y: bool = _get_axis_flag(inherited_axes, 1)
	return Vector2(inherit_x, inherit_y)


## Returns a vector whose axes are 1 or 0 depending on the given bitfield.
## 
## Users should not call this directly.
static func _get_vector3_mask(inherited_axes: int) -> Vector3:
	var inherit_x: bool = _get_axis_flag(inherited_axes, 0)
	var inherit_y: bool = _get_axis_flag(inherited_axes, 1)
	var inherit_z: bool = _get_axis_flag(inherited_axes, 2)
	return Vector3(inherit_x, inherit_y, inherit_z)


## Returns whether the given axis flag is set.
## 
## Users should not call this directly.
static func _get_axis_flag(inherited_axes: int, axis_index: int) -> bool:
	return (inherited_axes >> axis_index) & 0x1
