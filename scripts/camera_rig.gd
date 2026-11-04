extends Node2D

@onready var camera: Camera2D = $Camera2D

var target: Node2D

## Assigns the follow target and keeps the camera inside the authored arena.
func configure(follow_target: Node2D, world_bounds: Rect2) -> void:
	target = follow_target
	camera.limit_left = floori(world_bounds.position.x)
	camera.limit_top = floori(world_bounds.position.y)
	camera.limit_right = ceili(world_bounds.end.x)
	camera.limit_bottom = ceili(world_bounds.end.y)
	snap_to_target()

## Moves the rig to the player while Camera2D smooths the rendered view.
func _process(_delta: float) -> void:
	if is_instance_valid(target):
		global_position = target.global_position

## Immediately recenters after a reset or teleport.
func snap_to_target() -> void:
	if not is_instance_valid(target):
		return
	global_position = target.global_position
	camera.reset_smoothing()

## Reports whether a world point is currently inside the camera view.
func is_world_position_visible(world_position: Vector2) -> bool:
	var half_view := get_viewport_rect().size * 0.5 / camera.zoom
	var view_center := camera.get_screen_center_position()
	return Rect2(view_center - half_view, half_view * 2.0).has_point(world_position)
