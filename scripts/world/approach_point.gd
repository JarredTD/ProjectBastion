@tool
class_name ApproachPoint
extends Marker2D

@export var spawn_enabled := true
@export_range(0.0, 100.0, 0.1) var spawn_weight := 1.0
@export var tags: Array[StringName] = []
@export var indicator_color := Color("f6c76b")
@export_range(80.0, 900.0, 10.0) var indicator_reach := 760.0

var highlighted := false
var target_position := Vector2.ZERO
var pulse_time := 0.0

func _ready() -> void:
	set_process(false)

## Points the warning arrow toward the map objective.
func set_target_position(value: Vector2) -> void:
	target_position = value
	queue_redraw()

## Shows or hides the build-phase warning drawn at this approach.
func set_highlighted(value: bool) -> void:
	highlighted = value
	pulse_time = 0.0
	set_process(value and not Engine.is_editor_hint())
	queue_redraw()

## Animates the active arrow.
func _process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()

## Draws a subtle editor marker and a stronger runtime warning when selected.
func _draw() -> void:
	if Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, 7.0, Color(indicator_color, 0.35))
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, Color(indicator_color, 0.7), 2.0)
	elif highlighted:
		var pulse := (sin(pulse_time * 4.0) + 1.0) * 0.5
		draw_circle(Vector2.ZERO, 20.0 + pulse * 3.0, Color(indicator_color, 0.18))
		draw_arc(Vector2.ZERO, 27.0 + pulse * 3.0, 0.0, TAU, 32, indicator_color, 3.0)
		draw_approach_arrow(pulse)

## Draws the path toward the stock.
func draw_approach_arrow(pulse: float) -> void:
	var target := to_local(target_position)
	if target.is_zero_approx():
		return
	var direction := target.normalized()
	var reach := minf(indicator_reach, maxf(60.0, target.length() - 72.0))
	var distance := 38.0
	while distance < reach - 34.0:
		var segment_end := minf(distance + 20.0, reach - 34.0)
		draw_line(direction * distance, direction * segment_end, Color(indicator_color, 0.5), 4.0)
		distance += 38.0
	var tip := direction * (reach + pulse * 8.0)
	var arrow_base := tip - direction * 24.0
	var normal := Vector2(-direction.y, direction.x)
	draw_colored_polygon(PackedVector2Array([
		tip,
		arrow_base + normal * 12.0,
		arrow_base - normal * 12.0,
	]), indicator_color)

## Warns about missing approach settings in the inspector.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if spawn_enabled and spawn_weight <= 0.0:
		warnings.append("An enabled approach needs a positive spawn weight.")
	return warnings
