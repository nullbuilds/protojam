@tool
class_name HealthComponent
extends Node
## Tracks an entities health and vulnerabily state.

## Emitted when the health component has received damage.
## 
## This is only triggered when the damage was successfully filtered by
## [member source_mask] and [member type_mask]. If a [member mutator] has been
## defined, the damage object will contain the result of the mutation;
## otherwise, it will be the raw damage received. The [member Damage.amount] may
## exceed the health component's remaining health.
signal damage_taken(remaining_health: float, damage: Damage)

## Emitted to indicate the health has been depleted.
## 
## This signal is emitted after [signal damage_taken] when damage has been
## applied.
signal killed(damage: Damage)

@export_group("Health")
## The maximum allowed health.
@export var max_health: float = 1.0

## The initial health.
## 
## This value will be limited by [member max_health].
@export var initial_health: float = 1.0

## Forces all health calculations to be rounded up to the nearest integer.
## 
## A damage amount of [code]0.1[/code] would be rounded to [code]1.0[/code].
@export var use_integer_health: bool = false

@export_group("Damage")
## The damage source layers this health component can be damaged by.
## 
## [b]Note:[/b] Damage will not be received unless it orignated from a
## [member Damage.source_layer] this mask checks.
## [br][br]
## [b]Note:[/b] These are not related to avoidance flags in any way. Limitations
## in Godot's export system require layers to be one of the hardcoded types and
## avoidance flags were chosen as they are the least likely to be used.
@export_flags_avoidance var source_mask: int = 1

## The damage type layers this health component can be damaged by.
## 
## [b]Note:[/b] Damage will not be received unless it orignated from a
## [member Damage.type_layer] this mask checks.
## [br][br]
## [b]Note:[/b] These are not related to avoidance flags in any way. Limitations
## in Godot's export system require layers to be one of the hardcoded types and
## avoidance flags were chosen as they are the least likely to be used.
@export_flags_avoidance var type_mask: int = 1

## Optional mutator for incoming damage.
## 
## Mutation is applied after the damage has been filtered against
## [member source_mask] and [member type_mask] but before [signal damage_taken]
## is emitted or damage is passed to [member damage_parent].
@export var mutator: DamageMutator = null

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

@export_group("Invincibility")
## Ignores all incoming damage when set.
@export var invulnerable: bool = false

## Sets whether the health component has invincibility frames.
@export var i_frames_enabled: bool = false:
	set(value):
		i_frames_enabled = value
		notify_property_list_changed()

## How long the component will not take damage after taking a hit.
## 
## Used only when [member i_frames_enabled] is [code]true[/code].
@export var i_frame_duration: float = 0.25

var _health: float = 0.0
var _has_temporary_invincibility: bool = false
var _dead: bool = false
var _i_frame_timer: SceneTreeTimer = null

func _ready() -> void:
	var health: float = min(initial_health, max_health)
	
	if use_integer_health:
		health = ceilf(health)
	
	_health = health


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if null != damage_parent:
		if self.is_ancestor_of(damage_parent):
			warnings.push_back("The HealthComponent must not be an ancestor of damage_parent for it to receive damage. Please select a different node.")
		
		if not (damage_parent.has_method(&"apply_damage") \
				and damage_parent.get_method_argument_count(&"apply_damage") == 1):
			warnings.push_back("The damage_parent node must implement 'apply_damage(damage: Damage) -> Damage' for it to receive damage. Please select a different node.")
	
	return warnings


func _validate_property(property: Dictionary) -> void:
	if property.name == "i_frame_duration" and not i_frames_enabled:
		property.usage |= PROPERTY_USAGE_READ_ONLY | PROPERTY_USAGE_NO_EDITOR
		property.usage &= ~PROPERTY_USAGE_EDITOR


## Applies damage.
## 
## Damage will only be applied when the [Damage.source_layer] and
## [Damage.type_layer] are checked by this node's [member source_mask] and
## [member type_mask]. The return value will contain the damage actually
## deducted from its health or the damage applied to [member damage_parent] if
## defined. A [code]null[/code] will be returned if no damage was taken.
func apply_damage(damage: Damage) -> Damage:
	if not _can_receive_damage_from(damage, false):
		return null
	
	var applied_damage: Damage = damage.duplicate()
	if null != mutator:
		applied_damage = mutator.mutate(damage)
	
	return _subtract_health(applied_damage, false)


## Instantly kills the component even when invulnerable.
## 
## This works is as-if damage equal to the current health is applied. Signals
## and the [member damage_parent] are notified as normal; however, the
## [member mutator] is not invoked.
func kill() -> void:
	var damage: Damage = Damage.new()
	damage.amount = _health
	damage.source_layer = source_mask
	damage.type_layer = type_mask
	damage.lethal = true
	
	_subtract_health(damage, true)


## Returns if [param damage] can be applied.
## 
## Checks both the validity and applicability of the damage and also this
## component's internal state.
func _can_receive_damage_from(damage: Damage,
		ignore_invincibility: bool) -> bool:
	# Ignore if the damage is null, invalid, or not from a vulnerable layer
	return _can_receive_damage(ignore_invincibility) \
			and null != damage \
			and damage.is_valid() \
			and damage.is_received_by(source_mask, type_mask)


## Returns if this component can currently accept damage.
func _can_receive_damage(ignore_invincibility: bool) -> bool:
	return not _dead \
			and (ignore_invincibility or not (invulnerable or _has_temporary_invincibility))


## Subtracts [param damage] from health.
## 
## Does not invoke the mutator.
func _subtract_health(damage: Damage, ignore_invincibility: bool) -> Damage:
	if not _can_receive_damage_from(damage, ignore_invincibility):
		return null
	
	var applied_damage: Damage = damage.duplicate()
	
	# Update damage amount to health if lethal
	if damage.lethal:
		damage.amount = _health
	
	if use_integer_health:
		applied_damage.amount = ceilf(applied_damage.amount)
	
	# Clamp damage to how much we can actually receive
	applied_damage.amount = min(applied_damage.amount, _health)
	
	# Clamp subtraction to prevent possible floating point errors.
	_health = max(_health - applied_damage.amount, 0.0)
	
	if use_integer_health:
		_health = floor(_health)
	
	damage_taken.emit(_health, applied_damage)
	
	if _health <= 0:
		_dead = true
		killed.emit(damage)
	else:
		if i_frames_enabled:
			_start_temporary_invincibility()
	
	if is_instance_valid(damage_parent) and damage_parent.has_method(&"apply_damage"):
		applied_damage = damage_parent.call(&"apply_damage", applied_damage)
	
	return damage


## Starts the invincibility frames.
## 
## Will not start if already running.
func _start_temporary_invincibility() -> void:
	if i_frames_enabled and null == _i_frame_timer:
		_has_temporary_invincibility = true
		_i_frame_timer = get_tree().create_timer(i_frame_duration, false)
		_i_frame_timer.timeout.connect(
			func():
				_has_temporary_invincibility = false
				_i_frame_timer = null
		)
