class_name WaveDefinition
extends Resource

@export var enemies: Array[EnemyWaveEntry] = []
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
