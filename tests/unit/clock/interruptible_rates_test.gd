extends GdUnitTestSuite

const CHAPTER = preload("res://assets/data/three_day_survival.tres")


func test_same_minute_normal_wins_and_next_debt_uses_normal_cost() -> void:
	var c := Clock.new(CHAPTER)
	c.request_rate_mode(&"sleep")
	c.accumulate(0.1)
	assert_bool(c.consume_minute(func() -> void:
		c.request_rate_mode(&"normal", &"cold")
		c.request_rate_mode(&"sleep", &"exhaustion")
		assert_str(c.rate_mode).is_equal("sleep")
	)).is_true()
	assert_str(c.rate_mode).is_equal("normal")
	assert_bool(c.consume_minute()).is_false()
	assert_float(c.debt).is_equal_approx(0.05, 0.00001)
	c.advance_minute(func() -> void:
		c.request_rate_mode(&"wait")
		c.request_rate_mode(&"normal")
	)
	assert_str(c.rate_mode).is_equal("normal")
	c.advance_minute(func() -> void:
		c.request_rate_mode(&"wait")
		c.request_rate_mode(&"sleep")
	)
	c.request_rate_mode(&"wait")
	assert_str(c.rate_mode).is_equal("sleep")


func test_sleep_debt_carries_through_cap_midnight_and_sunrise() -> void:
	var sim := RunSimulation.new()
	sim.clock.minute_of_day = 1430
	sim.clock.request_rate_mode(&"sleep")
	sim.update(8.0)
	assert_int(sim.minute_sequence).is_equal(120)
	assert_int(sim.clock.day).is_equal(2)
	assert_int(sim.clock.minute_of_day).is_equal(110)
	assert_float(sim.clock.debt).is_equal_approx(2.0, 0.00001)
	sim.update(40.0, true)
	assert_int(sim.minute_sequence).is_equal(120)
	assert_float(sim.clock.debt).is_equal_approx(2.0, 0.00001)
	sim.update(0.05)
	assert_int(sim.minute_sequence).is_equal(161)
	var c := Clock.new(CHAPTER)
	c.minute_of_day = 1439
	c.request_rate_mode(&"sleep")
	c.accumulate(514 * 0.05)
	var sunrises: Array[int] = []
	var on_sunrise := func() -> void: sunrises.append(c.minute_of_day)
	c.sunrise.connect(on_sunrise)
	for i in 514:
		assert_bool(c.consume_minute()).is_true()
	c.sunrise.disconnect(on_sunrise)
	assert_int(c.day).is_equal(2)
	assert_array(sunrises).contains_exactly([513])
	assert_bool(c.consume_minute()).is_false()
