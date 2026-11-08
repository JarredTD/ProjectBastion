class_name EnemyAppearance
extends Resource

@export var active_texture: Texture2D
@export var defeated_texture: Texture2D
@export_range(0.01, 2.0, 0.01) var visual_scale := 0.2
@export var offset := Vector2.ZERO

## Checks the textures required for this appearance.
func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if active_texture == null:
		errors.append("Active texture is missing.")
	if defeated_texture == null:
		errors.append("Defeated texture is missing.")
	return errors
