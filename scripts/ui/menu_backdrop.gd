@tool
extends Control

const GRID_COLOR := Color(0.13, 0.2, 0.26, 0.28)
const BUILDING_COLOR := Color(0.055, 0.09, 0.12, 1)
const WINDOW_COLOR := Color(0.18, 0.56, 0.5, 0.45)
const TEAL := Color("40d3b0")
const GOLD := Color("f6c76b")

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

	var store := Rect2(size.x * 0.57, size.y * 0.25, size.x * 0.32, size.y * 0.48)
	draw_rect(store.grow(14.0), Color(0, 0, 0, 0.22))
	draw_rect(store, BUILDING_COLOR)
	draw_rect(Rect2(store.position, Vector2(store.size.x, 12.0)), TEAL)
	draw_rect(Rect2(store.position + Vector2(0, 42), Vector2(store.size.x, 18.0)), GOLD)
	for index in 8:
		var awning_x := store.position.x + index * store.size.x / 8.0
		if index % 2 == 0:
			draw_rect(Rect2(awning_x, store.position.y + 42.0, store.size.x / 8.0, 18.0), TEAL)

	var door_size := Vector2(store.size.x * 0.22, store.size.y * 0.42)
	var door := Rect2(store.position + Vector2(store.size.x * 0.39, store.size.y - door_size.y), door_size)
	draw_rect(door, Color(0.08, 0.15, 0.19, 1))
	draw_line(door.position + Vector2(door.size.x * 0.5, 0), door.end - Vector2(door.size.x * 0.5, 0), WINDOW_COLOR, 2.0)
	for side in [0.08, 0.7]:
		var window := Rect2(store.position + Vector2(store.size.x * side, store.size.y * 0.4), Vector2(store.size.x * 0.2, store.size.y * 0.25))
		draw_rect(window, WINDOW_COLOR)

	var sign_center := store.position + Vector2(store.size.x * 0.5, 24.0)
	draw_circle(sign_center, 11.0, Color(TEAL, 0.25))
	draw_arc(sign_center, 11.0, 0.0, TAU, 24, TEAL, 3.0)
	draw_circle(sign_center, 4.0, GOLD)

	for index in 7:
		var crowd_x := store.position.x - 34.0 + index * (store.size.x + 68.0) / 6.0
		var crowd_y := store.end.y + 28.0 + absf(3.0 - index) * 5.0
		draw_circle(Vector2(crowd_x, crowd_y), 8.0, Color(0.93, 0.36, 0.41, 0.55))
		draw_line(Vector2(crowd_x, crowd_y + 8.0), Vector2(crowd_x, crowd_y + 24.0), Color(0.93, 0.36, 0.41, 0.45), 5.0)
