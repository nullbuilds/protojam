@abstract
class_name CreditEntry
extends Resource
## Represents an arbitrary entry in a game's credits.

## Allows a visitor to examine this entry.
## 
## The default implementation simply visits this entry only.
func accept(visitor: CreditVisitor) -> void:
	visitor.visit(self)
