extends CanvasLayer

const GameState = preload("res://scripts/game_state.gd")

var upgrade_manager: UpgradeManager
var state: GameState

@onready var overlay: Control = %Overlay
@onready var coins_label: Label = %CoinsLabel
@onready var close_button: Button = %CloseButton
@onready var cards: Array[Control] = [%UpgradeCard0, %UpgradeCard1, %UpgradeCard2]
@onready var titles: Array[Label] = [%UpgradeTitle0, %UpgradeTitle1, %UpgradeTitle2]
@onready var descriptions: Array[Label] = [%UpgradeDescription0, %UpgradeDescription1, %UpgradeDescription2]
@onready var levels: Array[Label] = [%UpgradeLevel0, %UpgradeLevel1, %UpgradeLevel2]
@onready var buy_buttons: Array[Button] = [%UpgradeBuy0, %UpgradeBuy1, %UpgradeBuy2]


## Starts hidden and connects the fixed set of shop buttons.
func _ready() -> void:
	overlay.hide()
	close_button.pressed.connect(close)
	for index in buy_buttons.size():
		buy_buttons[index].pressed.connect(purchase.bind(index))


## Supplies the run systems used to price and apply purchases.
func configure(manager: UpgradeManager, game_state: GameState) -> void:
	upgrade_manager = manager
	state = game_state
	upgrade_manager.changed.connect(refresh)
	refresh()


## Opens the shop during a build phase and pauses the countdown.
func open() -> void:
	if upgrade_manager == null or state == null or state.phase != GameState.Phase.BUILD:
		return
	refresh()
	overlay.show()
	get_tree().paused = true
	close_button.grab_focus()


## Returns to the build phase.
func close() -> void:
	if not overlay.visible:
		return
	Audio.play_ui_click()
	overlay.hide()
	get_tree().paused = false


## Claims Escape before the pause menu while the shop is open.
func _input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func purchase(index: int) -> void:
	upgrade_manager.purchase(index)
	refresh()


## Refreshes prices, levels, locks, and affordability from the live run.
func refresh() -> void:
	if upgrade_manager == null or state == null:
		return
	coins_label.text = "%d COINS AVAILABLE" % floori(state.coins)
	for index in cards.size():
		var visible_card := index < upgrade_manager.definitions.size()
		cards[index].visible = visible_card
		if not visible_card:
			continue
		var definition: UpgradeDefinition = upgrade_manager.definitions[index]
		var current_level: int = upgrade_manager.level_for(index)
		titles[index].text = definition.display_name
		descriptions[index].text = definition.description
		levels[index].text = "LEVEL %d / %d" % [current_level, definition.max_level]
		if not upgrade_manager.is_unlocked(index):
			buy_buttons[index].text = "AFTER RUSH %d" % (definition.available_from_wave - 1)
			buy_buttons[index].disabled = true
		elif current_level >= definition.max_level:
			buy_buttons[index].text = "MAXED"
			buy_buttons[index].disabled = true
		else:
			var cost: int = upgrade_manager.next_cost(index)
			buy_buttons[index].text = "BUY  %d" % cost
			buy_buttons[index].disabled = state.coins < cost
