class_name _GlobalSaveDataContainer
extends _AbstractSaveDataContainer
## Encapsulates global save data.
## 
## Users should not use this directly. See [SaveDataManager] instead.

const _GLOBAL_DATA_FILE_NAME: String = "global.json"

var _base_directory: String = ""
var _save_data: ObservableDictionary = ObservableDictionary.new(
		_on_save_data_added,
		_on_save_data_removed.unbind(1),
		_on_save_data_changed.unbind(1))

## Constructs a new global data container.
## 
## The [param base_directory] sets the directory where the global data will be
## stored.
## [br][br]
## Users shoudl not call this function directly. See [SaveDataManager] instead.
func _init(base_directory: String) -> void:
	_base_directory = base_directory


## Reads the unparsed value associated with a save data key.
## 
## Returns the unparsed value for [param save_data_key] if previously set or
## loaded; otherwise, returns [code]null[/code].
## [br][br]
## Users should not call this function directly outside of an [AbstractSaveData]
## implementation. See [method AbstractSaveData.get_value] to read the parsed
## value instead.
func get_raw_value(save_data_key: StringName) -> Variant:
	return _save_data.get_value(save_data_key)


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
func set_raw_value(save_data_key: StringName, value: Variant) -> void:
	_save_data.set_value(save_data_key, value)


## Clears the value of all save data.
## 
## If a signal has been created for save data using
## [method create_save_data_change_signal], it will be emitted if the setting
## was not already cleared.
## [br][br]
## Users should not call this function directly.
func clear_data() -> void:
	_save_data.clear()


## Populates the global save data.
## 
## Users should not call this function directly.
func load_data() -> Error:
	var file_path: String = _get_global_save_path()
	var new_data: Dictionary[StringName, Variant] = {}
	var error: Error = _load_from_file(file_path, new_data)
	if Error.OK == error:
		_save_data.assign(new_data)
	elif Error.ERR_FILE_NOT_FOUND != error:
		# Not existing is normal for new games and not worth logging an error.
		push_error("Failed to load global save data; unable to load from file \"%s\"; error code %d" % [file_path, error])
		
	return error


## Persists the global save data.
## 
## Users should not call this function directly.
func save_data() -> Error:
	var file_path: String = _get_global_save_path()
	var typed_save_data: Dictionary[StringName, Variant] = {}
	typed_save_data.assign(_save_data.duplicate())
	var error: Error = _save_to_file(file_path, typed_save_data)
	if Error.OK != error:
		push_error("Failed to save global save data; unable to write to file \"%s\"; error code %d" % [file_path, error])
	return error


## Returns the path to the global save file.
## 
## Users should not call this directly.
func _get_global_save_path() -> String:
	return _base_directory.path_join(_GLOBAL_DATA_FILE_NAME)


## Called when save data is added.
## 
## Users should not call this function directly.
func _on_save_data_added(save_data_key: StringName, value: Variant) -> void:
	emit_save_data_changed(save_data_key, value)


## Called when save data is removed.
## 
## Users should not call this function directly.
func _on_save_data_removed(save_data_key: StringName) -> void:
	emit_save_data_changed(save_data_key, null)


## Called when save data is changed.
## 
## Users should not call this function directly.
func _on_save_data_changed(save_data_key: StringName, value: Variant) -> void:
	emit_save_data_changed(save_data_key, value)
