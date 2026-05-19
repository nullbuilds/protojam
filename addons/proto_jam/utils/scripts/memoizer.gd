class_name Memoizer
extends RefCounted
## Caches and automatically refreshes any type when it becomes invalid.

var _value: Variant = null
var _provider: Callable = Callable()
var _validator: Callable = Callable()

## Constructs a new memoizer.
## 
## The given [param provider] will be called to obtain a new value the first
## time [method get_value] is invoked or on subsequent calls when the cached
## value becomes invalid. The provider must take no arguments and return a value
## to cache.
## [br][br]
## A custom [param validator] may be provided to perform additional checks
## against a cached value. The validator must accept a single parameter of the
## same type returned by [param provider] and return [code]true[/code] if the
## instance is valid. The validator will not be during the same request in which
## a new value is provided as it is assumed providers will only return valid
## instances.
func _init(provider: Callable, validator: Callable = Callable()) -> void:
	_provider = provider
	_validator = validator


## Returns the cached value or obtains a new value if the cached instance is
## invalid.
func get_value() -> Variant:
	if _value is Object and not is_instance_valid(_value):
		_value = await _provider.call()
	elif null == _value:
		_value = await _provider.call()
	elif _validator.is_valid() and not await _validator.call(_value):
		_value = await _provider.call()
	
	return _value
