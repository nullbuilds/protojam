class_name Player
extends CharacterBody3D

@export var walk_speed: float = 6.0
@export var friction: float = 18.5
@export var acceleration: float = 18.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _movement_direction: Vector3 = Vector3.ZERO
@onready var _camera: PlayerCamera = %PlayerCamera
@onready var _health_component: HealthComponent = %HealthComponent
@onready var _player_input: PlayerInput = %PlayerInput

func _ready() -> void:
	collision_layer = 2 # Player
	collision_mask = 1 + 4 # Blocking + Units


func _process(_delta: float) -> void:
	_update_head_orientation()


func _physics_process(delta: float) -> void:
	_update_velocity(delta)


func _update_head_orientation() -> void:
	var look_amount: Vector2 = -_player_input.get_look_amount()
	var delta_yaw: float = look_amount.x
	var delta_pitch: float = look_amount.y
	_camera.rotate_camera(delta_yaw, delta_pitch)


func _update_velocity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	
	var movement_plane: Vector3 = Vector3(1.0, 0.0, 1.0)
	var movement_amount: Vector2 = _player_input.get_movement_amount()
	
	var camera_basis: Basis = _camera.get_camera_basis()
	var movement_amount_3d: Vector3 = Vector3(movement_amount.x, 0.0, movement_amount.y)
	var forward_vector: Vector3 = (camera_basis.z * movement_plane).normalized()
	var strafe_vector: Vector3 = (camera_basis.x * movement_plane).normalized()
	movement_amount_3d = strafe_vector * movement_amount_3d.x + forward_vector * movement_amount_3d.z
	movement_amount_3d.limit_length(1.0)
	
	var target_velocity: Vector3 = movement_amount_3d * walk_speed
	var lambda: float = acceleration
	if movement_amount_3d.is_zero_approx():
		target_velocity = Vector3.ZERO
		lambda = friction
	
	var weight: float = TimeUtils.framerate_aware_lerp_weight(lambda, delta)
	_movement_direction = velocity.lerp(target_velocity, weight)
	
	velocity.x = _movement_direction.x
	velocity.z = _movement_direction.z
	
	move_and_slide()
