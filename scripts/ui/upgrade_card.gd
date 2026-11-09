class_name UpgradeCard
extends Panel

signal purchase_requested(index: int)

var card_index := -1
var definition: UpgradeDefinition

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var sale_label: Label = %SaleLabel
@onready var level_label: Label = %LevelLabel
@onready var buy_button: Button = %BuyButton


func _ready() -> void:
	buy_button.pressed.connect(func() -> void: purchase_requested.emit(card_index))


## Binds this reusable card to one entry in the upgrade catalog.
func configure(index: int, upgrade_definition: UpgradeDefinition) -> void:
	card_index = index
	definition = upgrade_definition
	title_label.text = definition.display_name
	description_label.text = definition.description


## Refreshes the current level, sale state, price, and availability.
func refresh(manager: UpgradeManager, coins: float) -> void:
	if definition == null or card_index < 0:
		return
	var current_level := manager.level_for(card_index)
	var on_sale := manager.is_on_sale(card_index)
	sale_label.visible = on_sale
	sale_label.text = "%d%% OFF THIS RUSH" % manager.sale_percent()
	level_label.text = "LEVEL %d / %d" % [current_level, definition.max_level]
	if not manager.is_unlocked(card_index):
		buy_button.text = "AFTER RUSH %d" % (definition.available_from_wave - 1)
		buy_button.disabled = true
	elif current_level >= definition.max_level:
		buy_button.text = "MAXED"
		buy_button.disabled = true
	else:
		var cost := manager.next_cost(card_index)
		if on_sale:
			buy_button.text = "SALE  %d  •  WAS %d" % [cost, manager.regular_cost(card_index)]
		else:
			buy_button.text = "BUY  %d" % cost
		buy_button.disabled = coins < cost
