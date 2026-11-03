extends RefCounted

const GameConfig = preload("res://scripts/game_config.gd")
enum Phase { BUILD, DEFEND, VICTORY, DEFEAT }
enum BuildKind { WALL, TURRET }

var phase: Phase
var build_kind: int
var phase_time: float
var scrap: float
var base_hp: float
var occupied: Dictionary
var enemies_spawned: int
var enemies_defeated: int
var message: String
var message_time: float

## Starts new state objects with a clean build phase.
func _init() -> void:
	reset()

## Restores all match values without replacing the state object.
func reset() -> void:
	phase = Phase.BUILD
	build_kind = BuildKind.WALL
	phase_time = GameConfig.BUILD_DURATION
	scrap = GameConfig.STARTING_SCRAP
	base_hp = GameConfig.MAX_BASE_HP
	occupied = {}
	enemies_spawned = 0
	enemies_defeated = 0
	show_message("Build a perimeter before the raiders arrive.", 5.0)

## Shows a short HUD message for the given number of seconds.
func show_message(text: String, duration: float) -> void:
	message = text
	message_time = duration
