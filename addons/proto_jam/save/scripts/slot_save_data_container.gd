class_name _SlotSaveDataContainer
extends _AbstractSaveDataContainer
## A save game container which loads and saves from slots.
## 
## A save slot is an abstraction to the file system allowing save files to be
## read and written to without knowing their location. Like
## [_AnnotatedSaveDataContainer], each slot contains both game data and
## metadata. Additionally, the last read or written slot is persisted betwen
## executions to facilitate "continue" functionality.
## [br][br]
## Users should not use this directly. See [SaveDataManager] instead.

const _LAST_USED_SLOT_FILE_NAME: String = "last_used_slot"
const _SAVE_SLOT_FILE_NAME_TEMPLATE: String = "slot_%d.json"
const _SAVE_SLOT_PATTERN_GROUP: String = "slot"

var _base_directory: String = ""
var _active_slot: int = -1
var _save_data: _AnnotatedSaveDataContainer = _AnnotatedSaveDataContainer.new()
var _slot_file_pattern: RegEx = RegEx.create_from_string("slot_(?<slot>\\d+)\\.json")

## Constructs a new slot data container.
## 
## The [param base_directory] sets where all files will be stored and loaded
## from.
## [br][br]
## Users shoudl not call this function directly. See [SaveDataManager] instead.
func _init(base_directory: String) -> void:
	_base_directory = base_directory


## Fetches a list of every slot containing data.
## 
## Users should not call this function directly.
func get_used_slot_indices() -> Array[int]:
	var slots: Array[int] = []
	# The save directory not existing is normal for a new game.
	if DirAccess.dir_exists_absolute(_base_directory):
		for file_path in DirAccess.get_files_at(_base_directory):
			var search: RegExMatch = _slot_file_pattern.search(file_path)
			if null != search:
				var slot_string: String = search.get_string(_SAVE_SLOT_PATTERN_GROUP)
				var slot_index: int = slot_string.to_int()
				slots.push_back(slot_index)
	
	return slots


## Gets a copy of the metadata for the given slot.
## 
## The metadata will be stored in the given [param metadata] Dictionary. Unlike
## [method get_metadata], this method does not change the active slot or
## currently loaded data. An error will be returned for slots which cannot be
## read or contain no data.
## [br][br]
## Users should not call this function directly.
func inspect_slot_metadata(slot_index: int,
		metadata: Dictionary[StringName, Variant]) -> Error:
	var file_path: String = _get_slot_file_path(slot_index)
	var slot: _AnnotatedSaveDataContainer = _AnnotatedSaveDataContainer.new()
	var error: Error = slot.load_data(file_path)
	if Error.OK == error:
		metadata.assign(slot.get_metadata())
	
	return error


## Gets the active slot index.
## 
## The active slot is whichever slot was last loaded from or saved to. If no
## slot has ever been written to, it will default to slot 0.
## [br][br]
## Users should not call this function directly.
func get_active_slot() -> int:
	return _get_active_slot_with_override()


## Loads a save slot's data.
## 
## A negative [param slot_index] will cause the last used slot to be loaded
## instead or slot [code]0[/code] if no slot has been used. The loaded slot will
## be made active.
## [br][br]
## Users should not call this function directly.
func load_slot(slot_index: int = -1) -> Error:
	slot_index = _get_active_slot_with_override(slot_index)
	
	var file_path: String = _get_slot_file_path(slot_index)
	var error: Error = _save_data.load_data(file_path)
	if Error.OK == error:
		_active_slot = slot_index
		var last_used_error: Error = _save_last_used_slot(_active_slot)
		if Error.OK != last_used_error:
			push_error("Failed to save last used slot; error code %d" % [file_path, last_used_error])
	
	return error


## Saves to the given slot.
## 
## A negative [param slot_index] will cause the last used slot to be saved to
## instead or slot [code]0[/code] if no slot has been used. The saved slot will
## be made active.
## [br][br]
## Users should not call this function directly.
func save_slot(slot_index: int = -1) -> Error:
	slot_index = _get_active_slot_with_override(slot_index)
	
	var file_path: String = _get_slot_file_path(slot_index)
	var error: Error = _save_data.save_data(file_path)
	if Error.OK == error:
		_active_slot = slot_index
		var last_used_error: Error = _save_last_used_slot(_active_slot)
		if Error.OK != last_used_error:
			push_error("Failed to save last used slot; error code %d" % [file_path, last_used_error])
	
	return error


## Deletes a save slot file.
## 
## [b]Note:[/b] Only the slot file is removed. Currently loaded data is not
## affected if the slot is active. To remove both, a calls to
## [method clear_main_data] and [method clear_metadata] must also be made.
## [br][br]
## Users should not call this function directly. See [SaveDataManager] instead.
func delete_slot(slot_index: int) -> Error:
	var file_path: String = _get_slot_file_path(slot_index)
	
	var error: Error = Error.OK
	if FileAccess.file_exists(file_path):
		error = DirAccess.remove_absolute(file_path)
		if Error.OK != error:
			push_warning("Failed to delete slot %d's save file \"%s\"; error code %d" % [slot_index, file_path, error])
	return error


