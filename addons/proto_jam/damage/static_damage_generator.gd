class_name StaticDamageGenerator
extends DamageGenerator
## Generates a fixed amount of [Damage].

## The source layers the generated [Damage] [b]originates from[/b].
## 
## Damage can be dealt from one or more of 32 different layers. This is useful
## for expressing protections against friendly fire.
## [br][br]
## [b]Note: [/b] An entity can only receive damage from a source it scans as
## defined by its [code]source_mask[/code]. See also [member type_layer].
@export_flags_avoidance var source_layer: int = 1

## The type layers the generated [Damage] [b]is[/b].
## 
## Damage can be categorized by one or more of 32 different layers. This is
## useful for expressing elemental damage and resistances like fire or water.
## [br][br]
## [b]Note: [/b] An entity can only receive damage from a type it is susceptible
## to as defined by its [code]type_mask[/code]. See also [member source_layer].
@export_flags_avoidance var type_layer: int = 1

## The amount of damage to generate.
## 
## [b]Note: [/b] Damage is always expressed as a real positive number. Negative
## damage values and [code]INF[code] are invalid and should be ignored by
## recipients.
@export_range(0.0, 1.0, 0.1, "or_greater") var amount: float = 1.0

## Makes the generated [Damage] lethal.
## 
## This indicates the reciepient should die regardless of [member amount] (even
## if it is [code]0.0[/code]). This is recommended for kill barriers or scripted
## events which must guarantee the recipient will not survive regardless of
## their health and damage resistance.
## [br][br]
## [b]Note:[/b] An entity will only die from this damage if their
## [code]source_mask[/code] and [code]type_mask[/code] include layers from both
## [member source_layer] and [member type_layer].
var lethal: bool = false

func generate() -> Damage:
	var damage: Damage = Damage.new()
	damage.source_layer = source_layer
	damage.type_layer = type_layer
	damage.amount = amount
	damage.lethal = lethal
	return damage
