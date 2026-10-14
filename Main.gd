extends Node3D

@onready var player_1: CharacterBody3D = $Player1
@onready var player_2: CharacterBody3D = $Player2
@onready var ball: RigidBody3D = $Ball
@onready var result_label: Label = $HUD/ResultLabel

var player_1_score: int = 0
var player_2_score: int = 0

func _ready() -> void:
	reset_positions()
	result_label.text = "Floodlight FC"

func _process(_delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_R):
		reset_positions()
	if Input.is_physical_key_pressed(KEY_N):
		player_1_score = 0
		player_2_score = 0
		update_scoreboard()
		reset_positions()
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		get_tree().quit()

func reset_positions() -> void:
	player_1.global_position = Vector3(-6.0, 1.0, 0.0)
	player_2.global_position = Vector3(6.0, 1.0, 0.0)
	player_1.velocity = Vector3.ZERO
	player_2.velocity = Vector3.ZERO
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.global_position = Vector3(0.0, 1.5, 0.0)

func update_scoreboard() -> void:
	$HUD/Player1ScoreLabel.text = "Home: %d" % player_1_score
	$HUD/Player2ScoreLabel.text = "Away: %d" % player_2_score

func _on_player_1_goal_body_entered(body: Node3D) -> void:
	if body == ball:
		player_2_score += 1
		result_label.text = "Away scores!"
		update_scoreboard()
		reset_positions()

func _on_player_2_goal_body_entered(body: Node3D) -> void:
	if body == ball:
		player_1_score += 1
		result_label.text = "Home scores!"
		update_scoreboard()
		reset_positions()
