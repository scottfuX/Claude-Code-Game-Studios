extends GdUnitTestSuite

const CHAPTER = preload("res://assets/data/three_day_survival.tres")


func test_hydration_uses_awake_asleep_and_high_effort_rates() -> void:
	var awake := NeedsModel.new(CHAPTER)
	var asleep := NeedsModel.new(CHAPTER)
	var work := NeedsModel.new(CHAPTER)
	asleep.energy = 40.0
	assert_bool(asleep.request_sleep(true)).is_true()
	for i in 60:
		awake.step_minute()
		asleep.step_minute()
		work.step_minute(&"wade", false, false, &"heavy")
	assert_float(awake.hydration).is_equal_approx(98.6, 0.00001)
	assert_float(asleep.hydration).is_equal_approx(99.3, 0.00001)
	assert_float(work.hydration).is_equal_approx(97.9, 0.00001)
	assert_bool(awake.accept_drink(1000.0)).is_true()
	assert_float(awake.hydration).is_equal(100.0)


func test_dehydration_crossing_grace_reset_and_once_only_candidate() -> void:
	for accept in [true, false]:
		var n := NeedsModel.new(CHAPTER)
		n.hydration = 0.01
		n.step_minute()
		assert_float(n.hydration).is_zero()
		assert_int(n.zero_hydration_minutes).is_zero()
		for i in 359:
			n.step_minute()
		assert_int(n.zero_hydration_minutes).is_equal(359)
		assert_bool(n.dehydration_due).is_false()
		assert_bool(n.accept_drink(1.0 if accept else 0.0)).is_equal(accept)
		n.step_minute()
		assert_bool(n.dehydration_due).is_equal(not accept)
		assert_int(n.zero_hydration_minutes).is_equal(0 if accept else 360)
		n.step_minute()
		assert_bool(n.dehydration_due).is_false()


func test_parched_composes_with_exhaustion_and_uses_rising_hysteresis() -> void:
	var n := NeedsModel.new(CHAPTER)
	n.hydration = 8.0
	n.energy = 9.0
	n.step_minute()
	assert_str(n.hydration_stage).is_equal("Parched")
	assert_float(n.fatigue_penalty()).is_equal_approx(0.15, 0.00001)
	assert_float(n.action_mult()).is_equal_approx(1.375, 0.00001)
	var previous := n.energy
	n.step_minute(&"idle", true)
	assert_float(previous - n.energy).is_equal_approx(2.5 * 1.2 / 60.0, 0.00001)
	n.accept_drink(11.0 - n.hydration)
	assert_str(n.hydration_stage).is_equal("Parched")
	n.accept_drink(1.0)
	assert_str(n.hydration_stage).is_equal("Thirsty")
	n.accept_drink(19.0)
	assert_str(n.hydration_stage).is_equal("Thirsty")
	n.accept_drink(1.0)
	assert_str(n.hydration_stage).is_equal("OK")
