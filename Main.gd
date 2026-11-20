extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://Player.tscn")
const BALL_SCRIPT = preload("res://Ball.gd")
const FIELD_LENGTH := 100.0
const FIELD_WIDTH := 64.0
const MATCH_SECONDS := 300.0

var players: Array[CharacterBody3D] = []
var ball: RigidBody3D
var controlled_player: CharacterBody3D
var home_score := 0
var away_score := 0
var time_left := MATCH_SECONDS
var match_active := true
var paused := false
var joystick_vector := Vector2.ZERO
var sprint_held := false
var shoot_held := false
var pass_held := false
var joystick_finger := -1
var finger_actions: Dictionary = {}
var goal_cooldown := 0.0
var player_switch_timer := 0.0
var hud_score: Label
var hud_clock: Label
var hud_status: Label
var joystick_label: Label

const HOME_FORMATION := [
	Vector3(-43, 0.9, 0), Vector3(-30, 0.9, -22), Vector3(-32, 0.9, -8),
	Vector3(-32, 0.9, 8), Vector3(-30, 0.9, 22), Vector3(-15, 0.9, -16),
	Vector3(-13, 0.9, 0), Vector3(-15, 0.9, 16), Vector3(-4, 0.9, -20),
	Vector3(-3, 0.9, 0), Vector3(-4, 0.9, 20)
]
const AWAY_FORMATION := [
	Vector3(43, 0.9, 0), Vector3(30, 0.9, -22), Vector3(32, 0.9, -8),
	Vector3(32, 0.9, 8), Vector3(30, 0.9, 22), Vector3(15, 0.9, -16),
	Vector3(13, 0.9, 0), Vector3(15, 0.9, 16), Vector3(4, 0.9, -20),
	Vector3(3, 0.9, 0), Vector3(4, 0.9, 20)
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_environment()
	_build_ball()
	_spawn_teams()
	_build_hud()
	_select_nearest_player()
	_update_scoreboard()

func _process(delta: float) -> void:
	if not match_active or paused:
		return
	time_left = maxf(0.0, time_left - delta)
	goal_cooldown = maxf(0.0, goal_cooldown - delta)
	player_switch_timer -= delta
	if player_switch_timer <= 0.0:
		player_switch_timer = 1.0
		_try_auto_switch_player()
	if time_left <= 0.0:
		match_active = false
		hud_status.text = "FULL TIME"
	_update_scoreboard()
	_check_goal()

func _physics_process(_delta: float) -> void:
	if controlled_player == null or paused:
		return
	var direction := Vector3(joystick_vector.x, 0.0, joystick_vector.y)
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.z += 1.0
	controlled_player.set("move_input", Vector2(direction.x, direction.z).limit_length(1.0))
	controlled_player.set("sprinting", sprint_held or Input.is_key_pressed(KEY_SHIFT))
	if shoot_held or Input.is_key_pressed(KEY_K):
		controlled_player.set("kick_requested", true)
		shoot_held = false
	if pass_held or Input.is_key_pressed(KEY_J):
		controlled_player.set("pass_requested", true)
		pass_held = false

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		var screen := get_viewport().get_visible_rect().size
		if touch.pressed:
			if touch.position.x < screen.x * 0.48 and touch.position.y > screen.y * 0.43 and joystick_finger == -1:
				joystick_finger = touch.index
				_update_joystick(touch.position, screen)
			elif touch.position.x > screen.x * 0.62:
				var action := _action_for_position(touch.position, screen)
				finger_actions[touch.index] = action
				_set_action(action, true)
		else:
			if touch.index == joystick_finger:
				joystick_finger = -1
				joystick_vector = Vector2.ZERO
			if finger_actions.has(touch.index):
				_set_action(str(finger_actions[touch.index]), false)
				finger_actions.erase(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		var screen := get_viewport().get_visible_rect().size
		if drag.index == joystick_finger:
			_update_joystick(drag.position, screen)
		elif finger_actions.has(drag.index):
			var previous: String = str(finger_actions[drag.index])
			var next_action := _action_for_position(drag.position, screen)
			if previous != next_action:
				_set_action(previous, false)
				finger_actions[drag.index] = next_action
				_set_action(next_action, true)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_toggle_pause()

func _action_for_position(position: Vector2, screen: Vector2) -> String:
	var ratio := position.y / maxf(1.0, screen.y)
	if ratio > 0.82:
		return "sprint"
	if ratio > 0.65:
		return "pass"
	return "shoot"

func _set_action(action: String, active: bool) -> void:
	match action:
		"shoot": shoot_held = active
		"pass": pass_held = active
		"sprint": sprint_held = active

func _update_joystick(position: Vector2, screen: Vector2) -> void:
	var center := Vector2(screen.x * 0.20, screen.y * 0.76)
	var radius := minf(screen.x, screen.y) * 0.13
	joystick_vector = ((position - center) / radius).limit_length(1.0)

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.035, 0.07, 0.09)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.7, 0.78)
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -25, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = false
	add_child(sun)

	_add_box("PitchBase", Vector3(0, -0.35, 0), Vector3(FIELD_LENGTH, 0.7, FIELD_WIDTH), Color(0.035, 0.25, 0.105))
	var ground := StaticBody3D.new()
	ground.name = "PitchCollision"
	var ground_shape := CollisionShape3D.new()
	var ground_box := BoxShape3D.new()
	ground_box.size = Vector3(FIELD_LENGTH, 0.7, FIELD_WIDTH)
	ground_shape.shape = ground_box
	ground_shape.position.y = -0.35
	ground.add_child(ground_shape)
	add_child(ground)

	var camera := Camera3D.new()
	camera.name = "MatchCamera"
	camera.position = Vector3(0, 69, 79)
	camera.fov = 55.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)

	for i in range(10):
		var stripe_color := Color(0.075, 0.39, 0.17) if i % 2 == 0 else Color(0.06, 0.34, 0.145)
		_add_box("GrassStripe", Vector3(-45.0 + i * 10.0, 0.012, 0), Vector3(10.0, 0.025, FIELD_WIDTH), stripe_color)
	_add_pitch_markings()
	_build_goals_and_stands()

