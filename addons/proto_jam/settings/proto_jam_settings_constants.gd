@tool
@abstract
class_name _ProtoJamSettingsConstants
extends Node
## Internal class for housing constants used by the ProtoJam Settings plugin.

## The project setting defining the settings file path.
@warning_ignore("unused_private_class_variable")
static var _settings_file_path_setting: PluginProjectSetting = \
		PluginProjectSetting.new(
				"addons/proto_jam/settings/file_path",
				"user://settings.json",
				TYPE_STRING,
				PROPERTY_HINT_FILE_PATH,
				"The path where user settings will be saved."
			)


## Returns all project settings required by the plugin.
static func _get_project_settings() -> Array[PluginProjectSetting]:
	return [_settings_file_path_setting]
