@tool
class_name HitBox3D
extends Node3D
## Represents a damageable area in 3D space.
## 
## This node requires at least one [DamageBox3D] child to function. Once added
## as a child, users should no longer access the damage box directly as the hit
## box takes ownership of it.

## Emitted when the hit box has received damage.
## 
## This is only triggered when the damage was successfully filtered by
## [member source_mask] and [member type_mask]. If a [member mutator] has been
## defined, the damage object will contain the result of the mutation;
## otherwise, it will be the raw damage received.
## 
## This signal is emitted [i]before[/i] damage is passed up to
## [member damage_parent].
signal damage_taken(damage: Damage)

## The collision layers to expose this hit box to.
## 
## Damage can only be registered on layers which the damage source scans with
## its [code]collision_mask[/code]; however, this is only intended to be used to
## avoid conflicts with non-damage physics objectrs and should not be used for
## damage filtering. Use [member source_mask] and [member type_mask] for
## filtering.
## [br][br]
## [b]Note:[/b]Users are [i]strongly[/i] encouraged to dedicate a physics layer
## exclusively to damageable nodes like this to avoid interfering with other
## physics operations.
@export_flags_3d_physics var collision_layer: int = 2 ** 31:
	set(value):
		collision_layer = value
		
		if not is_node_ready():
			await ready
		
		_update_collision_layer()


## The damage source layers this hit box [b]checks[/b].
## 
## [b]Note:[/b] Damage will not be received unless it orignated from a
## [member Damage.source_layer] this mask checks.
## [br][br]
## [b]Note:[/b] These are not related to avoidance flags in any way. Limitations
## in Godot's export system require layers to be one of the hardcoded types and
## avoidance flags were chosen as they are the least likely to be used.
@export_flags_avoidance var source_mask: int = Damage.SOURCE_FLAG_ALL

## The damage type layers this hit box [b]checks[/b].
## 
## [b]Note:[/b] Damage will not be received unless it orignated from a
## [member Damage.type_layer] this mask checks.
## [br][br]
## [b]Note:[/b] These are not related to avoidance flags in any way. Limitations
## in Godot's export system require layers to be one of the hardcoded types and
## avoidance flags were chosen as they are the least likely to be used.
@export_flags_avoidance var type_mask: int = Damage.TYPE_FLAG_ALL

## An optional parent to be notified of incoming damage.
## 
## A valid parent must implement its own [method apply_damage] function with an
## identical signature. When damage is applied to a hit box, it will first apply
## the [member mutator] (if defined) and emit [signal damage_taken]. It will
## then pass the resulting damage to the parent's damage function.
@export var damage_parent: Node = null:
	set(value):
		damage_parent = value
		update_configuration_warnings()

## Optional mutator for incoming damage.
## 
## Mutation is applied after the damage has been filtered against
## [member source_mask] and [member type_mask] but before [signal damage_taken]
## is emitted or damage is passed to [member damage_parent].
@export var mutator: DamageMutator = null

var _damage_boxes: Array[DamageBox3D] = []

func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if find_children("*", "DamageBox3D", false).is_empty():
		warnings.push_back("This node has no area, so it cannot accept damage from physical sources.\nConsider adding a DamageBox3D as a child to define its area.")
	
	if null != damage_parent:
		if self.is_ancestor_of(damage_parent):
			warnings.push_back("The HitBox3D must not be an ancestor of damage_parent for it to receive damage. Please select a different node.")
		
		if not (damage_parent.has_method(&"apply_damage") \
				and damage_parent.get_method_argument_count(&"apply_damage") == 1):
			warnings.push_back("The damage_parent node must implement 'apply_damage(damage: Damage) -> Damage' for it to receive damage. Please select a different node.")
	
	return warnings

## Applies damage to the hit box.
## 
## Damage will only be applied when the [Damage.source_layer] and
## [Damage.type_layer] are checked by the box's [member source_mask] and
## [member type_mask]. The return value will contain the damage actually
## received by its [member damage_parent] (if defined) or just the damage received by
## this hit box. A [code]null[/code] will be returned if no damage was taken.
func apply_damage(damage: Damage) -> Damage:
	if damage.is_received_by(source_mask, type_mask):
		var applied_damage: Damage = damage.duplicate()
		
		if null != mutator:
			applied_damage = mutator.mutate(damage)
			
		if null != applied_damage:
			damage_taken.emit(applied_damage)
			
			if is_instance_valid(damage_parent) and damage_parent.has_method(&"apply_damage"):
				applied_damage = damage_parent.call(&"apply_damage", applied_damage)
			
			return applied_damage
	
	return null


func _update_collision_layer() -> void:
	for damage_box in _damage_boxes:
		damage_box.collision_layer = collision_layer


func _add_damage_box(damage_box: DamageBox3D) -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		# Don't change the settings while in-editor. It's confusing and doesn't
		# provide value.
		return
	
	damage_box.set_damage_handler(apply_damage)
	damage_box.monitoring = false
	damage_box.monitorable = true
	damage_box.collision_mask = 0
	damage_box.collision_layer = collision_layer
	# TODO how can I detect if any of these properties change so they can be
	# changed back?
	_damage_boxes.push_back(damage_box)


func _remove_damage_box(damage_box: DamageBox3D) -> void:
	if not _damage_boxes.has(damage_box):
		# If we had no record of this box, it's not ours to interact with
		return
	
	if Engine.is_editor_hint():
		# Don't change the settings while in-editor. It's confusing and doesn't
		# provide value.
		update_configuration_warnings()
		return
	
	damage_box.set_damage_handler(Callable())
	
	# TODO disconnect any signals
	_damage_boxes.erase(damage_box)


func _on_child_entered_tree(node: Node) -> void:
	if node is DamageBox3D:
		_add_damage_box(node)


func _on_child_exiting_tree(node: Node) -> void:
	if node is DamageBox3D:
		_remove_damage_box(node)
