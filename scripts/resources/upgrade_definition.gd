class_name UpgradeDefinition
extends Resource

enum Effect { WALL_HEALTH, TURRET_DAMAGE, PLAYER_DAMAGE }

@export var id: StringName
@export var display_name := "Upgrade"
@export_multiline var description := "Improves the night shift."
@export var effect := Effect.WALL_HEALTH
@export_range(0.0, 2.0, 0.05) var amount := 0.2
@export_range(0, 999, 1) var base_cost := 60
@export_range(0, 999, 1) var cost_step := 40
@export_range(1, 10, 1) var max_level := 3
@export_range(1, 99, 1) var available_from_wave := 2


## Returns the price of the next level.
func cost_for_level(current_level: int) -> int:
	return base_cost + cost_step * maxi(0, current_level)
