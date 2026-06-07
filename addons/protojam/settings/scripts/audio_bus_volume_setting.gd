class_name AudioBusVolumeRangeSetting
extends RangeSetting
## A setting defining the linear volume for an audio bus.
## 
## [b]Note:[/b] setting changes are not automatically applied to the bus. See
## [method apply] for more details.

## The name of the audio bus to apply this setting to.
@export var bus_name: StringName = "":
	set(value):
		if value == bus_name:
			return
		
		# The setting value is not affected by this change, do not call
		# emit_value_changed. Only emit_changed for the export variable itself.
		bus_name = value
		emit_changed()


## Returns the index of the bus this setting applies to.
## 
## Convenience function to get the bus index this setting should apply to.
## Returns [code]-1[/code] if no such bus exists.
func get_bus_index() -> int:
	return AudioServer.get_bus_index(bus_name)


## Applies the setting to its audio bus.
## 
## Convenience function to apply the volume setting to its audio bus with an
## optional [param multiplier]. The multiplier can be used to perform fades
## while respecting the user's volume limit or to adjust the gain based on
## speaker/headphone configuration. Negative multipliers are clamped to
## [code]0.0[/code]
## 
## [b]Note:[/b] setting changes are [b]NOT[/b] applied automatically to the bus.
## Users must listen for [signal AbstractSetting.value_changed] and call this
## accordingly. This is done to allow for audio ducking and other volume effects
## which may override the setting.
func apply(multiplier: float = 1.0) -> Error:
	var bus_index: int = get_bus_index()
	if bus_index < 0:
		push_error("Failed to set volume of audio bus \"%s\"; no such bus" % bus_name)
		return Error.ERR_DOES_NOT_EXIST
	
	var linear_volume: float = get_value() * max(multiplier, 0.0)
	AudioServer.set_bus_volume_linear(bus_index, linear_volume)
	return Error.OK
