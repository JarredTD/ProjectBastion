extends CanvasLayer

signal build_selected(index: int)
signal wave_start_requested
signal run_restart_requested
signal endless_requested

const GameConfig = preload("res://scripts/game_config.gd")
const GameState = preload("res://scripts/game_state.gd")

var state: GameState
var build_definitions: Array
var touch_mode := false

@onready var phase_label: Label = %PhaseLabel
@onready var score_label: Label = %ScoreLabel
@onready var coin_label: Label = %CoinLabel
@onready var core_label: Label = %CoreLabel
@onready var build_panel: Control = %BuildPanel
@onready var wall_button: Button = %WallButton
@onready var turret_button: Button = %TurretButton
@onready var start_wave_button: Button = %StartWaveButton
@onready var build_hint_label: Label = %BuildHintLabel
@onready var wave_intel_panel: Control = %WaveIntelPanel
@onready var intel_title: Label = %IntelTitle
@onready var intel_wave: Label = %IntelWave
@onready var intel_composition: Label = %IntelComposition
@onready var intel_approaches: Label = %IntelApproaches
@onready var help_label: Label = %HelpLabel
@onready var message_panel: Control = %MessagePanel
@onready var message_label: Label = %MessageLabel
@onready var core_warning_panel: Control = %CoreWarningPanel
@onready var end_panel: Control = %EndPanel
@onready var end_title: Label = %EndTitle
@onready var end_score: Label = %EndScore
@onready var end_breakdown: Label = %EndBreakdown
@onready var end_stats: Label = %EndStats
@onready var record_label: Label = %RecordLabel
@onready var continue_button: Button = %ContinueButton
@onready var restart_button: Button = %RestartButton
@onready var layout: Control = $Layout

var core_warning_time := 0.0

## Connects the clickable controls to the HUD's public signals.
func _ready() -> void:
	wall_button.pressed.connect(func() -> void: build_selected.emit(GameState.BuildKind.WALL))
	turret_button.pressed.connect(func() -> void: build_selected.emit(GameState.BuildKind.TURRET))
	start_wave_button.pressed.connect(func() -> void: wave_start_requested.emit())
	continue_button.pressed.connect(func() -> void: endless_requested.emit())
	restart_button.pressed.connect(func() -> void: run_restart_requested.emit())
	get_viewport().size_changed.connect(update_safe_area)

## Supplies the live match state and buildable definitions shown by the HUD.
func configure(game_state: GameState, definitions: Array) -> void:
	state = game_state
	build_definitions = definitions

## Updates the short line of feedback beneath the build controls.
func set_build_hint(text: String) -> void:
	build_hint_label.text = text

## Adapts labels and guidance for touch controls.
func set_touch_mode(enabled: bool) -> void:
	touch_mode = enabled
	help_label.visible = not enabled
	build_hint_label.visible = not enabled
	update_safe_area()

## Insets the HUD around mobile display cutouts.
func update_safe_area() -> void:
	layout.offset_left = 0.0
	layout.offset_top = 0.0
	layout.offset_right = 0.0
	layout.offset_bottom = 0.0
	if not touch_mode:
		return
	var screen_size := Vector2(DisplayServer.screen_get_size())
	var safe_area := DisplayServer.get_display_safe_area()
	var viewport_size := get_viewport().get_visible_rect().size
	if screen_size.x <= 0.0 or screen_size.y <= 0.0 or safe_area.size == Vector2i.ZERO:
		return
	var scale := viewport_size / screen_size
	layout.offset_left = maxf(0.0, safe_area.position.x * scale.x)
	layout.offset_top = maxf(0.0, safe_area.position.y * scale.y)
	layout.offset_right = -maxf(0.0, (screen_size.x - safe_area.end.x) * scale.x)
	layout.offset_bottom = -maxf(0.0, (screen_size.y - safe_area.end.y) * scale.y)

## Briefly warns the player when the core is attacked offscreen.
func show_core_warning() -> void:
	core_warning_time = 1.5

