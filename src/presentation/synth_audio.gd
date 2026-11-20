class_name SynthAudio extends RefCounted

## Generates original seeded PCM at startup; e.g. create(&"wind"), never gameplay RNG.
static func create(kind: StringName, rate: int = 22050) -> AudioStreamWAV:
	if rate < 8000 or rate > 48000 or kind not in [&"wind", &"fire", &"step", &"gather", &"chop"]:
		return null
	var loop := kind in [&"wind", &"fire"]
	var duration := 3.0 if loop else 0.28
	var count := int(duration * rate)
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261119
	var low := 0.0
	for i in count:
		var time := float(i) / rate
		var noise := rng.randf_range(-1, 1)
		low = lerpf(low, noise, 0.02)
		var sample := low * (0.7 + 0.2 * sin(TAU * time / duration))
		if kind == &"fire":
			sample = noise * 0.07 + (noise * 0.6 if rng.randf() > 0.997 else 0.0)
		elif not loop:
			var envelope := pow(1.0 - float(i) / count, 3.0)
			sample = envelope * (noise * 0.35 + sin(TAU * (100 if kind == &"chop" else 220) * time) * 0.15)
		var fade := minf(1, minf(time * 30, (duration - time) * 30))
		pcm.encode_s16(i * 2, int(clampf(sample * fade, -1, 1) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = pcm
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream
