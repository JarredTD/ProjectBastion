extends Node2D

const GameConfig = preload("res://scripts/game_config.gd")
const GameState = preload("res://scripts/game_state.gd")
const REPAIR_COST_PER_SECOND := 6.0
const STRUCTURE_REPAIR_PER_SECOND := 24.0
const STOREFRONT_REPAIR_PER_SECOND := 18.0

var state := GameState.new()
var repair_sound_cooldown := 0.0
var touch_repair_held := false

@export var score_rules: ScoreRules

@onready var player: CharacterBody2D = $Actors/Player
@onready var world: Node2D = $World
@onready var camera_rig: Node2D = $CameraRig
@onready var build_manager: Node2D = $BuildManager
@onready var wave_director: Node = $WaveDirector
@onready var upgrade_manager: UpgradeManager = $UpgradeManager
@onready var hud: CanvasLayer = $Hud
@onready var mobile_controls: CanvasLayer = $MobileControls
@onready var upgrade_panel: CanvasLayer = $UpgradePanel
@onready var pause_menu: CanvasLayer = $PauseMenu

## Wires the scene together once every child is ready.
func _ready() -> void:
	if score_rules == null:
		push_warning("Score rules are missing; using default values.")
		score_rules = ScoreRules.new()
	Audio.play_music(Audio.MusicState.BUILD)
	world.configure(state)
	player.configure(world.arena_rect(), world.player_start_position())
	camera_rig.configure(player, world.arena_rect())
	hud.configure(state, build_manager.definitions)
	mobile_controls.configure(state)
	upgrade_manager.configure(state)
	upgrade_panel.configure(upgrade_manager, state)
	hud.build_selected.connect(select_building)
	hud.wave_start_requested.connect(start_defense)
	hud.run_restart_requested.connect(reset_game)
	hud.endless_requested.connect(continue_endless)
	hud.upgrades_requested.connect(upgrade_panel.open)
	pause_menu.restart_requested.connect(reset_game)
	pause_menu.main_menu_requested.connect(_on_pause_main_menu_requested)
	mobile_controls.world_action_requested.connect(_on_touch_world_action)
	mobile_controls.movement_changed.connect(player.set_touch_movement)
	mobile_controls.repair_held_changed.connect(set_touch_repair_held)
	mobile_controls.pause_requested.connect(pause_menu.toggle)
	mobile_controls.upgrades_requested.connect(upgrade_panel.open)
	mobile_controls.touch_mode_changed.connect(hud.set_touch_mode)
	hud.set_touch_mode(mobile_controls.is_touch_mode())
	build_manager.hover_hint_changed.connect(hud.set_build_hint)
	wave_director.enemy_defeated.connect(_on_enemy_defeated)
	wave_director.core_hit.connect(_on_core_hit)
	wave_director.wave_cleared.connect(_on_wave_cleared)
	state.reset(wave_director.objective_wave_count(), wave_director.begin_run())
	prepare_current_wave()

## Advances the build timer and handles held repair input.
func _process(delta: float) -> void:
	repair_sound_cooldown = maxf(0.0, repair_sound_cooldown - delta)
	state.message_time = maxf(0.0, state.message_time - delta)
	if state.phase == GameState.Phase.BUILD:
		state.phase_time -= delta
		if state.phase_time <= 0.0:
			start_defense()
	elif state.phase == GameState.Phase.DEFEND and (Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or touch_repair_held):
		repair_nearby(delta)

## Routes discrete keyboard and mouse actions for the current phase.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		handle_key(event.keycode)
	elif event is InputEventMouseButton and event.pressed and not mobile_controls.blocks_mouse_gameplay():
		var mouse_position := get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_LEFT:
			primary_action(mouse_position)
		elif event.button_index == MOUSE_BUTTON_RIGHT and state.phase == GameState.Phase.BUILD:
			remove_action(mouse_position)

## Uses the current phase to interpret the primary world action.
func primary_action(world_position: Vector2) -> void:
	if state.phase == GameState.Phase.BUILD:
		build_manager.try_place(world_position)
	elif state.phase == GameState.Phase.DEFEND:
		player.try_attack(world_position)

## Removes a structure when demolition is available.
func remove_action(world_position: Vector2) -> void:
	if state.phase == GameState.Phase.BUILD:
		build_manager.try_remove(world_position)

## Tracks the held repair action supplied by touch controls.
func set_touch_repair_held(value: bool) -> void:
	touch_repair_held = value

