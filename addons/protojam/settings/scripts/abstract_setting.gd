@abstract
class_name AbstractSetting
extends Resource
## Abstract interface for defining a game setting.
## 
## Users should extend this class and implement [method from_raw] and
## [method to_raw] to create  custom setting types that will be automatically
## managed by the [SettingsManager].

## Emitted when the value of the setting changes.
signal value_changed(value: Variant)

## The unique key for the setting.
@export var setting_key: StringName = "":
	set(value):
		# Key is unchanged, connections don't require updating, exit fast
		if value == setting_key:
			return
		
		# Disconnect from the old signal, if any
		if not setting_key.is_empty():
			var old_signal: Signal = SettingsManager.create_setting_change_signal(setting_key)
			if old_signal.is_connected(_on_setting_value_changed):
				old_signal.disconnect(_on_setting_value_changed)
		
		# Connect new signal
		var new_signal: Signal = SettingsManager.create_setting_change_signal(value)
		new_signal.connect(_on_setting_value_changed)
		
		var old_value: Variant = get_value()
		setting_key = value
		emit_changed()
		var new_value: Variant = get_value()
		
		if old_value != new_value:
			emit_value_changed()


## Gets the current value of the setting.
## 
## Custom [AbstractSetting] implementations should not typically override this
## function. See [method AbstractSetting.from_raw] instead.
func get_value() -> Variant:
	if not setting_key.is_empty():
		return from_raw(SettingsManager.get_raw_setting(setting_key))
	return from_raw(null)


## Sets the value of the setting.
## 
## Custom [AbstractSetting] implementations should not typically override this
## function. See [method AbstractSetting.to_raw] instead.
func set_value(value: Variant):
	if not setting_key.is_empty():
		SettingsManager.set_raw_setting(setting_key, to_raw(value))


## Parses a raw setting value into the desired type.
## 
## Parses and validates the return value of
## [method SettingsManager.get_raw_setting] to produce what is returned by
## [method get_value].
## [br][br]
## Custom implementations should not make any assumptions of the passed
## [param value]. It may be null, an incompatible type, or otherwise invalid.
## This function [b]MUST[/b] gracefully handle all conditions (not just what
## [method to_raw] produces).
@abstract
func from_raw(value: Variant) -> Variant


## Encodes a setting's value into its raw form.
## 
## Encodes the parameter passed to [method set_value] into a raw value to be
## stored using [method SettingsManager.set_raw_setting].
## [br][br]
## Custom implementations should not make any assumptions of the passed
## [param value]. It may be null, an incompatible type, or otherwise invalid.
## This function [b]MUST[/b] gracefully handle all conditions and produce a
## value consistent with what [method from_raw] expects.
@abstract
func to_raw(value: Variant) -> Variant


## Convenience function for implementors to emit [signal value_changed].
## 
## This function is intended to be called by implementors when an export setting
## affecting the parsing of a raw value changes. If the change would cause
## [method get_value] to return a different result for the same raw setting then
## this should be called to emit the signal.
## 
## [b]Note:[/b] this is not to be confused with [method Resource.emit_changed]
## which should also be called when an exported variable changes. When an export
## variable that affects the setting value has changed,
## [method Resource.emit_changed] should be called first, immediately followed
## by this function.
func emit_value_changed() -> void:
	value_changed.emit(get_value())


## Emits [signal value_changed] when the value has changed.
## 
## Custom [AbstractSetting] implementations should not override this.
func _on_setting_value_changed(value: Variant) -> void:
	value_changed.emit(from_raw(value))
