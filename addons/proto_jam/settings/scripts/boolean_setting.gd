class_name BooleanSetting
extends AbstractSetting
## A setting whose value is either [code]true[/code] or [code]false[/code].

## The default value of the setting.
@export var default_value: bool = false:
	set(value):
		if value == default_value:
			return
		
		var old_value: bool = get_value()
		default_value = value
		emit_changed()
		var new_value: bool = get_value()
		
		if old_value != new_value:
			emit_value_changed()


func from_raw(value: Variant) -> Variant:
	return _convert(value)


func to_raw(value: Variant) -> Variant:
	return _convert(value)


## Converts a raw or parsed setting into a boolean.
## 
## Converts the given [param value] into a boolean snapped to [member step_value]
## within [member min_value] and [member max_value] or returns
## [member default_value] when the given value is [code]null[/code] or of a
## different type.
func _convert(value: Variant) -> bool:
	var return_value: bool = default_value
	if _is_valid_boolean(value):
		return_value = value
	
	return return_value


## Checks if the given raw value is a valid boolean.
func _is_valid_boolean(value: Variant) -> bool:
	return value != null and typeof(value) == TYPE_BOOL
