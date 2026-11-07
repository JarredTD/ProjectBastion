extends Node

const RECORDS_PATH := "user://records.cfg"
const MODES: Array[StringName] = [&"objective", &"endless"]

var best_scores := {
	&"objective": 0,
	&"endless": 0,
}

## Loads local records before the first run begins.
func _ready() -> void:
	load_records()

## Returns the best score saved for a run mode.
func best_score(mode: StringName) -> int:
	return int(best_scores.get(mode, 0))

## Keeps a new local record and reports whether the score improved it.
func record_score(mode: StringName, score: int) -> bool:
	if mode not in MODES or score <= best_score(mode):
		return false
	best_scores[mode] = maxi(0, score)
	save_records()
	return true

## Reports whether the current platform expects user files to survive.
func is_persistent() -> bool:
	return OS.is_userfs_persistent()

## Reads valid local records without trusting edited or damaged values.
func load_records() -> void:
	var config := ConfigFile.new()
	var load_error := config.load(RECORDS_PATH)
	if load_error == ERR_FILE_NOT_FOUND:
		return
	if load_error != OK:
		push_warning("Could not load local records: %s" % error_string(load_error))
		return
	for mode in MODES:
		var saved_value: Variant = config.get_value("scores", String(mode), 0)
		if typeof(saved_value) != TYPE_INT and typeof(saved_value) != TYPE_FLOAT:
			push_warning("Ignoring invalid %s score in local records." % mode)
			continue
		best_scores[mode] = maxi(0, int(saved_value))

## Writes both run-mode records to the user data directory.
func save_records() -> void:
	var config := ConfigFile.new()
	for mode in MODES:
		config.set_value("scores", String(mode), best_score(mode))
	var error := config.save(RECORDS_PATH)
	if error != OK:
		push_warning("Could not save local records: %s" % error_string(error))
