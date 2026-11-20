extends CharacterBody3D

signal foul_committed(foul_position: Vector3, offending_team: int)

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
var kick_animation_time := 0.0
var kick_leg_left := true
var keeper_dive_cooldown := 0.0
var keeper_dive_time := 0.0
var tackle_requested := false
var tackle_cooldown := 0.0
var tackle_time := 0.0
var shirt_material: StandardMaterial3D

func _ready() -> void:
	add_to_group("football_players")
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	floor_snap_length = 0.25
	_build_player_model()
	if not ball_path.is_empty():
		ball = get_node_or_null(ball_path)

func _build_player_model() -> void:
	var kit_color := Color(0.055, 0.22, 0.78) if team_id == 0 else Color(0.82, 0.075, 0.095)
	var trim_color := Color(0.92, 0.91, 0.78) if team_id == 0 else Color(0.08, 0.08, 0.1)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.43, 0.27, 0.19) if player_number % 3 == 0 else Color(0.66, 0.43, 0.29)
	skin.roughness = 0.88
	shirt_material = StandardMaterial3D.new()
	shirt_material.albedo_color = kit_color
	shirt_material.roughness = 0.82
	var trim := StandardMaterial3D.new()
	trim.albedo_color = trim_color
	trim.roughness = 0.82

	# Anatomical torso and kit details.
	var torso := MeshInstance3D.new()
	torso.name = "Torso"
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.255
	torso_mesh.height = 0.92
	torso.mesh = torso_mesh
	torso.position.y = 1.12
	torso.material_override = shirt_material
	add_child(torso)

	var shorts := MeshInstance3D.new()
	var shorts_mesh := BoxMesh.new()
	shorts_mesh.size = Vector3(0.43, 0.34, 0.29)
	shorts.mesh = shorts_mesh
	shorts.position = Vector3(0, 0.67, 0)
	shorts.material_override = trim
	add_child(shorts)

	# Neck, head and hair cap.
	var neck := MeshInstance3D.new()
	var neck_mesh := CylinderMesh.new()
	neck_mesh.top_radius = 0.085
	neck_mesh.bottom_radius = 0.095
	neck_mesh.height = 0.18
	neck.mesh = neck_mesh
	neck.position.y = 1.66
	neck.material_override = skin
	add_child(neck)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.165
	head_mesh.height = 0.36
	head.mesh = head_mesh
	head.position = Vector3(0, 1.84, 0)
	head.material_override = skin
	add_child(head)

	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.168
	hair_mesh.height = 0.18
	hair.mesh = hair_mesh
	hair.position = Vector3(0, 1.96, 0.012)
	var hair_mat := StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.055, 0.04, 0.03)
	hair.material_override = hair_mat
	add_child(hair)

	# Number panel on the back of each shirt.
	var number := Label3D.new()
	number.text = str(player_number)
	number.font_size = 32
	number.pixel_size = 0.006
	number.position = Vector3(0, 1.22, 0.258)
	number.rotation.y = PI
	number.modulate = Color.WHITE
	add_child(number)

	# Pivoted limbs provide a lightweight animated rig without external assets.
	var left_arm := _make_limb("LeftArm", Vector3(-0.29, 1.43, 0), 0.63, 0.105, shirt_material, true)
	var right_arm := _make_limb("RightArm", Vector3(0.29, 1.43, 0), 0.63, 0.105, shirt_material, true)
	var left_leg := _make_limb("LeftLeg", Vector3(-0.13, 0.62, 0), 0.66, 0.115, trim, false)
	var right_leg := _make_limb("RightLeg", Vector3(0.13, 0.62, 0), 0.66, 0.115, trim, false)
	set_meta("left_arm", left_arm)
	set_meta("right_arm", right_arm)
	set_meta("left_leg", left_leg)
	set_meta("right_leg", right_leg)

	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null:
		collision = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		add_child(collision)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.29
	shape.height = 1.85
	collision.shape = shape
	collision.position.y = 0.92

