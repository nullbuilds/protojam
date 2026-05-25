@abstract
class_name AbstractSaveData
extends Resource
## Abstract interface for defining save data.
## 
## Users should extend this class and implement [method from_raw] and
## [method to_raw] to create  custom save data types that will be automatically
## managed by the [SaveDataManager].

## Emitted when the value of the save data changes.
signal value_changed(value: Variant)

## The unique key for saved property.
@export var save_data_key: StringName = &"":
	set(value):
		# Key is unchanged, connections don't require updating, exit fast
		if value == save_data_key:
			return
		
		# Disconnect from the old signal, if any
		if not save_data_key.is_empty():
			var old_signal: Signal = SaveDataManager.create_save_data_change_signal(save_data_key, global)
			if old_signal.is_connected(_on_save_value_changed):
				old_signal.disconnect(_on_save_value_changed)
		
		# Connect new signal
		var new_signal: Signal = SaveDataManager.create_save_data_change_signal(value, global)
		new_signal.connect(_on_save_value_changed)
		
		var old_value: Variant = get_value()
		save_data_key = value
		emit_changed()
		var new_value: Variant = get_value()
		
		if old_value != new_value:
			emit_value_changed()


## Indicates if this data should be saved globally or to a save slot.
@export var global: bool = false:
	set(value):
		global = value
		save_data_key = save_data_key # Force save key to refresh its connections


## Gets the current value of the save data.
## 
## Custom [AbstractSaveData] implementations should not typically override this
## function. See [method from_raw] instead.
func get_value() -> Variant:
	return from_raw(SaveDataManager.get_raw_save_data(save_data_key, global))


## Sets the value of the save data.
## 
## Custom [AbstractSaveData] implementations should not typically override this
## function. See [method to_raw] instead.
func set_value(value: Variant):
	SaveDataManager.set_raw_save_data(save_data_key, global, to_raw(value))


## Parses a raw save data into the desired type.
## 
## Parses and validates the return value of
## [method SaveDataManager.get_raw_data] to produce what is returned by
## [method get_value].
## [br][br]
## Custom implementations should not make any assumptions of the passed
## [param value]. It may be null, an incompatible type, or otherwise invalid.
## This function [b]MUST[/b] gracefully handle all conditions (not just what
## [method to_raw] produces).
@abstract
func from_raw(value: Variant) -> Variant


## Encodes save data's value into its raw form.
## 
## Encodes the parameter passed to [method set_value] into a raw value to be
## stored using [method SaveDataManager.set_raw_data].
## [br][br]
## Custom implementations should not make any assumptions of the passed
## [param value]. It may be null, an incompatible type, or otherwise invalid.
## This function [b]MUST[/b] gracefully handle all conditions and produce a
## value consistent with what [method from_raw] expects.
@abstract
func to_raw(value: Variant) -> Variant


## Convenience function for implementors to emit [signal value_changed].
## 
## This function is intended to be called by implementors when an exported field
## affecting the parsing of a raw value changes. If the change would cause
## [method get_value] to return a different result for the same raw save data
## then this should be called to emit the signal.
## 
## [b]Note:[/b] this is not to be confused with [method Resource.emit_changed]
## which should also be called when an exported variable changes. When an export
## variable that affects the save data value has changed,
## [method Resource.emit_changed] should be called first, immediately followed
## by this function.
func emit_value_changed() -> void:
	value_changed.emit(get_value())


## Emits [signal value_changed] when the value has changed.
## 
## Custom [AbstractSaveData] implementations should not override this.
func _on_save_value_changed(value: Variant) -> void:
	value_changed.emit(from_raw(value))
