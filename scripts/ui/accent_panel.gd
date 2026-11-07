@tool
class_name AccentPanel
extends Panel

enum Edge { TOP, RIGHT, BOTTOM, LEFT }

@export var accent_color := Color("40d3b0"):
	set(value):
		accent_color = value
		queue_redraw()
@export var accent_edge := Edge.TOP:
	set(value):
		accent_edge = value
		queue_redraw()
@export_range(1.0, 12.0, 1.0) var accent_width := 4.0:
	set(value):
		accent_width = value
		queue_redraw()

func _draw() -> void:
	var accent_rect := Rect2(Vector2.ZERO, size)
	match accent_edge:
		Edge.TOP:
			accent_rect.size.y = accent_width
		Edge.RIGHT:
			accent_rect.position.x = size.x - accent_width
			accent_rect.size.x = accent_width
		Edge.BOTTOM:
			accent_rect.position.y = size.y - accent_width
			accent_rect.size.y = accent_width
		Edge.LEFT:
			accent_rect.size.x = accent_width
	draw_rect(accent_rect, accent_color)
