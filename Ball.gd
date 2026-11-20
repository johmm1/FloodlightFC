extends RigidBody3D

@export var max_speed: float = 27.0

func _physics_process(_delta: float) -> void:
	var horizontal := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	if horizontal.length() > max_speed:
		horizontal = horizontal.normalized() * max_speed
		linear_velocity.x = horizontal.x
		linear_velocity.z = horizontal.z
	if global_position.y < -2.0:
		global_position = Vector3.ZERO
		linear_velocity = Vector3.ZERO
