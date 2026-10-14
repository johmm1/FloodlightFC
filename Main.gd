extends Node3D

@onready var player_1: CharacterBody3D = $Player1
@onready var player_2: CharacterBody3D = $Player2
@onready var ball: RigidBody3D = $Ball
@onready var score_label: Label = $HUD/ScoreLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var status_label: Label = $HUD/StatusLabel
@onready var field_mesh: MeshInstance3D = $Pitch/MeshInstance3D

var home_score: int = 0
var away_score: int = 0
var match_length: float = 90.0
var time_left: float = match_length
var match_running: bool = true

func _ready() -> void:
	apply_stadium_theme()
	player_1.player_number = 1
	player_2.player_number = 2
	player_2.is_ai = true
	reset_positions()
	update_hud()
	status_label.text = "Kickoff"

func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_R):
		reset_positions()
	if Input.is_physical_key_pressed(KEY_N):
		home_score = 0
		away_score = 0
		time_left = match_length
		match_running = true
		status_label.text = "Kickoff"
		reset_positions()
		update_hud()
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		get_tree().quit()

	if match_running:
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			match_running = false
			status_label.text = "Full Time"
		update_hud()

func reset_positions() -> void:
	player_1.global_position = Vector3(-6.0, 1.0, 0.0)
	player_2.global_position = Vector3(6.0, 1.0, 0.0)
	player_1.velocity = Vector3.ZERO
	player_2.velocity = Vector3.ZERO
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.global_position = Vector3(0.0, 1.4, 0.0)
	ball.sleeping = false

func update_hud() -> void:
	score_label.text = "%d - %d" % [home_score, away_score]
	timer_label.text = "Time: %02d" % int(max(0.0, time_left))
	if status_label.text.is_empty():
		status_label.text = "Kickoff"

func apply_stadium_theme() -> void:
	var pitch_mat = StandardMaterial3D.new()
	pitch_mat.albedo_color = Color(0.08, 0.52, 0.26)
	pitch_mat.roughness = 0.8
	field_mesh.material_override = pitch_mat

	var player_1_mat = StandardMaterial3D.new()
	player_1_mat.albedo_color = Color(0.18, 0.42, 0.94)
	var player_2_mat = StandardMaterial3D.new()
	player_2_mat.albedo_color = Color(0.94, 0.25, 0.32)
	var ball_mat = StandardMaterial3D.new()
	ball_mat.albedo_color = Color(1.0, 0.82, 0.2)

	if player_1.get_node_or_null("Body") is MeshInstance3D:
		player_1.get_node("Body").material_override = player_1_mat
	if player_2.get_node_or_null("Body") is MeshInstance3D:
		player_2.get_node("Body").material_override = player_2_mat
	if ball.get_node_or_null("BallMesh") is MeshInstance3D:
		ball.get_node("BallMesh").material_override = ball_mat

func _on_home_goal_body_entered(body: Node3D) -> void:
	if body == ball:
		away_score += 1
		status_label.text = "Away score"
		reset_positions()
		update_hud()

func _on_away_goal_body_entered(body: Node3D) -> void:
	if body == ball:
		home_score += 1
		status_label.text = "Home score"
		reset_positions()
		update_hud()
