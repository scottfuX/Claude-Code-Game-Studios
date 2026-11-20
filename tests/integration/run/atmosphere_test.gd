extends GdUnitTestSuite

func test_synthesis_is_seeded_bounded_and_rejects_unknown_sounds() -> void:
	assert_object(SynthAudio.create(&"missing")).is_null()
	assert_object(SynthAudio.create(&"wind", 0)).is_null()
	var first := SynthAudio.create(&"step", 8000)
	var second := SynthAudio.create(&"step", 8000)
	assert_int(first.data.size()).is_equal(4480)
	assert_bool(first.data == second.data).is_true()
	assert_int(first.loop_mode).is_equal(AudioStreamWAV.LOOP_DISABLED)
	var wind := SynthAudio.create(&"wind", 8000)
	assert_int(wind.loop_end).is_equal(24000)
	assert_int(wind.loop_mode).is_equal(AudioStreamWAV.LOOP_FORWARD)

func test_atmosphere_maps_daylight_and_pauses_without_rule_mutations() -> void:
	var shell: Node = auto_free(preload("res://src/run/app_shell.tscn").instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	var run := shell.get_child(0) as RunCoordinator
	var atmosphere: WinterAtmosphere = run.get("_atmosphere")
	atmosphere.set_daylight(0)
	var density: float = run.environment_node.environment.fog_density
	atmosphere.set_daylight(1)
	assert_float(run.environment_node.environment.fog_density).is_less(density)
	run.survivor.frozen = true
	atmosphere.call("_process", 1.0)
	var snow: CPUParticles3D = atmosphere.get("_snow")
	assert_float(snow.speed_scale).is_zero()
	assert_int(run.simulation.clock.minute_of_day).is_equal(990)
	assert_int(run.simulation.rng.draw_count).is_zero()

func test_software_quality_detection_and_explicit_overrides() -> void:
	var data := AtmosphereTuning.new()
	for adapter: String in ["llvmpipe (LLVM 15.0.7, 256 bits)", "SOFTPIPE", "SwiftShader", "Software Rasterizer", "lavapipe", "Microsoft Basic Render Driver"]:
		assert_bool(data.uses_low_quality(adapter)).is_true()
		assert_bool(data.ambient_audio_for(adapter)).is_false()
	for adapter: String in ["NVIDIA GeForce RTX 4060", "AMD Radeon RX 7600", "Intel UHD Graphics", ""]:
		assert_bool(data.uses_low_quality(adapter)).is_false()
		assert_bool(data.ambient_audio_for(adapter)).is_true()
	data.quality = AtmosphereTuning.Quality.HIGH
	assert_bool(data.uses_low_quality("llvmpipe")).is_false()
	assert_bool(data.ambient_audio_for("llvmpipe")).is_true()
	data.quality = AtmosphereTuning.Quality.LOW
	assert_bool(data.uses_low_quality("NVIDIA")).is_true()
	data.low_ambient_audio_enabled = true
	assert_bool(data.ambient_audio_for("NVIDIA")).is_true()

func test_low_preset_disables_only_loops_and_keeps_contact_audio() -> void:
	var atmosphere: WinterAtmosphere = auto_free(WinterAtmosphere.new())
	var data := AtmosphereTuning.new()
	data.quality = AtmosphereTuning.Quality.LOW
	atmosphere.tuning = data
	atmosphere.environment = Environment.new()
	atmosphere.set_process(false)
	add_child(atmosphere)
	assert_bool(atmosphere.low_quality).is_true()
	var wind: AudioStreamPlayer = atmosphere.get("_wind")
	var fire: AudioStreamPlayer = atmosphere.get("_fire")
	var steps: AudioStreamPlayer = atmosphere.get("_steps")
	assert_object(wind.stream).is_null()
	assert_object(fire.stream).is_null()
	assert_object(steps.stream).is_not_null()
	atmosphere.footstep(Vector3.ZERO, 0)
	assert_bool(steps.playing).is_true()
