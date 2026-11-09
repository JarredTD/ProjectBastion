class_name RunDefinition
extends Resource

@export var objective_waves: Array[WaveDefinition] = []
@export var endless_enemies: Array[EnemyWaveEntry] = []
@export_range(1.0, 4.0, 0.05) var endless_enemy_growth := 2.1
@export_range(1, 5000, 1) var endless_maximum_enemies := 600
@export_range(0.1, 100.0, 0.05) var endless_starting_health_multiplier := 2.2
@export_range(1.0, 3.0, 0.05) var endless_health_growth := 1.2
@export_range(0.05, 10.0, 0.05) var endless_starting_interval := 0.7
@export_range(0.1, 1.0, 0.05) var endless_interval_decay := 0.85
@export_range(0.05, 10.0, 0.05) var endless_minimum_interval := 0.2
@export_range(1, 16, 1) var endless_starting_approaches := 4
@export_range(1, 16, 1) var endless_maximum_approaches := 8
@export_range(0.0, 300.0, 1.0) var endless_build_duration := 20.0

## Returns an objective wave or creates the requested endless wave.
func wave_for(wave_number: int) -> WaveDefinition:
	if wave_number <= 0:
		return null
	if wave_number <= objective_waves.size():
		return objective_waves[wave_number - 1]
	var endless_index := wave_number - objective_waves.size() - 1
	var wave := WaveDefinition.new()
	var base_enemy_count := 0
	for base_entry in endless_enemies:
		if base_entry != null and base_entry.enemy != null:
			base_enemy_count += base_entry.count
	var maximum_scale := float(endless_maximum_enemies) / maxi(1, base_enemy_count)
	var enemy_scale := minf(pow(endless_enemy_growth, endless_index), maximum_scale)
	var remaining_enemies := endless_maximum_enemies
	for base_entry in endless_enemies:
		if base_entry == null or base_entry.enemy == null:
			continue
		if remaining_enemies <= 0:
			break
		var entry := EnemyWaveEntry.new()
		entry.enemy = base_entry.enemy
		entry.count = mini(maxi(1, roundi(base_entry.count * enemy_scale)), remaining_enemies)
		remaining_enemies -= entry.count
		wave.enemies.append(entry)
	wave.enemy_health_multiplier = endless_starting_health_multiplier * pow(endless_health_growth, endless_index)
	wave.spawn_interval = maxf(
		endless_minimum_interval,
		endless_starting_interval * pow(endless_interval_decay, endless_index)
	)
	wave.approach_count = mini(endless_maximum_approaches, endless_starting_approaches + endless_index)
	wave.build_duration = endless_build_duration
	return wave

## Checks the objective and endless wave data.
func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if objective_waves.is_empty():
		errors.append("At least one objective wave is required.")
	for index in objective_waves.size():
		var wave := objective_waves[index]
		if wave == null:
			errors.append("Objective wave %d is missing." % (index + 1))
			continue
		for error in wave.validation_errors():
			errors.append("Objective wave %d: %s" % [index + 1, error])
	if endless_enemies.is_empty():
		errors.append("Endless enemy roster cannot be empty.")
	for index in endless_enemies.size():
		var entry := endless_enemies[index]
		if entry == null or entry.enemy == null:
			errors.append("Endless enemy entry %d is incomplete." % (index + 1))
			continue
		for error in entry.enemy.validation_errors():
			errors.append("Endless %s: %s" % [entry.enemy.display_name, error])
	return errors
