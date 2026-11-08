extends "res://scripts/actors/structure.gd"

@export_range(0.0, 1000.0, 1.0) var damage := 19.0

var targets: Array[Node2D] = []

@onready var fire_timer: Timer = %FireTimer
@onready var flash_timer: Timer = %FlashTimer
@onready var muzzle_flash: Line2D = %MuzzleFlash
@onready var visuals: Node2D = $Visuals

## Connects detection and firing timers after base structure setup.
func _ready() -> void:
	super()
	%DetectionArea.body_entered.connect(_on_body_entered)
	%DetectionArea.body_exited.connect(_on_body_exited)
	fire_timer.timeout.connect(fire)
	flash_timer.timeout.connect(func() -> void: muzzle_flash.visible = false)

## Tracks an enemy when it enters firing range.
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		targets.append(body)

## Stops tracking an enemy after it leaves firing range.
func _on_body_exited(body: Node2D) -> void:
	targets.erase(body)

## Fires at the nearest valid enemy currently in range.
func fire() -> void:
	targets = targets.filter(func(tracked_enemy: Node2D) -> bool: return is_instance_valid(tracked_enemy))
	if targets.is_empty():
		return
	var selected_target: Node2D = targets[0]
	for candidate in targets:
		if global_position.distance_to(candidate.global_position) < global_position.distance_to(selected_target.global_position):
			selected_target = candidate
	Audio.play_sfx(&"turret_fire", -3.0, randf_range(0.96, 1.05))
	visuals.rotation = global_position.direction_to(selected_target.global_position).angle() + PI * 0.5
	selected_target.take_damage(damage)
	muzzle_flash.points = PackedVector2Array([Vector2.ZERO, to_local(selected_target.global_position)])
	muzzle_flash.visible = true
	flash_timer.start()
