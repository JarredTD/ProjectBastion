extends Control

const GAME_SCENE := "res://main.tscn"

@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var settings_panel: Control = $SettingsPanel

## Gives keyboard focus to Play when the menu opens.
func _ready() -> void:
	get_tree().paused = false
	Audio.play_music(Audio.MusicState.MENU)
	play_button.grab_focus()

## Starts a new game.
func _on_play_pressed() -> void:
	Audio.play_ui_click()
	var error := get_tree().change_scene_to_file(GAME_SCENE)
	if error != OK:
		push_error("Could not start the game: %s" % error_string(error))

## Opens the shared audio settings panel.
func _on_settings_pressed() -> void:
	Audio.play_ui_click()
	settings_panel.open()

## Returns keyboard focus after closing audio settings.
func _on_settings_closed() -> void:
	settings_button.grab_focus()

## Closes the game.
func _on_quit_pressed() -> void:
	get_tree().quit()
