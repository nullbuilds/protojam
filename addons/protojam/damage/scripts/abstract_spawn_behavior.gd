@abstract
class_name AbstractSpawnBehavior
extends Resource
## Performs an arbitrary operation on a spawned node before it is added to the
## tree.

## Applies the behavior to the given [param spawned_node].
## 
## The [param owner] is the node for which the spawned node is being created but
## is not necessarily its parent. For example, a death effect may be spawned for
## an owner but added to the tree as a sibling of the owner.
@abstract
func apply(spawned_node: Node, owner: Node) -> void
