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
var score: int
var shopper_points: int
var rush_points: int
var stock_points: int
var wave_number: int
var waves_cleared: int
var wave_enemies: int
var wave_enemies_defeated: int
var wave_composition: String
var wave_approaches: String
var objective_wave_count: int
var endless: bool
var run_seed: int
var message: String
var message_time: float

## Starts new state objects with a clean build phase.
func _init() -> void:
	reset(0, 0)

## Restores all match values without replacing the state object.
func reset(objective_waves: int, seed: int) -> void:
	phase = Phase.BUILD
	build_kind = BuildKind.WALL
	phase_time = GameConfig.BUILD_DURATION
	scrap = GameConfig.STARTING_SCRAP
	base_hp = GameConfig.MAX_BASE_HP
	occupied = {}
	enemies_defeated = 0
	score = 0
	shopper_points = 0
	rush_points = 0
	stock_points = 0
	wave_number = 1
	waves_cleared = 0
	wave_enemies = 0
	wave_enemies_defeated = 0
	wave_composition = ""
	wave_approaches = ""
	objective_wave_count = objective_waves
	endless = false
	run_seed = seed
	show_message("Build a perimeter before the shoppers arrive.", 5.0)

## Adds points earned by turning away a shopper.
func award_shopper_points(points: int) -> void:
	var safe_points := maxi(0, points)
	shopper_points += safe_points
	score += safe_points

## Adds points earned by clearing a rush.
func award_rush_points(points: int) -> void:
	var safe_points := maxi(0, points)
	rush_points += safe_points
	score += safe_points

## Adds the remaining-stock bonus at objective completion.
func award_stock_points(points: int) -> void:
	var safe_points := maxi(0, points)
	stock_points += safe_points
	score += safe_points

## Shows a short HUD message for the given number of seconds.
func show_message(text: String, duration: float) -> void:
	message = text
	message_time = duration
