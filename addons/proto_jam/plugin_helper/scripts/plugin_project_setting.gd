@tool
class_name PluginProjectSetting
extends RefCounted
## Represents a project setting added by a plugin.

var _name: StringName
var _default: Variant
var _type: Variant.Type
var _hint: PropertyHint
var _hint_string: String

## Initializes a new plugin project setting.
func _init(name: StringName, default: Variant, type: Variant.Type, hint: PropertyHint, hint_string: String) -> void:
	_name = name
	_default = default
	_type = type
	_hint = hint
	_hint_string = hint_string


## Returns the setting.
## 
## Similar to [method ProjectSettings.get_setting_with_override] but returns the
## settings default value when undefined.
func get_setting_with_default_override() -> Variant:
	if ProjectSettings.has_setting(_name):
		return ProjectSettings.get_setting_with_override(_name)
	
	return _default


## Registers the setting with the project.
## 
## This should be called from [method EditorPlugin._enter_tree] to ensure the
## setting is available.
## [br][br]
## The setting will remain even if the plugin is disabled as removing it may
## cause data loss if the plugin is later re-enabled.
func register() -> void:
	if not ProjectSettings.has_setting(_name):
		ProjectSettings.set_setting(_name, _default)
	
	ProjectSettings.set_initial_value(_name, _default)
	ProjectSettings.add_property_info({
		"name": _name,
		"type": _type,
		"hint": _hint,
		"hint_string": _hint_string
	})


## Unregisters the setting from the project.
## 
## This should be called from [method EditorPlugin._exit_tree] to ensure the
## setting is removed when no longer in use.
## [br][br]
## The setting will remain even if the plugin is disabled if its value has been
## changed from the default. This is to prevent data loss if the user chooses
## to re-enable a plugin.
func unregister() -> void:
	if ProjectSettings.has_setting(_name):
		var value: Variant = ProjectSettings.get_setting(_name)
		if not value or value == _default:
			ProjectSettings.set_setting(_name, null)
			ProjectSettings.remove_meta(_name)
