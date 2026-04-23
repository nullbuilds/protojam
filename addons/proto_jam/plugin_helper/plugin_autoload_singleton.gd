@tool
class_name PluginAutoloadSingleton
extends Node
## Represents an autoload added by a plugin.

var _singleton_name: String = ""
var _script_path: String = ""

## Initializes a new plugin autoload.
## 
## Defines a singleton autoload of the script at [param script_path] that will
## be registered with the name [param singleton_name].
func _init(singleton_name: String, script_path: String) -> void:
	_singleton_name = singleton_name
	_script_path = script_path


## Adds the the autoload to the project.
## 
## Adds the autoload to the porject using the given [param plugin].
## [br][br]
## This should be called from [method EditorPlugin._enable_plugin] to ensure the
## autoload is available.
func enable(plugin: EditorPlugin) -> void:
	var script_path: String = _get_script_path(plugin)
	plugin.add_autoload_singleton(_singleton_name, script_path)


## Removes the the autoload to the project.
## 
## Removes the autoload from the porject using the given [param plugin].
## [br][br]
## This should be called from [method EditorPlugin._disable_plugin] to ensure
## the autoload removed with the plugin.
func disable(plugin: EditorPlugin) -> void:
	plugin.remove_autoload_singleton(_singleton_name)


## Gets the absolute path to a script file.
## 
## Returns the absolute path to [param script_path] under [param plugin].
func _get_script_path(plugin: EditorPlugin) -> String:
	if _script_path.is_absolute_path():
		return _script_path
	
	var script: Script = plugin.get_script() as Script
	var base_path: String = "res://"
	if null != script:
		base_path = script.resource_path.get_base_dir()
	
	return base_path.path_join(_script_path)
