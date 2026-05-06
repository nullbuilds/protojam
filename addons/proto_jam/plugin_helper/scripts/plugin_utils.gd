@tool
@abstract
class_name PluginUtils
extends RefCounted
## Static utilities for common plugin functions.

## Gets the absolute path to a plugin script.
## 
## Returns empty string if the path could not be determined.
static func get_plugin_path(plugin: EditorPlugin) -> String:
	var script: Script = plugin.get_script() as Script
	if null != script:
		return script.resource_path
	
	return ""


## Gets the absolute path to script file within a plugin.
## 
## Returns the absolute path to [param script_path].
static func get_plugin_script_path(plugin: EditorPlugin, script_path: String) -> String:
	if script_path.is_absolute_path():
		return script_path
	
	var plugin_path: String = get_plugin_path(plugin)
	var base_path: String = "res://"
	if not plugin_path.is_empty():
		base_path = plugin_path.get_base_dir()
	
	return base_path.path_join(script_path)


## Enables or disables sub-plugins.
## 
## Enables sub-plugins in order when [param enable] is true; otherwise, disables
## them in reverse order. [param plugin_paths] must contain the paths to each
## sub-plugin directory relative to the parent plugin's directory.
## 
## [b]Warning:[/b] the behavior of this function is untested for [param parent]
## plugins which are not top-level plugins (ie double-nesting).
static func set_enable_sub_plugins(parent: EditorPlugin,
		plugin_paths: Array[String], enable: bool) -> void:
	# Disable plugins in reverse order to ensure intra-plugin dependencies are
	# not broken.
	var sub_plugins: Array = plugin_paths.duplicate()
	if not enable:
		sub_plugins.reverse()
	
	# Find where the parent is installed
	var root_plugin_path: String = get_plugin_path(parent)
	
	if not root_plugin_path.is_empty():
		# Get the directory name of the parent
		# TODO check if this work for double-nested plugins?
		var root_name: String = root_plugin_path.get_base_dir().get_file()
		
		for sub_plugin in sub_plugins:
			var sub_plugin_path: String = root_name.path_join(sub_plugin)
			
			# Ensure we're not trying to disable a plugin which has not been
			# enabled as that causes an error (common when adding sub-plugins to
			# an already enabled plugin)
			if enable or EditorInterface.is_plugin_enabled(sub_plugin_path):
				EditorInterface.set_plugin_enabled(sub_plugin_path, enable)
	else:
		push_error("Failed to enable sub-plugins; did you install ProtoJam correctly?")
