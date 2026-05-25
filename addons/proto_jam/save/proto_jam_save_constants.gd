@tool
@abstract
class_name _ProtoJamSaveConstants
extends Node
## Internal class for housing constants used by the ProtoJam save plugin.

## The project setting defining the save file path.
@warning_ignore("unused_private_class_variable")
static var _save_file_directory_setting: PluginProjectSetting = \
		PluginProjectSetting.new(
				"addons/proto_jam/save/save_directory",
				"user://saves/",
				TYPE_STRING,
				PROPERTY_HINT_DIR,
				"The directory where user saves will be created."
			)


## Returns all project settings required by the plugin.
static func _get_project_settings() -> Array[PluginProjectSetting]:
	return [_save_file_directory_setting]
