@abstract
class_name TimeUtils
extends RefCounted
## Static utilities for dealing with time.

const _MILLIS_PER_CENTI: int = 10
const _CENTIS_PER_SECOND: int = 100
const _MILLIS_PER_SECOND: int = 1000
const _SECONDS_PER_MINUTE: int = 60
const _CENTIS_PER_MINUTE: int = _CENTIS_PER_SECOND * _SECONDS_PER_MINUTE
const _MILLIS_PER_MINUTE: int = _MILLIS_PER_SECOND * _SECONDS_PER_MINUTE

## Returns a weight between [0.0, 1.0) suitable for passing to a
## [code]lerp[/code] function to make it framerate independent.
## 
## Passing the return value of this function into the weight of a [method lerp]
## function and assigning the result back to the original variable produces an
## exponential decay. A higher [param lambda] produces a faster transition.
## [param delta] must be set to the [method Node.get_process_delta_time] or
## [method Node.get_physics_process_delta_time] of the current frame depending
## on whether this is called from [method Node._process] or
## [method Node._physics_process] respectively. Neither [param lambda] nor
## [param delta] may be negative.
## [br][br]
## Be aware the return value will never reach 1.0. It will become impercetibly
## close but some applications may need to snap the result to prevent jitter.
## [br][br]
## Usage:
## [codeblock]
## class_name Player
## extends CharacterBody3D
## 
## func _physics_process(delta: float) -> void:
##     # Slow to a stop
##     var weight: float = TimeUtils.framerate_aware_lerp_weight(2.0, delta)
##     velocity = velocity.lerp(Vector3.ZERO, weight)
##     move_and_slide() 
## [/codeblock]
## [br][br]
## See [url]https://www.rorydriscoll.com/2016/03/07/frame-rate-independent-damping-using-lerp/[/url]
static func framerate_aware_lerp_weight(lambda: float, delta: float) -> float:
	# Exponential decay does not work with a negative exponent as raising e to a
	# positive number will exceed 1.0. Raising e to a negative number approaches
	# zero keeping it bounded between (0.0, 1.0].
	lambda = max(lambda, 0.0)
	delta = max(delta, 0.0)
	
	return 1.0 - exp(-lambda * delta)


## Converts [param minutes] to milliseconds.
static func minutes_to_millis(minutes: Variant) -> int:
	return floor(minutes * _MILLIS_PER_MINUTE)


## Converts [param seconds] to milliseconds.
static func seconds_to_millis(seconds: Variant) -> int:
	return floor(seconds * _MILLIS_PER_SECOND)


## Converts [param minutes] to centiseconds.
static func minutes_to_centis(minutes: Variant) -> int:
	return floor(minutes * _CENTIS_PER_MINUTE)


## Converts [param seconds] to centiseconds.
static func seconds_to_centis(seconds: Variant) -> int:
	return floor(seconds * _CENTIS_PER_SECOND)


## Converts [param millis] to centiseconds.
static func millis_to_centis(millis: Variant) -> int:
	return floor(millis / _MILLIS_PER_CENTI)


# Converts [param millis] to whole minutes.
static func millis_to_minutes(millis: int) -> int:
	return floor(millis / float(_MILLIS_PER_MINUTE))


## Converts [param millis] to whole seconds.
static func millis_to_seconds(millis: int) -> int:
	return floor(millis / float(_MILLIS_PER_SECOND))


## Converts [param centis] to whole minutes.
static func centis_to_minutes(centis: int) -> int:
	return floor(centis / float(_CENTIS_PER_MINUTE))


## Converts [param centis] to whole seconds.
static func centis_to_seconds(centis: int) -> int:
	return floor(centis / float(_CENTIS_PER_SECOND))


## Formats an elapsed time in milliseconds to a mm:ss:SS or mm:ss.SSS format.
## 
## By default, the time is formatted with centisecond precision. Setting
## [param full_precision] to [code]true[/code] returns the time in millisecond
## precision.
static func format_stopwatch(millis: int, full_precision: bool = false) -> String:
	if not full_precision:
		var centis: int = millis_to_centis(millis)
		return _format_stopwatch_centis(centis)
	
	return _format_stopwatch_millis(millis)


## Formats an elapsed time in milliseconds to a mm:ss.SSS format.
static func _format_stopwatch_millis(millis: int) -> String:
	var remaining_millis: int = millis
	
	var minutes: int = millis_to_minutes(millis)
	remaining_millis -= minutes_to_millis(minutes)
	
	var seconds: int = millis_to_seconds(remaining_millis)
	remaining_millis -= seconds_to_millis(seconds)
	
	return "%02d:%02d:%03d" % [minutes, seconds, remaining_millis]


## Formats an elapsed time in centiseconds to a mm:ss:SS format.
static func _format_stopwatch_centis(centis: int) -> String:
	var remaining_centis: int = centis
	
	var minutes: int = centis_to_minutes(centis)
	remaining_centis -= minutes_to_centis(minutes)
	
	var seconds: int = centis_to_seconds(remaining_centis)
	remaining_centis -= seconds_to_centis(seconds)
	
	return "%02d:%02d:%02d" % [minutes, seconds, remaining_centis]
