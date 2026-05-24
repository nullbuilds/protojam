class_name ObservableDictionary
extends RefCounted
## A dictionary which invokes callbacks when its contents change.
## 
## [b]Note:[/b] Unlike [Dictionary], instances of this class do not
## automatically serialize. To obtain a serializable copy, use
## [method duplicate].

var _data: Dictionary = {}
var _key_added: Callable = Callable()
var _key_removed: Callable = Callable()
var _value_changed: Callable = Callable()

## Constructs a new monitored dictionary.
## 
## The [param key_added] and [param key_removed] callbacks must take the key and
## value as arguments and return no value. The [param value_changed] callback
## must take the key, new value, and old value as arguments and return no value.
func _init(
		key_added: Callable = Callable(),
		key_removed: Callable = Callable(),
		value_changed: Callable = Callable()) -> void:
	_key_added = key_added
	_key_removed = key_removed
	_value_changed = value_changed


## Equivalent to [method Dictionary.keys].
func keys() -> Array:
	return _data.keys()


## Equivalent to [method Dictionary.is_empty].
func is_empty() -> bool:
	return _data.size()


## Equivalent to [method Dictionary.size].
func size() -> int:
	return _data.size()


## Equivalent to [method Dictionary.has].
func has(key: Variant) -> bool:
	return _data.has(key)


## Equivalent to [method Dictionary.get].
func get_value(key: Variant, default: Variant = null) -> Variant:
	return _data.get(key, default)


## Equivalent to [method Dictionary.get_or_add].
func get_or_add(key: Variant, default: Variant = null) -> Variant:
	if _data.has(key):
		return _data.get(key)
	
	_data.set(key, default)
	if _key_added.is_valid():
		_key_added.call(key, default)
	
	return default


## Equivalent to [method Dictionary.set].
func set_value(key: Variant, value: Variant) -> void:
	var had_key: bool = _data.has(key)
	var old_value: Variant = _data.get(key)
	
	_data.set(key, value)
	
	if had_key:
		if value != old_value and _value_changed.is_valid():
			_value_changed.call(key, value, old_value)
	elif _key_added.is_valid():
		_key_added.call(key, value)


## Equivalent to [method Dictionary.erase].
func erase(key: Variant) -> bool:
	var old_value: Variant = _data.get(key)
	var removed: bool = _data.erase(key)
	
	if removed and _key_removed.is_valid():
		_key_removed.call(key, old_value)
	
	return removed


## Equivalent to [method Dictionary.assign].
func assign(dictionary: Dictionary) -> void:
	var old_data: Dictionary = _data.duplicate()
	_data.assign(dictionary)
	_report_changes(_data, old_data)


## Equivalent to [method Dictionary.duplicate].
func duplicate(deep: bool = false) -> Dictionary:
	return _data.duplicate(deep)


## Compares the two dictionaries and invokes the callbacks for any changes.
## 
## Users should not call this directly.
func _report_changes(new_data: Dictionary, old_data: Dictionary) -> void:
	# TODO write key union more efficiently
	var combined_keys: Array = new_data.merged(old_data).keys()
	
	for key in combined_keys:
		var old_value: Variant = old_data.get(key)
		var new_value: Variant = new_data.get(key)
		
		# Explicitly check if old_data and new_data have the key before
		# comparing. Comparing without checking could return true if the new or
		# old value happens to be the default and the other does not contain the
		# key.
		if old_data.has(key):
			if new_data.has(key):
				if old_value != new_value and _value_changed.is_valid():
					_value_changed.call(key, new_value, old_value)
			elif _key_removed.is_valid():
				_key_removed.call(key, old_value)
		elif _key_added.is_valid():
			_key_added.call(key, new_value)
