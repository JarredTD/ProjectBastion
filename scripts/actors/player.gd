extends CharacterBody2D

@export_range(0.0, 1000.0, 1.0) var speed := 190.0
@export_range(0.0, 1000.0, 1.0) var attack_damage := 30.0
@export_range(0.0, 1000.0, 1.0) var attack_range := 92.0

var controls_enabled := true
var combat_enabled := false
var movement_bounds := Rect2()

@onready var attack_timer: Timer = %AttackTimer
@onready var flash_timer: Timer = %FlashTimer
@onready var attack_flash: Line2D = %AttackFlash

## Connects the short-lived attack effect.
func _ready() -> void:
	flash_timer.timeout.connect(func() -> void: attack_flash.visible = false)

## Gives the player the part of the world they are allowed to move through.
func configure(arena_bounds: Rect2) -> void:
	movement_bounds = arena_bounds

## Reads movement input and moves the character through physics.
func _physics_process(_delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_key_pressed(KEY_LEFT): direction.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT): direction.x += 1.0
	if Input.is_key_pressed(KEY_UP): direction.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN): direction.y += 1.0
	direction = direction.limit_length(1.0)
	velocity = direction * speed
	move_and_slide()
	global_position.x = clampf(global_position.x, movement_bounds.position.x + 12.0, movement_bounds.end.x - 12.0)
	global_position.y = clampf(global_position.y, movement_bounds.position.y + 12.0, movement_bounds.end.y - 12.0)
	if direction != Vector2.ZERO:
		rotation = direction.angle() + PI * 0.5

## Attacks the enemy nearest the click when it is within reach.
func try_attack(mouse_position: Vector2) -> void:
	if not combat_enabled or not attack_timer.is_stopped():
		return
	var target: Node2D = null
	var best_mouse_distance := 42.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var mouse_distance: float = enemy.global_position.distance_to(mouse_position)
		if global_position.distance_to(enemy.global_position) <= attack_range and mouse_distance < best_mouse_distance:
			target = enemy
			best_mouse_distance = mouse_distance
	if target != null:
		Audio.play_sfx(&"player_attack", -1.0, randf_range(0.97, 1.04))
		target.take_damage(attack_damage)
		attack_flash.points = PackedVector2Array([Vector2.ZERO, to_local(target.global_position)])
		attack_flash.visible = true
		flash_timer.start()
	attack_timer.start()

## Finds the nearest damaged structure close enough to repair.
func find_repair_target() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := 58.0
	for structure in get_tree().get_nodes_in_group("structures"):
		var distance: float = global_position.distance_to(structure.global_position)
		if structure.is_damaged() and distance < nearest_distance:
			nearest = structure
			nearest_distance = distance
	return nearest

## Returns the player to their starting point for a new run.
func reset() -> void:
	global_position = Vector2(576.0, 465.0)
	rotation = 0.0
	velocity = Vector2.ZERO
	controls_enabled = true
	combat_enabled = false
	attack_timer.stop()
	flash_timer.stop()
	attack_flash.hide()
