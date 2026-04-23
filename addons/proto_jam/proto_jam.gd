@tool
extends EditorPlugin
## Initializes the ProtoJam plugin.

const _PLUGIN_NAME: String = "proto_jam"
const _SUB_PLUGINS: Array[String] = [
	"plugin_helper",
	"utils",
	"settings",
	"background_loader",
]

func _enable_plugin() -> void:
	_enable_sub_plugins(true)


func _disable_plugin() -> void:
	_enable_sub_plugins(false)


## Enables or disables sub-plugins.
## 
## Enables sub-plugins in order when [param enable] is true; otherwise, disables
## them in reverse order.
func _enable_sub_plugins(enable: bool) -> void:
	var plugins: Array = _SUB_PLUGINS.duplicate()
	
	# Disable plugins in reverse order to ensure intra-plugin dependencies are
	# not broken.
	if not enable:
		plugins.reverse()
	
	for plugin in plugins:
		var plugin_name: String = _PLUGIN_NAME.path_join(plugin)
		EditorInterface.set_plugin_enabled(plugin_name, enable)