func _add_pitch_markings() -> void:
	var white := Color(0.88, 0.92, 0.86)
	_add_box("TouchlineTop", Vector3(0, 0.04, -31.5), Vector3(100, 0.045, 0.16), white)
	_add_box("TouchlineBottom", Vector3(0, 0.04, 31.5), Vector3(100, 0.045, 0.16), white)
	_add_box("GoalLineLeft", Vector3(-49.5, 0.04, 0), Vector3(0.16, 0.045, 63), white)
	_add_box("GoalLineRight", Vector3(49.5, 0.04, 0), Vector3(0.16, 0.045, 63), white)
	_add_box("HalfwayLine", Vector3(0, 0.045, 0), Vector3(0.12, 0.045, 63), white)
	var circle := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 9.0
	torus.outer_radius = 9.14
	circle.mesh = torus
	circle.position.y = 0.06
	var mat := StandardMaterial3D.new()
	mat.albedo_color = white
	circle.material_override = mat
	add_child(circle)
	_add_box("CenterSpot", Vector3(0, 0.07, 0), Vector3(0.35, 0.04, 0.35), white)
	for side in [-1.0, 1.0]:
		_add_box("PenaltyBox", Vector3(side * 40.0, 0.05, 0), Vector3(18, 0.045, 40), white)
		_add_box("SixYardBox", Vector3(side * 45.0, 0.052, 0), Vector3(8, 0.045, 18), white)
		_add_box("PenaltySpot", Vector3(side * 39.0, 0.07, 0), Vector3(0.35, 0.04, 0.35), white)

func _add_box(label: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	mesh_instance.material_override = material
	add_child(mesh_instance)

func _build_goals_and_stands() -> void:
	for side in [-1.0, 1.0]:
		var x := side * 51.0
		_add_box("GoalCrossbar", Vector3(x, 2.45, 0), Vector3(0.18, 0.18, 7.5), Color(0.92, 0.94, 0.91))
		for z in [-3.7, 3.7]:
			_add_box("GoalPost", Vector3(x, 1.2, z), Vector3(0.18, 2.4, 0.18), Color(0.92, 0.94, 0.91))
		_add_box("GoalNetBack", Vector3(side * 52.3, 1.2, 0), Vector3(0.08, 2.4, 7.5), Color(0.7, 0.78, 0.76, 0.45))
		_add_box("StandLong", Vector3(0, 4.0, side * 37.0), Vector3(108, 7.0, 5.0), Color(0.12, 0.16, 0.2))
		_add_box("StandEnd", Vector3(side * 57.0, 4.0, 0), Vector3(5.0, 7.0, 76), Color(0.1, 0.14, 0.18))
	for side in [-1.0, 1.0]:
		var floodlight := OmniLight3D.new()
		floodlight.position = Vector3(side * 53.0, 15.0, side * 35.0)
		floodlight.light_color = Color(0.78, 0.86, 1.0)
		floodlight.light_energy = 1.5
		floodlight.omni_range = 30.0
		floodlight.shadow_enabled = false
		add_child(floodlight)

func _build_ball() -> void:
	ball = RigidBody3D.new()
	ball.name = "Ball"
	ball.position = Vector3(0, 0.28, 0)
	ball.mass = 0.43
	ball.linear_damp = 0.35
	ball.angular_damp = 0.28
	ball.continuous_cd = true
	ball.set_script(BALL_SCRIPT)
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	var mesh := MeshInstance3D.new()
	mesh.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.96, 0.96, 0.91)
	material.roughness = 0.45
	mesh.material_override = material
	ball.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.22
	collision.shape = shape
	ball.add_child(collision)
	add_child(ball)

func _spawn_teams() -> void:
	for team in [0, 1]:
		var formation: Array = HOME_FORMATION if team == 0 else AWAY_FORMATION
		for index in range(11):
			var player := PLAYER_SCENE.instantiate() as CharacterBody3D
			player.name = ("Home_" if team == 0 else "Away_") + str(index + 1)
			player.set("team_id", team)
			player.set("player_number", index + 1)
			player.set("is_ai", true)
			player.set("home_position", formation[index])
			player.position = formation[index]
			add_child(player)
			player.set("ball_path", NodePath("../Ball"))
			players.append(player)
	_reset_kickoff()

