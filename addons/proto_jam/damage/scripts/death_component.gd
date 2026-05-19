class_name DeathComponent
extends Node
## Removes its owner on death and optionally spawns a death effect.
## 
## If provided, the effect will be added to the parent of this node's owner.

## Emitted before spawning the death effect.
## 
## Will not be called if this node's owner is invalid.
signal dying()

## Emitted after the death effect is spawned and before this node's owner is
## freed.
## 
## Will not be called if this node's owner is invalid.
signal died()

## The health component to monitor.
@export var health_component: HealthComponent = null:
	set(value):
		if is_instance_valid(health_component):
			if health_component.killed.is_connected(_die):
				health_component.killed.disconnect(_die)
		
		health_component = value
		
		if is_instance_valid(health_component):
			if not health_component.killed.is_connected(_die):
				health_component.killed.connect(_die.unbind(2), CONNECT_ONE_SHOT)
		
		if Engine.is_editor_hint():
			update_configuration_warnings()
			if not is_instance_valid(health_component):
				var reset_health_node: Callable = func() -> void:
					health_component = null
					update_configuration_warnings()
				
				if not health_component.tree_exited.is_connected(reset_health_node):
					health_component.tree_exited.connect(reset_health_node)


## Whether to free this node's owner on death.
@export var free_owner: bool = true

## An optional provider for an effect to be spawned on death.
@export var death_effect_provider: AbstractDeathEffectProvider = null

## Behaviors to apply to the spawned death effect.
@export var effect_spawn_behaviors: Array[AbstractSpawnBehavior] = []

## Destroys this node's owner and spawns the death effect.
## 
## Users should not call this directly.
func _die() -> void:
	if is_instance_valid(owner):
		dying.emit()
		await _spawn_death_effect()
		
		died.emit()
		if free_owner:
			owner.queue_free()


## Spawns the death effect, if provided.
## 
## Users should not call this directly.
func _spawn_death_effect() -> void:
	if not is_instance_valid(death_effect_provider):
		return
	
	var owner_parent: Node = owner.get_parent()
	if is_instance_valid(owner_parent) and owner_parent.is_inside_tree():
		# Users may define their providers as coroutins so await is required
		@warning_ignore("redundant_await")
		var effect: Node = await death_effect_provider.provide(owner)
		if is_instance_valid(effect):
			for behavior in effect_spawn_behaviors:
				behavior.apply(effect, owner)
			owner_parent.add_child(effect)
