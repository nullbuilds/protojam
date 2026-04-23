@abstract
class_name SettingsManager
extends Node
## Static game settings manager.
## 
## Manages low-level storage and retreival of game settings. See
## [AbstractSetting] for methods to read/change settings.
## [br][br]
## The file settings are saved to can be customized by changing the
## [code]addons/proto_jam/settings/file_path[/code] project setting.

static var _settings: Dictionary[StringName, Variant] = {}
static var _setting_signals: Dictionary[StringName, Signal] = {}
static var _signal_bus: RefCounted = RefCounted.new()

## Returns a signal to monitor value changes of a setting.
## 
## Creates a signal to monitor when the value of the setting identified by
## [param setting_key] changes. This function is indempotent and will return the
## same signal if called multiple times with the same key.
## [br][br]
## The resulting signal is emitted with the setting's new value as the only
## argument.
## [br][br]
## The returned signal will not be deallocated until the engine exists. Users
## should avoid calling this method directly and instead use
## [signal AbstractSetting.value_changed].
static func create_setting_change_signal(setting_key: StringName) -> Signal:
	return BaseUtils.get_or_create( \
			_setting_signals, \
			setting_key, \
			func() -> Signal:
				var signal_name: StringName = StringName(setting_key + "_changed")
				var sig: Signal = Signal(_signal_bus, signal_name)
				_signal_bus.add_user_signal(signal_name, [
					# This is actually a Variant but there is no TYPE_ constant
					# for Variant
					{ "name": "value", "type": TYPE_OBJECT },
				])
				return sig)


## Reads the unparsed value associated with a setting key.
## 
## Returns the unparsed value for [param setting_key] if previously set or
## loaded; otherwise, returns [code]default[/code] or [code]null[/code].
## [br][br]
## Users should not call this method directly outside of an [AbstractSetting]
## implementation. See [method AbstractSetting.get_value] to read the parsed
## value instead.
static func get_raw_setting(setting_key: StringName) -> Variant:
	return _settings.get(setting_key)


## Sets the unparsed value associated with a setting key.
## 
## Overwrites or sets the unparsed value for [param setting_key]. A
## [param value] of [code]null[/code] effectively unsets the setting.
## [br][br]
## Users should not call this method directly outside of an [AbstractSetting]
## implementation. See [method AbstractSetting.set_value] to write the parsed
## value instead.
## [br][br]
##  If a signal has been created for this setting using
## [method create_setting_change_signal], it will be emitted if the value has
### changed.
static func set_raw_setting(setting_key: StringName, value: Variant) -> void:
	var old_value: Variant = _settings.get(setting_key)
	_settings.set(setting_key, value)
	
	if value != old_value:
		_emit_setting_changed(setting_key, value)


## Save current settings.
## 
## This function performs a blocking save of the game's settings to the user's
## device regardless of whether changes have been made.
## [br][br]
## Returns [constant OK] if saving was successful.
static func save_settings() -> Error:
	var settings_file_path: String = _get_settings_file_path()
	
	var file: FileAccess = FileAccess.open(settings_file_path, FileAccess.WRITE)
	if null == file:
		var error: Error = FileAccess.get_open_error()
		push_error("Failed to save settings; could not open file \"%s\" for writing; error code %d" % [settings_file_path, error])
		return error
	
	var encoded_data: String = JSON.stringify(_settings, "  ", true)
	if not file.store_string(encoded_data):
		var error: Error = file.get_error()
		push_error("Failed to save settings; could not write to \"%s\"; error code %d" % [settings_file_path, error])
		return error
	
	# Closing isn't technically required since FileAccess does this
	# automatically when it goes out of scope but I'm doing it explicitly to
	# indicate that any signals should be emitted AFTER this call to ensure the
	# file has already been written in the event of a crash caused by a signal
	# callback.
	file.close()
	print("Settings saved to \"%s\"" %settings_file_path)
	return Error.OK


