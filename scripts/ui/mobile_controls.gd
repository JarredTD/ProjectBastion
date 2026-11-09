extends CanvasLayer

signal world_action_requested(screen_position: Vector2, removing: bool)
signal movement_changed(direction: Vector2)
signal repair_held_changed(held: bool)
signal pause_requested
signal upgrades_requested
signal touch_mode_changed(enabled: bool)

const GameState = preload("res://scripts/game_state.gd")

var state: GameState
var native_touch := false
var desktop_preview := false
var repair_held := false

@onready var controls: Control = %Controls
@onready var joystick: Control = %VirtualJoystick
@onready var remove_button: Button = %RemoveButton
@onready var repair_button: Button = %RepairButton
@onready var pause_button: Button = %PauseButton
@onready var upgrades_button: Button = %UpgradesButton

func _ready() -> void:
	native_touch = OS.get_name() in ["Web", "Android", "iOS"] and DisplayServer.is_touchscreen_available()
	desktop_preview = OS.get_cmdline_user_args().has("--touch-ui") or OS.get_environment("BASTION_TOUCH_PREVIEW") == "1"
	joystick.connect(&"direction_changed", func(direction: Vector2) -> void: movement_changed.emit(direction))
	repair_button.button_down.connect(set_repair_held.bind(true))
	repair_button.button_up.connect(set_repair_held.bind(false))
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	upgrades_button.pressed.connect(func() -> void: upgrades_requested.emit())
	get_viewport().size_changed.connect(update_safe_area)
	apply_touch_mode()
	update_safe_area()

## Supplies the live phase used to show context-sensitive controls.
func configure(game_state: GameState) -> void:
	state = game_state

func _process(_delta: float) -> void:
	if state == null or not is_touch_mode():
		return
	var playing := state.phase == GameState.Phase.BUILD or state.phase == GameState.Phase.DEFEND
	joystick.visible = playing
	pause_button.visible = playing
	upgrades_button.visible = state.phase == GameState.Phase.BUILD
	remove_button.visible = state.phase == GameState.Phase.BUILD
	repair_button.visible = state.phase == GameState.Phase.DEFEND
	if not remove_button.visible:
		remove_button.button_pressed = false
	if not repair_button.visible:
		set_repair_held(false)

## Converts otherwise-unhandled touches into world actions.
func _unhandled_input(event: InputEvent) -> void:
	if not is_touch_mode() or state == null:
		return
	if event is InputEventScreenTouch and event.pressed:
		world_action_requested.emit(event.position, remove_button.button_pressed)
		get_viewport().set_input_as_handled()

## Toggles the complete touch presentation while running on desktop.
func toggle_desktop_preview() -> void:
	if native_touch:
		return
	desktop_preview = not desktop_preview
	apply_touch_mode()

func is_touch_mode() -> bool:
	return native_touch or desktop_preview

func blocks_mouse_gameplay() -> bool:
	return desktop_preview

func apply_touch_mode() -> void:
	var enabled := is_touch_mode()
	controls.visible = enabled
	Input.emulate_mouse_from_touch = not enabled
	Input.emulate_touch_from_mouse = desktop_preview
	if not enabled:
		joystick.call(&"release")
		set_repair_held(false)
	update_safe_area()
	touch_mode_changed.emit(enabled)

func set_repair_held(held: bool) -> void:
	if repair_held == held:
		return
	repair_held = held
	repair_held_changed.emit(held)

## Keeps controls clear of notches and system gesture areas.
func update_safe_area() -> void:
	controls.offset_left = 0.0
	controls.offset_top = 0.0
	controls.offset_right = 0.0
	controls.offset_bottom = 0.0
	if not is_touch_mode() or OS.get_name() not in ["Web", "Android", "iOS"]:
		return
	var screen_size := Vector2(DisplayServer.screen_get_size())
	var safe_area := DisplayServer.get_display_safe_area()
	var viewport_size := get_viewport().get_visible_rect().size
	if screen_size.x <= 0.0 or screen_size.y <= 0.0 or safe_area.size == Vector2i.ZERO:
		return
	var scale := viewport_size / screen_size
	controls.offset_left = maxf(0.0, safe_area.position.x * scale.x)
	controls.offset_top = maxf(0.0, safe_area.position.y * scale.y)
	controls.offset_right = -maxf(0.0, (screen_size.x - safe_area.end.x) * scale.x)
	controls.offset_bottom = -maxf(0.0, (screen_size.y - safe_area.end.y) * scale.y)
