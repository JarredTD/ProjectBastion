extends Node

enum MusicState { NONE, MENU, BUILD, DEFENSE, VICTORY, DEFEAT }

const MUSIC_PATHS := {
	MusicState.MENU: "res://assets/audio/music/menu.wav",
	MusicState.BUILD: "res://assets/audio/music/build.wav",
	MusicState.DEFENSE: "res://assets/audio/music/defense.wav",
	MusicState.VICTORY: "res://assets/audio/music/victory.wav",
	MusicState.DEFEAT: "res://assets/audio/music/defeat.wav",
}
const LOOPING_STATES := [MusicState.MENU, MusicState.BUILD, MusicState.DEFENSE]
const UI_CLICK_PATH := "res://assets/audio/sfx/ui_click.wav"

@onready var music_players: Array[AudioStreamPlayer] = [$MusicA, $MusicB]
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer
@onready var ui_player: AudioStreamPlayer = $UiPlayer

var current_music := MusicState.NONE
var active_music_player := 0
var music_tween: Tween
var prepared_music: Dictionary = {}
var ui_click: AudioStream

## Prepares looping copies without changing the imported source files.
func _ready() -> void:
	for state in MUSIC_PATHS:
		var stream: AudioStream = load(MUSIC_PATHS[state]).duplicate()
		if state in LOOPING_STATES and stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
		prepared_music[state] = stream
	ui_click = load(UI_CLICK_PATH)

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

## Plays a non-positional gameplay sound with room for overlapping voices.
func play_sfx(stream: AudioStream, volume_db := 0.0, pitch_scale := 1.0) -> void:
	if stream == null:
		return
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	sfx_player.pitch_scale = pitch_scale
	sfx_player.play()

## Plays the shared menu confirmation sound.
func play_ui_click() -> void:
	ui_player.stream = ui_click
	ui_player.play()
