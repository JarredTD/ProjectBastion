extends Node2D

const GameConfig = preload("res://scripts/game_config.gd")

@onready var game: Node2D = get_parent()
@onready var core_health_bar: Node2D = %CoreHealthBar
@onready var core_health_fill: ColorRect = %CoreHealthFill

## Keeps the core health bar in step with the current match state.
func _process(_delta: float) -> void:
	var health_ratio: float = clampf(game.state.base_hp / GameConfig.MAX_BASE_HP, 0.0, 1.0)
	core_health_fill.size.x = 76.0 * health_ratio
	core_health_bar.visible = health_ratio < 1.0

## Returns the playable rectangle authored by the Arena control.
func arena_rect() -> Rect2:
	return Rect2($Arena.position, $Arena.size)

## Returns the core's current world position.
func core_position() -> Vector2:
	return $Core.global_position

## Returns the authored starting position for the player.
func player_start_position() -> Vector2:
	return $PlayerStart.global_position

## Collects every authored enemy approach marker.
func spawn_markers() -> Array[Marker2D]:
	var markers: Array[Marker2D] = []
	for marker in $SpawnPoints.get_children():
		if marker is Marker2D:
			markers.append(marker)
	return markers
