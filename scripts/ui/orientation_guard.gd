extends CanvasLayer

@onready var overlay: Control = %Overlay

func _ready() -> void:
	get_viewport().size_changed.connect(update_visibility)
	update_visibility()

## Covers the game in portrait when a touch device needs landscape play.
func update_visibility() -> void:
	var touch_capable := OS.get_name() in ["Web", "Android", "iOS"] and DisplayServer.is_touchscreen_available()
	touch_capable = touch_capable or OS.get_cmdline_user_args().has("--touch-ui")
	touch_capable = touch_capable or OS.get_environment("BASTION_TOUCH_PREVIEW") == "1"
	var window_size := DisplayServer.window_get_size()
	overlay.visible = touch_capable and window_size.y > window_size.x
