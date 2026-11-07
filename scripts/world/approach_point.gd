@tool
class_name ApproachPoint
extends Marker2D

@export var display_name := "Approach"
@export var spawn_enabled := true
@export_range(0.0, 100.0, 0.1) var spawn_weight := 1.0
@export var tags: Array[StringName] = []
@export var indicator_color := Color("f6c76b")

var highlighted := false

## Shows or hides the build-phase warning drawn at this approach.
func set_highlighted(value: bool) -> void:
	highlighted = value
	queue_redraw()

## Draws a subtle editor marker and a stronger runtime warning when selected.
func _draw() -> void:
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, 7.0, Color(indicator_color, 0.35))
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, Color(indicator_color, 0.7), 2.0)
	elif highlighted:
		draw_circle(Vector2.ZERO, 20.0, Color(indicator_color, 0.2))
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 32, indicator_color, 3.0)
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 32, Color(indicator_color, 0.45), 2.0)

## Surfaces common map-authoring mistakes in the scene inspector.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if display_name.strip_edges().is_empty():
		warnings.append("Display name cannot be empty.")
	if spawn_enabled and spawn_weight <= 0.0:
		warnings.append("An enabled approach needs a positive spawn weight.")
	return warnings