## Refreshes labels, selection states, and phase-specific panels.
func _process(delta: float) -> void:
	core_warning_time = maxf(0.0, core_warning_time - delta)
	core_warning_panel.visible = core_warning_time > 0.0
	if state == null:
		return
	phase_label.text = phase_text()
	score_label.text = "SCORE  %s" % format_score(state.score)
	coin_label.text = "COINS  %03d" % floori(state.coins)
	core_label.text = "STOCK  %03d" % ceili(state.base_hp)
	core_label.modulate = Color("ed5b68") if state.base_hp <= GameConfig.MAX_BASE_HP * 0.3 else Color.WHITE
	build_panel.visible = state.phase == GameState.Phase.BUILD
	wave_intel_panel.visible = state.phase == GameState.Phase.BUILD or state.phase == GameState.Phase.DEFEND
	if wave_intel_panel.visible:
		intel_title.text = "NEXT RUSH" if state.phase == GameState.Phase.BUILD else "CURRENT RUSH"
		intel_wave.text = wave_title()
		intel_composition.text = state.wave_composition
		intel_approaches.text = state.wave_approaches.replace(", ", "  •  ")
	if build_definitions.size() >= 2:
		wall_button.text = "%s\n%d coins" % [build_definitions[0].display_name, build_definitions[0].cost] if touch_mode else "[1] %s\n%d coins" % [build_definitions[0].display_name, build_definitions[0].cost]
		turret_button.text = "%s\n%d coins" % [build_definitions[1].display_name, build_definitions[1].cost] if touch_mode else "[2] %s\n%d coins" % [build_definitions[1].display_name, build_definitions[1].cost]
		wall_button.icon = build_definitions[0].icon
		turret_button.icon = build_definitions[1].icon
		wall_button.disabled = state.coins < build_definitions[0].cost
		turret_button.disabled = state.coins < build_definitions[1].cost
	wall_button.button_pressed = state.build_kind == GameState.BuildKind.WALL
	turret_button.button_pressed = state.build_kind == GameState.BuildKind.TURRET
	if touch_mode:
		start_wave_button.text = "START ENDLESS  %d" % (state.wave_number - state.objective_wave_count) if state.endless else "START WAVE  %d" % state.wave_number
	else:
		start_wave_button.text = "START ENDLESS  %d  [SPACE]" % (state.wave_number - state.objective_wave_count) if state.endless else "START WAVE  %d  [SPACE]" % state.wave_number
	help_label.text = help_text()
	help_label.offset_top = -154.0 if state.phase == GameState.Phase.BUILD else -28.0
	help_label.offset_bottom = -132.0 if state.phase == GameState.Phase.BUILD else -5.0
	var finished := state.phase == GameState.Phase.VICTORY or state.phase == GameState.Phase.DEFEAT
	message_panel.visible = state.message_time > 0.0 and not finished
	message_label.text = state.message
	end_panel.visible = finished
	if finished and state.run_summary != null:
		var summary := state.run_summary
		end_title.text = "STORE SECURED" if state.phase == GameState.Phase.VICTORY else "STOCK LOST"
		end_title.modulate = Color("78ead2") if state.phase == GameState.Phase.VICTORY else Color("ed5b68")
		end_score.text = "SCORE  %s" % format_score(summary.score)
		end_breakdown.text = "Shopper points  %s\nRush bonuses  %s\nStock secured  %s" % [
			format_score(summary.shopper_points),
			format_score(summary.rush_points),
			format_score(summary.stock_points),
		]
		end_stats.text = "%d rushes cleared  •  %d shoppers turned away\nStock remaining  %d  •  Run seed  %d" % [
			summary.waves_cleared,
			summary.shoppers_defeated,
			summary.stock_remaining,
			summary.run_seed,
		]
		var mode_name := "ENDLESS" if summary.mode == &"endless" else "OBJECTIVE"
		var record_kind := "LOCAL BEST" if summary.persistent_record else "SESSION BEST"
		record_label.text = "%s%s  •  %s" % [
			"NEW " if summary.new_best else "",
			"%s %s" % [mode_name, record_kind],
			format_score(summary.best_score),
		]
		continue_button.visible = state.phase == GameState.Phase.VICTORY

## Adds thousands separators to score values without locale-dependent output.
func format_score(value: int) -> String:
	var digits := str(maxi(0, value))
	var formatted := ""
	while digits.length() > 3:
		formatted = "," + digits.right(3) + formatted
		digits = digits.left(digits.length() - 3)
	return digits + formatted

## Builds the short phase label shown in the top bar.
func phase_text() -> String:
	match state.phase:
		GameState.Phase.BUILD:
			if state.endless:
				return "BUILD  E%d  %02d" % [state.wave_number - state.objective_wave_count, ceili(state.phase_time)]
			return "BUILD  %d / %d  %02d" % [state.wave_number, state.objective_wave_count, ceili(state.phase_time)]
		GameState.Phase.VICTORY: return "VICTORY"
		GameState.Phase.DEFEAT: return "DEFEAT"
		_:
			if state.endless:
				return "ENDLESS  %d  %d / %d" % [state.wave_number - state.objective_wave_count, state.wave_enemies_defeated, state.wave_enemies]
			return "WAVE  %d / %d  %d / %d" % [state.wave_number, state.objective_wave_count, state.wave_enemies_defeated, state.wave_enemies]

## Builds the compact wave name shown in the rush-intelligence panel.
func wave_title() -> String:
	if state.endless:
		return "ENDLESS  %d" % (state.wave_number - state.objective_wave_count)
	return "WAVE  %d OF %d" % [state.wave_number, state.objective_wave_count]

## Returns the controls that matter in the current phase.
func help_text() -> String:
	match state.phase:
		GameState.Phase.BUILD: return "WASD move  •  LMB place  •  RMB remove  •  1/2 select  •  Space start  •  Esc pause"
		GameState.Phase.DEFEND: return "WASD move  •  LMB attack  •  Hold RMB near damage to repair  •  Esc pause"
		_: return "Press R to play again"
