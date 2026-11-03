extends CanvasLayer

signal restart_requested
signal main_menu_requested

@onready var overlay: Control = %Overlay
@onready var resume_button: Button = %ResumeButton

## Starts hidden so the match receives input normally.
func _ready() -> void:
	overlay.hide()

## Lets Escape pause and resume even while the rest of the tree is stopped.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle()
		get_viewport().set_input_as_handled()

## Switches between paused and active play.
func toggle() -> void:
	if overlay.visible:
		close()
	else:
		open()

## Stops the match and shows the pause controls.
func open() -> void:
	overlay.show()
	get_tree().paused = true
	resume_button.grab_focus()

## Hides the pause controls and returns to the match.
func close() -> void:
	get_tree().paused = false
	overlay.hide()

## Returns to play from the Resume button.
func _on_resume_pressed() -> void:
	close()

## Unpauses before asking the game to reset itself.
func _on_restart_pressed() -> void:
	close()
	restart_requested.emit()

## Unpauses before asking the game to leave the match.
func _on_main_menu_pressed() -> void:
	close()
	main_menu_requested.emit()
