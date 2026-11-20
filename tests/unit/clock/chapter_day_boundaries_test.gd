extends GdUnitTestSuite

const CHAPTER = preload("res://assets/data/three_day_survival.tres")


func test_chapter_emits_one_midnight_and_sunrise_through_day_four() -> void:
	var c := Clock.new(CHAPTER)
	assert_int(c.minute_of_day).is_equal(780)
	assert_str(c.phase()).is_equal("Day")
	assert_int(Clock.new().minute_of_day).is_equal(990)
	var midnights: Array[int] = []
	var sunrises: Array[Vector2i] = []
	var ticks: Array[int] = [0]
	var on_midnight := func(day: int) -> void:
		midnights.append(day)
		assert_int(c.minute_of_day).is_zero()
	var on_sunrise := func() -> void:
		sunrises.append(Vector2i(c.day, c.minute_of_day))
		assert_str(c.phase()).is_equal("Day")
	c.day_changed.connect(on_midnight)
	c.sunrise.connect(on_sunrise)
	c.minute_tick.connect(func() -> void: ticks[0] += 1)
	while c.day < 4 or c.minute_of_day < 520:
		c.advance_minute()
	c.day_changed.disconnect(on_midnight)
	c.sunrise.disconnect(on_sunrise)
	assert_array(midnights).contains_exactly([2, 3, 4])
	assert_array(sunrises).contains_exactly([Vector2i(2, 513), Vector2i(3, 516), Vector2i(4, 519)])
	assert_int(ticks[0]).is_equal(3 * 1440 + 520 - 780)
	assert_float(c.sunset_hour() - c.sunrise_hour()).is_equal_approx(7.7, 0.00001)
