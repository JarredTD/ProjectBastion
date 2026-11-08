extends Node2D

signal hover_hint_changed(text: String)

const GameConfig = preload("res://scripts/game_config.gd")
const GameState = preload("res://scripts/game_state.gd")

@export_node_path("Node2D") var world_path: NodePath
@export_node_path("Node2D") var structures_path: NodePath
@export var definitions: Array[BuildDefinition] = [
	preload("res://data/buildables/wall.tres"),
	preload("res://data/buildables/turret.tres"),
]

@onready var game: Node2D = get_parent()
@onready var world: Node2D = get_node(world_path)
@onready var structures: Node2D = get_node(structures_path)
@onready var preview: Polygon2D = $Preview

var placed_definitions: Dictionary = {}
var last_hover_hint := ""
var definitions_valid := false

## Verifies that every build option has the scene needed for placement.
func _ready() -> void:
	if definitions.is_empty():
		push_error("Build manager requires at least one build definition.")
		preview.hide()
		return
	for index in definitions.size():
		var definition := definitions[index]
		if definition == null or definition.scene == null:
			push_error("Build definition %d is missing its resource or scene." % index)
			preview.hide()
			return
	definitions_valid = true

## Updates the placement preview and its contextual hint.
func _process(_delta: float) -> void:
	if not definitions_valid:
		return
	var state: GameState = game.state
	var mouse_position := get_global_mouse_position()
	preview.visible = state.phase == GameState.Phase.BUILD and world.arena_rect().has_point(mouse_position) and not pointer_is_over_ui()
	if not preview.visible:
		set_hover_hint("")
		return
	var cell := cell_from_position(mouse_position)
	var place_pos := cell_center(cell)
	preview.global_position = place_pos
	var definition: BuildDefinition = current_definition(state)
	var occupied: bool = state.occupied.has(cell)
	var valid: bool = not occupied and place_pos.distance_to(world.core_position()) >= world.core_clearance() and state.coins >= definition.cost
	if occupied:
		preview.color = Color(0.95, 0.62, 0.24, 0.55)
	else:
		preview.color = Color(0.25, 0.9, 0.68, 0.45) if valid else Color(1.0, 0.25, 0.3, 0.45)
	set_hover_hint(placement_hint(state, cell, place_pos, definition))

## Places the selected structure when the hovered cell is valid and affordable.
func try_place(mouse_position: Vector2) -> void:
	if not definitions_valid:
		game.state.show_message("Build data is unavailable.", 2.0)
		return
	var state: GameState = game.state
	if not world.arena_rect().has_point(mouse_position):
		return
	var cell := cell_from_position(mouse_position)
	var place_pos := cell_center(cell)
	var definition: BuildDefinition = current_definition(state)
	if state.occupied.has(cell):
		Audio.play_sfx(&"invalid", -3.0)
		state.show_message("There's already something there.", 2.0)
		return
	if place_pos.distance_to(world.core_position()) < world.core_clearance():
		Audio.play_sfx(&"invalid", -3.0)
		state.show_message("That's too close to the stock.", 2.0)
		return
	if state.coins < definition.cost:
		Audio.play_sfx(&"invalid", -3.0)
		state.show_message("Not enough coins.", 2.0)
		return
	var structure: StaticBody2D = definition.scene.instantiate()
	structures.add_child(structure)
	structure.global_position = place_pos
	structure.configure(cell)
	structure.destroyed.connect(_on_structure_destroyed)
	state.occupied[cell] = true
	placed_definitions[cell] = definition
	state.coins -= definition.cost
	Audio.play_sfx(&"place", -1.0, randf_range(0.96, 1.04))

## Removes a placed structure during building and refunds its full cost.
func try_remove(mouse_position: Vector2) -> void:
	var state: GameState = game.state
	if state.phase != GameState.Phase.BUILD or not world.arena_rect().has_point(mouse_position):
		return
	var cell := cell_from_position(mouse_position)
	if not state.occupied.has(cell):
		return
	for structure in structures.get_children():
		if structure.cell == cell:
			var definition: BuildDefinition = placed_definitions.get(cell)
			if definition != null:
				state.coins += definition.cost
				state.show_message("%s removed  •  +%d coins" % [definition.display_name.capitalize(), definition.cost], 2.0)
			state.occupied.erase(cell)
			placed_definitions.erase(cell)
			Audio.play_sfx(&"remove", -1.0, randf_range(0.96, 1.04))
			structure.queue_free()
			return

## Clears placed structures and local placement records for a new run.
func reset() -> void:
	for structure in structures.get_children():
		structure.queue_free()
	placed_definitions.clear()
	preview.visible = definitions_valid

## Converts a world-space pointer position into a grid cell.
func cell_from_position(mouse_position: Vector2) -> Vector2i:
	return Vector2i(floori(mouse_position.x / GameConfig.GRID_SIZE), floori(mouse_position.y / GameConfig.GRID_SIZE))

## Returns the world-space center of a grid cell.
func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * GameConfig.GRID_SIZE + Vector2.ONE * GameConfig.GRID_SIZE * 0.5

## Returns the build definition selected by the current state.
func current_definition(state: GameState) -> BuildDefinition:
	return definitions[clampi(state.build_kind, 0, definitions.size() - 1)]

## Describes what a click would do at the hovered cell.
func placement_hint(state: GameState, cell: Vector2i, place_pos: Vector2, definition: BuildDefinition) -> String:
	if state.occupied.has(cell):
		return "Right-click to remove • full refund"
	if place_pos.distance_to(world.core_position()) < world.core_clearance():
		return "Can't build this close to the stock"
	if state.coins < definition.cost:
		return "%d more coins needed" % ceili(definition.cost - state.coins)
	return "Left-click to place %s" % definition.display_name.capitalize()

## Prevents world previews from appearing beneath interactive HUD controls.
func pointer_is_over_ui() -> bool:
	var hovered_control := get_viewport().gui_get_hovered_control()
	return hovered_control != null and hovered_control.mouse_filter != Control.MOUSE_FILTER_IGNORE

## Emits hover copy only when it has actually changed.
func set_hover_hint(text: String) -> void:
	if text == last_hover_hint:
		return
	last_hover_hint = text
	hover_hint_changed.emit(text)

## Releases a grid cell after its structure is destroyed during combat.
func _on_structure_destroyed(cell: Vector2i) -> void:
	game.state.occupied.erase(cell)
	placed_definitions.erase(cell)
