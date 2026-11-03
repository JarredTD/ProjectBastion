extends Control

signal closed

const BUS_NAMES: Array[StringName] = [&"Master", &"Music", &"SFX", &"UI"]

@onready var sliders := {
	&"Master": %MasterSlider,
	&"Music": %MusicSlider,
	&"SFX": %SfxSlider,
	&"UI": %UiSlider,
}
@onready var value_labels := {
	&"Master": %MasterValue,
	&"Music": %MusicValue,
	&"SFX": %SfxValue,
	&"UI": %UiValue,
}
@onready var back_button: Button = %BackButton

## Connects every volume row to the same settings API.
func _ready() -> void:
	for bus_name in BUS_NAMES:
		var slider: HSlider = sliders[bus_name]
		slider.value_changed.connect(_on_volume_changed.bind(bus_name))
		slider.drag_ended.connect(_on_slider_drag_ended)
	%DefaultsButton.pressed.connect(_on_defaults_pressed)
	back_button.pressed.connect(close)
	sync_from_settings()
	hide()

## Lets Escape close settings from either the title or pause menu.
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

## Opens the panel with its controls matching the saved mix.
func open() -> void:
	sync_from_settings()
	show()
	back_button.grab_focus()

## Saves the current mix and returns to the previous menu.
func close() -> void:
	Audio.play_ui_click()
	Settings.save_settings()
	hide()
	closed.emit()

## Reports whether this panel currently owns the menu interaction.
func is_open() -> bool:
	return visible

## Copies saved volumes into the sliders without changing their meaning.
func sync_from_settings() -> void:
	for bus_name in BUS_NAMES:
		var percent := Settings.get_audio_volume(bus_name) * 100.0
		sliders[bus_name].set_value_no_signal(percent)
		update_value_label(bus_name, percent)

## Applies slider movement immediately so the player can hear the result.
func _on_volume_changed(value: float, bus_name: StringName) -> void:
	Settings.set_audio_volume(bus_name, value / 100.0, false)
	update_value_label(bus_name, value)

## Persists a slider value after the player finishes dragging it.
func _on_slider_drag_ended(_value_changed: bool) -> void:
	Settings.save_settings()

## Restores the shipped mix and refreshes every control.
func _on_defaults_pressed() -> void:
	Audio.play_ui_click()
	Settings.reset_audio_settings()
	sync_from_settings()

## Shows a rounded percentage beside one volume slider.
func update_value_label(bus_name: StringName, value: float) -> void:
	value_labels[bus_name].text = "%d%%" % roundi(value)
