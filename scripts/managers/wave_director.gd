extends Node

signal enemy_defeated(reward: float)
signal core_hit(damage: float)
signal wave_cleared

@export_node_path("Node2D") var enemies_path: NodePath
@export_node_path("Node2D") var world_path: NodePath
@export var run_definition: RunDefinition

var active := false
var spawned := 0
var alive := 0
var spawn_cooldown := 0.4
var rng := RandomNumberGenerator.new()
var run_seed := 0
var current_wave: WaveDefinition
var enemy_roster: Array[EnemyDefinition] = []
var approach_points: Array[ApproachPoint] = []

@onready var enemies: Node2D = get_node(enemies_path)
@onready var world: Node2D = get_node(world_path)

## Checks the authored wave and approach data before play begins.
func _ready() -> void:
	if run_definition == null:
		push_error("Wave director requires a run definition.")
	else:
		for error in run_definition.validation_errors():
			push_error("Run definition: %s" % error)
	if world.approach_points().is_empty():
		push_error("Wave director requires at least one world approach point.")

## Starts a run with the supplied seed, or creates one.
func begin_run(seed := 0) -> int:
	if seed == 0:
		var seed_source := RandomNumberGenerator.new()
		seed_source.randomize()
		seed = seed_source.randi()
		if seed == 0:
			seed = 1
	run_seed = seed
	return run_seed

## Spawns enemies at the configured interval while the wave is active.
func _process(delta: float) -> void:
	if not active or current_wave == null or spawned >= enemy_roster.size():
		return
	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0:
		spawn_enemy()
		spawn_cooldown = current_wave.spawn_interval

## Chooses this wave's approaches before the build phase.
func prepare_wave(wave_number: int) -> bool:
	if run_definition == null:
		return false
	rng.seed = hash([run_seed, wave_number])
	current_wave = run_definition.wave_for(wave_number)
	if current_wave == null:
		return false
	var wave_errors := current_wave.validation_errors()
	if not wave_errors.is_empty():
		for error in wave_errors:
			push_error("Wave %d: %s" % [wave_number, error])
		return false
	enemy_roster = current_wave.enemy_roster()
	if enemy_roster.is_empty():
		push_error("Wave %d requires at least one valid enemy." % wave_number)
		return false
	if not enemy_scenes_are_valid():
		return false
	shuffle_enemy_roster()
	set_approaches_highlighted(false)
	var available: Array[ApproachPoint] = []
	for point in world.approach_points():
		if point.spawn_enabled and point.spawn_weight > 0.0:
			available.append(point)
	approach_points.clear()
	var approach_total := mini(current_wave.approach_count, available.size())
	for _index in approach_total:
		var selected := choose_weighted_approach(available)
		if selected == null:
			break
		approach_points.append(selected)
		available.erase(selected)
	set_approaches_highlighted(true)
	spawned = 0
	alive = 0
	spawn_cooldown = 0.4
	return not approach_points.is_empty()

## Starts spawning and wakes any enemies already in the scene.
func start_wave() -> void:
	if current_wave == null or approach_points.is_empty():
		return
	set_approaches_highlighted(false)
	active = true
	for enemy in enemies.get_children():
		enemy.active = true

## Pauses spawning and every living enemy.
func stop_wave() -> void:
	active = false
	for enemy in enemies.get_children():
		enemy.active = false

## Removes active enemies and clears the prepared wave.
func reset() -> void:
	active = false
	spawned = 0
	alive = 0
	spawn_cooldown = 0.4
	current_wave = null
	enemy_roster.clear()
	set_approaches_highlighted(false)
	approach_points.clear()
	for enemy in enemies.get_children():
		enemy.queue_free()

## Creates one enemy and connects its combat signals.
func spawn_enemy() -> void:
	var definition := enemy_roster[spawned]
	var enemy: CharacterBody2D = definition.scene.instantiate()
	enemies.add_child(enemy)
	enemy.global_position = random_spawn_position()
	enemy.configure(definition, world.core_position())
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.core_hit.connect(func(damage: float) -> void: core_hit.emit(damage))
	spawned += 1
	alive += 1

## Shuffles exact wave composition without changing its authored counts.
func shuffle_enemy_roster() -> void:
	for index in range(enemy_roster.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var selected := enemy_roster[swap_index]
		enemy_roster[swap_index] = enemy_roster[index]
		enemy_roster[index] = selected

## Checks that enemy scenes expose the methods and signals used here.
func enemy_scenes_are_valid() -> bool:
	var checked: Dictionary[PackedScene, bool] = {}
	for definition in enemy_roster:
		if checked.has(definition.scene):
			continue
		checked[definition.scene] = true
		var instance := definition.scene.instantiate()
		var valid := instance is CharacterBody2D
		valid = valid and instance.has_method("configure")
		valid = valid and instance.has_signal("defeated")
		valid = valid and instance.has_signal("core_hit")
		instance.free()
		if not valid:
			push_error("Enemy scene for %s does not meet the spawning contract." % definition.display_name)
			return false
	return true

## Chooses one of the approach markers revealed for this wave.
func random_spawn_position() -> Vector2:
	var approach := choose_weighted_approach(approach_points)
	if approach == null:
		push_error("Wave requires at least one approach point.")
		return world.core_position()
	return approach.global_position

## Chooses an approach using its spawn weight.
func choose_weighted_approach(points: Array[ApproachPoint]) -> ApproachPoint:
	var total_weight := 0.0
	for point in points:
		total_weight += point.spawn_weight
	if total_weight <= 0.0:
		return null
	var roll := rng.randf_range(0.0, total_weight)
	for point in points:
		roll -= point.spawn_weight
		if roll <= 0.0:
			return point
	return points.back()

## Keeps the selected map warnings in step with the build phase.
func set_approaches_highlighted(value: bool) -> void:
	for point in approach_points:
		point.set_highlighted(value)

## Returns the fixed enemy budget prepared for this wave.
func enemy_count() -> int:
	return enemy_roster.size()

## Describes the exact enemy mix prepared for the HUD.
func enemy_summary() -> String:
	return current_wave.roster_summary() if current_wave != null else ""

## Returns the build time configured for this wave.
func build_duration() -> float:
	return current_wave.build_duration if current_wave != null else 0.0

## Names the pressure points selected for the current wave.
func approach_summary() -> String:
	var names := PackedStringArray()
	for point in approach_points:
		names.append(point.display_label())
	return ", ".join(names)

## Returns the number of waves in the completable objective.
func objective_wave_count() -> int:
	return run_definition.objective_waves.size() if run_definition != null else 0

## Tracks wave progress and reports the reward to the match coordinator.
func _on_enemy_defeated(reward: float) -> void:
	alive -= 1
	enemy_defeated.emit(reward)
	if current_wave != null and spawned >= enemy_roster.size() and alive <= 0:
		active = false
		wave_cleared.emit()
