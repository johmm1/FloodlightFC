extends RigidBody3D

@export var max_speed: float = 18.0
@export var drag: float = 0.985

func _physics_process(_delta: float) -> void:
	if linear_velocity.length() > max_speed:
		linear_velocity = linear_velocity.normalized() * max_speed
	linear_velocity *= drag
	if linear_velocity.length() < 0.05:
		linear_velocity = Vector3.ZERO
	if abs(global_position.x) > 15.8:
		global_position.x = sign(global_position.x) * 15.8
		linear_velocity.x *= -0.25
	if abs(global_position.z) > 8.8:
		global_position.z = sign(global_position.z) * 8.8
		linear_velocity.z *= -0.25
	if global_position.y < 0.8:
		global_position.y = 0.8
		linear_velocity.y = max(0.0, linear_velocity.y)

func reset_ball() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = Vector3(0.0, 1.4, 0.0)
