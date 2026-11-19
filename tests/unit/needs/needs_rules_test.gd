extends GdUnitTestSuite


func test_needs_drain_rest_and_stages() -> void:
	var n := NeedsModel.new()
	n.step_minute(&"heavy", true, false)
	assert_float(n.energy).is_equal_approx(90.0 - 6.5 / 60, 0.001)
	n.step_minute(&"idle", false, true)
	assert_float(n.energy).is_equal_approx(90.0 - 5.0 / 60, 0.001)
	n.energy = 9
	n.refresh_stage()
	assert_str(n.stage).is_equal("Exhausted")
	n.energy = 11
	n.refresh_stage()
	assert_str(n.stage).is_equal("Exhausted")
	n.energy = 12
	n.refresh_stage()
	assert_str(n.stage).is_equal("Tired")
