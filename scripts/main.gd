extends Node2D

const GameConfig = preload("res://scripts/game_config.gd")
const GameState = preload("res://scripts/game_state.gd")

var state := GameState.new()
var repair_sound_cooldown := 0.0

@onready var player: CharacterBody2D = $Actors/Player
@onready var world: Node2D = $World
@onready var camera_rig: Node2D = $CameraRig
@onready var build_manager: Node2D = $BuildManager
@onready var wave_director: Node = $WaveDirector
@onready var hud: CanvasLayer = $Hud
@onready var pause_menu: CanvasLayer = $PauseMenu

## Wires the scene together once every child is ready.
func _ready() -> void:
	Audio.play_music(Audio.MusicState.BUILD)
	player.configure(world.arena_rect(), world.player_start_position())
	camera_rig.configure(player, world.arena_rect())
	hud.configure(state, build_manager.definitions)
	hud.build_selected.connect(select_building)
	hud.wave_start_requested.connect(start_defense)
	hud.run_restart_requested.connect(reset_game)
	hud.endless_requested.connect(continue_endless)
	pause_menu.restart_requested.connect(reset_game)
	pause_menu.main_menu_requested.connect(_on_pause_main_menu_requested)
	build_manager.hover_hint_changed.connect(hud.set_build_hint)
	wave_director.enemy_defeated.connect(_on_enemy_defeated)
	wave_director.core_hit.connect(_on_core_hit)
	wave_director.wave_cleared.connect(_on_wave_cleared)
	state.reset(wave_director.objective_wave_count())
	prepare_current_wave()

## Advances the build timer and handles held repair input.
func _process(delta: float) -> void:
	repair_sound_cooldown = maxf(0.0, repair_sound_cooldown - delta)
	state.message_time = maxf(0.0, state.message_time - delta)
	if state.phase == GameState.Phase.BUILD:
		state.phase_time -= delta
		if state.phase_time <= 0.0:
			start_defense()
	elif state.phase == GameState.Phase.DEFEND and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		repair_nearby(delta)

