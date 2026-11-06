class_name RunDefinition
extends Resource

@export var objective_waves: Array[WaveDefinition] = []
@export_range(1, 10000, 1) var endless_starting_enemies := 30
@export_range(1.0, 4.0, 0.05) var endless_enemy_growth := 2.1
@export_range(0.05, 10.0, 0.05) var endless_starting_interval := 0.7
@export_range(0.1, 1.0, 0.05) var endless_interval_decay := 0.85
@export_range(0.05, 10.0, 0.05) var endless_minimum_interval := 0.2
@export_range(1, 16, 1) var endless_starting_approaches := 4
@export_range(1, 16, 1) var endless_maximum_approaches := 8
@export_range(0.0, 300.0, 1.0) var endless_build_duration := 20.0

## Returns the authored objective wave or builds the requested endless wave.
func wave_for(wave_number: int) -> WaveDefinition:
	if wave_number <= 0:
		return null
	if wave_number <= objective_waves.size():
		return objective_waves[wave_number - 1]
	var endless_index := wave_number - objective_waves.size() - 1
	var wave := WaveDefinition.new()
	wave.enemy_count = roundi(endless_starting_enemies * pow(endless_enemy_growth, endless_index))
	wave.spawn_interval = maxf(
		endless_minimum_interval,
		endless_starting_interval * pow(endless_interval_decay, endless_index)
	)
	wave.approach_count = mini(endless_maximum_approaches, endless_starting_approaches + endless_index)
	wave.build_duration = endless_build_duration
	return wave
