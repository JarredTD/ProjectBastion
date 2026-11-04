extends Node

signal audio_volume_changed(bus_name: StringName, volume: float)

const SETTINGS_PATH := "user://settings.cfg"
const AUDIO_BUSES: Array[StringName] = [&"Master", &"Music", &"SFX", &"UI"]
const DEFAULT_VOLUMES := {
	&"Master": 0.9,
	&"Music": 0.7,
	&"SFX": 0.85,
	&"UI": 0.8,
}

var audio_volumes := DEFAULT_VOLUMES.duplicate()

## Loads saved preferences before the first scene begins playing audio.
func _ready() -> void:
	load_settings()
	apply_audio_settings()

## Returns the saved linear volume for an audio bus.
func get_audio_volume(bus_name: StringName) -> float:
	return audio_volumes.get(bus_name, DEFAULT_VOLUMES.get(bus_name, 1.0))

## Applies a clamped volume immediately and optionally saves it.
func set_audio_volume(bus_name: StringName, volume: float, save_change := true) -> void:
	if bus_name not in AUDIO_BUSES:
		push_warning("Unknown audio bus: %s" % bus_name)
		return
	var safe_volume := clampf(volume, 0.0, 1.0)
	audio_volumes[bus_name] = safe_volume
	apply_bus_volume(bus_name, safe_volume)
	audio_volume_changed.emit(bus_name, safe_volume)
	if save_change:
		save_settings()

## Restores the shipped audio mix and writes it to disk.
func reset_audio_settings() -> void:
	audio_volumes = DEFAULT_VOLUMES.duplicate()
	apply_audio_settings()
	save_settings()

## Reads audio preferences, falling back safely when no file exists.
func load_settings() -> void:
	var config := ConfigFile.new()
	var load_error := config.load(SETTINGS_PATH)
	if load_error == ERR_FILE_NOT_FOUND:
		return
	if load_error != OK:
		push_warning("Could not load audio settings: %s" % error_string(load_error))
		return
	for bus_name in AUDIO_BUSES:
		var saved_value: Variant = config.get_value("audio", String(bus_name).to_lower(), get_audio_volume(bus_name))
		if typeof(saved_value) != TYPE_FLOAT and typeof(saved_value) != TYPE_INT:
			push_warning("Ignoring invalid %s volume in audio settings." % bus_name)
			continue
		audio_volumes[bus_name] = clampf(float(saved_value), 0.0, 1.0)

## Writes the current audio preferences to the user data directory.
func save_settings() -> void:
	var config := ConfigFile.new()
	for bus_name in AUDIO_BUSES:
		config.set_value("audio", String(bus_name).to_lower(), get_audio_volume(bus_name))
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save audio settings: %s" % error_string(error))

## Applies every stored value to Godot's audio buses.
func apply_audio_settings() -> void:
	for bus_name in AUDIO_BUSES:
		var volume := get_audio_volume(bus_name)
		apply_bus_volume(bus_name, volume)
		audio_volume_changed.emit(bus_name, volume)

## Updates one bus while treating zero as a true mute.
func apply_bus_volume(bus_name: StringName, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_warning("Missing audio bus: %s" % bus_name)
		return
	AudioServer.set_bus_mute(bus_index, volume <= 0.0)
	AudioServer.set_bus_volume_linear(bus_index, maxf(volume, 0.0001))