## Converts a touch position through the active camera before acting on it.
func _on_touch_world_action(screen_position: Vector2, removing: bool) -> void:
	var world_position := get_viewport().get_canvas_transform().affine_inverse() * screen_position
	if removing:
		remove_action(world_position)
	else:
		primary_action(world_position)

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
		KEY_F10:
			mobile_controls.toggle_desktop_preview()

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
	if mobile_controls.is_touch_mode():
		state.show_message("The rush is here! Tap shoppers to fight. Hold REPAIR near damage.", 5.0)
	else:
		state.show_message("The rush is here! Left-click to fight. Hold right-click near damage to repair.", 5.0)

## Repairs the nearest damaged structure, or the core, while spending coins.
func repair_nearby(delta: float) -> void:
	if state.coins <= 0.0:
		return
	var affordable_time := minf(delta, state.coins / REPAIR_COST_PER_SECOND)
	var target: Node2D = player.find_repair_target()
	var repaired_amount := 0.0
	var repair_rate := STRUCTURE_REPAIR_PER_SECOND
	if target != null:
		repaired_amount = target.repair(repair_rate * affordable_time)
	elif player.global_position.distance_to(world.core_position()) < world.core_repair_range() and state.base_hp < GameConfig.MAX_BASE_HP:
		repair_rate = STOREFRONT_REPAIR_PER_SECOND
		repaired_amount = minf(repair_rate * affordable_time, GameConfig.MAX_BASE_HP - state.base_hp)
		state.base_hp += repaired_amount
	if repaired_amount > 0.0:
		state.coins = maxf(0.0, state.coins - repaired_amount / repair_rate * REPAIR_COST_PER_SECOND)
		if repair_sound_cooldown <= 0.0:
			Audio.play_sfx(&"repair", -5.0, randf_range(0.96, 1.04))
			repair_sound_cooldown = 0.24

## Clears the arena and starts a fresh build phase.
func reset_game(seed := 0) -> void:
	wave_director.reset()
	build_manager.reset()
	state.reset(wave_director.objective_wave_count(), wave_director.begin_run(seed))
	player.reset()
	upgrade_manager.reset()
	touch_repair_held = false
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
	state.wave_composition = wave_director.enemy_summary()
	player.combat_enabled = false
	var has_new_upgrades := upgrade_manager.has_unlocks_for_wave(state.wave_number)
	var has_sale := upgrade_manager.sale_index() >= 0
	if has_new_upgrades and has_sale:
		state.show_message("New upgrades are available, including a flash sale.", 4.0)
	elif has_new_upgrades:
		state.show_message("New upgrades available. Spend coins before the rush.", 4.0)
	elif has_sale:
		state.show_message("A flash sale is open for this build phase.", 4.0)
	else:
		state.show_message("Build before the rush.", 4.0)

## Freezes active play and presents the final result.
func finish_run(result: GameState.Phase, message: String) -> void:
	state.phase = result
	finalize_run_summary(result)
	state.show_message(message, 999.0)
	player.controls_enabled = false
	player.combat_enabled = false
	wave_director.stop_wave()
	Audio.play_music(Audio.MusicState.VICTORY if result == GameState.Phase.VICTORY else Audio.MusicState.DEFEAT)

## Captures the completed run and updates its mode's local record.
func finalize_run_summary(result: GameState.Phase) -> void:
	var mode: StringName = &"endless" if state.endless else &"objective"
	var new_best := Records.record_score(mode, state.score)
	state.run_summary = RunSummary.new(
		mode,
		state.score,
		state.shopper_points,
		state.rush_points,
		state.stock_points,
		state.waves_cleared,
		state.enemies_defeated,
		roundi(state.base_hp),
		state.run_seed,
		result == GameState.Phase.VICTORY,
		Records.best_score(mode),
		new_best,
		Records.is_persistent(),
	)

## Awards coins and updates the defeated-enemy count.
func _on_enemy_defeated(reward: float, score_value: int) -> void:
	state.coins += reward
	state.enemies_defeated += 1
	state.wave_enemies_defeated += 1
	state.award_shopper_points(score_value)

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
	state.award_rush_points(score_rules.rush_clear_bonus(state.wave_number))
	if not state.endless and state.wave_number >= state.objective_wave_count:
		state.award_stock_points(score_rules.stock_bonus(state.base_hp, GameConfig.MAX_BASE_HP))
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
