class_name EnemyDefinition
extends Resource

@export_category("Identity")
@export var display_name := "Enemy"
@export var scene: PackedScene
@export var behavior_id: StringName = &"direct"
@export var accent_color := Color("ed5b68")

@export_category("Movement and combat")
@export_range(1.0, 10000.0, 1.0) var max_health := 72.0
@export_range(0.0, 1000.0, 1.0) var speed := 58.0
@export_range(0.0, 1000.0, 1.0) var structure_damage := 13.0
@export_range(0.0, 1000.0, 1.0) var objective_damage := 12.0
@export_range(0.05, 10.0, 0.05) var attack_interval := 0.75
@export_range(0.0, 1000.0, 1.0) var reward := 5.0
