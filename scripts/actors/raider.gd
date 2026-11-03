extends CharacterBody2D

signal defeated(reward: float)
signal core_hit(damage: float)

@export var max_health := 72.0
@export var speed := 39.0
@export var structure_damage := 13.0
@export var core_damage := 12.0
@export var attack_interval := 0.75
@export var reward := 5.0

var health: float
var attack_cooldown := 0.0
var active := true
var target_position := Vector2.ZERO

@onready var health_fill: ColorRect = %HealthFill
@onready var health_bar: Node2D = %HealthBar

## Starts the raider at full health.
func _ready() -> void:
	health = max_health
	update_health_bar()

## Sets the core this raider should move toward.
func configure(core_position: Vector2) -> void:
	target_position = core_position

## Moves toward the core and attacks anything that blocks the way.
func _physics_process(delta: float) -> void:
	if not active:
		velocity = Vector2.ZERO
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if global_position.distance_to(target_position) < 47.0:
		velocity = Vector2.ZERO
		if attack_cooldown <= 0.0:
			core_hit.emit(core_damage)
			attack_cooldown = attack_interval
		return
	velocity = global_position.direction_to(target_position) * speed
	move_and_slide()
	for index in get_slide_collision_count():
		var collider := get_slide_collision(index).get_collider()
		if collider != null and collider.has_method("take_damage") and attack_cooldown <= 0.0:
			collider.take_damage(structure_damage)
			attack_cooldown = attack_interval
			break

## Removes health and reports the reward when the raider dies.
func take_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	update_health_bar()
	if health <= 0.0:
		Audio.play_sfx(&"raider_death", -2.0, randf_range(0.92, 1.08))
		active = false
		defeated.emit(reward)
		queue_free()
	else:
		Audio.play_sfx(&"hit", -5.0, randf_range(0.9, 1.1))

## Resizes the health bar and hides it while health is full.
func update_health_bar() -> void:
	health_fill.size.x = 24.0 * health / max_health
	health_bar.visible = health < max_health
