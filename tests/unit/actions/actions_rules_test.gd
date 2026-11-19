extends GdUnitTestSuite


func test_action_cancel_pause_and_once_only_completion() -> void:
	var a := ActionRunner.new()
	assert_bool(a.start(&"chop_log", 4, 1.5)).is_true()
	assert_str(a.advance(5, true)).is_empty()
	assert_float(a.elapsed_s).is_equal(0.0)
	a.cancel()
	assert_str(a.advance(10)).is_empty()
	a.start(&"strike", 0.5, 1.5)
	assert_str(a.advance(0.75)).is_equal("strike")
	assert_str(a.advance(1)).is_empty()
