@abstract
class_name CreditVisitor
extends Node
## A visitor for walking a [CreditEntry] heirarchy.

## Visits a credit entry.
@abstract
func visit(entry: CreditEntry) -> void

## Exits the last nested credit entry.
@abstract
func exit() -> void
