extends Node3D

@onready var player_1: CharacterBody3D = $Player1
@onready var player_2: CharacterBody3D = $Player2
@onready var ball: RigidBody3D = $Ball
@onready var score_label: Label = $HUD/ScoreLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var status_label: Label = $HUD/StatusLabel

var home_score: int = 0
var away_score: int = 0
var game_time: float = 90.0
var match_running: bool = true

func _ready() -> void:
	player_1.player_number = 1
	player_2.player_number = 2
	reset_positions()
	update_hud()

func _process(delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_R):
		reset_positions()
	if Input.is_physical_key_pressed(KEY_N):
		home_score = 0
		away_score = 0
		reset_positions()
		update_hud()
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		get_tree().quit()

	if match_running:
		game_time -= delta
		if game_time <= 0.0:
			game_time = 0.0
			match_running = false
			status_label.text = "Full time"
		update_hud()

func reset_positions() -> void:
	player_1.global_position = Vector3(-6.0, 1.0, 0.0)
	player_2.global_position = Vector3(6.0, 1.0, 0.0)
	player_1.velocity = Vector3.ZERO
	player_2.velocity = Vector3.ZERO
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.global_position = Vector3(0.0, 1.4, 0.0)

func update_hud() -> void:
	score_label.text = "%d - %d" % [home_score, away_score]
	timer_label.text = "Time: %02d" % max(0, int(game_time))
	if status_label.text.is_empty():
		status_label.text = "Kickoff"

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
