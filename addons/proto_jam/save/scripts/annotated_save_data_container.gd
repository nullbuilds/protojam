class_name _AnnotatedSaveDataContainer
extends _AbstractSaveDataContainer
## Encapsulates save data and metadata describing the save.
## 
## Unlike a [_GlobalSaveDataContainer], an annotated container includes two
## types of data: main data and metadata. Main data represents the game data you
## want stored while metadata describes the save itself. These sets of data are
## loaded and saved together.
## [br][br]
## Users should not use this directly. See [SaveDataManager] instead.

const _METADATA_KEY: StringName = &"metadata"
const _MAIN_DATA_KEY: StringName = &"data"

var _metadata: Dictionary[StringName, Variant] = {}
var _main_data: ObservableDictionary = ObservableDictionary.new(
		_on_save_data_added,
		_on_save_data_removed.unbind(1),
		_on_save_data_changed.unbind(1))

## Returns a [b]shallow[/b] copy of all metadata.
## 
## Users should not call this function directly. See [SaveDataManager] instead.
func get_metadata() -> Variant:
	return _metadata.duplicate(true)


## Reads the value associated with the metadata key.
## 
## Returns the value for [param metadata_key] if previously set or loaded;
## otherwise, returns [code]null[/code].
## [br][br]
## Users should not call this function directly. See [SaveDataManager] instead.
func get_metadata_value(metadata_key: StringName) -> Variant:
	return _metadata.get(metadata_key)


## Sets the value associated with a metadata key.
## 
## Overwrites or sets the value for [param metadata_key]. A
## [param value] of [code]null[/code] effectively unsets the metadata.
## [br][br]
## Users should not call this function directly. See [SaveDataManager] instead.
func set_metadata_value(metadata_key: StringName, value: Variant) -> void:
	_metadata.set(metadata_key, value)


## Clears the value of all metadata (main data is not affected).
## 
## Users should not call this directly.
func clear_metadata() -> void:
	_metadata.clear()


## Reads the unparsed value associated with a save data key.
## 
## Returns the unparsed value for [param save_data_key] if previously set or
## loaded; otherwise, returns [code]null[/code].
## [br][br]
## Users should not call this function directly outside of an [AbstractSaveData]
## implementation. See [method AbstractSaveData.get_value] to read the parsed
## value instead.
func get_raw_main_data_value(save_data_key: StringName) -> Variant:
	return _main_data.get_value(save_data_key)


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
	_main_data.set_value(save_data_key, value)


## Clears the value of all main data (metadata is not affected).
## 
## If a signal has been created for save data using
## [method create_save_data_change_signal], it will be emitted if the setting
## was not already cleared.
## [br][br]
## Users should not call this function directly.
func clear_main_data() -> void:
	_main_data.clear()


## Populates the main data and metadata from the given file.
## 
## Users should not call this function directly.
func load_data(file_path: String) -> Error:
	var new_data: Dictionary[StringName, Variant] = {}
	var error: Error = _load_from_file(file_path, new_data)
	if Error.OK == error:
		var new_metadata: Dictionary[StringName, Variant] = {}
		if new_data.has(_METADATA_KEY):
			new_metadata.assign(new_data.get(_METADATA_KEY))
		_metadata.assign(new_metadata)
		
		var new_save_data: Dictionary[StringName, Variant] = {}
		if new_data.has(_MAIN_DATA_KEY):
			new_save_data.assign(new_data.get(_MAIN_DATA_KEY))
		_main_data.assign(new_save_data)
	elif Error.ERR_FILE_NOT_FOUND != error:
		# Not existing is normal for new games and should not log an error
		push_error("Failed to load save data; unable to load from file \"%s\"; error code %d" % [file_path, error])
	
	return error


## Persists the main data and metadata to the given file.
## 
## Users should not call this function directly.
func save_data(file_path: String) -> Error:
	var combined_data: Dictionary[StringName, Variant] = {}
	combined_data.set(_METADATA_KEY, _metadata)
	combined_data.set(_MAIN_DATA_KEY, _main_data.duplicate())
	
	var error: Error = _save_to_file(file_path, combined_data)
	if Error.OK != error:
		push_error("Failed to save data; unable to write to file \"%s\"; error code %d" % [file_path, error])
	return error


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
