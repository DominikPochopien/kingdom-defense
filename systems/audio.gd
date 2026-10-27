extends Node
## Dźwięki gry generowane kodem (bez plików audio).
## Autoload "Audio" - użycie z dowolnego miejsca: Audio.play("coin").

const MIX_RATE := 22050
const VOICES := 8
const VOLUME_DB := -8.0

var muted := false

var _streams := {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_streams["shoot"] = _make_tone(900, 0.07)
	_streams["magic"] = _make_tone(500, 0.16)
	_streams["boom"] = _make_tone(0, 0.25, true, 0.6)
	_streams["coin"] = _make_tone(1300, 0.08, false, 0.35)
	_streams["build"] = _make_tone(300, 0.12)
	_streams["hurt"] = _make_tone(140, 0.25, false, 0.6)
	_streams["wave"] = _make_tone(220, 0.4)
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(sound: String) -> void:
	if muted or not _streams.has(sound):
		return
	for player in _players:
		if not player.playing:
			player.stream = _streams[sound]
			player.volume_db = VOLUME_DB
			player.play()
			return


func toggle_mute() -> void:
	muted = not muted


## Krótki, wygasający ton (sinus) albo szum.
static func _make_tone(freq: float, duration: float, noise := false, volume := 0.5) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = MIX_RATE
	var n := int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(n)
	for i in n:
		var t := float(i) / MIX_RATE
		var envelope := 1.0 - float(i) / float(n)
		var v := randf() * 2.0 - 1.0 if noise else sin(TAU * freq * t)
		var sample := int(clamp(v * envelope * volume * 127.0, -127, 127))
		data[i] = sample & 0xFF
	stream.data = data
	return stream
