@tool
class_name DamageBox3D
extends Area3D
## Represents an area in 3D space which can either deal or receive damage.
## 
## This node is intended to be used as a child of a [HitBox3D] to give it a
## detection area. Users can also monitor [signal damage_box_entered] to apply
## damage to other damage boxes.

## Emitted when this box overlaps with another damage box.
signal damage_box_entered(damage_box: DamageBox3D)

## Emitted when the area has received damage.
## 
## This signal is emitted [i]before[/i] damage is passed up to the handler set
## by [method set_damage_handler].
signal damage_taken(damage: Damage)

var _damage_handler_callback: Callable = Callable()

func _ready() -> void:
	area_entered.connect(_on_area_entered)


## Sets the handler to be executed when damage is applied to this area.
## 
## The [param callback] must accept a single parameter containing the [Damage]
## being dealt and return the damage that was actually taken (ex after a
## [DamageMutator] has been applied) or null if no damage was taken.
func set_damage_handler(callback: Callable) -> void:
	_damage_handler_callback = callback


## Applies damage to this area.
## 
## [b]Note[/b] Nothing will happen unless a damage handler has been set with
## [method set_damage_handler].
func apply_damage(damage: Damage) -> Damage:
	damage_taken.emit(damage)
	
	if _damage_handler_callback.is_valid():
		return _damage_handler_callback.call(damage)
	
	return null


func _on_area_entered(area: Area3D) -> void:
	if area is DamageBox3D:
		damage_box_entered.emit(area)
