class_name WaveDefinition
extends Resource

@export var enemies: Array[EnemyWaveEntry] = []
@export_range(0.1, 100.0, 0.05) var enemy_health_multiplier := 1.0
@export_range(0.05, 10.0, 0.05) var spawn_interval := 1.0
@export_range(1, 16, 1) var approach_count := 2
@export_range(0.0, 300.0, 1.0) var build_duration := 25.0

## Expands each roster entry into the enemies spawned this wave.
func enemy_roster() -> Array[EnemyDefinition]:
	var roster: Array[EnemyDefinition] = []
	for entry in enemies:
		if entry == null or entry.enemy == null or entry.enemy.scene == null:
			push_error("Wave contains an incomplete enemy entry.")
			continue
		for _index in entry.count:
			roster.append(entry.enemy)
	return roster

## Describes the exact enemy composition shown before the wave begins.
func roster_summary() -> String:
	var parts := PackedStringArray()
	for entry in enemies:
		if entry == null or entry.enemy == null:
			continue
		var label := entry.enemy.display_name if entry.count == 1 else entry.enemy.plural_name
		parts.append("%d %s" % [entry.count, label])
	return ", ".join(parts)

## Checks that every roster entry has an enemy definition.
func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if enemies.is_empty():
		errors.append("Enemy roster cannot be empty.")
	for index in enemies.size():
		var entry := enemies[index]
		if entry == null:
			errors.append("Enemy entry %d is missing." % (index + 1))
			continue
		if entry.enemy == null:
			errors.append("Enemy entry %d has no definition." % (index + 1))
			continue
		for error in entry.enemy.validation_errors():
			errors.append("%s: %s" % [entry.enemy.display_name, error])
	return errors
