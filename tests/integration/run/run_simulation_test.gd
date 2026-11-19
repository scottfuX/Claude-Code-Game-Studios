extends GdUnitTestSuite


func test_simulation_same_minute_out_terminal_and_restart() -> void:
	var s := RunSimulation.new()
	var f := s.create_fire(Vector3.ZERO)
	f.stage = &"Embers"
	f.ember_minutes = 89
	f.publish_heat()
	s.step_minute()
	assert_str(f.stage).is_equal("Out")
	assert_float(s.last_felt_temp_c).is_equal_approx(s.thermal.air_temp_c() - 2.88, 0.001)
	s.clock.day = 2
	s.clock.minute_of_day = 512
	s.body.core_temp_c = 30.001
	s.body.stage = &"Critical"
	s.step_minute()
	assert_str(s.terminal).is_equal("hypothermia")
	var fresh := RunSimulation.new()
	assert_float(fresh.body.core_temp_c).is_equal(37.0)
	assert_int(fresh.fires.size()).is_equal(0)
	fresh.clock.day = 2
	fresh.clock.minute_of_day = 512
	fresh.step_minute()
	assert_str(fresh.terminal).is_equal("dawn_survived")


func test_simulation_actions_keep_work_until_minute_barrier_and_commit_once() -> void:
	var s := RunSimulation.new()
	var node := GatherNode.new(&"deadfall", 2)
	assert_bool(s.start_action(&"chop_log", null, node)).is_true()
	s.update(1.5)
	assert_float(s.body.rate_c_per_hour).is_equal_approx(-0.21, 0.02)
	assert_float(s.needs.energy).is_equal_approx(90 - 5.0 / 60, 0.001)
	s.update(0.5, true)
	assert_float(s.actions.elapsed_s).is_equal(1.5)
	s.movement = &"walk"
	s.update(0.1)
	assert_int(s.rng.draw_count).is_equal(0)
	s.movement = &"idle"
	s.start_action(&"chop_log", null, node)
	s.update(6.0)
	assert_int(s.rng.draw_count).is_equal(1)
	s.update(6.0)
	assert_int(s.rng.draw_count).is_equal(1)
	s.body.stage = &"Critical"
	assert_bool(s.start_action(&"chop_log", null, node)).is_false()


func test_terminal_discards_action_before_any_completion_draw() -> void:
	var s := RunSimulation.new()
	var node := GatherNode.new(&"deadfall", 2)
	s.start_action(&"chop_log", null, node)
	s.body.core_temp_c = 30.001
	s.clock.day = 2
	s.clock.minute_of_day = 512
	s.update(10)
	assert_str(s.terminal).is_equal("hypothermia")
	assert_int(s.rng.draw_count).is_equal(0)
	assert_int(node.remaining).is_equal(2)
	var sequence := s.minute_sequence
	s.update(100)
	assert_int(s.minute_sequence).is_equal(sequence)


func test_empty_actions_no_profile_and_zero_energy_are_safe() -> void:
	var a := ActionRunner.new()
	assert_bool(a.start(&"strike", 0, 1.5)).is_false()
	assert_bool(a.start(&"strike", NAN, 1.5)).is_false()
	assert_str(a.advance(1)).is_empty()
	var rng := RunRng.new()
	var m := MishapResolver.new()
	m.resolve(&"clear_snow", 2.4, 0, 0, rng)
	assert_int(rng.draw_count).is_equal(0)
	var n := NeedsModel.new()
	n.energy = 0
	n.step_minute(&"heavy", true)
	assert_float(n.energy).is_equal(0.0)
	assert_str(n.stage).is_equal("Exhausted")
	var s := RunSimulation.new()
	assert_bool(s.start_action(&"missing")).is_false()
	assert_object(s.create_fire(Vector3.ZERO)).is_not_null()
	assert_object(s.create_fire(Vector3.ONE)).is_not_null()
	assert_object(s.create_fire(Vector3.ZERO)).is_null()
