extends Node2D

const GameConfig = preload("res://scripts/game_config.gd")

@export_range(0.0, 256.0, 1.0) var core_build_radius := 96.0

@onready var game: Node2D = get_parent()
@onready var core_health_bar: Node2D = %CoreHealthBar
@onready var core_health_fill: ColorRect = %CoreHealthFill

## Points each approach warning toward the stock.
func _ready() -> void:
	for point in approach_points():
		point.set_target_position(core_position())

## Keeps the core health bar in step with the current match state.
func _process(_delta: float) -> void:
	var health_ratio: float = clampf(game.state.base_hp / GameConfig.MAX_BASE_HP, 0.0, 1.0)
	core_health_fill.size.x = 76.0 * health_ratio
	core_health_bar.visible = health_ratio < 1.0

## Returns the playable area.
func arena_rect() -> Rect2:
	return Rect2($Arena.position, $Arena.size)

## Returns the core's current world position.
func core_position() -> Vector2:
	return $Core.global_position

## Returns the clearance structures should leave around the storefront.
func core_clearance() -> float:
	return core_build_radius

## Returns the player's starting position.
func player_start_position() -> Vector2:
	return $PlayerStart.global_position

## Returns the enemy approach points in this map.
func approach_points() -> Array[ApproachPoint]:
	var points: Array[ApproachPoint] = []
	for point in $SpawnPoints.get_children():
		if point is ApproachPoint:
			points.append(point)
	return points
