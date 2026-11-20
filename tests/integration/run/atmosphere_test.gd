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
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var run := shell.get("_run") as RunCoordinator
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

func test_fog_palette_persists_between_clock_ticks() -> void:
	var shell: Node = auto_free(preload("res://src/run/app_shell.tscn").instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var run := shell.get("_run") as RunCoordinator
	var environment := run.environment_node.environment
	for minute: int in [990, 1031, 1034, 1035, 1036, 0, 465, 466, 510]:
		run.simulation.clock.minute_of_day = minute
		run.call("_update_lighting")
		var fog := environment.fog_light_color
		var density := environment.fog_density
		for frame in 3:
			run.call("_update_lighting")
			assert_bool(environment.fog_light_color.is_equal_approx(fog)).is_true()
			assert_float(environment.fog_density).is_equal(density)

func test_sun_moon_handoff_is_continuous_at_both_twilight_boundaries() -> void:
	var shell: Node = auto_free(preload("res://src/run/app_shell.tscn").instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var run := shell.get("_run") as RunCoordinator
	for boundary: int in [465, 1035]:
		run.simulation.clock.minute_of_day = boundary - 3
		run.call("_update_lighting")
		var energy := run.sun.light_energy
		var color := run.sun.light_color
		var rotation := run.sun.rotation
		var opacity := run.sun.shadow_opacity
		for minute in range(boundary - 2, boundary + 4):
			run.simulation.clock.minute_of_day = minute
			run.call("_update_lighting")
			assert_float(absf(run.sun.light_energy - energy)).is_less(0.02)
			assert_float(absf(run.sun.light_color.r - color.r)).is_less(0.04)
			assert_float(absf(run.sun.light_color.g - color.g)).is_less(0.04)
			assert_float(absf(run.sun.light_color.b - color.b)).is_less(0.04)
			assert_float(run.sun.rotation.distance_to(rotation)).is_less(0.05)
			assert_float(absf(run.sun.shadow_opacity - opacity)).is_less(0.02)
			assert_bool(run.sun.shadow_enabled).is_true()
			energy = run.sun.light_energy
			color = run.sun.light_color
			rotation = run.sun.rotation
			opacity = run.sun.shadow_opacity
	run.simulation.clock.minute_of_day = 0
	run.call("_update_lighting")
	var atmosphere: WinterAtmosphere = run.get("_atmosphere")
	assert_float(run.sun.light_energy).is_equal_approx(atmosphere.tuning.moon_energy, 0.0001)
	assert_float(run.sun.shadow_opacity).is_zero()
	run.simulation.clock.minute_of_day = 720
	run.call("_update_lighting")
	assert_float(run.sun.light_energy).is_equal_approx(0.85, 0.0001)

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
