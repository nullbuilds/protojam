@abstract
class_name RandomUtils
extends RefCounted
## Static utilities for random number generation and related activities.

## Similar to [method Array.pick_random] but uses a custom
## [RandomNumberGenerator].
## 
## Note that [param rng]'s state will be updated even if it is unnecessary to do
## so like when [param array] is empty or has a single element.
static func pick_random(rng: RandomNumberGenerator, array: Array) -> Variant:
	var random: int = rng.randi()
	var size: int = array.size()
	
	if size <= 0:
		# TODO return an appropriate value if the array is typed
		return null
	elif 1 == size:
		return array.front()
	
	var index: int = posmod(random, array.size())
	return array[index]
