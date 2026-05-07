@tool
extends EditorPlugin
## Initializes the ProtoJam input plugin.

var _mouse_mode_manager: PluginAutoloadSingleton = \
		PluginAutoloadSingleton.new(
			"MouseModeManager",
			PluginUtils.get_plugin_script_path(self, "scripts/mouse_mode_manager.gd")
		)

func _enable_plugin() -> void:
	_mouse_mode_manager.enable(self)


func _disable_plugin() -> void:
	_mouse_mode_manager.disable(self)
