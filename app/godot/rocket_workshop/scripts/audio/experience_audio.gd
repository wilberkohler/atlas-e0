extends Node
class_name VS1ExperienceAudio

signal audio_event(event_name: String, world_position: Vector3)

const MIX_RATE := 22050
const EVENT_SHAPES := {
	"plastic": {"frequency": 170.0, "duration": 0.08, "volume": -19.0, "noise": 0.34},
	"cardboard": {"frequency": 105.0, "duration": 0.07, "volume": -21.0, "noise": 0.48},
	"tape": {"frequency": 340.0, "duration": 0.16, "volume": -20.0, "noise": 0.62},
	"snap": {"frequency": 660.0, "duration": 0.08, "volume": -15.0, "noise": 0.06},
	"ready": {"frequency": 520.0, "duration": 0.18, "volume": -18.0, "noise": 0.02},
	"anticipation": {"frequency": 78.0, "duration": 0.42, "volume": -17.0, "noise": 0.16},
	"launch": {"frequency": 230.0, "duration": 0.36, "volume": -12.0, "noise": 0.42},
	"impact": {"frequency": 68.0, "duration": 0.22, "volume": -13.0, "noise": 0.54},
}


func play_event(event_name: String, world_position: Vector3 = Vector3.ZERO) -> void:
	audio_event.emit(event_name, world_position)
	var shape: Dictionary = EVENT_SHAPES.get(event_name, {})
	if shape.is_empty():
		return
	var player := AudioStreamPlayer.new()
	player.name = "TemporarySynth_%s" % event_name
	player.volume_db = float(shape.volume)
	player.stream = _make_wave(
		float(shape.frequency),
		float(shape.duration),
		float(shape.noise),
		event_name.hash()
	)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _make_wave(frequency: float, duration: float, noise_amount: float, seed: int) -> AudioStreamWAV:
	var sample_count: int = maxi(1, int(duration * MIX_RATE))
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for index: int in range(sample_count):
		var t := float(index) / float(MIX_RATE)
		var progress := float(index) / float(sample_count)
		var envelope := pow(1.0 - progress, 2.0) * minf(1.0, progress * 18.0)
		var bend := frequency * (1.0 + progress * 0.22)
		var tone := sin(TAU * bend * t)
		var noise := rng.randf_range(-1.0, 1.0)
		var mixed := clampf((tone * (1.0 - noise_amount) + noise * noise_amount) * envelope, -1.0, 1.0)
		bytes.encode_s16(index * 2, int(mixed * 24500.0))
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = MIX_RATE
	wave.stereo = false
	wave.data = bytes
	return wave
