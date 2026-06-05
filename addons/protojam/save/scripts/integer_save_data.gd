class_name IntegerSaveData
extends AbstractSaveData
## Save data containing a single integer value.

## The default value.
@export var default_value: int = 0:
	set(value):
		if value == default_value:
			return
		
		var old_value: int = get_value()
		default_value = value
		emit_changed()
		var new_value: int = get_value()
		
		if old_value != new_value:
			emit_value_changed()


func from_raw(value: Variant) -> Variant:
	return _convert(value)


func to_raw(value: Variant) -> Variant:
	return _convert(value)


## Converts a raw or parsed setting into an integer.
## 
## Converts the given [param value] into an integer or returns
## [member default_value] when the given value is [code]null[/code] or of a
## different type.
func _convert(value: Variant) -> int:
	var return_value: int = default_value
	
	# JSON only supports "number" types so we must convert whatever we get to an
	# int always.
	if _is_valid_number(value):
		return_value = floori(value)
	
	return return_value


## Checks if the given raw value is a valid number.
func _is_valid_number(value: Variant) -> bool:
	return value != null and typeof(value) in [TYPE_FLOAT, TYPE_INT]
