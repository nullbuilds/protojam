class_name DamageMutator
extends Resource
## Modifies a [Damage] object in some way.
## 
## Useful for implementing damage bonuses, resistances, etc.
## 
## [b]Note:[/b] This base implementation passes damage through unmodified.

## Returns a mutated copy of [param damage].
## 
## [code]null[/code] may be returned to indicate the damage should be
## completely ignored. Conversely, when [code]null[/code] is passed as an
## argument, the mutator may choose to generate and return non-null damage.
func mutate(damage: Damage) -> Damage:
	return damage.duplicate() if null != damage else null