## Routes discrete keyboard and mouse actions for the current phase.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		handle_key(event.keycode)
	elif event is InputEventMouseButton and event.pressed:
		var mouse_position := get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_LEFT:
			if state.phase == GameState.Phase.BUILD:
				build_manager.try_place(mouse_position)
			elif state.phase == GameState.Phase.DEFEND:
				player.try_attack(mouse_position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and state.phase == GameState.Phase.BUILD:
			build_manager.try_remove(mouse_position)

## Handles shortcuts that should work alongside the clickable HUD controls.
func handle_key(keycode: Key) -> void:
	match keycode:
		KEY_1:
			select_building(GameState.BuildKind.WALL)
		KEY_2:
			select_building(GameState.BuildKind.TURRET)
		KEY_SPACE:
			if state.phase == GameState.Phase.BUILD:
				start_defense()
		KEY_R:
			if state.phase == GameState.Phase.VICTORY or state.phase == GameState.Phase.DEFEAT:
				reset_game()

## Selects a buildable when the match is still in its build phase.
func select_building(index: int) -> void:
	if state.phase == GameState.Phase.BUILD and index >= 0 and index < build_manager.definitions.size():
		state.build_kind = index

## Ends building and releases the prepared enemy wave.
func start_defense() -> void:
	if state.phase != GameState.Phase.BUILD:
		return
	state.phase = GameState.Phase.DEFEND
	Audio.play_music(Audio.MusicState.DEFENSE)
	Audio.play_sfx(&"wave_start")
	player.combat_enabled = true
	wave_director.start_wave()
	state.show_message("The rush is here! Left-click to fight. Hold right-click near damage to repair.", 5.0)

## Repairs the nearest damaged structure, or the core, while spending scrap.
func repair_nearby(delta: float) -> void:
	if state.scrap <= 0.0:
		return
	var target: Node2D = player.find_repair_target()
	var repaired := false
	if target != null:
		repaired = target.repair(24.0 * delta)
	elif player.global_position.distance_to(world.core_position()) < 74.0 and state.base_hp < GameConfig.MAX_BASE_HP:
		state.base_hp = minf(GameConfig.MAX_BASE_HP, state.base_hp + 18.0 * delta)
		repaired = true
	if repaired:
		state.scrap = maxf(0.0, state.scrap - 6.0 * delta)
		if repair_sound_cooldown <= 0.0:
			Audio.play_sfx(&"repair", -5.0, randf_range(0.96, 1.04))
			repair_sound_cooldown = 0.24

## Clears the arena and starts a fresh build phase.
func reset_game() -> void:
	wave_director.reset()
	build_manager.reset()
	state.reset(wave_director.objective_wave_count())
	player.reset()
	camera_rig.snap_to_target()
	repair_sound_cooldown = 0.0
	Audio.play_music(Audio.MusicState.BUILD)
	prepare_current_wave()

## Leaves the completed objective intact and begins the escalating endless run.
func continue_endless() -> void:
	if state.phase != GameState.Phase.VICTORY:
		return
	state.endless = true
	state.wave_number += 1
	player.controls_enabled = true
	Audio.play_music(Audio.MusicState.BUILD)
	prepare_current_wave()

## Selects and reveals the next wave before its build timer begins.
func prepare_current_wave() -> void:
	if not wave_director.prepare_wave(state.wave_number):
		finish_run(GameState.Phase.DEFEAT, "The next rush could not be prepared.")
		return
	state.phase = GameState.Phase.BUILD
	state.phase_time = wave_director.build_duration()
	state.wave_enemies = wave_director.enemy_count()
	state.wave_enemies_defeated = 0
	player.combat_enabled = false
	var wave_name := "Endless %d" % (state.wave_number - state.objective_wave_count) if state.endless else "Wave %d" % state.wave_number
	state.show_message(
		"%s: %d shoppers approaching from %s." % [wave_name, state.wave_enemies, wave_director.approach_summary()],
		state.phase_time
	)

## Freezes active play and presents the final result.
func finish_run(result: GameState.Phase, message: String) -> void:
	state.phase = result
	state.show_message(message, 999.0)
	player.controls_enabled = false
	player.combat_enabled = false
	wave_director.stop_wave()
	Audio.play_music(Audio.MusicState.VICTORY if result == GameState.Phase.VICTORY else Audio.MusicState.DEFEAT)

## Awards scrap and updates the defeated-enemy count.
func _on_enemy_defeated(reward: float) -> void:
	state.scrap += reward
	state.enemies_defeated += 1
	state.wave_enemies_defeated += 1

## Applies core damage and ends the run if the core falls.
func _on_core_hit(damage: float) -> void:
	if state.phase != GameState.Phase.DEFEND:
		return
	state.base_hp = maxf(0.0, state.base_hp - damage)
	Audio.play_sfx(&"core_hit", -2.0, randf_range(0.96, 1.03))
	if not camera_rig.is_world_position_visible(world.core_position()):
		hud.show_core_warning()
	if state.base_hp <= 0.0:
		finish_run(GameState.Phase.DEFEAT, "The stock was overrun.")

## Advances the objective or ends it before the optional endless run.
func _on_wave_cleared() -> void:
	if state.phase != GameState.Phase.DEFEND:
		return
	state.waves_cleared += 1
	if not state.endless and state.wave_number >= state.objective_wave_count:
		finish_run(GameState.Phase.VICTORY, "Opening time reached. The stock is secure!")
		return
	state.wave_number += 1
	Audio.play_music(Audio.MusicState.BUILD)
	prepare_current_wave()

## Returns to the title screen from the pause menu.
func _on_pause_main_menu_requested() -> void:
	var error := get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	if error != OK:
		push_error("Could not return to the main menu: %s" % error_string(error))
