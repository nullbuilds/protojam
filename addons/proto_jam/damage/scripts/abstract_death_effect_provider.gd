@abstract
class_name AbstractDeathEffectProvider
extends Resource
## Provides a death effect for use with a [DeathComponent].

## Provides a death effect.
## 
## Must be called with the node that the death effect is being created for.
## [br][br]
## Users should implemnt this method to return a death effect.
@abstract
func provide(owner: Node) -> Node
