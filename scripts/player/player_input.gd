class_name PlayerInput
extends Node

@export var mouse_look_speed: float = 0.0174533
@export var mouse_x_sensitivity_setting: RangeSetting = null
@export var mouse_y_sensitivity_setting: RangeSetting = null
@export var mouse_invert_x_setting: BooleanSetting = null
@export var mouse_invert_y_setting: BooleanSetting = null

var _movement_amount: Vector2 = Vector2.ZERO
var _mouse_movement: Vector2 = Vector2.ZERO

func _ready() -> void:
	if null == mouse_x_sensitivity_setting:
		push_error("mouse_x_sensitivity_setting must not be null")
	
	if null == mouse_y_sensitivity_setting:
		push_error("mouse_y_sensitivity_setting must not be null")
	
	if null == mouse_invert_x_setting:
		push_error("mouse_invert_x_setting must not be null")
	
	if null == mouse_invert_y_setting:
		push_error("mouse_invert_y_setting must not be null")


func _physics_process(_delta: float) -> void:
	_movement_amount = _get_movement_vector()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.MOUSE_MODE_CAPTURED == Input.mouse_mode:
			_mouse_movement += event.screen_relative


func get_movement_amount() -> Vector2:
	return _movement_amount


func get_look_amount() -> Vector2:
	var mouse_x_sensitivity: float = mouse_x_sensitivity_setting.get_value()
	var mouse_y_sensitivity: float = mouse_y_sensitivity_setting.get_value()
	var mouse_sensitivity: Vector2 = Vector2(mouse_x_sensitivity, mouse_y_sensitivity)
	
	var mouse_input: Vector2 = _mouse_movement * mouse_sensitivity * mouse_look_speed
	_mouse_movement = Vector2.ZERO
	
	
	var delta_yaw: float = mouse_input.x
	if mouse_invert_x_setting.get_value():
		delta_yaw = -delta_yaw
	
	var delta_pitch: float = mouse_input.y
	if mouse_invert_y_setting.get_value():
		delta_pitch = -delta_pitch
	
	return Vector2(delta_yaw, delta_pitch)


func _get_movement_vector() -> Vector2:
	return Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_backward")
