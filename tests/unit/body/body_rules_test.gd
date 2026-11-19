extends GdUnitTestSuite


func test_body_rates_hysteresis_and_death() -> void:
	var b := BodyThermoregulation.new()
	b.step_minute(-4.2, &"heavy")
	assert_float(b.rate_c_per_hour).is_equal_approx(-0.2096, 0.001)
	b.core_temp_c = 33.9
	b.stage = &"Hypothermic"
	b.core_temp_c = 34.1
	b.refresh_stage()
	assert_str(b.stage).is_equal("Hypothermic")
	b.core_temp_c = 34.2
	b.refresh_stage()
	assert_str(b.stage).is_equal("Cold")
	b.core_temp_c = 30.01
	b.step_minute(-11.9)
	assert_bool(b.is_dead()).is_true()
	assert_float(b.core_temp_c).is_equal(30.0)


func test_body_activity_max_shiver_wetness_and_invalid_sample() -> void:
	var b := BodyThermoregulation.new()
	b.core_temp_c = 36.0
	b.stage = &"Chilled"
	b.step_minute(-4.2, &"walk", &"heavy")
	assert_float(b.rate_c_per_hour).is_equal_approx(0.0904, 0.001)
	b.step_minute(NAN, &"heavy")
	assert_float(b.rate_c_per_hour).is_equal_approx(0.0904, 0.001)
	var wet := BodyThermoregulation.new()
	wet.wetness = 1
	wet.step_minute(-4.2, &"heavy")
	assert_float(wet.rate_c_per_hour).is_equal_approx(-1.0192, 0.001)
	var invalid := BodyThermoregulation.new()
	invalid.step_minute(NAN)
	assert_float(invalid.core_temp_c).is_equal(37.0)
