extends Node

signal enemy_defeated(reward: float)
signal core_hit(damage: float)
signal wave_cleared

@export_node_path("Node2D") var enemies_path: NodePath
@export_node_path("Node2D") var world_path: NodePath
@export var raider_scene: PackedScene = preload("res://scenes/actors/raider.tscn")
@export var run_definition: RunDefinition

var active := false
var spawned := 0
var alive := 0
var spawn_cooldown := 0.4
var rng := RandomNumberGenerator.new()
var current_wave: WaveDefinition
var approach_markers: Array[Marker2D] = []

@onready var enemies: Node2D = get_node(enemies_path)
@onready var world: Node2D = get_node(world_path)

## Checks the authored wave and approach data before play begins.
func _ready() -> void:
	rng.randomize()
	if run_definition == null:
		push_error("Wave director requires a run definition.")
	elif run_definition.objective_waves.is_empty():
		push_error("Run definition requires at least one objective wave.")
	if world.spawn_markers().is_empty():
		push_error("Wave director requires at least one world spawn marker.")

## Spawns raiders at the configured interval while the wave is active.
func _process(delta: float) -> void:
	if not active or current_wave == null or spawned >= current_wave.enemy_count:
		return
	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0:
		spawn_raider()
		spawn_cooldown = current_wave.spawn_interval

## Chooses this wave's pressure points once so the player can prepare for them.
func prepare_wave(wave_number: int) -> bool:
	if run_definition == null:
		return false
	current_wave = run_definition.wave_for(wave_number)
	if current_wave == null:
		return false
	var available: Array[Marker2D] = world.spawn_markers()
	approach_markers.clear()
	var approach_total := mini(current_wave.approach_count, available.size())
	for index in approach_total:
		var selected_index := rng.randi_range(index, available.size() - 1)
		var selected: Marker2D = available[selected_index]
		available[selected_index] = available[index]
		available[index] = selected
		approach_markers.append(available[index])
	spawned = 0
	alive = 0
	spawn_cooldown = 0.4
	return not approach_markers.is_empty()

## Starts spawning and wakes any raiders already in the scene.
func start_wave() -> void:
	if current_wave == null or approach_markers.is_empty():
		return
	active = true
	for enemy in enemies.get_children():
		enemy.active = true

## Pauses spawning and every living raider.
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
	approach_markers.clear()
	rng.randomize()
	for enemy in enemies.get_children():
		enemy.queue_free()

## Creates one raider and connects its combat signals.
func spawn_raider() -> void:
	var raider: CharacterBody2D = raider_scene.instantiate()
	enemies.add_child(raider)
	raider.global_position = random_spawn_position()
	raider.configure(world.core_position())
	raider.defeated.connect(_on_raider_defeated)
	raider.core_hit.connect(func(damage: float) -> void: core_hit.emit(damage))
	spawned += 1
	alive += 1

## Chooses one of the approach markers revealed for this wave.
func random_spawn_position() -> Vector2:
	if approach_markers.is_empty():
		push_error("Wave requires at least one approach marker.")
		return world.core_position()
	return approach_markers[rng.randi_range(0, approach_markers.size() - 1)].global_position

## Returns the fixed enemy budget prepared for this wave.
func enemy_count() -> int:
	return current_wave.enemy_count if current_wave != null else 0

## Returns the build time configured for this wave.
func build_duration() -> float:
	return current_wave.build_duration if current_wave != null else 0.0

## Names the pressure points selected for the current wave.
func approach_summary() -> String:
	var names := PackedStringArray()
	for marker in approach_markers:
		names.append(String(marker.name).capitalize())
	return ", ".join(names)

## Returns the number of waves in the completable objective.
func objective_wave_count() -> int:
	return run_definition.objective_waves.size() if run_definition != null else 0

## Tracks wave progress and reports the reward to the match coordinator.
func _on_raider_defeated(reward: float) -> void:
	alive -= 1
	enemy_defeated.emit(reward)
	if current_wave != null and spawned >= current_wave.enemy_count and alive <= 0:
		active = false
		wave_cleared.emit()
