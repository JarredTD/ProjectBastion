@tool
extends Node2D

const GameConfig = preload("res://scripts/game_config.gd")
const GameState = preload("res://scripts/game_state.gd")

@export_category("Storefront footprint")
@export_range(1.0, 256.0, 1.0) var core_attack_radius := 68.0
@export_range(1.0, 256.0, 1.0) var core_repair_radius := 76.0
@export_range(1.0, 256.0, 1.0) var core_build_radius := 96.0

var state: GameState

@onready var core_health_bar: Node2D = %CoreHealthBar
@onready var core_health_fill: ColorRect = %CoreHealthFill
@onready var parking_lot: TextureRect = %ParkingLot
@onready var endless_parking_lot: TextureRect = %EndlessParkingLot

## Validates the storefront footprint and points each approach toward the stock.
func _ready() -> void:
	if not Engine.is_editor_hint():
		for warning in storefront_warnings():
			push_warning(warning)
		core_health_bar.hide()
	for point in approach_points():
		point.set_target_position(core_position())

## Shows storefront setup problems directly in the editor inspector.
func _get_configuration_warnings() -> PackedStringArray:
	return storefront_warnings()

## Checks interaction ranges against the collision shape authored in the scene.
func storefront_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var collision_node := get_node_or_null("Core/CoreBody/CoreCollisionShape") as CollisionShape2D
	if collision_node == null:
		warnings.append("Storefront requires a collision shape.")
		return warnings
	var core_shape := collision_node.shape as CircleShape2D
	if core_shape == null:
		warnings.append("Storefront collision must use a circle shape.")
		return warnings
	if core_attack_radius < core_shape.radius + GameConfig.GRID_SIZE * 0.5:
		warnings.append("Storefront attack radius needs enough room for a shopper at the edge.")
	if core_repair_radius <= core_shape.radius:
		warnings.append("Storefront repair radius should extend beyond its collision radius.")
	if core_build_radius < core_shape.radius + GameConfig.GRID_SIZE * 0.5:
		warnings.append("Storefront build radius is too small for the building grid.")
	return warnings

## Supplies the live match state while keeping the world usable on its own.
func configure(game_state: GameState) -> void:
	state = game_state

## Keeps the core health bar in step with the current match state.
func _process(_delta: float) -> void:
	if state == null:
		return
	parking_lot.visible = not state.endless
	endless_parking_lot.visible = state.endless
	var health_ratio: float = clampf(state.base_hp / GameConfig.MAX_BASE_HP, 0.0, 1.0)
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

## Returns how close shoppers get before attacking the storefront.
func core_attack_range() -> float:
	return core_attack_radius

## Returns how close the player must be to repair the storefront.
func core_repair_range() -> float:
	return core_repair_radius

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
