class_name FadeTransitionProvider
extends AbstractTransitionProvider
## Creates instances of [FadeTransition].

## The canvas layer to display the transition on.
## 
## [b]Note:[/b] The value must be between
## [constant RenderingServer.CANVAS_LAYER_MIN] and
## [constant RenderingServer.CANVAS_LAYER_MAX] (inclusive).
@export_range(RenderingServer.CANVAS_LAYER_MIN, RenderingServer.CANVAS_LAYER_MAX)
var canvas_layer: int = 1

## The color to transition out to.
@export var out_color: Color = Color.BLACK

## The color to transition in to.
@export var in_color: Color = Color(0.0, 0.0, 0.0, 0.0)

## How long it takes to transition in as seconds.
@export_range(0.0, 3.0, 0.1, "or_greater") var transition_in_time: float = 0.5

## How long it takes to transition out as seconds.
@export_range(0.0, 3.0, 0.1, "or_greater") var transition_out_time: float = 0.5

func provide() -> AbstractTransition:
	var transition: FadeTransition = FadeTransition.new()
	transition.canvas_layer = canvas_layer
	transition.out_color = out_color
	transition.in_color = in_color
	transition.transition_in_time = transition_in_time
	transition.transition_out_time = transition_out_time
	
	return transition
