@abstract
class_name DamageGenerator
extends Resource
## Generates [Damage] objects.
## 
## Intended for use with [HurtBox3D] and similar damage dealing nodes.

## Generates damage.
## 
## [code]null[/code] may be returned to indicate that no damage should be dealt.
@abstract
func generate() -> Damage