## Reads the value associated with the metadata key.
## 
## Returns the value for [param metadata_key] if previously set or loaded;
## otherwise, returns [code]null[/code].
## [br][br]
## Users should not call this function directly. See [SaveDataManager] instead.
func get_metadata_value(metadata_key: StringName) -> Variant:
	return _save_data.get_metadata_value(metadata_key)


## Sets the value associated with a metadata key.
## 
## Overwrites or sets the value for [param metadata_key]. A
## [param value] of [code]null[/code] effectively unsets the metadata.
## [br][br]
## Users should not call this function directly. See [SaveDataManager] instead.
func set_metadata_value(metadata_key: StringName, value: Variant) -> void:
	_save_data.set_metadata_value(metadata_key, value)


## Clears the value of all metadata (main data is not affected).
## 
## Users should not call this function directly.
func clear_metadata() -> void:
	_save_data.clear_metadata()


## Reads the unparsed value associated with a save data key.
## 
## Returns the unparsed value for [param save_data_key] if previously set or
## loaded; otherwise, returns [code]null[/code].
## [br][br]
## Users should not call this function directly outside of an [AbstractSaveData]
## implementation. See [method AbstractSaveData.get_value] to read the parsed
## value instead.
func get_raw_main_data_value(save_data_key: StringName) -> Variant:
	return _save_data.get_raw_main_data_value(save_data_key)


## Sets the unparsed value associated with a save data key.
## 
## Overwrites or sets the unparsed value for [param save_data_key]. A
## [param value] of [code]null[/code] effectively unsets the save data.
## [br][br]
## Users should not call this function directly outside of an [AbstractSaveData]
## implementation. See [method AbstractSaveData.set_value] to write the parsed
## value instead.
## [br][br]
## If a signal has been created for this save data using
## [method create_save_data_change_signal], it will be emitted if the value has
### changed.
func set_raw_main_data_value(save_data_key: StringName, value: Variant) -> void:
	_save_data.set_raw_main_data_value(save_data_key, value)


## Clears the value of all main data (metadata is not affected).
## 
## If a signal has been created for save data using
## [method create_save_data_change_signal], it will be emitted if the setting
## was not already cleared.
## [br][br]
## Users should not call this function directly.
func clear_main_data() -> void:
	_save_data.clear_main_data()


## Returns the index of the slot that should be used.
## 
## A negative [param override_index] indicates the last read or written slot
## index should be used. If no slot has been read or written to, slot
## [code]0[/code] is returned.
## [br][br]
## Users should not call this function directly.
func _get_active_slot_with_override(override_index: int = -1) -> int:
	if override_index >= 0:
		return override_index
	
	if _active_slot >= 0:
		return _active_slot
	
	var last_used_slot: int = _get_last_used_slot()
	if last_used_slot >= 0:
		return last_used_slot
	
	return 0


## Loads the index of the slot persisted from previous executions.
##
## A [code]-1[/code] will be returned when there was no last used slot or it
## could not be loaded.
## [br][br]
## User should not call this function directly.
func _get_last_used_slot() -> int:
	var slot_index: int = -1
	var file_path: String = _get_last_used_slot_path()
	if FileAccess.file_exists(file_path):
		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		if null == file:
			var error: Error = FileAccess.get_open_error()
			push_error("Failed to load last used slot file; could not open \"%s\" for reading; error code %d" % [file_path, error])
		else:
			# This file should only contain 8 bytes
			var length: int = file.get_length()
			if 8 != length:
				push_error("Failed to load last used slot file; could not parse \"%s\"; expected 8 bytes but contained %d" % [file_path, length])
				return slot_index
			else:
				# Get contents and close file ASAP to ensure it closes cleanly
				slot_index = file.get_64()
				file.close()
	
	return slot_index


## Saves the index of the last used slot.
##
## User should not call this function directly.
func _save_last_used_slot(slot_index: int) -> Error:
	var file_path: String = _get_last_used_slot_path()
	
	var error: Error = Error.OK
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if null != file:
		if file.store_64(slot_index):
			# Closing isn't technically required since FileAccess does this
			# automatically when it goes out of scope but I'm doing it
			# explicitly to indicate that any signals should be emitted AFTER
			# this call to ensure the file has already been written in the event
			# of a crash caused by a signal callback.
			file.close()
		else:
			error = file.get_error()
	else:
		error = FileAccess.get_open_error()
	
	return error


## Returns the path to the last used slot file.
## 
## Users should not call this function directly.
func _get_last_used_slot_path() -> String:
	return _base_directory.path_join(_LAST_USED_SLOT_FILE_NAME)


## Gets the path to the save file for the given slot.
## 
## Users should not call this function directly.
func _get_slot_file_path(slot_index: int) -> String:
	var file_name: String = _SAVE_SLOT_FILE_NAME_TEMPLATE % slot_index
	return _base_directory.path_join(file_name)
