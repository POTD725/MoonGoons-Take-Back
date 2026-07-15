extends Node
## Procedural original music and sound effects for Syndicate Rising.
## Audio is synthesized at runtime, so the build ships without external samples or licenses.

const MIX_RATE: int = 22050

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var _music_cache: Dictionary = {}
var _sfx_cache: Dictionary = {}
var muted: bool = false

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "SyndicateMusic"
	music_player.volume_db = -18.0
	add_child(music_player)
	for index: int in range(5):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SyndicateSFX%d" % index
		player.volume_db = -8.0
		add_child(player)
		sfx_players.append(player)

func set_muted(value: bool) -> void:
	muted = value
	music_player.stream_paused = muted
	for player: AudioStreamPlayer in sfx_players:
		player.stream_paused = muted

func toggle_muted() -> bool:
	set_muted(not muted)
	return muted

func play_music(theme: String) -> void:
	if muted:
		return
	if not _music_cache.has(theme):
		_music_cache[theme] = _make_music(theme)
	var stream: AudioStreamWAV = _music_cache[theme] as AudioStreamWAV
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func play_sfx(kind: String) -> void:
	if muted:
		return
	if not _sfx_cache.has(kind):
		_sfx_cache[kind] = _make_sfx(kind)
	var player: AudioStreamPlayer = _available_sfx_player()
	player.stream = _sfx_cache[kind] as AudioStreamWAV
	player.play()

func _available_sfx_player() -> AudioStreamPlayer:
	for player: AudioStreamPlayer in sfx_players:
		if not player.playing:
			return player
	return sfx_players[0]

func _make_music(theme: String) -> AudioStreamWAV:
	var seconds: float = 5.0
	var sample_count: int = int(seconds * float(MIX_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)
	var base_frequency: float = 55.0
	var pulse_frequency: float = 110.0
	var shimmer_frequency: float = 329.63
	if theme == "combat":
		base_frequency = 65.41
		pulse_frequency = 130.81
		shimmer_frequency = 392.0
	elif theme == "cutscene":
		base_frequency = 43.65
		pulse_frequency = 87.31
		shimmer_frequency = 261.63
	for index: int in range(sample_count):
		var time_value: float = float(index) / float(MIX_RATE)
		var beat_phase: float = fmod(time_value, 0.5)
		var beat: float = exp(-beat_phase * 9.0) * sin(TAU * pulse_frequency * time_value)
		var drone: float = sin(TAU * base_frequency * time_value) * 0.42
		drone += sin(TAU * base_frequency * 1.5 * time_value) * 0.16
		var shimmer_gate: float = 0.5 + 0.5 * sin(TAU * 0.2 * time_value)
		var shimmer: float = sin(TAU * shimmer_frequency * time_value) * 0.08 * shimmer_gate
		var sample_value: float = clampf(drone + beat * 0.25 + shimmer, -1.0, 1.0)
		_store_sample(data, index, int(sample_value * 32767.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream

func _make_sfx(kind: String) -> AudioStreamWAV:
	var duration: float = 0.18
	var start_frequency: float = 520.0
	var end_frequency: float = 760.0
	var noise_amount: float = 0.0
	match kind:
		"click":
			duration = 0.07
			start_frequency = 720.0
			end_frequency = 980.0
		"accept":
			duration = 0.22
			start_frequency = 410.0
			end_frequency = 880.0
		"repair":
			duration = 0.35
			start_frequency = 180.0
			end_frequency = 420.0
			noise_amount = 0.16
		"hit":
			duration = 0.13
			start_frequency = 130.0
			end_frequency = 70.0
			noise_amount = 0.42
		"special":
			duration = 0.42
			start_frequency = 280.0
			end_frequency = 1220.0
		"warning":
			duration = 0.5
			start_frequency = 720.0
			end_frequency = 720.0
		"victory":
			duration = 0.75
			start_frequency = 330.0
			end_frequency = 990.0
		"defeat":
			duration = 0.7
			start_frequency = 330.0
			end_frequency = 90.0
	var count: int = int(duration * float(MIX_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = kind.hash()
	for index: int in range(count):
		var progress: float = float(index) / float(maxi(1, count - 1))
		var frequency: float = lerpf(start_frequency, end_frequency, progress)
		var envelope: float = pow(1.0 - progress, 1.7)
		if kind == "warning":
			envelope *= 0.35 + 0.65 * float(int(progress * 8.0) % 2)
		var tone: float = sin(TAU * frequency * float(index) / float(MIX_RATE))
		var noise: float = rng.randf_range(-1.0, 1.0) * noise_amount
		var sample_value: float = clampf((tone + noise) * envelope * 0.75, -1.0, 1.0)
		_store_sample(data, index, int(sample_value * 32767.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream

func _store_sample(data: PackedByteArray, index: int, value: int) -> void:
	var clamped: int = clampi(value, -32768, 32767)
	data[index * 2] = clamped & 0xff
	data[index * 2 + 1] = (clamped >> 8) & 0xff
