class_name Damage
extends RefCounted
## Encapsulates some unit of damage being dealt.

## Damage source flags specifying no source.
const SOURCE_FLAG_NONE: int = 0

## Damage source flags specifying all sources.
const SOURCE_FLAG_ALL: int = -1

## Damage type flags specifying no type.
const TYPE_FLAG_NONE: int = 0

## Damage type flags specifying all types.
const TYPE_FLAG_ALL: int = -1

## The source layers this [Damage] [b]originated from[/b].
## 
## Damage can be dealt from one or more of 32 different layers. This is useful
## for expressing protections against friendly fire.
## [br][br]
## [b]Note: [/b] An entity can only receive damage from a source it scans as
## defined by its [code]source_mask[/code]. See also [member type_layer].
var source_layer: int = 1

## The type layers this [Damage] [b]is[/b].
## 
## Damage can be categorized by one or more of 32 different layers. This is
## useful for expressing elemental damage and resistances like fire or water.
## [br][br]
## [b]Note: [/b] An entity can only receive damage from a type it is susceptible
## to as defined by its [code]type_mask[/code]. See also [member source_layer].
var type_layer: int = 1

## The amount of raw damage being dealt.
## 
## [b]Note: [/b] Damage is always expressed as a real positive number. Negative
## damage values and [code]INF[code] are invalid and should be ignored by
## recipients.
var amount: float = 1.0

## Indicates this damage is lethal.
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


## Returns if the damage can be received by an entity with the given maskes.
func is_received_by(source_mask: int, type_mask: int) -> bool:
	return 0 != source_layer & source_mask and 0 != type_layer & type_mask


## Returns if the damage amount is valid.
## 
## Invalid damage should be ignored by recipients as if it never happened.
func is_valid() -> bool:
	return amount >= 0.0


## Returns a copy of this damage.
func duplicate() -> Damage:
	var copy: Damage = Damage.new()
	copy.source_layer = source_layer
	copy.type_layer = type_layer
	copy.amount = amount
	copy.lethal = lethal
	return copy
