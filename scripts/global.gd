extends Node

var player0wins = 0
var player1wins = 0
var gamemode = 0
var player0class = 0
var player1class = 1

var music_enabled: bool = true
var music_player: AudioStreamPlayer

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.stream = load("res://assets/sounds/track.mp3")
	music_player.autoplay = false
	add_child(music_player)
	play_music()


func toggle_music():
	music_enabled = !music_enabled
	if music_enabled:
		play_music()
	else:
		music_player.stop()


func play_music():
	if music_enabled and not music_player.playing:
		music_player.play()
