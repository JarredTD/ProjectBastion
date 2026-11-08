class_name EnemyDefinition
extends Resource

@export_category("Identity")
@export var display_name := "Enemy"
@export var plural_name := "Enemies"
@export var scene: PackedScene
@export var accent_color := Color("ed5b68")

@export_category("Presentation")
@export var appearances: Array[EnemyAppearance] = []

@export_category("Movement and combat")
@export_range(1.0, 10000.0, 1.0) var max_health := 72.0
@export_range(0.0, 1000.0, 1.0) var speed := 58.0
@export_range(0.0, 1000.0, 1.0) var structure_damage := 13.0
@export_range(0.0, 1000.0, 1.0) var objective_damage := 12.0
@export_range(0.05, 10.0, 0.05) var attack_interval := 0.75
@export_range(0.0, 1000.0, 1.0) var reward := 5.0
@export_range(0, 100000, 1) var score_value := 100

## Checks the fields needed to spawn this enemy.
func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if display_name.strip_edges().is_empty():
		errors.append("Display name cannot be empty.")
	if plural_name.strip_edges().is_empty():
		errors.append("Plural name cannot be empty.")
	if scene == null:
		errors.append("Enemy scene is missing.")
	if appearances.is_empty():
		errors.append("At least one appearance is required.")
	for index in appearances.size():
		var appearance := appearances[index]
		if appearance == null:
			errors.append("Appearance %d is missing." % index)
			continue
		for error in appearance.validation_errors():
			errors.append("Appearance %d: %s" % [index, error])
	return errors
