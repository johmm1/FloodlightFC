extends CharacterBody3D

@export var player_number: int = 1
@export var is_ai: bool = true
@export var team_id: int = 0
@export var move_speed: float = 6.2
@export var acceleration: float = 13.0
@export var ball_path: NodePath

var ball: RigidBody3D
var home_position: Vector3 = Vector3.ZERO
var controlled := false
var move_input := Vector2.ZERO
var sprinting := false
var kick_requested := false
var pass_requested := false
var kick_cooldown := 0.0
var shirt_material: StandardMaterial3D

func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	floor_snap_length = 0.25
	_build_player_model()
	if not ball_path.is_empty():
		ball = get_node_or_null(ball_path)

func _build_player_model() -> void:
	var torso := get_node_or_null("Body") as MeshInstance3D
	if torso == null:
		torso = MeshInstance3D.new()
		torso.name = "Body"
		add_child(torso)
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.32
	capsule.height = 1.05
	torso.mesh = capsule
	torso.position.y = 1.05
	shirt_material = StandardMaterial3D.new()
	shirt_material.albedo_color = Color(0.08, 0.32, 0.9) if team_id == 0 else Color(0.88, 0.12, 0.16)
	shirt_material.roughness = 0.78
	torso.material_override = shirt_material

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.19
	head_mesh.height = 0.38
	head.mesh = head_mesh
	head.position = Vector3(0, 1.76, 0)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.62, 0.39, 0.25)
	head.material_override = skin
	add_child(head)

	var shorts := MeshInstance3D.new()
	var shorts_mesh := BoxMesh.new()
	shorts_mesh.size = Vector3(0.48, 0.34, 0.32)
	shorts.mesh = shorts_mesh
	shorts.position.y = 0.55
	var shorts_mat := StandardMaterial3D.new()
	shorts_mat.albedo_color = Color(0.07, 0.08, 0.11) if team_id == 0 else Color(0.92, 0.92, 0.88)
	shorts.material_override = shorts_mat
	add_child(shorts)

	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		add_child(collision)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9

func _physics_process(delta: float) -> void:
	if ball == null and not ball_path.is_empty():
		ball = get_node_or_null(ball_path)
	kick_cooldown = maxf(0.0, kick_cooldown - delta)
	var direction := Vector3.ZERO
	var speed := move_speed
	if controlled:
		direction = Vector3(move_input.x, 0.0, move_input.y)
		if sprinting:
			speed *= 1.28
	else:
		direction = _get_ai_direction()
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	if direction.length_squared() > 0.001:
		var target_velocity := direction * speed
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
		rotation.y = atan2(direction.x, direction.z)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * 0.65 * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * 0.65 * delta)
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = -0.2
	move_and_slide()
	global_position.x = clampf(global_position.x, -48.0, 48.0)
	global_position.z = clampf(global_position.z, -30.0, 30.0)
	if controlled and kick_requested:
		_try_kick(false)
	if controlled and pass_requested:
		_try_kick(true)
	kick_requested = false
	pass_requested = false

func _get_ai_direction() -> Vector3:
	if ball == null:
		return Vector3.ZERO
	var to_ball := ball.global_position - global_position
	to_ball.y = 0.0
	var distance := to_ball.length()
	var target := home_position
	var attacking_right := team_id == 0
	var ball_on_our_half := (ball.global_position.x < 0.0) if team_id == 0 else (ball.global_position.x > 0.0)
	if distance < 15.0 and (ball_on_our_half or distance < 8.0):
		target = ball.global_position + Vector3(-2.0 if attacking_right else 2.0, 0.0, 0.0)
	else:
		target.x += clampf(ball.global_position.x * 0.22, -9.0, 9.0)
		target.z += clampf(ball.global_position.z * 0.25, -7.0, 7.0)
	var offset := target - global_position
	offset.y = 0.0
	if offset.length() < 1.0:
		return Vector3.ZERO
	return offset.normalized()

func _try_kick(is_pass: bool) -> void:
	if ball == null or kick_cooldown > 0.0 or global_position.distance_to(ball.global_position) > 2.0:
		return
	var forward := -global_transform.basis.z
	var target_direction := forward
	if is_pass:
		target_direction = (Vector3(home_position.x + (8.0 if team_id == 0 else -8.0), 0.25, home_position.z) - ball.global_position).normalized()
	else:
		target_direction = (forward + Vector3(0.0, 0.16, 0.0)).normalized()
	ball.sleeping = false
	ball.apply_central_impulse(target_direction * (8.5 if is_pass else 15.5))
	kick_cooldown = 0.38
