extends GdUnitTestSuite


func test_clock_rates_pause_and_debt() -> void:
	var c := Clock.new()
	assert_float(c.seconds_per_minute()).is_equal(1.5)
	c.accumulate(3.0, true)
	assert_bool(c.consume_minute()).is_false()
	c.accumulate(3.0)
	assert_bool(c.consume_minute()).is_true()
	assert_bool(c.consume_minute()).is_true()
	assert_int(c.minute_of_day).is_equal(782)
	c.rate_mode = &"wait"
	assert_float(c.seconds_per_minute()).is_equal(0.25)
	var sim := RunSimulation.new()
	sim.update(1000.0)
	assert_int(sim.clock.minute_of_day).is_equal(900)
	assert_float(sim.clock.debt).is_greater(0.0)


func test_clock_phases_and_day_two_sunrise() -> void:
	var c := Clock.new()
	assert_float(c.sunrise_hour()).is_equal(8.5)
	c.minute_of_day = 990
	assert_str(c.phase()).is_equal("Dusk")
	c.minute_of_day = 1035
	assert_str(c.phase()).is_equal("Night")
	assert_float(c.seconds_per_minute()).is_equal(1.0)
	c.day = 2
	assert_float(c.sunrise_hour()).is_equal_approx(8.55, 0.001)


func test_clock_boundary_notifications_and_fractional_debt() -> void:
	var c := Clock.new()
	var counts: Array[int] = [0, 0]
	c.sunrise.connect(func() -> void: counts[0] += 1)
	c.day_changed.connect(func(_day: int) -> void: counts[1] += 1)
	c.minute_of_day = 1439
	c.advance_minute()
	assert_int(counts[1]).is_equal(1)
	c.minute_of_day = 512
	c.advance_minute()
	assert_int(counts[0]).is_equal(1)
	c.accumulate(0.75)
	assert_bool(c.consume_minute()).is_false()
	c.accumulate(0.75)
	assert_bool(c.consume_minute()).is_true()
