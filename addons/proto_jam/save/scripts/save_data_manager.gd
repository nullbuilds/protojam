@abstract
class_name SaveDataManager
extends RefCounted
## Static game save data manager.
## 
## Manages low-level storage and retreival of game save data. See
## [AbstractSaveData] for methods to read/change data.
## [br][br]
## The save system stores three types of data:
## * [b]Slot data[/b] - A individual save file that can be written to. Only a
##     single slot may be loaded at a time but there is no practical limit to
##     how many slots exist or what a slot represents; additionally, there is no
##     requirement for slots to contain the same type data. Slot data should
##     typically be accessed using [AbstractSaveData] handles.
## * [b]Global data[/b] - A single global store of data maintained separately
##     from the slot data. Ideal for play stats, acheivements, etc. Global data
##     should typically be accessed using [AbstractSaveData] handles with
##     [member AbstractSaveData.global] set to [code]true[/code].
## * [b]Slot metadata[/b] - An additional set of metadata associated with each
##     save slot intended to store information about the slot itself like save
##     number, name, time, etc. The metadata for the active slot is read and
##     written to using [method get_slot_metadata_value] and
##     [method set_slot_metadata_value]. Metadata for arbitrary slots can be read
##     using [method inspect_slot_metadata].
## [br][br]
## The directory saves are written to can be customized by changing the
## [code]addons/proto_jam/save/save_directory[/code] project setting.
## [br][br]
## All operations are thread-safe.

static var _slot_data: _SlotSaveDataContainer = _SlotSaveDataContainer.new(_get_save_directory_path())
static var _global_data: _GlobalSaveDataContainer = _GlobalSaveDataContainer.new(_get_save_directory_path())
static var _mutex: Mutex = Mutex.new()

## Reads the unparsed value associated with a save data key.
## 
## Returns the unparsed value associated with [param save_data_key] and
## [param is_global] if previously set or loaded; otherwise, returns
## [code]null[/code].
## [br][br]
## Users should not call this function directly outside of an [AbstractSaveData]
## implementation. See [method AbstractSaveData.get_value] to read the parsed
## value instead.
static func get_raw_save_data(
		save_data_key: StringName,
		is_global: bool) -> Variant:
	_mutex.lock()
	
	var data: Variant = null
	if is_global:
		data = _global_data.get_raw_value(save_data_key)
	else:
		data = _slot_data.get_raw_main_data_value(save_data_key)
	
	_mutex.unlock()
	return data


## Sets the unparsed value associated with a save data key.
## 
## Overwrites or sets the unparsed value associated with [param save_data_key]
## and [param is_global]. A [param value] of [code]null[/code] effectively
## unsets the data.
## [br][br]
## Users should not call this function directly outside of an [AbstractSaveData]
## implementation. See [method AbstractSaveData.set_value] to write the parsed
## value instead.
## [br][br]
## If a signal has been created for this save data using
## [method create_save_data_change_signal], it will be emitted if the value has
### changed.
static func set_raw_save_data(
		save_data_key: StringName,
		is_global: bool,
		value: Variant) -> void:
	_mutex.lock()
	if is_global:
		_global_data.set_raw_value(save_data_key, value)
	else:
		_slot_data.set_raw_main_data_value(save_data_key, value)
	_mutex.unlock()


## Fetches a list of every slot containing data.
static func get_used_slot_indices() -> Array[int]:
	_mutex.lock()
	var used_slots: Array[int] = _slot_data.get_used_slot_indices()
	_mutex.unlock()
	return used_slots


## Gets a copy of the metadata for the given slot.
## 
## The metadata will be stored in the given [param metadata] Dictionary. Unlike
## [method get_metadata], this function does not change the active slot or
## currently loaded data. An error will be returned for slots which cannot be
## read or contain no data.
static func inspect_slot_metadata(slot_index: int,
		metadata: Dictionary[StringName, Variant]) -> Error:
	_mutex.lock()
	var error: Error = _slot_data.inspect_slot_metadata(slot_index, metadata)
	_mutex.unlock()
	return error


## Gets the active slot index.
## 
## The active slot is whichever slot was last loaded from or saved to. If no
## slot has ever been written to, it will default to slot 0.
static func get_active_slot() -> int:
	_mutex.lock()
	var slot: int = _slot_data.get_active_slot()
	_mutex.unlock()
	return slot


## Loads a save slot's data.
## 
## A negative [param slot_index] will cause the last used slot to be loaded
## instead or slot [code]0[/code] if no slot has been used. The loaded slot will
## be made active.
static func load_slot_data(slot_index: int = -1) -> Error:
	_mutex.lock()
	var error: Error = _slot_data.load_slot(slot_index)
	_mutex.unlock()
	return error


