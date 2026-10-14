extends CharacterBody3D

@export var player_number: int = 1
@export var move_speed: float = 7.5
@export var jump_force: float = 6.5
@export var gravity: float = 20.0

func _physics_process(delta: float) -> void:
	var move_input_x: int = 0
	var move_input_z: int = 0

	if player_number == 1:
		move_input_x = int(Input.is_physical_key_pressed(KEY_RIGHT)) - int(Input.is_physical_key_pressed(KEY_LEFT))
		move_input_z = int(Input.is_physical_key_pressed(KEY_DOWN)) - int(Input.is_physical_key_pressed(KEY_UP))
		if Input.is_physical_key_pressed(KEY_TAB) and is_on_floor():
			velocity.y = jump_force
	else:
		move_input_x = int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A))
		move_input_z = int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W))
		if Input.is_physical_key_pressed(KEY_SPACE) and is_on_floor():
			velocity.y = jump_force

	var move_dir = Vector3(move_input_x, 0.0, move_input_z)
	if move_dir.length_squared() > 0.0:
		move_dir = move_dir.normalized()
		var direction_angle = atan2(move_dir.x, move_dir.z)
		rotation.y = direction_angle
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = min(velocity.y, 0.0)

	move_and_slide()

	# Keep the player from sinking into the pitch.
	if global_position.y < 1.0:
		global_position.y = 1.0
		velocity.y = max(velocity.y, 0.0)
