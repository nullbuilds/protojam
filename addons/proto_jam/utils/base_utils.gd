@abstract
class_name BaseUtils
extends Node
## Utilities for common base operations.
## 
## This class provides static functions for commonly performed operations on
## base data types like dictionaries and arrays.

## Returns or creates the value for the given key.
## 
## Similar to [method Dictionary.get_or_add] but defers the creation of the
## default value to a no-args [param callable]. The callback will not be invoked
## if a value already exists.
## [br][br]
## Prefer this function when the default value is expensive to create or
## requires additional registration.
static func get_or_create(dictionary: Dictionary, key: Variant,
		callable: Callable) -> Variant:
	if not dictionary.has(key):
		var value: Variant = callable.call()
		dictionary.set(key, value)
	
	return dictionary.get(key)


## Returns a copy of dictionary with only the filtered entries.
## 
## Similar to [method Array.filter]. The [param filter] receives the key and
## value for one entry as arguments and should return [code]true[/code] to
## retain the entry in the filtered dictionary or [code]false[/code] to
## exclude it.
## [br][br]
## Usage:
## [codeblock]
## var items: Dictionary[StringName, int] = {
##     &"egg": 2,
##     &"bullet": 20,
##     &"herb": 0,
##     &"key": -1,
## }
## 
## # Remove items matching a key
## var egg_filter: Callable = func(key: Variant, _value: Variant) -> bool:
##     return &"egg" != key
## 
## # Prints { "bullet": 20, "herb": 0, "key": -1 }
## print(filterd(items, egg_filter))
## 
## # Remove items based on value
## var empty_filter: Callable = func(_key: Variant, value: Variant) -> bool:
##     return value > 0
## 
## # Prints { "egg": 2, "bullet": 20 }
## print(filterd(items, empty_filter))
## [/codeblock]
static func filterd(dictionary: Dictionary, filter: Callable) -> Dictionary:
	var new_dictionary: Dictionary = {}
	for key in dictionary.keys():
		var value: Variant = dictionary.get(key)
		if filter.call(key, value):
			new_dictionary.set(key, value)
	
	return new_dictionary


## Removes all elements from [param a] that are also in [param b].
static func remove_all(a: Array, b: Array) -> void:
	# TODO use a more performant implementation
	for element in b:
		a.erase(element)
