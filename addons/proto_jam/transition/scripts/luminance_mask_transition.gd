@tool
class_name LuminanceMaskTransition
extends AbstractTransition
## Transitions using a mask controlled by a sweeping luminance threshold.
## 
## This is an extremely common effect dating to games as old as the '90s. A
## greyscale gradient (aka mask) covering the screen is sampled and compared
## against a minimum luminance value that sweeps from high to low depending on
## the transition type. Areas of the mask lighter than the luminance threshold
## are kept opaque while darker areas are made transparent. An optional second
## image can be displayed over opaque areas instead of black if desired.

## The mask shader
const _LUMINANCE_MASK_SHADER: Shader = preload("uid://cmfvot1v46phy")

## The canvas layer to display the transition on.
## 
## [b]Note:[/b] The value must be between
## [constant RenderingServer.CANVAS_LAYER_MIN] and
## [constant RenderingServer.CANVAS_LAYER_MAX] (inclusive).
@export_range(RenderingServer.CANVAS_LAYER_MIN, RenderingServer.CANVAS_LAYER_MAX)
var canvas_layer: int = 1:
	set(value):
		canvas_layer = value
		
		if not is_node_ready():
			await ready
		
		_canvas.layer = wrapi(value, RenderingServer.CANVAS_LAYER_MIN, RenderingServer.CANVAS_LAYER_MAX + 1)


## The greyscale mask to sample.
## 
## This image should contain a gradient spanning from pure white to pure black.
## The gradient can be cut, distorted, or otherwise modified to create various
## effects.
@export var mask_texture: Texture2D = null:
	set(value):
		mask_texture = value
		
		if not is_node_ready():
			await ready
		
		_material.set_shader_parameter("mask_texture", mask_texture)
		update_configuration_warnings()


## An optional texture to display over masked areas of the screen.
## 
## Solid black will be used if left [code]null[/code].
@export var display_texture: Texture2D = null:
	set(value):
		display_texture = value
		
		if not is_node_ready():
			await ready
		
		_material.set_shader_parameter("display_texture", display_texture)


## How long it takes to transition in as seconds.
@export_range(0.0, 3.0, 0.1, "or_greater") var transition_in_time: float = 0.5

## How long it takes to transition out as seconds.
@export_range(0.0, 3.0, 0.1, "or_greater") var transition_out_time: float = 0.5

## The minimum luminance value to mask.
@export_range(0.0, 1.0, 0.01, "or_less") var min_luminance_threshold: float = -0.001

## The maximum luminance value to mask.
@export_range(0.0, 1.0, 0.01) var max_luminance_threshold: float = 1.0

## Whether to invert the mask threshold.
@export var invert_mask: bool = false:
	set(value):
		invert_mask = value
		
		if not is_node_ready():
			await ready
		
		_material.set_shader_parameter("invert", invert_mask)


var _material: ShaderMaterial = ShaderMaterial.new()
var _canvas: CanvasLayer = CanvasLayer.new()
var _overlay: ColorRect = ColorRect.new()
var _tween: Tween = null

func _ready() -> void:
	_material.shader = _LUMINANCE_MASK_SHADER
	
	_overlay.material = _material
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.add_child(_overlay, false, Node.INTERNAL_MODE_BACK)
	
	add_child(_canvas, false, Node.INTERNAL_MODE_BACK)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if null == mask_texture:
		warnings.push_back("A mask_texture is required for LuminanceMaskTransition to work. Please create a Texture2D resource and assign it.")
	
	return warnings


func _start_transition_in() -> void:
	# Cancel previous tween, if any, since this can be called while already
	# transitioning
	_cancel_tween()
	
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	_tween = create_tween()
	_tween.tween_method(
			_adjust_luminance_cutoff,
			min_luminance_threshold,
			max_luminance_threshold,
			transition_in_time)
	_tween.tween_callback(_end_transition_in)
	_tween.tween_callback(_overlay.set.bind("mouse_filter", Control.MOUSE_FILTER_IGNORE))


func _start_transition_out() -> void:
	# Cancel previous tween, if any, since this can be called while already
	# transitioning
	_cancel_tween()
	
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_tween = create_tween()
	_tween.tween_method(
			_adjust_luminance_cutoff,
			max_luminance_threshold,
			min_luminance_threshold,
			transition_out_time)
	_tween.tween_callback(_end_transition_out)
	_tween.tween_callback(_overlay.set.bind("mouse_filter", Control.MOUSE_FILTER_STOP))


## Cancels the running tween, if any.
## 
## Users should not override this function.
func _cancel_tween() -> void:
	if is_instance_valid(_tween):
		_tween.stop()
		_tween = null


## Callback to update the luminance cutoff.
## 
## Users should not override this function.
func _adjust_luminance_cutoff(cutoff: float) -> void:
	_material.set_shader_parameter("luminance_cutoff", cutoff)