## Loads previously saved settings, if any.
## 
## This function performs a blocking load of the game's settings from the user's
## device overwriting all locally stored values. Returns [constant OK] if
## loading was successful.
## [br][br]
## A value changed signal will be emitted for each setting which has had a
## signal created using [method create_setting_change_signal]. No signals will
## be triggered if the current settings are empty and no settings file exists.
## [br][br]
## This method should be called as soon as the game starts preferably from the
## main scene's [method Node._ready] function to ensure systems depending
## on these settings get the chosen value as soon as possible.
static func load_settings() -> Error:
	var settings_file_path: String = _get_settings_file_path()
	
	# Take no action if the file doesn't exist (ie on first play)
	if not FileAccess.file_exists(settings_file_path):
		print("Using default settings; no such file \"%s\"" %settings_file_path)
		return Error.OK
	
	# Open settings file for reading
	var file: FileAccess = FileAccess.open(settings_file_path, FileAccess.READ)
	if null == file:
		var error: Error = FileAccess.get_open_error()
		push_error("Failed to load settings; could not open \"%s\" for reading; error code %d" % [settings_file_path, error])
		return error
	
	# Get contents and close file ASAP to ensure it closes cleanly
	var file_contents: String = file.get_as_text()
	file.close()
	
	# Parse the contents as a JSON object
	var json: Variant = JSON.parse_string(file_contents)
	if null == json:
		push_error("Failed to load settings; contents of \"%s\" are malformed" % settings_file_path)
		return Error.ERR_PARSE_ERROR
	elif json is not Dictionary:
		push_error("Failed to load settings; contents of \"%s\" are malformed; not an object" % settings_file_path)
		return Error.ERR_PARSE_ERROR
	
	# Remove loaded keys that aren't strings or are empty (ie aren't valid)
	json = BaseUtils.filterd(json, func(key: Variant, _value: Variant) -> bool:
		if key is not String and key is not StringName:
			var type: String = type_string(typeof(key))
			push_warning("Failed to load setting; key \"%s\" in \"%s\" is not a string; was \"%s\"" % [key, settings_file_path, type])
			return false
		elif key.is_empty():
			push_warning("Failed to load setting; key \"%s\" in \"%s\" is empty" % [key, settings_file_path])
			return false
		return true)
	
	# Update cached settings
	var _old_settings: Dictionary[StringName, Variant] = _settings.duplicate(false)
	_settings.assign(json)
	
	print("Settings loaded from \"%s\"" %settings_file_path)
	
	# Notify listeners of the changes
	_emit_settings_changed(_settings, _old_settings)
	
	return Error.OK


## Returns the settings file path.
static func _get_settings_file_path() -> String:
	return _ProtoJamSettingsConstants._settings_file_path_setting \
			.get_setting_with_default_override()


## Emits previously created change signals for changed settings.
## 
## Compares the keys and values of [param new_settings] and [param old_settings]
## emitting a signal for each key that is no longer defined or whose value has
## changed. I signal will only be emitted if it was created using
## [method create_setting_change_signal].
static func _emit_settings_changed(new_settings: Dictionary[StringName, Variant],
		old_settings: Dictionary[StringName, Variant]) -> void:
	# TODO write more efficently
	var combined_keys: Array[StringName] = new_settings.merged(old_settings).keys()
	
	for key in combined_keys:
		var new_value: Variant = new_settings.get(key)
		
		# Explicitly check if old_settings and new_settings have the key before
		# comparing. Comparing without checking could return true if the new or
		# old value happens to be the default and the other does not contain the
		# key.
		if old_settings.has(key) and new_settings.has(key):
			var old_value: Variant = old_settings.get(key)
			if old_value != new_value:
				_emit_setting_changed(key, new_value)
		else:
			_emit_setting_changed(key, new_value)


## Emits a previously created change signal for the given setting.
## 
## If a signal has been created for this setting using
## [method create_setting_change_signal], it will be emitted.
static func _emit_setting_changed(setting_key: StringName, value: Variant) -> void:
	if _setting_signals.has(setting_key):
		_setting_signals.get(setting_key).emit(value)
