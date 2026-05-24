class_name ObservableDictionary
extends RefCounted
## A dictionary which invokes callbacks when its contents change.

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


## Returns the list of keys in the dictionary.
## 
## [b]Note:[/b] Modifying the returned array does not affect the dictionary.
func keys() -> Array:
	return _data.keys()


## Returns [code]true[/code] if the dictionary is empty (its size is
## [code]0[/code]).
## 
## See also [method size].
func is_empty() -> bool:
	return _data.size()


## Returns the number of entries in the dictionary.
## 
## Empty dictionaries ([code]{ }[/code]) always return [code]0[/code].
## 
## See also [method is_empty].
func size() -> int:
	return _data.size()


## Returns [code]true[/code] if the dictionary contains an entry with the given
## [param key].
## [br][br]
## [b]Note:[/b] This method returns [code]true[/code] as long as the [param key]
## exists, even if its corresponding value is [code]null[/code].
func has(key: Variant) -> bool:
	return _data.has(key)


## Returns the corresponding value for the given [param key] in the dictionary.
## 
## If the [param key] does not exist, returns [param default], or
## [code]null[code] if the parameter is omitted.
func get_value(key: Variant, default: Variant = null) -> Variant:
	return _data.get(key, default)


## Gets a value and ensures the key is set.
## 
## If the [param key] exists in the dictionary, this behaves like [method get].
## Otherwise, the [param default] value is inserted into the dictionary and
## returned.
func get_or_add(key: Variant, default: Variant = null) -> Variant:
	if _data.has(key):
		return _data.get(key)
	
	_data.set(key, default)
	if _key_added.is_valid():
		_key_added.call(key, default)
	
	return default


## Sets the value of the element at the given [param key] to the given
## [param value].
func set_value(key: Variant, value: Variant) -> void:
	var had_key: bool = _data.has(key)
	var old_value: Variant = _data.get(key)
	
	_data.set(key, value)
	
	if had_key:
		if value != old_value and _value_changed.is_valid():
			_value_changed.call(key, value, old_value)
	elif _key_added.is_valid():
		_key_added.call(key, value)


## Removes the dictionary entry by key, if it exists.
## 
## Returns [code]true[/code] if the given [param key] existed in the dictionary,
## otherwise [code]false[/code].
func erase(key: Variant) -> bool:
	var old_value: Variant = _data.get(key)
	var removed: bool = _data.erase(key)
	
	if removed and _key_removed.is_valid():
		_key_removed.call(key, old_value)
	
	return removed


## Overwrites the contents of this dictionary with the provided dictionary.
## 
## This operation performs a copy. Changes to the keys/values of the original
## dictionary will not be reflected here.
func assign(dictionary: Dictionary) -> void:
	var old_data: Dictionary = _data.duplicate()
	_data.assign(dictionary)
	_report_changes(_data, old_data)


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
