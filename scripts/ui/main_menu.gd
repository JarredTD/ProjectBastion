extends Control

const GAME_SCENE := "res://main.tscn"

@onready var play_button: Button = %PlayButton

## Gives keyboard focus to Play when the menu opens.
func _ready() -> void:
	get_tree().paused = false
	play_button.grab_focus()

## Starts a new game.
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

## Closes the game.
func _on_quit_pressed() -> void:
	get_tree().quit()
