extends GdUnitTestSuite

const CHAPTER = preload("res://assets/data/three_day_survival.tres")


func test_seeded_chapter_ends_once_at_third_sunrise_across_frame_partitions() -> void:
	var coarse := _replay(40.0)
	var fine := _replay(0.75)
	assert_array(coarse[1]).contains_exactly([&"day_2", &"sunrise", &"day_3", &"sunrise", &"day_4", &"sunrise", &"dawn_survived"])
	assert_array(fine[1]).is_equal(coarse[1])
	assert_dict(fine[0]).is_equal(coarse[0])
	assert_int(coarse[0][&"clock"][&"day"]).is_equal(4)
	assert_int(coarse[0][&"clock"][&"minute_of_day"]).is_equal(519)
	assert_int(coarse[0][&"clock"][&"elapsed_minutes"]).is_equal(3 * 1440 + 519 - 780)
	var fresh := RunSimulation.new(4, CHAPTER)
	assert_str(fresh.terminal).is_empty()
	assert_int(fresh.clock.day).is_equal(1)
	assert_int(fresh.minute_sequence).is_zero()
	assert_float(fresh.needs.hydration).is_equal(100.0)
	assert_float(fresh.needs.weight_kg).is_equal(72.0)
	assert_bool(fresh.needs.is_asleep).is_false()


func test_terminal_precedence_suppresses_wake_collapse_and_uncommitted_action() -> void:
	for cause in [&"hypothermia", &"dehydration", &"dawn_survived"]:
		var tuning := CHAPTER.duplicate() as SliceTuning
		tuning.rate_min = -0.6
		tuning.rate_max = -0.6
		var sim := RunSimulation.new(4, tuning)
		sim.clock.day = 4
		sim.clock.minute_of_day = 518
		var node := GatherNode.new(&"bush", 8)
		assert_bool(sim.start_action(&"gather_sticks", null, node)).is_true()
		if cause != &"dawn_survived":
			sim.needs.hydration = 0.0
			sim.needs.zero_hydration_minutes = 359
		if cause == &"hypothermia":
			sim.body.core_temp_c = 30.001
		sim.needs.energy = 0.01
		var ends: Array[StringName] = []
		var wakes: Array[StringName] = []
		sim.run_ended.connect(func(result: StringName) -> void: ends.append(result))
		sim.needs.sleep_changed.connect(func(_asleep: bool, result: StringName) -> void: wakes.append(result))
		sim.update(100.0)
		assert_str(sim.terminal).is_equal(cause)
		assert_array(ends).contains_exactly([cause])
		assert_array(wakes).is_empty()
		assert_int(sim.minute_sequence).is_equal(1)
		assert_int(sim.rng.draw_count).is_zero()
		assert_int(node.remaining).is_equal(8)
		assert_str(sim.actions.action).is_empty()
		sim.update(100.0)
		sim.step_minute()
		assert_int(sim.minute_sequence).is_equal(1)
		assert_array(ends).contains_exactly([cause])
		assert_bool(sim.request_sleep()).is_false()
		assert_bool(sim.start_action(&"gather_sticks", null, node)).is_false()


func test_default_starts_at_dusk_and_keeps_its_first_sunrise_outcome() -> void:
	var sim := RunSimulation.new()
	assert_int(sim.clock.minute_of_day).is_equal(990)
	assert_bool(sim.request_sleep()).is_false()
	assert_bool(sim.snapshot().has(&"needs")).is_false()
	sim.clock.day = 2
	sim.clock.minute_of_day = 512
	sim.step_minute()
	assert_str(sim.terminal).is_equal("dawn_survived")


func _replay(delta: float) -> Array:
	var tuning := CHAPTER.duplicate() as SliceTuning
	tuning.cooling = 0.0
	var sim := RunSimulation.new(4, tuning)
	var trace: Array[StringName] = []
	sim.clock.day_changed.connect(func(day: int) -> void: trace.append(StringName("day_%d" % day)))
	sim.clock.sunrise.connect(func() -> void: trace.append(&"sunrise"))
	sim.run_ended.connect(func(cause: StringName) -> void: trace.append(cause))
	var node := GatherNode.new(&"bush", 8)
	assert_bool(sim.start_action(&"gather_sticks", null, node)).is_true()
	sim.update(5.0)
	assert_int(sim.rng.draw_count).is_equal(1)
	sim.clock.request_rate_mode(&"wait")
	for i in 3000:
		if sim.terminal != &"":
			break
		sim.update(delta)
	assert_int(sim.rng.draw_count).is_equal(1)
	return [sim.snapshot(), trace]
