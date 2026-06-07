class_name LuminanceMaskTransitionProvider
extends AbstractTransitionProvider
## Creates instances of [LuminanceMaskTransition].

## The canvas layer to display the transition on.
## 
## [b]Note:[/b] The value must be between
## [constant RenderingServer.CANVAS_LAYER_MIN] and
## [constant RenderingServer.CANVAS_LAYER_MAX] (inclusive).
@export_range(RenderingServer.CANVAS_LAYER_MIN, RenderingServer.CANVAS_LAYER_MAX)
var canvas_layer: int = 1

## The greyscale mask to sample.
## 
## This image should contain a gradient spanning from pure white to pure black.
## The gradient can be cut, distorted, or otherwise modified to create various
## effects.
@export var mask_texture: Texture2D = null

## An optional texture to display over masked areas of the screen.
## 
## Solid black will be used if left [code]null[/code].
@export var display_texture: Texture2D = null

## How long it takes to transition in as seconds.
@export_range(0.0, 3.0, 0.1, "or_greater") var transition_in_time: float = 0.5

## How long it takes to transition out as seconds.
@export_range(0.0, 3.0, 0.1, "or_greater") var transition_out_time: float = 0.5

## The minimum luminance value to mask.
@export_range(0.0, 1.0, 0.01, "or_less") var min_luminance_threshold: float = -0.001

## The maximum luminance value to mask.
@export_range(0.0, 1.0, 0.01) var max_luminance_threshold: float = 1.0

## Whether to invert the mask threshold.
@export var invert_mask: bool = false

func provide() -> AbstractTransition:
	var transition: LuminanceMaskTransition = LuminanceMaskTransition.new()
	transition.canvas_layer = canvas_layer
	transition.mask_texture = mask_texture
	transition.display_texture = display_texture
	transition.transition_in_time = transition_in_time
	transition.transition_out_time = transition_out_time
	transition.min_luminance_threshold = min_luminance_threshold
	transition.max_luminance_threshold = max_luminance_threshold
	transition.invert_mask = invert_mask
	
	return transition
