class_name CreditSectionEntry
extends CreditGroupEntry
## Represents a named section within a game's credits (ex Composers).

## The name of the section.
@export var name: String = ""

## The entries within this section.
@export var entries: Array[CreditEntry] = []

func get_entries() -> Array[CreditEntry]:
	return entries
