extends Node
## Runtime-generated audio keeps web and Android builds self-contained.

var effects: Dictionary = {}
var effect_players: Array[AudioStreamPlayer] = []
var ambient_player: AudioStreamPlayer
var _player_cursor: int = 0

func _ready() -> void:
	for index in range(6):
		var player := AudioStreamPlayer.new()
		player.name = "EffectPlayer%d" % index
		player.volume_db = -7.0
		add_child(player)
		effect_players.append(player)
	effects = {
		"click": _tone([760.0], 0.055, 0.24),
		"confirm": _tone([520.0, 780.0], 0.14, 0.28),
		"alert": _tone([330.0, 270.0, 390.0], 0.36, 0.34),
		"repair": _tone([110.0, 165.0, 220.0], 0.42, 0.32),
		"upgrade": _tone([440.0, 554.0, 659.0, 880.0], 0.48, 0.30),
		"dispatch": _tone([180.0, 260.0, 420.0, 690.0], 0.62, 0.38),
		"error": _tone([180.0, 145.0], 0.22, 0.30),
		"reward": _tone([660.0, 880.0, 1100.0], 0.46, 0.30),
		"laser": _tone([980.0, 720.0, 420.0], 0.18, 0.34),
		"rail": _tone([120.0, 68.0, 44.0], 0.52, 0.48),
		"impact": _noise_burst(0.28, 0.35),
		"harvest": _tone([170.0, 210.0, 280.0, 350.0], 0.72, 0.26),
		"door": _noise_burst(0.16, 0.18),
		"work": _noise_burst(0.10, 0.13)
	}
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "PrecinctAmbience"
	ambient_player.volume_db = -22.0
	ambient_player.stream = _ambient_hum()
	add_child(ambient_player)
	ambient_player.play()

func play(sound_id:String) -> void:
	if not effects.has(sound_id) or effect_players.is_empty():
		return
	var player:AudioStreamPlayer = effect_players[_player_cursor % effect_players.size()]
	_player_cursor += 1
	player.stream = effects[sound_id] as AudioStream
	player.play()

func set_ambience_enabled(enabled:bool) -> void:
	if ambient_player == null:
		return
	if enabled and not ambient_player.playing:
		ambient_player.play()
	elif not enabled:
		ambient_player.stop()

func _tone(frequencies:Array, duration:float, amplitude:float) -> AudioStreamWAV:
	var rate:int = 22050
	var sample_count:int = maxi(1, int(duration * float(rate)))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var progress:float = float(sample_index) / float(sample_count)
		var frequency_index:int = mini(frequencies.size() - 1, int(progress * float(frequencies.size())))
		var frequency:float = float(frequencies[frequency_index])
		var envelope:float = sin(PI * progress)
		var value:float = sin(TAU * frequency * float(sample_index) / float(rate)) * amplitude * envelope
		_store_sample(bytes, sample_index, value)
	return _wav(bytes, rate, false)

func _noise_burst(duration:float, amplitude:float) -> AudioStreamWAV:
	var rate:int = 22050
	var sample_count:int = maxi(1, int(duration * float(rate)))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var seed_value:int = 1337
	for sample_index in range(sample_count):
		seed_value = int((seed_value * 1103515245 + 12345) & 0x7fffffff)
		var random_value:float = (float(seed_value % 2000) / 1000.0) - 1.0
		var progress:float = float(sample_index) / float(sample_count)
		var envelope:float = pow(1.0 - progress, 2.0)
		_store_sample(bytes, sample_index, random_value * amplitude * envelope)
	return _wav(bytes, rate, false)

func _ambient_hum() -> AudioStreamWAV:
	var rate:int = 22050
	var duration:float = 4.0
	var sample_count:int = int(duration * float(rate))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var time_value:float = float(sample_index) / float(rate)
		var pulse:float = 0.65 + sin(TAU * 0.35 * time_value) * 0.12
		var value:float = (sin(TAU * 54.0 * time_value) * 0.13 + sin(TAU * 108.0 * time_value) * 0.045 + sin(TAU * 216.0 * time_value) * 0.016) * pulse
		_store_sample(bytes, sample_index, value)
	return _wav(bytes, rate, true)

func _store_sample(bytes:PackedByteArray, sample_index:int, value:float) -> void:
	var integer_value:int = clampi(int(value * 32767.0), -32768, 32767)
	if integer_value < 0:
		integer_value += 65536
	bytes[sample_index * 2] = integer_value & 0xff
	bytes[sample_index * 2 + 1] = (integer_value >> 8) & 0xff

func _wav(bytes:PackedByteArray, rate:int, looping:bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = bytes.size() / 2
	return stream
