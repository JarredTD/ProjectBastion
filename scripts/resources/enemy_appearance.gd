class_name EnemyAppearance
extends Resource

@export var sprite_frames: SpriteFrames
@export var active_animation: StringName = &"active"
@export var defeated_animation: StringName = &"defeated"
@export_range(0.01, 2.0, 0.01) var visual_scale := 0.2
@export var offset := Vector2.ZERO

## Checks the animations required for this appearance.
func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if sprite_frames == null:
		errors.append("Sprite frames are missing.")
		return errors
	if not sprite_frames.has_animation(active_animation):
		errors.append("Active animation '%s' is missing." % active_animation)
	if not sprite_frames.has_animation(defeated_animation):
		errors.append("Defeated animation '%s' is missing." % defeated_animation)
	return errors
