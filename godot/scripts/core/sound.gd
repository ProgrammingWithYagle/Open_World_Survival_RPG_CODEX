extends Node

var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var next_voice := 0
var current_theme := ""
var cache: Dictionary = {}


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	music = AudioStreamPlayer.new()
	add_child(music)
	ambience = AudioStreamPlayer.new()
	add_child(ambience)
	for i in range(12):
		var player := AudioStreamPlayer.new()
		add_child(player)
		voices.append(player)
	apply_preferences()


func _stream(name_: String) -> AudioStream:
	if cache.has(name_):
		return cache[name_]
	var path := "res://audio/%s.wav" % name_
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path)
	cache[name_] = stream
	return stream


func apply_preferences() -> void:
	if music != null:
		music.volume_db = linear_to_db(maxf(.0001, float(L.preferences.music))) - 5.0
	if ambience != null:
		ambience.volume_db = linear_to_db(maxf(.0001, float(L.preferences.effects))) - 9.0


func theme(name_: String) -> void:
	if music == null:
		return
	if name_ == current_theme:
		return
	current_theme = name_
	var stream := _stream("music_" + name_)
	if stream == null:
		return
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
	music.stream = stream
	music.play()
	if not ambience.playing:
		var bed := _stream("ambience_forest")
		if bed is AudioStreamWAV:
			bed.loop_mode = AudioStreamWAV.LOOP_FORWARD
			bed.loop_end = int(bed.get_length() * bed.mix_rate)
		ambience.stream = bed
		if bed != null:
			ambience.play()


func effect(name_: String, pitch := 1.0) -> void:
	if voices.is_empty():
		return
	var stream := _stream(name_)
	if stream == null:
		return
	var player := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = linear_to_db(maxf(.0001, float(L.preferences.effects))) - 8.0
	player.play()


func shutdown() -> void:
	if music != null:
		music.stop()
		music.stream = null
	if ambience != null:
		ambience.stop()
		ambience.stream = null
	for player in voices:
		player.stop()
		player.stream = null
	cache.clear()
	current_theme = ""


func _exit_tree() -> void:
	shutdown()
