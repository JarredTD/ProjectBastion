extends Node

enum MusicState { NONE, MENU, BUILD, DEFENSE, VICTORY, DEFEAT }

const LOOPING_STATES := [MusicState.MENU, MusicState.BUILD, MusicState.DEFENSE]

@export var catalog: AudioCatalog

@onready var music_players: Array[AudioStreamPlayer] = [$MusicA, $MusicB]
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer
@onready var ui_player: AudioStreamPlayer = $UiPlayer

var current_music := MusicState.NONE
var active_music_player := 0
var music_tween: Tween
var prepared_music: Dictionary = {}
var sfx_playback: AudioStreamPlaybackPolyphonic

## Prepares looping copies without changing the imported source files.
func _ready() -> void:
	var music_streams := {
		MusicState.MENU: catalog.menu_music,
		MusicState.BUILD: catalog.build_music,
		MusicState.DEFENSE: catalog.defense_music,
		MusicState.VICTORY: catalog.victory_music,
		MusicState.DEFEAT: catalog.defeat_music,
	}
	for state in music_streams:
		var stream: AudioStream = music_streams[state].duplicate()
		if state in LOOPING_STATES and stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
		prepared_music[state] = stream
	sfx_player.play()
	sfx_playback = sfx_player.get_stream_playback() as AudioStreamPlaybackPolyphonic

## Stops active playback before the engine releases audio resources.
func _exit_tree() -> void:
	if music_tween != null and music_tween.is_valid():
		music_tween.kill()
	for player in music_players:
		player.stop()
		player.stream = null
	sfx_player.stop()
	sfx_playback = null
	sfx_player.stream = null
	ui_player.stop()
	ui_player.stream = null
	prepared_music.clear()

## Crossfades to the music assigned to a game state.
func play_music(state: MusicState, fade_time := 0.75) -> void:
	if state == current_music and music_players[active_music_player].playing:
		return
	if not prepared_music.has(state):
		stop_music(fade_time)
		return
	if music_tween != null and music_tween.is_valid():
		music_tween.kill()
	var previous := music_players[active_music_player]
	active_music_player = 1 - active_music_player
	var next := music_players[active_music_player]
	next.stop()
	next.stream = prepared_music[state]
	next.volume_db = -60.0
	next.play()
	music_tween = create_tween().set_parallel(true)
	music_tween.tween_property(next, "volume_db", 0.0, fade_time)
	if previous.playing:
		music_tween.tween_property(previous, "volume_db", -60.0, fade_time)
		music_tween.chain().tween_callback(previous.stop)
	current_music = state

## Fades out whichever music deck is currently active.
func stop_music(fade_time := 0.5) -> void:
	if music_tween != null and music_tween.is_valid():
		music_tween.kill()
	var player := music_players[active_music_player]
	if player.playing:
		music_tween = create_tween()
		music_tween.tween_property(player, "volume_db", -60.0, fade_time)
		music_tween.tween_callback(player.stop)
	current_music = MusicState.NONE

## Plays a named gameplay sound with room for overlapping voices.
func play_sfx(cue: StringName, volume_db := 0.0, pitch_scale := 1.0) -> void:
	var stream := catalog.sound_for(cue)
	if stream == null or sfx_playback == null:
		return
	sfx_playback.play_stream(stream, 0.0, volume_db, pitch_scale)

## Plays the shared menu confirmation sound.
func play_ui_click() -> void:
	ui_player.stream = catalog.ui_click
	ui_player.play()
