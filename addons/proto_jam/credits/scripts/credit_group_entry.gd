@abstract
class_name CreditGroupEntry
extends CreditEntry
## Represents a credit entry containing sub-entries.

## Returns the entries within this group.
@abstract
func get_entries() -> Array[CreditEntry]


## Allows a visitor to examine this entry and its children.
## 
## The default implementation visits this entry followed by its children
## depth-first.
func accept(visitor: CreditVisitor) -> void:
	visitor.visit(self)
	
	for entry in get_entries():
		entry.accept(visitor)
	
	visitor.exit()
