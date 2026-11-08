extends CanvasLayer

@onready var overlay: Control = %Overlay

func _ready() -> void:
	get_viewport().size_changed.connect(update_visibility)
	update_visibility()

## Covers the game in portrait when a touch device needs landscape play.
func update_visibility() -> void:
	var touch_capable := DisplayServer.is_touchscreen_available()
	touch_capable = touch_capable or OS.get_cmdline_user_args().has("--touch-ui")
	touch_capable = touch_capable or OS.get_environment("BASTION_TOUCH_PREVIEW") == "1"
	var viewport_size := get_viewport().get_visible_rect().size
	overlay.visible = touch_capable and viewport_size.y > viewport_size.x

