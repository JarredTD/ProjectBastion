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
var enemies_defeated: int
var wave_number: int
var waves_cleared: int
var wave_enemies: int
var wave_enemies_defeated: int
var objective_wave_count: int
var endless: bool
var message: String
var message_time: float

## Starts new state objects with a clean build phase.
func _init() -> void:
	reset(0)

## Restores all match values without replacing the state object.
func reset(objective_waves: int) -> void:
	phase = Phase.BUILD
	build_kind = BuildKind.WALL
	phase_time = GameConfig.BUILD_DURATION
	scrap = GameConfig.STARTING_SCRAP
	base_hp = GameConfig.MAX_BASE_HP
	occupied = {}
	enemies_defeated = 0
	wave_number = 1
	waves_cleared = 0
	wave_enemies = 0
	wave_enemies_defeated = 0
	objective_wave_count = objective_waves
	endless = false
	show_message("Build a perimeter before the shoppers arrive.", 5.0)

## Shows a short HUD message for the given number of seconds.
func show_message(text: String, duration: float) -> void:
	message = text
	message_time = duration
