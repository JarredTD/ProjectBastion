class_name RunSummary
extends RefCounted

var mode: StringName
var score: int
var shopper_points: int
var rush_points: int
var stock_points: int
var waves_cleared: int
var shoppers_defeated: int
var stock_remaining: int
var run_seed: int
var victory: bool
var best_score: int
var new_best: bool
var persistent_record: bool

func _init(
	run_mode: StringName,
	total_score: int,
	shopper_score: int,
	rush_score: int,
	stock_score: int,
	cleared_waves: int,
	defeated_shoppers: int,
	remaining_stock: int,
	seed: int,
	run_won: bool,
	local_best: int,
	is_new_best: bool,
	can_persist: bool,
) -> void:
	mode = run_mode
	score = total_score
	shopper_points = shopper_score
	rush_points = rush_score
	stock_points = stock_score
	waves_cleared = cleared_waves
	shoppers_defeated = defeated_shoppers
	stock_remaining = remaining_stock
	run_seed = seed
	victory = run_won
	best_score = local_best
	new_best = is_new_best
	persistent_record = can_persist