func _make_limb(limb_name: String, pivot_position: Vector3, length: float, radius: float, material: Material, arm: bool) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = limb_name
	pivot.position = pivot_position
	add_child(pivot)

	var segment := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = length
	segment.mesh = capsule
	segment.position.y = -length * 0.5
	segment.material_override = material
	pivot.add_child(segment)

	if arm:
		var hand := MeshInstance3D.new()
		var hand_mesh := SphereMesh.new()
		hand_mesh.radius = 0.09
		hand_mesh.height = 0.18
		hand.mesh = hand_mesh
		hand.position.y = -length * 0.93
		var hand_material := StandardMaterial3D.new()
		hand_material.albedo_color = Color(0.62, 0.4, 0.27)
		hand.material_override = hand_material
		pivot.add_child(hand)
	else:
		var boot := MeshInstance3D.new()
		var boot_mesh := BoxMesh.new()
		boot_mesh.size = Vector3(0.2, 0.13, 0.34)
		boot.mesh = boot_mesh
		boot.position = Vector3(0, -length * 0.94, -0.065)
		var boot_material := StandardMaterial3D.new()
		boot_material.albedo_color = Color(0.035, 0.035, 0.04)
		boot.material_override = boot_material
		pivot.add_child(boot)
	return pivot

func _physics_process(delta: float) -> void:
	if ball == null and not ball_path.is_empty():
		ball = get_node_or_null(ball_path)
	kick_cooldown = maxf(0.0, kick_cooldown - delta)
	keeper_dive_cooldown = maxf(0.0, keeper_dive_cooldown - delta)
	keeper_dive_time = maxf(0.0, keeper_dive_time - delta)
	tackle_cooldown = maxf(0.0, tackle_cooldown - delta)
	tackle_time = maxf(0.0, tackle_time - delta)
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
		rotation.y = atan2(-direction.x, -direction.z)
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
	_animate_locomotion(delta)
	if tackle_requested:
		_try_tackle()
	if is_ai and not controlled:
		_try_ai_tackle()
	if is_ai and player_number == 1:
		_try_goalkeeper_save()
	_update_dribble_control(delta)
	if controlled and kick_requested:
		_try_kick(false)
	if controlled and pass_requested:
		_try_kick(true)
	if not controlled and ball != null and global_position.distance_to(ball.global_position) < 1.65 and kick_cooldown <= 0.0:
		var attack_direction := Vector3(1.0 if team_id == 0 else -1.0, 0.12, -ball.global_position.z * 0.025).normalized()
		ball.sleeping = false
		ball.apply_central_impulse(attack_direction * 10.5)
		kick_cooldown = 0.75
	kick_requested = false
	pass_requested = false

