extends GdUnitTestSuite


func test_clock_rates_pause_and_debt() -> void:
	var c := Clock.new()
	assert_float(c.seconds_per_minute()).is_equal(1.5)
	c.accumulate(3.0, true)
	assert_bool(c.consume_minute()).is_false()
	c.accumulate(3.0)
	assert_bool(c.consume_minute()).is_true()
	assert_bool(c.consume_minute()).is_true()
	assert_int(c.minute_of_day).is_equal(992)
	c.rate_mode = &"wait"
	assert_float(c.seconds_per_minute()).is_equal(0.25)
	var sim := RunSimulation.new()
	sim.update(1000.0)
	assert_int(sim.clock.minute_of_day).is_equal(1110)
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


func test_default_run_starts_at_dusk_and_resource_controls_start_time() -> void:
	var sim := RunSimulation.new()
	assert_int(sim.clock.day).is_equal(1)
	assert_int(sim.clock.minute_of_day).is_equal(990)
	assert_str(sim.clock.phase()).is_equal("Dusk")
	assert_int(sim.clock.snapshot()[&"elapsed_minutes"]).is_zero()
	var hud := HudModel.new()
	hud.update(sim.snapshot(), 0)
	assert_bool(hud.hint_gone).is_false()
	for i in 9:
		sim.step_minute()
	hud.update(sim.snapshot(), 0)
	assert_bool(hud.hint_gone).is_false()
	sim.step_minute()
	hud.update(sim.snapshot(), 0)
	assert_bool(hud.hint_gone).is_true()
	var tuning := SliceTuning.new()
	tuning.start_day = 2
	tuning.start_minute_of_day = 780
	var custom := RunSimulation.new(1, tuning)
	assert_int(custom.clock.day).is_equal(2)
	assert_int(custom.clock.minute_of_day).is_equal(780)
	assert_str(custom.clock.phase()).is_equal("Day")
