class_name PlayerCamera
extends Node3D

@export_range(0.0, 89.0, 1.0, "radians_as_degrees") var min_pitch: float = deg_to_rad(70.0)
@export_range(0.0, 89.0, 1.0, "radians_as_degrees") var max_pitch: float = deg_to_rad(80.0)
@export var camera_position_acceleration: float = 5.0
@export var field_of_view_setting: RangeSetting = null:
	set(value):
		if field_of_view_setting == value:
			return
		
		if null != field_of_view_setting:
			if field_of_view_setting.value_changed.is_connected(_update_field_of_view):
				field_of_view_setting.value_changed.disconnect(_update_field_of_view)
		
		field_of_view_setting = value
		
		if null != field_of_view_setting:
			field_of_view_setting.value_changed.connect(_update_field_of_view)
			_update_field_of_view()


var _camera: Camera3D = Camera3D.new()
var _camera_delta_rotation: Vector3 = Vector3.ZERO

func _ready() -> void:
	if null == field_of_view_setting:
		push_error("field_of_view_setting must not be null")
	
	# Manually handle camera physics interpolation
	_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_camera.top_level = true
	_camera.rotation = global_rotation
	_camera.position = get_global_transform_interpolated().origin
	add_child(_camera, false, Node.INTERNAL_MODE_FRONT)


func _process(delta: float) -> void:
	var interpolated_transform: Transform3D = get_global_transform_interpolated()
	var interpolated_position: Vector3 = interpolated_transform.origin
	var interpolated_rotation: Vector3 = interpolated_transform.basis.get_euler()
	
	# Apply parent's interpolated rotation then apply uninterpolated delta rotation
	_camera.rotation = interpolated_rotation
	_camera.rotate_y(_camera_delta_rotation.y)
	_camera.rotate_object_local(Vector3.RIGHT, _camera_delta_rotation.x)
	
	# Move to interpolated position
	var movement_weight: float = TimeUtils.framerate_aware_lerp_weight(camera_position_acceleration, delta)
	_camera.position = _camera.position.lerp(interpolated_position, movement_weight)


func rotate_camera(delta_yaw: float, delta_pitch: float) -> void:
	_camera_delta_rotation.y += delta_yaw
	_camera_delta_rotation.x = clampf(_camera_delta_rotation.x + delta_pitch, -min_pitch, max_pitch)


func get_camera_basis() -> Basis:
	return Basis(_camera.global_basis)


func _update_field_of_view() -> void:
	_camera.fov = field_of_view_setting.get_value()
