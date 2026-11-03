extends StaticBody2D

signal destroyed(cell: Vector2i)

@export var max_health := 150.0

var health: float
var cell := Vector2i.ZERO

@onready var health_fill: ColorRect = %HealthFill
@onready var health_bar: Node2D = %HealthBar

## Starts each placed structure at full health.
func _ready() -> void:
	health = max_health
	update_health_bar()

## Records the grid cell used by placement and demolition.
func configure(grid_cell: Vector2i) -> void:
	cell = grid_cell

## Removes health and frees the occupied cell when the structure breaks.
func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	update_health_bar()
	if health <= 0.0:
		destroyed.emit(cell)
		queue_free()

## Restores health and returns whether any repair was actually needed.
func repair(amount: float) -> bool:
	if health >= max_health:
		return false
	health = minf(max_health, health + amount)
	update_health_bar()
	return true

## Reports whether this structure has health left to restore.
func is_damaged() -> bool:
	return health < max_health

## Resizes the health bar and hides it while health is full.
func update_health_bar() -> void:
	health_fill.size.x = 28.0 * health / max_health
	health_bar.visible = health < max_health
