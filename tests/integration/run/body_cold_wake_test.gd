extends GdUnitTestSuite

const CHAPTER = preload("res://assets/data/three_day_survival.tres")


func test_fire_out_does_not_wake_but_later_body_cold_interrupts_debt() -> void:
	var tuning := CHAPTER.duplicate() as SliceTuning
	tuning.rate_min = -0.6
	tuning.rate_max = -0.6
	var sim := RunSimulation.new(1, tuning)
	sim.clock.minute_of_day = 1200
	sim.body.core_temp_c = 36.515
	sim.needs.energy = 70.0
	var fire := sim.create_fire(Vector3.ZERO)
	fire.stage = &"Embers"
	fire.ember_minutes = tuning.ember_life - 1
	fire.publish_heat()
	var cold_wakes: Array[StringName] = []
	var wakes: Array[StringName] = []
	sim.body.wake_request.connect(func(cause: StringName) -> void: cold_wakes.append(cause))
	sim.needs.sleep_changed.connect(func(asleep: bool, cause: StringName) -> void:
		if not asleep:
			wakes.append(cause)
	)
	assert_bool(sim.request_sleep()).is_true()
	sim.update(0.05)
	assert_int(sim.minute_sequence).is_equal(1)
	assert_str(fire.stage).is_equal("Out")
	assert_str(sim.body.stage).is_equal("Warm")
	assert_bool(sim.needs.is_asleep).is_true()
	assert_array(cold_wakes).is_empty()
	sim.update(0.1)
	assert_int(sim.minute_sequence).is_equal(2)
	assert_str(sim.body.stage).is_equal("Chilled")
	assert_array(cold_wakes).contains_exactly([&"cold"])
	assert_array(wakes).contains_exactly([&"cold"])
	assert_str(sim.clock.rate_mode).is_equal("normal")
	assert_float(sim.clock.debt).is_equal_approx(0.05, 0.00001)
	assert_float(sim.needs.hydration).is_equal_approx(100.0 - 2 * 0.7 / 60.0, 0.00001)
	sim.update(0.95)
	assert_int(sim.minute_sequence).is_equal(3)
	assert_float(sim.needs.hydration).is_equal_approx(100.0 - (2 * 0.7 + 1.4) / 60.0, 0.00001)
	assert_array(wakes).contains_exactly([&"cold"])


func test_collapse_while_already_cold_wakes_once_and_cancels_work() -> void:
	var tuning := CHAPTER.duplicate() as SliceTuning
	tuning.weather_enabled = false
	tuning.rate_min = -0.6
	tuning.rate_max = -0.6
	var sim := RunSimulation.new(1, tuning)
	sim.body.core_temp_c = 35.0
	sim.body.refresh_stage()
	sim.needs.energy = 0.01
	var node := GatherNode.new(&"bush", 8)
	assert_bool(sim.start_action(&"gather_sticks", null, node)).is_true()
	var wakes: Array[StringName] = []
	sim.needs.sleep_changed.connect(func(_asleep: bool, cause: StringName) -> void: wakes.append(cause))
	sim.update(1.5)
	assert_bool(sim.needs.is_asleep).is_false()
	assert_array(wakes).contains_exactly([&"cold"])
	assert_float(sim.needs.energy).is_equal(5.0)
	assert_str(sim.clock.rate_mode).is_equal("normal")
	assert_str(sim.actions.action).is_empty()
	assert_int(sim.rng.draw_count).is_zero()
	sim.update(1.5)
	assert_array(wakes).contains_exactly([&"cold"])
	assert_int(node.remaining).is_equal(8)


func test_reaching_cold_while_skipping_requests_normal_even_at_natural_wake() -> void:
	var tuning := CHAPTER.duplicate() as SliceTuning
	tuning.rate_min = -0.6
	tuning.rate_max = -0.6
	for sleep in [true, false]:
		var sim := RunSimulation.new(1, tuning)
		sim.clock.minute_of_day = 1200
		sim.body.core_temp_c = 35.505
		sim.body.refresh_stage()
		sim.needs.weight_kg = 64.8
		sim.needs.energy = 79.98
		var wakes: Array[StringName] = []
		sim.needs.sleep_changed.connect(func(asleep: bool, cause: StringName) -> void:
			if not asleep:
				wakes.append(cause)
		)
		if sleep:
			assert_bool(sim.request_sleep()).is_true()
		else:
			sim.clock.request_rate_mode(&"wait")
		sim.step_minute()
		assert_str(sim.body.stage).is_equal("Cold")
		assert_bool(sim.needs.is_asleep).is_false()
		assert_str(sim.clock.rate_mode).is_equal("normal")
		assert_array(wakes).contains_exactly([&"cold"] if sleep else [])


func test_natural_external_and_same_minute_wakes_settle_before_next_tick() -> void:
	var tuning := CHAPTER.duplicate() as SliceTuning
	tuning.cooling = 0.0
	var sim := RunSimulation.new(1, tuning)
	sim.clock.minute_of_day = 1200
	sim.needs.weight_kg = 64.8
	sim.needs.energy = 79.9
	var wakes: Array[StringName] = []
	sim.needs.sleep_changed.connect(func(asleep: bool, cause: StringName) -> void:
		if not asleep:
			wakes.append(cause)
	)
	assert_bool(sim.request_sleep()).is_true()
	sim.update(0.1)
	assert_int(sim.minute_sequence).is_equal(1)
	assert_float(sim.needs.energy).is_equal_approx(80.0, 0.00001)
	assert_str(sim.clock.rate_mode).is_equal("normal")
	assert_bool(sim.request_sleep()).is_true()
	sim.clock.request_rate_mode(&"normal")
	assert_bool(sim.needs.is_asleep).is_false()
	assert_array(wakes).contains_exactly([&"rested", &"interrupted"])
	sim.needs.energy = 0.01
	var interrupt := sim.clock.request_rate_mode.bind(&"normal", &"alarm")
	sim.clock.minute_tick.connect(interrupt, CONNECT_ONE_SHOT)
	sim.step_minute()
	assert_float(sim.needs.energy).is_equal(5.0)
	assert_bool(sim.needs.is_asleep).is_false()
	assert_str(sim.clock.rate_mode).is_equal("normal")
	assert_array(wakes).contains_exactly([&"rested", &"interrupted", &"interrupted"])
