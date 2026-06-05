class_name FloatSaveData
extends AbstractSaveData
## Save data containing a single floating point number.

## The default value.
@export var default_value: float = 0.0:
	set(value):
		if value == default_value:
			return
		
		var old_value: float = get_value()
		default_value = value
		emit_changed()
		var new_value: float = get_value()
		
		if old_value != new_value:
			emit_value_changed()


func from_raw(value: Variant) -> Variant:
	return _convert(value)


func to_raw(value: Variant) -> Variant:
	return _convert(value)


## Converts a raw or parsed setting into a float.
## 
## Converts the given [param value] into a float or returns
## [member default_value] when the given value is [code]null[/code] or of a
## different type.
func _convert(value: Variant) -> float:
	var return_value: float = default_value
	if _is_valid_float(value):
		return_value = value
	
	return return_value


## Checks if the given raw value is a valid float.
func _is_valid_float(value: Variant) -> bool:
	return value != null and typeof(value) == TYPE_FLOAT
