extends Node
## Audio autoload: looping chiptune tracks and a small SFX pool.

const TRACKS := {
	"title": "res://assets/generated/audio/title_theme.wav",
	"day": "res://assets/generated/audio/day_theme.wav",
	"night": "res://assets/generated/audio/night_theme.wav",
	"boss": "res://assets/generated/audio/boss_theme.wav",
}
const SFX := {
	"hoe": "res://assets/generated/audio/hoe.wav",
	"plant": "res://assets/generated/audio/plant.wav",
	"water": "res://assets/generated/audio/water.wav",
	"harvest": "res://assets/generated/audio/harvest.wav",
	"hit": "res://assets/generated/audio/hit.wav",
	"hurt": "res://assets/generated/audio/hurt.wav",
	"die": "res://assets/generated/audio/die.wav",
	"coin": "res://assets/generated/audio/coin.wav",
	"click": "res://assets/generated/audio/click.wav",
	"dawn": "res://assets/generated/audio/dawn.wav",
	"horn": "res://assets/generated/audio/horn.wav",
	"buy": "res://assets/generated/audio/buy.wav",
	"boss_roar": "res://assets/generated/audio/boss_roar.wav",
	"explosion": "res://assets/generated/audio/explosion.wav",
	"seed": "res://assets/generated/audio/seed.wav",
	"victory": "res://assets/generated/audio/victory.wav",
	"gameover": "res://assets/generated/audio/gameover.wav",
}

var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _cache := {}
var _current_track := ""
var music_db := -11.0
var sfx_db := -6.0
var music_level := 1.0
var sfx_level := 1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	ambience_player = AudioStreamPlayer.new()
	ambience_player.bus = "Master"
	ambience_player.volume_db = -19.0
	add_child(ambience_player)
	for i in range(10):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_pool.append(p)


func _stream(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var s: AudioStream = load(path)
	_cache[path] = s
	return s


func play_music(name: String) -> void:
	if _current_track == name and music_player.playing:
		return
	var path: String = TRACKS.get(name, "")
	if path == "":
		return
	var stream := _stream(path)
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	music_player.stream = stream
	music_player.volume_db = _music_volume_db()
	music_player.play()
	_current_track = name


func set_music_on(on: bool) -> void:
	music_level = 1.0 if on else 0.0
	music_player.volume_db = _music_volume_db()


func set_sfx_on(on: bool) -> void:
	sfx_level = 1.0 if on else 0.0


func _music_volume_db() -> float:
	if music_level <= 0.001:
		return -80.0
	return music_db + linear_to_db(music_level)


func stop_music() -> void:
	music_player.stop()
	_current_track = ""


func play_ambience(name: String) -> void:
	var path := "res://assets/generated/audio/rain_loop.wav" if name == "rain" else ""
	if path == "" or ambience_player.playing:
		return
	var stream := _stream(path)
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	ambience_player.stream = stream
	ambience_player.play()


func stop_ambience() -> void:
	ambience_player.stop()


func sfx(name: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var path: String = SFX.get(name, "")
	if path == "":
		return
	var p := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool.size()
	p.stream = _stream(path)
	p.pitch_scale = pitch
	if sfx_level <= 0.001:
		p.volume_db = -80.0
	else:
		p.volume_db = sfx_db + linear_to_db(sfx_level) + volume_db
	p.play()
