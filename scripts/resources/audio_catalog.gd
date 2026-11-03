class_name AudioCatalog
extends Resource

@export_category("Music")
@export var menu_music: AudioStream
@export var build_music: AudioStream
@export var defense_music: AudioStream
@export var victory_music: AudioStream
@export var defeat_music: AudioStream

@export_category("Interface")
@export var ui_click: AudioStream

@export_category("Gameplay")
@export var place: AudioStream
@export var remove: AudioStream
@export var invalid: AudioStream
@export var wave_start: AudioStream
@export var player_attack: AudioStream
@export var repair: AudioStream
@export var turret_fire: AudioStream
@export var hit: AudioStream
@export var raider_death: AudioStream
@export var structure_break: AudioStream
@export var core_hit: AudioStream

## Resolves a named gameplay cue without exposing file paths to actors.
func sound_for(cue: StringName) -> AudioStream:
	match cue:
		&"ui_click": return ui_click
		&"place": return place
		&"remove": return remove
		&"invalid": return invalid
		&"wave_start": return wave_start
		&"player_attack": return player_attack
		&"repair": return repair
		&"turret_fire": return turret_fire
		&"hit": return hit
		&"raider_death": return raider_death
		&"structure_break": return structure_break
		&"core_hit": return core_hit
		_:
			push_warning("Unknown sound cue: %s" % cue)
			return null
