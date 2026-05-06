class_name RangeSetting
extends AbstractSetting
## A setting whose value is constrained to a discrete set of steps within a
## range.

## The minimum (inclusive) value of the setting.
@export var min_value: float = 0.0:
	set(value):
		if value == min_value:
			return
		
		var old_value: bool = get_value()
		min_value = value
		emit_changed()
		var new_value: bool = get_value()
		
		if old_value != new_value:
			emit_value_changed()


## The maximum (inclusive) value of the setting.
@export var max_value: float = 1.0:
	set(value):
		if value == max_value:
			return
		
		var old_value: bool = get_value()
		max_value = value
		emit_changed()
		var new_value: bool = get_value()
		
		if old_value != new_value:
			emit_value_changed()


## The increment size of the setting.
@export var step_value: float = 0.01:
	set(value):
		if value == step_value:
			return
		
		var old_value: bool = get_value()
		step_value = value
		emit_changed()
		var new_value: bool = get_value()
		
		if old_value != new_value:
			emit_value_changed()


## The default value of the setting.
@export var default_value: float = 0.5:
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


## Converts a raw or parsed setting into a valid float.
## 
## Converts the given [param value] into a float snapped to [member step_value]
## within [member min_value] and [member max_value] or returns
## [member default_value] when the given value is [code]null[/code] or of a
## different type.
func _convert(value: Variant) -> float:
	var parsed_value: float = default_value
	if _is_valid_float(value):
		parsed_value = value
	
	return clampf(snappedf(parsed_value, step_value), min_value, max_value)


## Checks the given value is a valid float.
func _is_valid_float(value: Variant) -> bool:
	return value != null and typeof(value) == TYPE_FLOAT
