@tool
extends EditorPlugin
## Initializes the ProtoJam save plugin.

func _enter_tree() -> void:
	for setting in _ProtoJamSaveConstants._get_project_settings():
		setting.register()


func _exit_tree() -> void:
	for setting in _ProtoJamSaveConstants._get_project_settings():
		setting.unregister()
