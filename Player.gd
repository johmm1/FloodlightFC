extends CharacterBody3D

@export var player_number: int = 1
@export var move_speed: float = 7.5
@export var jump_force: float = 6.5
@export var gravity: float = 18.0

func _physics_process(delta: float) -> void:
	var input_dir: Vector3 = Vector3.ZERO

	if player_number == 1:
		if Input.is_physical_key_pressed(KEY_UP):
			input_dir.z -= 1
		if Input.is_physical_key_pressed(KEY_DOWN):
			input_dir.z += 1
		if Input.is_physical_key_pressed(KEY_LEFT):
			input_dir.x -= 1
		if Input.is_physical_key_pressed(KEY_RIGHT):
			input_dir.x += 1
		if Input.is_physical_key_pressed(KEY_TAB):
			try_jump()
	else:
		if Input.is_physical_key_pressed(KEY_W):
			input_dir.z -= 1
		if Input.is_physical_key_pressed(KEY_S):
			input_dir.z += 1
		if Input.is_physical_key_pressed(KEY_A):
			input_dir.x -= 1
		if Input.is_physical_key_pressed(KEY_D):
			input_dir.x += 1
		if Input.is_physical_key_pressed(KEY_SPACE):
			try_jump()

	if input_dir.length_squared() > 0.0:
		input_dir = input_dir.normalized()
		var angle = atan2(input_dir.x, input_dir.z)
		rotation.y = angle
		velocity.x = input_dir.x * move_speed
		velocity.z = input_dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = min(velocity.y, 0.0)

	move_and_slide()

func try_jump() -> void:
	if is_on_floor():
		velocity.y = jump_force
