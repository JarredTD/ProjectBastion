extends Control

signal direction_changed(direction: Vector2)

@export var base_color := Color(0.12, 0.18, 0.25, 0.82)
@export var ring_color := Color(0.31, 0.84, 0.71, 0.9)
@export var knob_color := Color(0.91, 0.95, 1.0, 0.95)

var touch_index := -1
var mouse_active := false
var direction := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

## Tracks the finger or preview mouse currently steering the joystick.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index < 0:
			touch_index = event.index
			update_direction(event.position)
			accept_event()
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			set_direction(Vector2.ZERO)
			accept_event()
	elif event is InputEventScreenDrag and event.index == touch_index:
		update_direction(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_active = event.pressed
		if mouse_active:
			update_direction(event.position)
		else:
			set_direction(Vector2.ZERO)
		accept_event()
	elif event is InputEventMouseMotion and mouse_active:
		update_direction(event.position)
		accept_event()

## Clears held movement when controls are hidden or interrupted.
func release() -> void:
	touch_index = -1
	mouse_active = false
	set_direction(Vector2.ZERO)

func update_direction(pointer_position: Vector2) -> void:
	var radius := minf(size.x, size.y) * 0.34
	set_direction((pointer_position - size * 0.5) / radius)

func set_direction(value: Vector2) -> void:
	var next_direction := value.limit_length(1.0)
	if direction.is_equal_approx(next_direction):
		return
	direction = next_direction
	direction_changed.emit(direction)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	draw_circle(center, radius + 12.0, base_color)
	draw_arc(center, radius, 0.0, TAU, 48, ring_color, 3.0)
	draw_circle(center + direction * radius, 24.0, knob_color)

