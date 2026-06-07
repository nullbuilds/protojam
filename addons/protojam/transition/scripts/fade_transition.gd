class_name FadeTransition
extends AbstractTransition
## Transitions between clear and a desired color.

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


## The color to transition out to.
@export var out_color: Color = Color.BLACK

## The color to transition in to.
@export var in_color: Color = Color(0.0, 0.0, 0.0, 0.0)

## How long it takes to transition in as seconds.
@export_range(0.0, 3.0, 0.1, "or_greater") var transition_in_time: float = 0.5

## How long it takes to transition out as seconds.
@export_range(0.0, 3.0, 0.1, "or_greater") var transition_out_time: float = 0.5

var _canvas: CanvasLayer = CanvasLayer.new()
var _overlay: ColorRect = ColorRect.new()
var _tween: Tween = null

func _ready() -> void:
	_overlay.color = out_color
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.add_child(_overlay, false, Node.INTERNAL_MODE_BACK)
	
	add_child(_canvas, false, Node.INTERNAL_MODE_BACK)


func _start_transition_in() -> void:
	# Cancel previous tween, if any, since this can be called while already
	# transitioning
	_cancel_tween()
	
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	
	_tween = create_tween()
	_tween.tween_property(_overlay, "color", in_color, transition_in_time).from(out_color)
	_tween.tween_callback(_end_transition_in)
	_tween.tween_callback(_overlay.set.bind("mouse_filter", Control.MOUSE_FILTER_IGNORE))


func _start_transition_out() -> void:
	# Cancel previous tween, if any, since this can be called while already
	# transitioning
	_cancel_tween()
	
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_tween = create_tween()
	_tween.tween_property(_overlay, "color", out_color, transition_out_time).from(in_color)
	_tween.tween_callback(_end_transition_out)
	_tween.tween_callback(_overlay.set.bind("mouse_filter", Control.MOUSE_FILTER_STOP))


## Cancels the running tween, if any.
## 
## Users should not override this function.
func _cancel_tween() -> void:
	if is_instance_valid(_tween):
		_tween.stop()
		_tween = null
