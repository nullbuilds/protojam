@tool
extends EditorPlugin
## Initializes the ProtoJam audio plugin.

var _audio_manager: PluginAutoloadSingleton = \
		PluginAutoloadSingleton.new(
			"AudioManager",
			PluginUtils.get_plugin_script_path(self, "scripts/audio_manager.gd")
		)

func _enable_plugin() -> void:
	_audio_manager.enable(self)


func _disable_plugin() -> void:
	_audio_manager.disable(self)
