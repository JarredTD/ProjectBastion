class_name ScoreRules
extends Resource

@export_category("Rush bonuses")
@export_range(0, 100000, 1) var rush_clear_base := 500
@export_range(0, 100000, 1) var rush_clear_growth := 100

@export_category("Objective bonus")
@export_range(0, 100000, 1) var stock_bonus_max := 2000

## Returns the escalating bonus for completing a rush.
func rush_clear_bonus(wave_number: int) -> int:
	return rush_clear_base + maxi(1, wave_number) * rush_clear_growth

## Converts remaining stock into the objective-completion bonus.
func stock_bonus(stock: float, maximum_stock: float) -> int:
	if maximum_stock <= 0.0:
		return 0
	return roundi(clampf(stock / maximum_stock, 0.0, 1.0) * stock_bonus_max)
