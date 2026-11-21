extends GdUnitTestSuite

func test_drying_thresholds_clamps_and_pre_step_cooling() -> void:
	for felt in [-1.0, 0.0, 9.99, 10.0]:
		var body := BodyThermoregulation.new()
		body.wetness = 1.0
		body.step_minute(felt)
		var drying := 0.6 if felt >= 10 else (0.1 if felt >= 0 else 0.0)
		assert_float(body.wetness).is_equal_approx(1.0 - drying / 60.0, 0.000001)
		if felt == 0.0:
			assert_float(body.rate_c_per_hour).is_equal_approx(-0.88, 0.000001)
	var dry := BodyThermoregulation.new()
	dry.step_minute(10.0)
	assert_float(dry.wetness).is_equal(0.0)

func test_snowfall_wading_and_immersion_idempotency() -> void:
	var body := BodyThermoregulation.new()
	body.step_minute(-5.0, &"wade", &"idle", 0.05)
	assert_float(body.wetness).is_equal_approx(0.08 / 60.0, 0.000001)
	body.apply_immersion(12)
	assert_float(body.wetness).is_equal(1.0)
	body.step_minute(10.0)
	body.apply_immersion(12)
	assert_float(body.wetness).is_equal_approx(0.99, 0.000001)
	body.apply_immersion(13)
	assert_float(body.wetness).is_equal(1.0)
	body.step_minute(-5.0, &"wade", &"idle", 0.05)
	assert_float(body.wetness).is_equal(1.0)

func test_invalid_gain_and_dead_body_do_not_change_wetness() -> void:
	var body := BodyThermoregulation.new()
	body.apply_immersion(-1)
	body.step_minute(-5.0, &"idle", &"idle", NAN)
	assert_float(body.wetness).is_equal(0.0)
	body.core_temp_c = 30.0
	body.apply_immersion(1)
	body.step_minute(-5.0, &"wade", &"idle", 0.05)
	assert_float(body.wetness).is_equal(0.0)
