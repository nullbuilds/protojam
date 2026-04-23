@tool
extends EditorPlugin
## Initializes the ProtoJam settings plugin.

func _enter_tree() -> void:
	for setting in _ProtoJamSettingsConstants._get_project_settings():
		setting.register()


func _exit_tree() -> void:
	for setting in _ProtoJamSettingsConstants._get_project_settings():
		setting.unregister()
