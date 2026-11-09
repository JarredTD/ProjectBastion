class_name UpgradeManager
extends Node

signal changed

const GameState = preload("res://scripts/game_state.gd")

@export_node_path("CharacterBody2D") var player_path: NodePath
@export_node_path("Node2D") var structures_path: NodePath
@export var definitions: Array[UpgradeDefinition] = [
	preload("res://data/upgrades/reinforced_carts.tres"),
	preload("res://data/upgrades/security_training.tres"),
	preload("res://data/upgrades/staff_training.tres"),
]

var state: GameState
var levels: Dictionary = {}

@onready var player: CharacterBody2D = get_node(player_path)
@onready var structures: Node2D = get_node(structures_path)


## Validates the authored upgrade catalog once the scene is ready.
func _ready() -> void:
	var known_ids: Dictionary = {}
	for definition in definitions:
		if definition == null or definition.id == &"":
			push_error("Every upgrade requires a definition and id.")
			continue
		if known_ids.has(definition.id):
			push_error("Duplicate upgrade id: %s" % definition.id)
		known_ids[definition.id] = true


## Attaches the current run state and clears purchased levels.
func configure(game_state: GameState) -> void:
	state = game_state
	reset()


## Clears run upgrades and restores authored combat values.
func reset() -> void:
	levels.clear()
	apply_player_upgrades()
	for structure in structures.get_children():
		apply_to_structure(structure)
	changed.emit()


## Purchases one level during a build phase when it is available and affordable.
func purchase(index: int) -> bool:
	if state == null or state.phase != GameState.Phase.BUILD or index < 0 or index >= definitions.size():
		return false
	var definition := definitions[index]
	var current_level := level_for(index)
	if not is_unlocked(index) or current_level >= definition.max_level:
		Audio.play_sfx(&"invalid", -3.0)
		return false
	var cost := definition.cost_for_level(current_level)
	if state.coins < cost:
		Audio.play_sfx(&"invalid", -3.0)
		state.show_message("%d more coins needed for %s." % [ceili(cost - state.coins), definition.display_name.capitalize()], 2.0)
		return false
	state.coins -= cost
	levels[definition.id] = current_level + 1
	apply_player_upgrades()
	for structure in structures.get_children():
		apply_to_structure(structure)
	Audio.play_sfx(&"place", -2.0, 1.08)
	state.show_message("%s upgraded to level %d." % [definition.display_name.capitalize(), current_level + 1], 2.5)
	changed.emit()
	return true


## Applies current run upgrades to a newly placed or existing structure.
func apply_to_structure(structure: Node) -> void:
	if structure.is_in_group("walls") and structure.has_method(&"set_health_multiplier"):
		structure.call(&"set_health_multiplier", multiplier_for(UpgradeDefinition.Effect.WALL_HEALTH))
	if structure.is_in_group("turrets") and structure.has_method(&"set_damage_multiplier"):
		structure.call(&"set_damage_multiplier", multiplier_for(UpgradeDefinition.Effect.TURRET_DAMAGE))


## Returns the purchased level for a catalog entry.
func level_for(index: int) -> int:
	if index < 0 or index >= definitions.size():
		return 0
	return int(levels.get(definitions[index].id, 0))


## Reports whether the current rush has introduced this upgrade.
func is_unlocked(index: int) -> bool:
	return state != null and index >= 0 and index < definitions.size() and state.wave_number >= definitions[index].available_from_wave


## Reports whether this rush introduces at least one catalog entry.
func has_unlocks_for_wave(wave_number: int) -> bool:
	for definition in definitions:
		if definition.available_from_wave == wave_number:
			return true
	return false


## Returns the next price, even when the upgrade is currently locked.
func next_cost(index: int) -> int:
	if index < 0 or index >= definitions.size():
		return 0
	return definitions[index].cost_for_level(level_for(index))


## Multiplies every purchased level of one effect into its final value.
func multiplier_for(effect: int) -> float:
	var multiplier := 1.0
	for index in definitions.size():
		var definition := definitions[index]
		if definition.effect == effect:
			multiplier += definition.amount * level_for(index)
	return multiplier


func apply_player_upgrades() -> void:
	if player != null and player.has_method(&"set_attack_damage_multiplier"):
		player.call(&"set_attack_damage_multiplier", multiplier_for(UpgradeDefinition.Effect.PLAYER_DAMAGE))
