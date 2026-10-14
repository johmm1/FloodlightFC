extends Control

func _ready() -> void:
	$VBoxContainer/PlayButton.grab_focus()

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_controls_button_pressed() -> void:
	$InfoLabel.text = "Player 1: Arrow keys + Tab\nPlayer 2: W/A/S/D + Space\nL / F: kick\nR: reset\nN: reset score\nP: pause\nEsc: quit"

func _on_quit_button_pressed() -> void:
	get_tree().quit()
