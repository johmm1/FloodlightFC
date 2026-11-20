extends Control

func _ready() -> void:
	$Panel/VBoxContainer/PlayButton.grab_focus()

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_controls_button_pressed() -> void:
	$Panel/VBoxContainer/InfoLabel.text = "Touch: left joystick to move\nPASS and SHOOT: right side buttons\nSprint: hold SPRINT\nPC: WASD / arrows, Shift, J pass, K shoot"

func _on_quit_button_pressed() -> void:
	get_tree().quit()
