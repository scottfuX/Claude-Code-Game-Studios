extends GdUnitTestSuite

func test_seeded_transitions_dwell_and_duplicate_minutes() -> void:
	var a := WeatherController.new()
	var b := WeatherController.new()
	var ra := RunRng.new(91)
	var rb := RunRng.new(91)
	var previous: StringName = &"Clear"
	var deadline := -1
	var transitions := 0
	for minute in 1440:
		a.step_minute(minute, ra)
		b.step_minute(minute, rb)
		var values := a.snapshot()
		assert_dict(values).is_equal(b.snapshot())
		if minute == 0 or values[&"state"] != previous:
			if minute > 0:
				assert_int(minute).is_equal(deadline)
				transitions += 1
			deadline = values[&"transition_minute"]
			assert_int(deadline - minute).is_between(120, 360)
		previous = values[&"state"]
		var draws := ra.draw_count
		a.step_minute(minute, ra)
		a.step_minute(minute - 1, ra)
		assert_int(ra.draw_count).is_equal(draws)
	assert_int(transitions).is_greater(0)
	assert_int(ra.draw_count).is_equal(rb.draw_count)

func test_cold_snap_day_two_start_end_and_no_day_one_roll() -> void:
	var data := WeatherTuning.new()
	data.dwell_min = 10000
	data.dwell_max = 10000
	data.snap_chance = 1.0
	data.snap_min = 360
	data.snap_max = 360
	var weather := WeatherController.new(data)
	var rng := RunRng.new(4)
	weather.step_minute(359, rng)
	weather.step_minute(360, rng)
	assert_int(rng.draw_count).is_equal(1)
	assert_bool(weather.snapshot()[&"cold_snap"]).is_false()
	weather.step_minute(1799, rng)
	assert_int(rng.draw_count).is_equal(1)
	weather.step_minute(1800, rng)
	assert_int(rng.draw_count).is_equal(3)
	assert_float(weather.snapshot()[&"air_offset_c"]).is_equal(-8.0)
	weather.step_minute(2159, rng)
	assert_bool(weather.snapshot()[&"cold_snap"]).is_true()
	weather.step_minute(2160, rng)
	assert_bool(weather.snapshot()[&"cold_snap"]).is_false()
	assert_float(weather.snapshot()[&"air_offset_c"]).is_equal(0.0)

func test_weather_outputs_and_transition_weights() -> void:
	var data := WeatherTuning.new()
	data.dwell_min = 1
	data.dwell_max = 1
	data.snap_chance = 0.0
	var weather := WeatherController.new(data)
	var rng := RunRng.new(84)
	var expected_rng := RunRng.new(84)
	expected_rng.draw_unit()
	var previous: StringName = &"Clear"
	var counts: Dictionary[StringName, int] = {&"Clear": 0, &"Windy": 0, &"Snowing": 0}
	for minute in 1000:
		weather.step_minute(minute, rng)
		var values := weather.snapshot()
		if minute > 0:
			var roll := expected_rng.draw_unit()
			var expected: StringName
			match previous:
				&"Clear": expected = &"Windy" if roll < 0.5 else &"Snowing"
				&"Windy": expected = &"Clear" if roll < 0.4 else &"Snowing"
				&"Snowing": expected = &"Clear" if roll < 0.5 else &"Windy"
			assert_str(values[&"state"]).is_equal(String(expected))
			expected_rng.draw_unit()
		previous = values[&"state"]
		counts[values[&"state"]] += 1
		assert_float(values[&"wind_mps"]).is_equal(data.wind_mps[values[&"state"]])
		assert_float(values[&"snowfall_m_per_hour"]).is_equal(0.01 if values[&"state"] == &"Snowing" else 0.0)
		assert_float(values[&"wetness_per_hour"]).is_equal(0.05 if values[&"state"] == &"Snowing" else 0.0)
	for state: StringName in counts:
		assert_int(counts[state]).is_greater(0)

func test_invalid_inputs_install_defaults_and_do_not_draw() -> void:
	var data := WeatherTuning.new()
	data.dwell_min = 0
	assert_bool(data.is_valid()).is_false()
	var weather := WeatherController.new(data)
	assert_int(weather.tuning.dwell_min).is_equal(120)
	var rng := RunRng.new(2)
	weather.step_minute(-1, rng)
	weather.step_minute(0, null)
	assert_int(rng.draw_count).is_equal(0)
	var values := weather.snapshot()
	values[&"state"] = &"Snowing"
	assert_str(weather.snapshot()[&"state"]).is_equal("Clear")

func test_snap_duration_range_rejection_and_change_signal() -> void:
	for seed_value in 10:
		var data := WeatherTuning.new()
		data.snap_chance = 1.0
		var weather := WeatherController.new(data)
		var events: Array[Dictionary] = []
		weather.weather_changed.connect(func(value: Dictionary[StringName, Variant]) -> void: events.append(value))
		weather.step_minute(1800, RunRng.new(seed_value))
		assert_int(int(weather.snapshot()[&"snap_end_minute"]) - 1800).is_between(360, 720)
		assert_int(events.size()).is_equal(1)
	var never := WeatherTuning.new()
	never.snap_chance = 0.0
	var clear := WeatherController.new(never)
	var rng := RunRng.new(8)
	clear.step_minute(1800, rng)
	assert_bool(clear.snapshot()[&"cold_snap"]).is_false()
	assert_int(rng.draw_count).is_equal(2)