func _animate_locomotion(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var gait_speed := 0.0
	if horizontal_speed > 0.15:
		gait_speed = horizontal_speed / maxf(move_speed, 0.1)
	var phase := float(get_meta("gait_phase", 0.0)) + delta * (8.5 if sprinting else 6.2) * gait_speed
	set_meta("gait_phase", phase)
	var swing := sin(phase) * 0.58 * minf(gait_speed, 1.25)
	kick_animation_time = maxf(0.0, kick_animation_time - delta)
	var kick_swing := 0.0
	if kick_animation_time > 0.0:
		var kick_phase := 1.0 - kick_animation_time / 0.34
		kick_swing = sin(kick_phase * PI) * 1.05
	var left_leg := get_meta("left_leg") as Node3D
	var right_leg := get_meta("right_leg") as Node3D
	var left_arm := get_meta("left_arm") as Node3D
	var right_arm := get_meta("right_arm") as Node3D
	if left_leg and right_leg:
		left_leg.rotation.x = swing + (kick_swing if kick_leg_left else 0.0)
		right_leg.rotation.x = -swing + (kick_swing if not kick_leg_left else 0.0)
	if tackle_time > 0.0:
		rotation.x = lerpf(rotation.x, -0.28, 0.35)
	else:
		rotation.x = lerpf(rotation.x, 0.0, 0.2)
	if left_arm and right_arm:
		var dive_spread := 0.0
		if keeper_dive_time > 0.0 and player_number == 1:
			dive_spread = 1.15
		left_arm.rotation.x = -swing * 0.72 - dive_spread
		right_arm.rotation.x = swing * 0.72 - dive_spread
		left_arm.rotation.z = dive_spread * 0.65
		right_arm.rotation.z = -dive_spread * 0.65
func _get_ai_direction() -> Vector3:
	if ball == null:
		return Vector3.ZERO
	if player_number == 1:
		return _get_goalkeeper_direction()

	var target := _get_formation_target()
	var to_ball := ball.global_position - global_position
	to_ball.y = 0.0
	var distance := to_ball.length()
	var team_has_ball := _team_has_possession()
	var closest_teammate := _is_closest_teammate_to_ball()

	# Only the nearest defender presses aggressively; nearby midfielders offer cover.
	if not team_has_ball and distance < 13.0 and (closest_teammate or (player_number >= 6 and player_number <= 8 and distance < 8.0)):
		var approach_side := -1.6 if team_id == 0 else 1.6
		target = ball.global_position + Vector3(approach_side, 0.0, 0.0)
	elif team_has_ball and player_number >= 9:
		# Forward line attacks space beyond the ball while keeping wide players wide.
		var forward := 1.0 if team_id == 0 else -1.0
		var run_depth := 7.0 if player_number == 10 else 5.0
		target.x = maxf(home_position.x, ball.global_position.x) + forward * run_depth if team_id == 0 else minf(home_position.x, ball.global_position.x) - run_depth
		target.z = home_position.z * 0.88 + ball.global_position.z * 0.12
	var offset := target - global_position
	offset.y = 0.0
	if offset.length() < 0.8:
		return Vector3.ZERO
	return offset.normalized()

func _team_has_possession() -> bool:
	var nearest_distance := INF
	var nearest_team := -1
	for node in get_tree().get_nodes_in_group("football_players"):
		var teammate := node as CharacterBody3D
		if teammate == null:
			continue
		var distance := teammate.global_position.distance_to(ball.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_team = int(teammate.get("team_id"))
	return nearest_team == team_id

func _is_closest_teammate_to_ball() -> bool:
	var my_distance := global_position.distance_to(ball.global_position)
	for node in get_tree().get_nodes_in_group("football_players"):
		var teammate := node as CharacterBody3D
		if teammate == null or teammate == self or int(teammate.get("team_id")) != team_id:
			continue
		if teammate.global_position.distance_to(ball.global_position) + 0.05 < my_distance:
			return false
	return true

func _get_formation_target() -> Vector3:
	var target := home_position
	var forward := 1.0 if team_id == 0 else -1.0
	var ball_x := ball.global_position.x
	var ball_z := ball.global_position.z
	var has_ball := _team_has_possession()

	# The whole block shifts with play, but each line keeps its own spacing.
	target.z += clampf(ball_z * 0.20, -6.0, 6.0)
	if has_ball:
		var line_advance := 0.0
		if player_number >= 9:
			line_advance = 9.0 if player_number == 10 else 6.0
		elif player_number >= 6:
			line_advance = 4.0
		else:
			line_advance = 1.5
		target.x += forward * line_advance
		target.x += clampf((ball_x - home_position.x) * 0.10, -5.0, 5.0)
	else:
		target.x += clampf((ball_x - home_position.x) * 0.17, -8.0, 8.0)
	# Wide forwards and fullbacks preserve width instead of collapsing onto the ball.
	if player_number == 2 or player_number == 5 or player_number == 9 or player_number == 11:
		target.z = signf(home_position.z) * maxf(12.0, absf(target.z))
	target.x = clampf(target.x, -43.0, 43.0)
	target.z = clampf(target.z, -27.0, 27.0)
	return target


func _try_tackle() -> void:
	tackle_requested = false
	if ball == null or tackle_cooldown > 0.0:
		return
	var nearest_opponent: CharacterBody3D
	var nearest_distance := 2.0
	for node in get_tree().get_nodes_in_group("football_players"):
		var opponent := node as CharacterBody3D
		if opponent == null or opponent == self or int(opponent.get("team_id")) == team_id:
			continue
		var distance := global_position.distance_to(opponent.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_opponent = opponent
	var ball_distance := global_position.distance_to(ball.global_position)
	if ball_distance > 2.8 or nearest_distance > 1.8:
		return
	# A late challenge from behind the opponent is treated as a foul.
	var opponent_ball_distance := nearest_opponent.global_position.distance_to(ball.global_position)
	if opponent_ball_distance + 0.18 < ball_distance and nearest_distance < 1.3:
		tackle_time = 0.42
		tackle_cooldown = 1.15
		foul_committed.emit(global_position, team_id)
		return
	var toward_ball := ball.global_position - global_position
	toward_ball.y = 0.0
	if toward_ball.length_squared() < 0.01:
		toward_ball = -global_transform.basis.z
	toward_ball = toward_ball.normalized()
	ball.sleeping = false
	ball.apply_central_impulse((toward_ball + Vector3(0.0, 0.06, 0.0)).normalized() * 5.2)
	nearest_opponent.velocity += -toward_ball * 2.2
	tackle_time = 0.42
	tackle_cooldown = 1.15

func _try_ai_tackle() -> void:
	if ball == null or tackle_cooldown > 0.0 or global_position.distance_to(ball.global_position) > 2.2:
		return
	for node in get_tree().get_nodes_in_group("football_players"):
		var opponent := node as CharacterBody3D
		if opponent == null or opponent == self or int(opponent.get("team_id")) == team_id:
			continue
		if global_position.distance_to(opponent.global_position) < 1.35:
			tackle_requested = true
			_try_tackle()
			return

func _get_goalkeeper_direction() -> Vector3:
	var goal_x := -44.0 if team_id == 0 else 44.0
	var ball_threatening := (ball.global_position.x < -30.0) if team_id == 0 else (ball.global_position.x > 30.0)
	var target := Vector3(goal_x, 0.0, clampf(ball.global_position.z * 0.72, -3.0, 3.0))
	if ball_threatening:
		target.x = goal_x + (5.0 if team_id == 0 else -5.0)
		target.z = clampf(ball.global_position.z, -5.2, 5.2)
	var offset := target - global_position
	offset.y = 0.0
	if offset.length() < 0.55:
		return Vector3.ZERO
	return offset.normalized()

func _try_goalkeeper_save() -> void:
	if ball == null:
		return
	var to_ball := ball.global_position - global_position
	var flat_distance := Vector2(to_ball.x, to_ball.z).length()
	var goal_side := (ball.global_position.x < global_position.x) if team_id == 0 else (ball.global_position.x > global_position.x)
	if flat_distance < 8.0 and absf(to_ball.z) > 1.0 and keeper_dive_cooldown <= 0.0 and goal_side:
		keeper_dive_time = 0.48
		keeper_dive_cooldown = 1.15
		velocity.z += signf(to_ball.z) * 3.2
	if flat_distance < 1.45 and ball.global_position.y < 2.8 and absf(ball.global_position.z) < 7.0:
		var clear_direction := Vector3(1.0 if team_id == 0 else -1.0, 0.28, signf(ball.global_position.z) * 0.12).normalized()
		ball.sleeping = false
		ball.linear_velocity = Vector3.ZERO
		ball.apply_central_impulse(clear_direction * 11.5)
		keeper_dive_time = 0.3
		keeper_dive_cooldown = 1.0

func _update_dribble_control(delta: float) -> void:
	if not controlled or ball == null or move_input.length_squared() < 0.04 or kick_cooldown > 0.12:
		return
	var to_ball := ball.global_position - global_position
	to_ball.y = 0.0
	var distance := to_ball.length()
	if distance < 0.55 or distance > 1.65:
		return
	var forward := -global_transform.basis.z
	var target_position := global_position + forward * 1.05
	target_position.y = ball.global_position.y
	var desired_velocity := (target_position - ball.global_position) * 3.0
	desired_velocity = desired_velocity.limit_length(4.2)
	var velocity_error := desired_velocity - ball.linear_velocity
	velocity_error.y = 0.0
	ball.sleeping = false
	ball.apply_central_force(velocity_error * ball.mass * 7.5)

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
	kick_leg_left = player_number % 2 == 0
	kick_animation_time = 0.34
	kick_cooldown = 0.38
