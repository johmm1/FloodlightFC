extends CharacterBody3D

@export var player_number: int = 1
@export var is_ai: bool = false
@export var move_speed: float = 7.5
@export var sprint_multiplier: float = 1.35
@export var acceleration: float = 11.0
@export var friction: float = 12.0
@export var jump_force: float = 7.0
@export var gravity: float = 22.0
@export var kick_power: float = 14.0
@export var ball_path: NodePath

var ball: RigidBody3D
var kick_cooldown: float = 0.0

func _ready() -> void:
	if not ball_path.is_empty():
		ball = get_node(ball_path)

func _physics_process(delta: float) -> void:
	if ball == null and not ball_path.is_empty():
		ball = get_node(ball_path)

	var move_dir = Vector3.ZERO
	var current_speed = move_speed

	if is_ai:
		var target_vec = ball.global_position - global_position
		target_vec.y = 0.0
		if target_vec.length_squared() > 0.01:
			move_dir = target_vec.normalized()
			if global_position.distance_to(ball.global_position) < 1.6:
				move_dir = Vector3.ZERO
				if global_position.x < ball.global_position.x:
					move_dir.x = 1.0
				else:
					move_dir.x = -1.0
				if abs(ball.global_position.z - global_position.z) > 1.5:
					move_dir.z = sign(ball.global_position.z - global_position.z)
		current_speed = move_speed * 1.15
	else:
		var sprinting := false
		if player_number == 1:
			sprinting = Input.is_physical_key_pressed(KEY_SHIFT)
		else:
			sprinting = Input.is_physical_key_pressed(KEY_CONTROL)
		current_speed = move_speed * sprint_multiplier if sprinting else move_speed

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
		move_dir = Vector3(move_input_x, 0.0, move_input_z)

	if move_dir.length_squared() > 0.0:
		move_dir = move_dir.normalized()
		var direction_angle = atan2(move_dir.x, move_dir.z)
		rotation.y = direction_angle
		velocity.x = lerp(velocity.x, move_dir.x * current_speed, min(1.0, acceleration * delta))
		velocity.z = lerp(velocity.z, move_dir.z * current_speed, min(1.0, acceleration * delta))
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction)
		velocity.z = move_toward(velocity.z, 0.0, friction)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = min(velocity.y, 0.0)

	move_and_slide()
	if global_position.y < 1.0:
		global_position.y = 1.0
		velocity.y = max(velocity.y, 0.0)

	kick_cooldown = max(0.0, kick_cooldown - delta)
	if ball != null:
		try_kick()

func try_kick() -> void:
	if kick_cooldown > 0.0:
		return

	var kick_key: int = KEY_L if player_number == 1 else KEY_F
	if not is_ai:
		if not Input.is_physical_key_pressed(kick_key):
			return
		if global_position.distance_to(ball.global_position) > 1.8:
			return
	else:
		if global_position.distance_to(ball.global_position) > 1.4:
			return
		if abs(ball.global_position.x - global_position.x) > 1.5:
			return

	var kick_dir = (ball.global_position - global_position)
	if kick_dir.length_squared() < 0.01:
		kick_dir = Vector3(0.0, 0.0, 1.0) if player_number == 1 else Vector3(0.0, 0.0, -1.0)
	kick_dir.y = 0.35
	kick_dir = kick_dir.normalized()
	ball.apply_central_impulse(kick_dir * kick_power)
	kick_cooldown = 0.25
