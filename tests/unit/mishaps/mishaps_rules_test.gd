extends GdUnitTestSuite


func test_mishap_clamp_cause_and_seed() -> void:
	var a := RunRng.new(42)
	var b := RunRng.new(42)
	assert_float(a.draw_unit()).is_equal(b.draw_unit())
	var m := MishapResolver.new()
	assert_float(m.failure_chance(&"strike", 25, 0.8, 0.8)).is_equal(0.9)
	assert_str(m.cause(&"strike", 2.4, 0.12, 0.04)).is_equal("cold_hands")
	assert_str(m.cause(&"strike", 2.4, 0, 0)).is_equal("fumble")
