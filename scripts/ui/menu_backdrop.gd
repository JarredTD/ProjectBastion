@tool
extends Control

const GRID_COLOR := Color(0.13, 0.2, 0.26, 0.28)
const CROWD_COLOR := Color(1, 0.184, 0.424, 0.58)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

## Draws a simple storefront backdrop behind the main menu.
func _draw() -> void:
	for x in range(0, ceili(size.x), 48):
		draw_line(Vector2(x, 0), Vector2(x, size.y), GRID_COLOR, 1.0)
	for y in range(0, ceili(size.y), 48):
		draw_line(Vector2(0, y), Vector2(size.x, y), GRID_COLOR, 1.0)

	for index in 7:
		var crowd_x := size.x * 0.52 + index * size.x * 0.075
		var crowd_y := size.y * 0.78 + absf(3.0 - index) * 5.0
		draw_circle(Vector2(crowd_x, crowd_y), 8.0, CROWD_COLOR)
		draw_line(Vector2(crowd_x, crowd_y + 8.0), Vector2(crowd_x, crowd_y + 24.0), Color(CROWD_COLOR, 0.46), 5.0)