## Saves to the given slot.
## 
## A negative [param slot_index] will cause the last used slot to be saved to
## instead or slot [code]0[/code] if no slot has been used. The saved slot will
## be made active.
static func save_slot_data(slot_index: int = -1) -> Error:
	_mutex.lock()
	var error: Error = _slot_data.save_slot(slot_index)
	_mutex.unlock()
	return error


## Reads the value associated with the metadata key.
## 
## Returns the value for [param metadata_key] if previously set or loaded;
## otherwise, returns [code]null[/code].
static func get_slot_metadata_value(metadata_key: StringName) -> Variant:
	_mutex.lock()
	var value: Variant = _slot_data.get_metadata_value(metadata_key)
	_mutex.unlock()
	return value


## Sets the value associated with a metadata key.
## 
## Overwrites or sets the value for [param metadata_key]. A
## [param value] of [code]null[/code] effectively unsets the metadata.
static func set_slot_metadata_value(
		metadata_key: StringName,
		value: Variant) -> void:
	_mutex.lock()
	_slot_data.set_metadata_value(metadata_key, value)
	_mutex.unlock()


## Clears the currently loaded slot's metadata (main data is not affected).
## 
## A call to [method save_slot_data] is required to persist the change.
static func clear_slot_metadata() -> void:
	_mutex.lock()
	_slot_data.clear_metadata()
	_mutex.unlock()


## Clears the value of all slot main data (metadata is not affected).
## 
## Users should not call this function directly. See [AbstractSaveData] instead.
static func clear_slot_data() -> void:
	_mutex.lock()
	_slot_data.clear_main_data()
	_mutex.unlock()


## Clears all global save data.
## 
## [b]Note:[/b] A call to [method save_global_data] is required to persist the
## change.
static func clear_global_data() -> void:
	_mutex.lock()
	_global_data.clear_data()
	_mutex.unlock()


## Loads the global save data.
static func load_global_data() -> Error:
	_mutex.lock()
	var error: Error = _global_data.load_data()
	_mutex.unlock()
	return error


## Saves the global save data.
static func save_global_data() -> Error:
	_mutex.lock()
	var error: Error = _global_data.save_data()
	_mutex.unlock()
	return error


## Convenience function to save both global and slot data.
## 
## Global data is saved first followed by slot data to the default slot. An
## attempt to save slot data will be made even if saving global data fails.
## [br][br]
## Use [method save_global_data] and [method save_slot_data] for more specific
## error codes or if you need to alter this behavior.
static func save_all_data() -> Error:
	_mutex.lock()
	
	var global_error: Error = _global_data.save_data()
	if Error.OK != global_error:
		push_error("Failed to save global data; error code %d" % global_error)
	
	var slot_error: Error = _slot_data.save_slot()
	if Error.OK != slot_error:
		push_error("Failed to save slot data; error code %d" % slot_error)
	
	_mutex.unlock()
	
	if Error.OK != global_error or Error.OK != slot_error:
		return Error.FAILED
	
	return Error.OK


## Convenience function to load both global and slot data.
## 
## Global data is loaded first followed by slot data from the default slot. An
## attempt to load slot data will be made even if loading global data fails.
## [br][br]
## Use [method load_global_data] and [method load_slot_data] for more specific
## error codes or if you need to alter this behavior.
static func load_all_data() -> Error:
	_mutex.lock()
	
	var global_error: Error = _global_data.load_data()
	if Error.OK != global_error:
		push_error("Failed to load global data; error code %d" % global_error)
	
	var slot_error: Error = _slot_data.load_slot()
	if Error.OK != slot_error:
		push_error("Failed to load slot data; error code %d" % slot_error)
	
	_mutex.unlock()
	
	if Error.OK != global_error or Error.OK != slot_error:
		return Error.FAILED
	
	return Error.OK


## Returns a signal to monitor value changes of save data.
## 
## Creates a signal to monitor when the value of the save data identified by
## [param save_data_key] and [param is_global] changes. This function is
## indempotent and will return the same signal if called multiple times with the
## same key.
## [br][br]
## The resulting signal is emitted with the save data's new value as the only
## argument.
## [br][br]
## The returned signal will not be deallocated until the engine exists. Users
## should avoid calling this method directly and instead use
## [signal AbstractSaveData.value_changed].
static func create_save_data_change_signal(
		save_data_key: StringName,
		is_global: bool) -> Signal:
	_mutex.lock()
	
	var sig: Signal = Signal()
	if is_global:
		sig = _global_data.create_save_data_change_signal(save_data_key)
	else:
		sig = _slot_data.create_save_data_change_signal(save_data_key)
	
	_mutex.lock()
	return sig


## Returns the path to the save directory.
## 
## Users should not call this directly.
static func _get_save_directory_path() -> String:
	return _ProtoJamSaveConstants._save_file_directory_setting \
			.get_setting_with_default_override()
