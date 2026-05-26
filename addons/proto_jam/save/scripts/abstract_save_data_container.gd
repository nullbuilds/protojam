class_name _AbstractSaveDataContainer
extends RefCounted
## Represents a collection of saved game data.
## 
## Users should not use this directly. See [SaveDataManager] instead.

var _save_data_signals: Dictionary[StringName, Signal] = {}
var _signal_bus: RefCounted = RefCounted.new()

## Returns a signal to monitor value changes of save data.
## 
## Creates a signal to monitor when the value of the save data identified by
## [param save_data_key] changes. This function is indempotent and will return
## the same signal if called multiple times with the same key.
## [br][br]
## The resulting signal is emitted with the save data's new value as the only
## argument. The returned signal will not be deallocated until the engine
## exists.
## [br][br]
## Users should avoid calling this method directly.
func create_save_data_change_signal(save_data_key: StringName) -> Signal:
	return BaseUtils.get_or_create( \
			_save_data_signals, \
			save_data_key, \
			func() -> Signal:
				var signal_name: StringName = StringName(save_data_key + "_changed")
				var sig: Signal = Signal(_signal_bus, signal_name)
				_signal_bus.add_user_signal(signal_name, [
					# This is actually a Variant but there is no TYPE_ constant
					# for Variant
					{ "name": "value", "type": TYPE_OBJECT },
				])
				return sig)


## Emits a previously created change signal for the given save data.
## 
## If a signal has been created for this save data using
## [method create_save_data_change_signal], it will be emitted.
## [br][br]
## Users should not call this function directly.
func emit_save_data_changed(save_data_key: StringName, value: Variant) -> void:
	if _save_data_signals.has(save_data_key):
		_save_data_signals.get(save_data_key).emit(value)


## Loads the raw contents of a save file.
## 
## The contents of the loaded file are stored into [param data].
## [br][br]
## Users should not call this directly. See [SaveDataManager] instead.
static func _load_from_file(file_path: String, data: Dictionary[StringName, Variant]) -> Error:
	if not FileAccess.file_exists(file_path):
		return Error.ERR_FILE_NOT_FOUND
	
	# Open save file for reading
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if null == file:
		var error: Error = FileAccess.get_open_error()
		push_error("Failed to load save file; could not open \"%s\" for reading; error code %d" % [file_path, error])
		return error
	
	# Get contents and close file ASAP to ensure it closes cleanly
	var file_contents: String = file.get_as_text()
	file.close()
	
	# Parse the contents as a JSON object
	var json: Variant = JSON.parse_string(file_contents)
	if null == json:
		push_error("Failed to load save file; contents of \"%s\" are malformed" % file_path)
		return Error.ERR_PARSE_ERROR
	elif json is not Dictionary:
		push_error("Failed to load save file; contents of \"%s\" are malformed; not an object" % file_path)
		return Error.ERR_PARSE_ERROR
	
	# Remove loaded keys that aren't strings or are empty (ie aren't valid)
	json = BaseUtils.filterd(json, func(key: Variant, _value: Variant) -> bool:
		if key is not String and key is not StringName:
			var type: String = type_string(typeof(key))
			push_warning("Failed to load save data; key \"%s\" in \"%s\" is not a string; was \"%s\"" % [key, file_path, type])
			return false
		elif key.is_empty():
			push_warning("Failed to load save data; key \"%s\" in \"%s\" is empty" % [key, file_path])
			return false
		return true)
	
	data.assign(json)
	return Error.OK


## Saves the given [param data] to a file.
## 
## Users should not call this directly. See [SaveDataManager] instead.
static func _save_to_file(file_path: String, data: Dictionary[StringName, Variant]) -> Error:
	var parent_directory: String = file_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(parent_directory):
		var error: Error = DirAccess.make_dir_recursive_absolute(parent_directory)
		if Error.OK != error:
			push_error("Failed to save data; could not create parent directory \"%s\"; error code %d" % [parent_directory, error])
			return error
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if null == file:
		var error: Error = FileAccess.get_open_error()
		push_error("Failed to save data; could not open file \"%s\" for writing; error code %d" % [file_path, error])
		return error
	
	var encoded_data: String = JSON.stringify(data, "  ", true)
	if not file.store_string(encoded_data):
		var error: Error = file.get_error()
		push_error("Failed to save data; could not write to \"%s\"; error code %d" % [file_path, error])
		return error
	
	# Closing isn't technically required since FileAccess does this
	# automatically when it goes out of scope but I'm doing it explicitly to
	# indicate that any signals should be emitted AFTER this call to ensure the
	# file has already been written in the event of a crash caused by a signal
	# callback.
	file.close()
	print("Save data written to \"%s\"" % file_path)
	return Error.OK
