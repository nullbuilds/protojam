class_name StringSaveData
extends AbstractSaveData
## Save data containing a single string.

## The default value.
@export var default_value: String = "":
	set(value):
		if value == default_value:
			return
		
		var old_value: String = get_value()
		default_value = value
		emit_changed()
		var new_value: String = get_value()
		
		if old_value != new_value:
			emit_value_changed()


func from_raw(value: Variant) -> Variant:
	return _convert(value)


func to_raw(value: Variant) -> Variant:
	return _convert(value)


## Converts a raw or parsed setting into a string.
## 
## Converts the given [param value] into a string or returns
## [member default_value] when the given value is [code]null[/code] or of a
## different type.
func _convert(value: Variant) -> String:
	var return_value: String = default_value
	if _is_valid_string(value):
		return_value = value
	
	return return_value


## Checks if the given raw value is a valid string.
func _is_valid_string(value: Variant) -> bool:
	return value != null and typeof(value) == TYPE_STRING
