extends CanvasLayer

signal build_selected(index: int)
signal wave_start_requested
signal run_restart_requested

const GameConfig = preload("res://scripts/game_config.gd")
const GameState = preload("res://scripts/game_state.gd")

var state: GameState
var build_definitions: Array

@onready var phase_label: Label = %PhaseLabel
@onready var scrap_label: Label = %ScrapLabel
@onready var core_label: Label = %CoreLabel
@onready var build_panel: Control = %BuildPanel
@onready var wall_button: Button = %WallButton
@onready var turret_button: Button = %TurretButton
@onready var start_wave_button: Button = %StartWaveButton
@onready var build_hint_label: Label = %BuildHintLabel
@onready var help_label: Label = %HelpLabel
@onready var message_panel: Control = %MessagePanel
@onready var message_label: Label = %MessageLabel
@onready var end_panel: Control = %EndPanel
@onready var end_title: Label = %EndTitle
@onready var end_stats: Label = %EndStats
@onready var restart_button: Button = %RestartButton

## Connects the clickable controls to the HUD's public signals.
func _ready() -> void:
	wall_button.pressed.connect(func() -> void: build_selected.emit(GameState.BuildKind.WALL))
	turret_button.pressed.connect(func() -> void: build_selected.emit(GameState.BuildKind.TURRET))
	start_wave_button.pressed.connect(func() -> void: wave_start_requested.emit())
	restart_button.pressed.connect(func() -> void: run_restart_requested.emit())

## Supplies the live match state and buildable definitions shown by the HUD.
func configure(game_state: GameState, definitions: Array) -> void:
	state = game_state
	build_definitions = definitions

## Updates the short line of feedback beneath the build controls.
func set_build_hint(text: String) -> void:
	build_hint_label.text = text

## Refreshes labels, selection states, and phase-specific panels.
func _process(_delta: float) -> void:
	if state == null:
		return
	phase_label.text = phase_text()
	scrap_label.text = "SCRAP  %03d" % floori(state.scrap)
	core_label.text = "CORE  %03d" % ceili(state.base_hp)
	build_panel.visible = state.phase == GameState.Phase.BUILD
	if build_definitions.size() >= 2:
		wall_button.text = "[1] %s\n%d scrap" % [build_definitions[0].display_name, build_definitions[0].cost]
		turret_button.text = "[2] %s\n%d scrap" % [build_definitions[1].display_name, build_definitions[1].cost]
		wall_button.icon = build_definitions[0].icon
		turret_button.icon = build_definitions[1].icon
		wall_button.disabled = state.scrap < build_definitions[0].cost
		turret_button.disabled = state.scrap < build_definitions[1].cost
	wall_button.button_pressed = state.build_kind == GameState.BuildKind.WALL
	turret_button.button_pressed = state.build_kind == GameState.BuildKind.TURRET
	help_label.text = help_text()
	var finished := state.phase == GameState.Phase.VICTORY or state.phase == GameState.Phase.DEFEAT
	message_panel.visible = state.message_time > 0.0 and not finished
	message_label.text = state.message
	end_panel.visible = finished
	if finished:
		end_title.text = "BASTION SECURED" if state.phase == GameState.Phase.VICTORY else "BASTION LOST"
		end_title.modulate = Color("78ead2") if state.phase == GameState.Phase.VICTORY else Color("ed5b68")
		end_stats.text = "Enemies defeated: %d / %d" % [state.enemies_defeated, GameConfig.TOTAL_ENEMIES]

## Builds the short phase label shown in the top bar.
func phase_text() -> String:
	match state.phase:
		GameState.Phase.BUILD: return "BUILD  %02d" % ceili(state.phase_time)
		GameState.Phase.VICTORY: return "VICTORY"
		GameState.Phase.DEFEAT: return "DEFEAT"
		_: return "WAVE  1 / 1"

## Returns the controls that matter in the current phase.
func help_text() -> String:
	match state.phase:
		GameState.Phase.BUILD: return "WASD move  •  LMB place  •  RMB remove  •  1/2 select  •  Space start  •  Esc pause"
		GameState.Phase.DEFEND: return "WASD move  •  LMB attack  •  Hold RMB near damage to repair  •  Esc pause"
		_: return "Press R to play again"