func _try_auto_switch_player() -> void:
	if controlled_player == null:
		_select_nearest_player()
		return
	var nearest := controlled_player
	var nearest_distance := controlled_player.global_position.distance_to(ball.global_position)
	for player in players:
		if int(player.get("team_id")) != 0:
			continue
		var distance := player.global_position.distance_to(ball.global_position)
		if distance + 5.0 < nearest_distance:
			nearest = player
			nearest_distance = distance
	if nearest != controlled_player:
		controlled_player.set("controlled", false)
		controlled_player.set("is_ai", true)
		controlled_player = nearest
		controlled_player.set("controlled", true)
		controlled_player.set("is_ai", false)

func _select_nearest_player() -> void:
	var nearest: CharacterBody3D
	var best_distance := INF
	for player in players:
		if int(player.get("team_id")) != 0:
			continue
		var distance := player.global_position.distance_to(ball.global_position)
		if distance < best_distance:
			best_distance = distance
			nearest = player
	if controlled_player != null:
		controlled_player.set("controlled", false)
		controlled_player.set("is_ai", true)
	controlled_player = nearest
	if controlled_player != null:
		controlled_player.set("controlled", true)
		controlled_player.set("is_ai", false)

func _check_goal() -> void:
	if goal_cooldown > 0.0:
		return
	if absf(ball.global_position.z) > 4.0 or ball.global_position.y > 3.0:
		return
	if ball.global_position.x > 50.0:
		home_score += 1
		_goal_scored("GOAL! HOME TEAM")
	elif ball.global_position.x < -50.0:
		away_score += 1
		_goal_scored("GOAL! AWAY TEAM")

func _goal_scored(message: String) -> void:
	goal_cooldown = 2.0
	hud_status.text = message
	_update_scoreboard()
	_reset_kickoff()

func _reset_kickoff() -> void:
	for player in players:
		player.global_position = player.get("home_position")
		player.velocity = Vector3.ZERO
	ball.global_position = Vector3(0, 0.28, 0)
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.sleeping = false
	_select_nearest_player()

func _update_scoreboard() -> void:
	if hud_score:
		hud_score.text = "FLOODLIGHT FC     %d  —  %d" % [home_score, away_score]
	if hud_clock:
		var elapsed := int(MATCH_SECONDS - time_left)
		hud_clock.text = "%02d:%02d" % [elapsed / 60, elapsed % 60]

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := PanelContainer.new()
	top.anchor_left = 0.5
	top.anchor_right = 0.5
	top.offset_left = -220
	top.offset_right = 220
	top.offset_top = 14
	top.offset_bottom = 64
	layer.add_child(top)
	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(top_row)
	hud_score = Label.new()
	hud_score.add_theme_font_size_override("font_size", 20)
	top_row.add_child(hud_score)
	hud_clock = Label.new()
	hud_clock.add_theme_font_size_override("font_size", 20)
	top_row.add_child(hud_clock)

	hud_status = Label.new()
	hud_status.anchor_left = 0.5
	hud_status.anchor_right = 0.5
	hud_status.offset_left = -130
	hud_status.offset_right = 130
	hud_status.offset_top = 72
	hud_status.offset_bottom = 104
	hud_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_status.add_theme_font_size_override("font_size", 18)
	layer.add_child(hud_status)

	joystick_label = Label.new()
	joystick_label.text = "MOVE"
	joystick_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	joystick_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	joystick_label.anchor_left = 0.04
	joystick_label.anchor_top = 0.69
	joystick_label.anchor_right = 0.29
	joystick_label.anchor_bottom = 0.97
	joystick_label.add_theme_font_size_override("font_size", 18)
	layer.add_child(joystick_label)

	_make_action_button(layer, "SHOOT", 0.84, 0.56, "shoot")
	_make_action_button(layer, "PASS", 0.72, 0.72, "pass")
	_make_action_button(layer, "SPRINT", 0.84, 0.86, "sprint")

	var pause_button := Button.new()
	pause_button.text = "Ⅱ"
	pause_button.anchor_left = 0.94
	pause_button.anchor_right = 0.99
	pause_button.anchor_top = 0.04
	pause_button.anchor_bottom = 0.13
	layer.add_child(pause_button)
	pause_button.pressed.connect(_toggle_pause)

func _make_action_button(layer: CanvasLayer, caption: String, x: float, y: float, action: String) -> Button:
	var button := Button.new()
	button.text = caption
	button.anchor_left = x - 0.055
	button.anchor_right = x + 0.055
	button.anchor_top = y - 0.055
	button.anchor_bottom = y + 0.055
	button.add_theme_font_size_override("font_size", 16)
	layer.add_child(button)
	button.button_down.connect(func(): _set_action(action, true))
	button.button_up.connect(func(): _set_action(action, false))
	return button

func _toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused
	hud_status.text = "PAUSED" if paused else "PLAY"
