extends GdUnitTestSuite

func test_first_night_has_no_weather_or_weather_draws() -> void:
	var run := RunSimulation.new()
	run.step_minute()
	assert_object(run.weather).is_null()
	assert_bool(run.snapshot().has(&"weather")).is_false()
	assert_int(run.rng.draw_count).is_equal(0)
	assert_float(run.thermal.wind_eff()).is_equal_approx(2.4, 0.000001)

func test_three_night_profile_enables_weather_and_pause_freezes_it() -> void:
	var run := RunSimulation.new(23, preload("res://assets/data/three_day_survival.tres"))
	assert_object(run.weather).is_not_null()
	run.update(100.0, true)
	assert_int(run.rng.draw_count).is_equal(0)
	run.step_minute()
	assert_int(run.rng.draw_count).is_equal(1)
	assert_bool(run.snapshot().has(&"weather")).is_true()

func test_weather_publishes_before_fire_and_body_in_same_minute() -> void:
	var data := SliceTuning.new()
	data.weather_enabled = true
	data.start_day = 2
	data.start_minute_of_day = 359
	data.survival_day = 5
	var run := RunSimulation.new(23, data)
	var weather_data := WeatherTuning.new()
	weather_data.snap_chance = 1.0
	run.weather = WeatherController.new(weather_data)
	run.weather.state = &"Snowing"
	var baseline := ThermalField.new(data)
	baseline.begin_minute(2, 6)
	run.step_minute()
	assert_float(run.thermal.air_temp_c()).is_equal_approx(baseline.air_temp_c() - 8.0, 0.000001)
	assert_float(run.thermal.wind_eff()).is_equal_approx(3.2, 0.000001)
	assert_float(run.body.wetness).is_equal_approx(0.05 / 60.0, 0.000001)
	assert_float(run.last_felt_temp_c).is_equal_approx(run.thermal.effective_temp_c(run.position), 0.000001)

func test_weather_wait_replay_across_frame_partitions_and_restart() -> void:
	var data := SliceTuning.new()
	data.weather_enabled = true
	data.cooling = 0.0
	var coarse := RunSimulation.new(51, data)
	var fine := RunSimulation.new(51, data)
	coarse.clock.request_rate_mode(&"wait")
	fine.clock.request_rate_mode(&"wait")
	for i in 10:
		coarse.update(10.0)
	for i in 400:
		fine.update(0.25)
	assert_dict(coarse.weather.snapshot()).is_equal(fine.weather.snapshot())
	assert_dict(coarse.rng.snapshot()).is_equal(fine.rng.snapshot())
	assert_dict(coarse.snapshot()).is_equal(fine.snapshot())
	var fresh := RunSimulation.new(51, data)
	assert_int(fresh.rng.draw_count).is_equal(0)
	assert_str(fresh.weather.snapshot()[&"state"]).is_equal("Clear")
