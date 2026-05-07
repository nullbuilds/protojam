@tool
extends EditorPlugin
## Initializes the ProtoJam plugin.

const _SUB_PLUGINS: Array[String] = [
	"plugin_helper",
	"utils",
	"settings",
	"credits",
	"background_loader",
	"damage",
	"audio",
	"materials",
	"state_machine",
	"props",
	"transition",
	"input",
]

func _enable_plugin() -> void:
	PluginUtils.set_enable_sub_plugins(self, _SUB_PLUGINS, true)


func _disable_plugin() -> void:
	PluginUtils.set_enable_sub_plugins(self, _SUB_PLUGINS, false)
