@tool
class_name HurtBox3D
extends Node3D
## An area in 3D space which deals damage on contact.
## 
## This node requires at least one [DamageBox3D] child to function. Once added
## as a child, users should no longer access the damage box directly as the hurt
## box takes ownership of it.

## Emitted when damage is dealt to an object.
## 
## The [param damage] contains the damage sent but not necessarily received.
signal damage_dealt(damage: Damage)

## Emitted when a damaged object reports how much damage it received.
## 
## The [param damage] contains the actual damage received by the damageable
## area. This is emitted after [signal damage_dealt].
signal damage_reported(damage: Damage)

## The collision masks to monitor for damageable objects on.
## 
## Damage can only be given when the damage recipient exists on a layer being
## scanned by this mask; however, this is only intended to be used to avoid
## conflicts with non-damage physics objectrs and should not be used for damage
## filtering.
## [br][br]
## [b]Note:[/b]Users are [i]strongly[/i] encouraged to dedicate a physics layer
## exclusively to damage nodes like this to avoid interfering with other
## physics operations.
@export_flags_3d_physics var collision_mask: int = 2 ** 31:
	set(value):
		collision_mask = value
		
		if not is_node_ready():
			await ready
		
		_update_collision_mask()

## The generator to produce damage on contact with a damageable area.
@export var damage_generator: DamageGenerator = null:
	set(value):
		damage_generator = value
		update_configuration_warnings()

## An optional parent to be damaged when this node deals damaged.
## 
## This is usefule for one-shot objects which also destroy themselves on contact
## (ex projectiles, exploding enemies, etc)
## [br][br]
## A valid parent must implement its own [method apply_damage] function.
@export var damage_parent: Node = null:
	set(value):
		damage_parent = value
		update_configuration_warnings()

## Optional mutator for parent damage.
## 
## Mutation is applied tp the received damage before being passed to the
## [member damage_parent].
@export var parent_mutator: DamageMutator = null

var _damage_boxes: Array[DamageBox3D] = []

func _ready() -> void:
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if null == damage_generator:
		warnings.push_back("A damage generator must be provided for HurtBox3D to function. Please create a DamageGenerator resource for it.")
	
	if find_children("*", "DamageBox3D", false).is_empty():
		warnings.push_back("This node has no area, so it cannot deal damage to physical sources.\nConsider adding a DamageBox3D as a child to define its area.")
	
	if null != damage_parent:
		if self.is_ancestor_of(damage_parent):
			warnings.push_back("The HurtBox3D must not be an ancestor of damage_parent for it to receive damage. Please select a different node.")
		
		if not (damage_parent.has_method(&"apply_damage") \
				and damage_parent.get_method_argument_count(&"apply_damage") == 1):
			warnings.push_back("The damage_parent node must implement 'apply_damage(damage: Damage) -> Damage' for it to receive damage. Please select a different node.")
	
	return warnings


func _deal_damage(damage_box: DamageBox3D) -> void:
	if null == damage_generator:
		return
	
	var damage: Damage = damage_generator.generate()
	var applied_damage: Damage = damage_box.apply_damage(damage)
	damage_dealt.emit(damage.duplicate())
	
	if null != applied_damage:
		damage_reported.emit(applied_damage.duplicate())
		
		if null != parent_mutator:
			applied_damage = parent_mutator.mutate(applied_damage)
		
		if is_instance_valid(damage_parent) and damage_parent.has_method(&"apply_damage"):
			applied_damage = damage_parent.call(&"apply_damage", applied_damage)


func _update_collision_mask() -> void:
	for damage_box in _damage_boxes:
		damage_box.collision_mask = collision_mask


func _add_damage_box(damage_box: DamageBox3D) -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		# Don't change the settings while in-editor. It's confusing and doesn't
		# provide value.
		return
	
	damage_box.monitoring = true
	damage_box.monitorable = false
	damage_box.collision_mask = collision_mask
	damage_box.collision_layer = 0
	damage_box.damage_box_entered.connect(_on_damage_box_entered)
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
	
	damage_box.damage_box_entered.disconnect(_on_damage_box_entered)
	_damage_boxes.erase(damage_box)


func _on_child_entered_tree(node: Node) -> void:
	if node is DamageBox3D:
		_add_damage_box(node)


func _on_child_exiting_tree(node: Node) -> void:
	if node is DamageBox3D:
		_remove_damage_box(node)


func _on_damage_box_entered(damage_box: DamageBox3D) -> void:
	_deal_damage(damage_box)
