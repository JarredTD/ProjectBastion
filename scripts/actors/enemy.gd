extends CharacterBody2D

signal defeated(reward: float, score_value: int)
signal core_hit(damage: float)

var definition: EnemyDefinition
var appearance: EnemyAppearance
var health: float
var attack_cooldown := 0.0
var active := true
var target_position := Vector2.ZERO
var target_range := 56.0

@onready var health_fill: ColorRect = %HealthFill
@onready var health_bar: Node2D = %HealthBar
@onready var visual_sprite: AnimatedSprite2D = %VisualSprite
@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var defeat_timer: Timer = %DefeatTimer

## Hides the health bar until the enemy is configured.
func _ready() -> void:
	health_bar.hide()
	defeat_timer.timeout.connect(queue_free)

## Applies this enemy's stats and objective.
func configure(enemy_definition: EnemyDefinition, core_position: Vector2, objective_range: float, appearance_index: int) -> void:
	definition = enemy_definition
	target_position = core_position
	target_range = objective_range
	health = maxf(1.0, definition.max_health)
	appearance = definition.appearances[clampi(appearance_index, 0, definition.appearances.size() - 1)]
	visual_sprite.sprite_frames = appearance.sprite_frames
	visual_sprite.scale = Vector2.ONE * appearance.visual_scale
	visual_sprite.position = appearance.offset
	visual_sprite.play(appearance.active_animation)
	var circle := collision_shape.shape.duplicate() as CircleShape2D
	circle.radius = definition.collision_radius
	collision_shape.shape = circle
	health_bar.position = definition.health_bar_offset
	$HealthBar/Background.size.x = definition.health_bar_width
	health_fill.color = definition.accent_color
	update_health_bar()

## Enables or pauses this enemy without exposing its internal state.
func set_active(value: bool) -> void:
	active = value and health > 0.0
	if not active:
		velocity = Vector2.ZERO

## Moves toward the objective and attacks anything that blocks the way.
func _physics_process(delta: float) -> void:
	if not active:
		velocity = Vector2.ZERO
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if definition == null:
		velocity = Vector2.ZERO
		return
	if global_position.distance_to(target_position) < target_range:
		velocity = Vector2.ZERO
		if attack_cooldown <= 0.0:
			core_hit.emit(definition.objective_damage)
			attack_cooldown = definition.attack_interval
		return
	velocity = global_position.direction_to(target_position) * definition.speed
	move_and_slide()
	for index in get_slide_collision_count():
		var collider := get_slide_collision(index).get_collider()
		if collider != null and collider.has_method("take_damage") and attack_cooldown <= 0.0:
			collider.take_damage(definition.structure_damage)
			attack_cooldown = definition.attack_interval
			break

## Removes health and reports the reward when the enemy is defeated.
func take_damage(amount: float) -> void:
	if not active or health <= 0.0 or amount <= 0.0:
		return
	health = maxf(0.0, health - amount)
	update_health_bar()
	if health <= 0.0:
		Audio.play_sfx(&"enemy_defeat", -2.0, randf_range(0.92, 1.08))
		set_active(false)
		health_bar.hide()
		visual_sprite.play(appearance.defeated_animation)
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		defeated.emit(definition.reward, definition.score_value)
		defeat_timer.start()
	else:
		Audio.play_sfx(&"hit", -5.0, randf_range(0.9, 1.1))

## Resizes the health bar and hides it while health is full.
func update_health_bar() -> void:
	health_fill.size.x = definition.health_bar_width * health / definition.max_health
	health_bar.visible = health < definition.max_health
