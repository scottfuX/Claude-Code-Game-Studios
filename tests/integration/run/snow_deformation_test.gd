extends GdUnitTestSuite

func test_speed_samples_fresh_ground_beyond_current_body_press() -> void:
	var surface: SnowSurface = auto_free(SnowSurface.new())
	var survivor: SurvivorController = auto_free(SurvivorController.new())
	survivor.tuning = PlayfieldTuning.new()
	survivor.snow = surface
	surface.deformation.press(Vector3.ZERO, 0.30, 0.72)
	assert_float(survivor.snow_speed_factor(Vector3.FORWARD)).is_equal(survivor.tuning.fresh_snow_speed_factor)
	surface.deformation.clear(Vector3.FORWARD * survivor.tuning.snow_speed_probe_distance, 0.3)
	assert_float(survivor.snow_speed_factor(Vector3.FORWARD)).is_equal(1.0)
	assert_float(survivor.snow_speed_factor(Vector3.RIGHT)).is_equal(survivor.tuning.fresh_snow_speed_factor)
	survivor.snow = null
	assert_float(survivor.snow_speed_factor(Vector3.FORWARD)).is_equal(1.0)

func test_fresh_press_clear_and_persistence() -> void:
	var snow := SnowDeformation.new(128, 16)
	assert_float(snow.compaction_at(Vector3.ZERO)).is_zero()
	snow.press(Vector3.ZERO, 0.6, 0.5)
	assert_float(snow.compaction_at(Vector3.ZERO)).is_equal_approx(0.5, 0.01)
	snow.press(Vector3.ZERO, 0.6, 0.2)
	assert_float(snow.compaction_at(Vector3.ZERO)).is_equal_approx(0.5, 0.01)
	snow.clear(Vector3.ZERO, 0.6)
	snow.upload(1000)
	assert_float(snow.compaction_at(Vector3.ZERO)).is_equal(1.0)
	assert_bool(snow.dirty).is_false()
	assert_float(snow.compaction_at(Vector3(3, 0, 3))).is_zero()

func test_bounds_invalid_input_and_oval() -> void:
	var snow := SnowDeformation.new(128, 16)
	snow.press(Vector3.INF, 1, 1)
	snow.press(Vector3.ZERO, -1, 1)
	snow.press(Vector3.ZERO, 1, NAN)
	snow.clear(Vector3(100, 0, 100), 1)
	assert_bool(snow.dirty).is_false()
	assert_float(snow.compaction_at(Vector3.INF)).is_zero()
	assert_float(snow.compaction_at(Vector3(100, 0, 100))).is_zero()
	snow.press(Vector3.ZERO, 0.4, 1, 2)
	assert_float(snow.compaction_at(Vector3(0, 0, 0.45))).is_greater(0.5)
	assert_float(snow.compaction_at(Vector3(0.6, 0, 0))).is_zero()
	snow.clear(Vector3(8, 0, 8), 0.6)
	assert_float(snow.compaction_at(Vector3(8, 0, 8))).is_equal(1.0)

func test_speed_factor_and_dirty_upload_throttle() -> void:
	var snow := SnowDeformation.new(128, 16)
	assert_float(snow.speed_factor(Vector3.ZERO, 0.85)).is_equal_approx(0.85, 0.001)
	snow.press(Vector3.ZERO, 1, 0.5)
	assert_float(snow.speed_factor(Vector3.ZERO, 0.85)).is_equal_approx(0.925, 0.001)
	snow.upload(0.01)
	assert_bool(snow.dirty).is_true()
	snow.upload(0.1)
	assert_bool(snow.dirty).is_false()
	snow.clear(Vector3.ZERO, 1)
	assert_float(snow.speed_factor(Vector3.ZERO, 0.85)).is_equal(1.0)
