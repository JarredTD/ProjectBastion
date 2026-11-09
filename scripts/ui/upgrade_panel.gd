extends CanvasLayer

const GameState = preload("res://scripts/game_state.gd")

var upgrade_manager: UpgradeManager
var state: GameState
var cards: Array[UpgradeCard] = []

@export var card_scene: PackedScene

@onready var overlay: Control = %Overlay
@onready var coins_label: Label = %CoinsLabel
@onready var close_button: Button = %CloseButton
@onready var subtitle: Label = %Subtitle
@onready var sale_badge: TextureRect = %SaleBadge
@onready var cards_container: GridContainer = %Cards


## Starts hidden until the player opens the shop.
func _ready() -> void:
	overlay.hide()
	close_button.pressed.connect(close)


## Supplies the run systems used to price and apply purchases.
func configure(manager: UpgradeManager, game_state: GameState) -> void:
	upgrade_manager = manager
	state = game_state
	upgrade_manager.changed.connect(refresh)
	rebuild_cards()
	refresh()


## Creates one reusable card for every authored upgrade definition.
func rebuild_cards() -> void:
	for child in cards_container.get_children():
		cards_container.remove_child(child)
		child.queue_free()
	cards.clear()
	if card_scene == null:
		push_error("Upgrade panel requires a card scene.")
		return
	for index in upgrade_manager.definitions.size():
		var card := card_scene.instantiate() as UpgradeCard
		if card == null:
			push_error("Upgrade card scene must use UpgradeCard.")
			return
		cards_container.add_child(card)
		card.configure(index, upgrade_manager.definitions[index])
		card.purchase_requested.connect(purchase)
		cards.append(card)


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
	var active_sale := upgrade_manager.sale_index()
	sale_badge.modulate.a = 1.0 if active_sale >= 0 else 0.0
	subtitle.text = "One upgrade is discounted for this rush." if active_sale >= 0 else "Spend coins between rushes. Purchases last for this run."
	for card in cards:
		card.refresh(upgrade_manager, state.coins)
