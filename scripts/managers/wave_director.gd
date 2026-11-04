extends Node

signal enemy_defeated(reward: float)
signal core_hit(damage: float)
signal wave_cleared

const GameConfig = preload("res://scripts/game_config.gd")

@export_node_path("Node2D") var enemies_path: NodePath
@export_node_path("Node2D") var world_path: NodePath
@export var raider_scene: PackedScene = preload("res://scenes/actors/raider.tscn")

var active := false
var spawned := 0
var alive := 0
var spawn_cooldown := 0.4
var rng := RandomNumberGenerator.new()
var spawn_points_available := false

@onready var enemies: Node2D = get_node(enemies_path)
@onready var world: Node2D = get_node(world_path)

## Seeds spawn selection for this run of the game.
func _ready() -> void:
	rng.randomize()
	spawn_points_available = not world.spawn_positions().is_empty()
	if not spawn_points_available:
		push_error("Wave director requires at least one world spawn marker.")

## Spawns raiders at the configured interval while the wave is active.
func _process(delta: float) -> void:
	if not active or spawned >= GameConfig.TOTAL_ENEMIES:
		return
	spawn_cooldown -= delta
	if spawn_cooldown <= 0.0:
		spawn_raider()
		spawn_cooldown = 1.25

## Starts spawning and wakes any raiders already in the scene.
func start_wave() -> void:
	if not spawn_points_available:
		return
	active = true
	for enemy in enemies.get_children():
		enemy.active = true

## Pauses spawning and every living raider.
func stop_wave() -> void:
	active = false
	for enemy in enemies.get_children():
		enemy.active = false

## Removes active enemies and restores the first-wave counters.
func reset() -> void:
	active = false
	spawned = 0
	alive = 0
	spawn_cooldown = 0.4
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

## Chooses one of the spawn markers placed in the world scene.
func random_spawn_position() -> Vector2:
	var positions: Array[Vector2] = world.spawn_positions()
	if positions.is_empty():
		push_error("World requires at least one spawn marker.")
		return world.core_position()
	return positions[rng.randi_range(0, positions.size() - 1)]

## Tracks wave progress and reports the reward to the match coordinator.
func _on_raider_defeated(reward: float) -> void:
	alive -= 1
	enemy_defeated.emit(reward)
	if spawned >= GameConfig.TOTAL_ENEMIES and alive <= 0:
		active = false
		wave_cleared.emit()
