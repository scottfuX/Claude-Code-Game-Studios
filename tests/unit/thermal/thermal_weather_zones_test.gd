extends GdUnitTestSuite

func test_wind_and_air_sources_validate_update_and_restore() -> void:
	var field := ThermalField.new()
	var baseline := field.air_temp_c()
	assert_bool(field.register_wind_source(&"weather", 7.0)).is_true()
	assert_bool(field.register_wind_source(&"other", 4.0)).is_false()
	assert_float(field.wind_eff()).is_equal_approx(5.6, 0.000001)
	assert_bool(field.update_wind_source(&"wrong", 4)).is_false()
	assert_bool(field.update_wind_source(&"weather", NAN)).is_false()
	assert_bool(field.update_wind_source(&"weather", 4)).is_true()
	assert_bool(field.register_air_offset(&"snap", -8)).is_true()
	assert_float(field.air_temp_c()).is_equal_approx(baseline - 8, 0.000001)
	assert_bool(field.register_air_offset(&"snap", -8)).is_false()
	assert_bool(field.update_air_offset(&"snap", NAN)).is_false()
	assert_bool(field.update_air_offset(&"missing", -1)).is_false()
	assert_bool(field.update_air_offset(&"snap", -4)).is_true()
	assert_float(field.air_temp_c()).is_equal_approx(baseline - 4, 0.000001)
	field.unregister_wind_source(&"other")
	assert_float(field.wind_eff()).is_equal_approx(3.2, 0.000001)
	field.unregister_wind_source(&"weather")
	field.unregister_air_offset(&"snap")
	assert_float(field.wind_eff()).is_equal_approx(2.4, 0.000001)
	assert_float(field.air_temp_c()).is_equal_approx(baseline, 0.000001)

func test_five_metre_band_endpoints_midpoint_and_default_open() -> void:
	var field := ThermalField.new()
	assert_float(field.components(Vector3.ZERO)[&"zone"]).is_equal(0.0)
	assert_bool(field.register_zone(&"trees", &"forest", _rectangle(0, 20))).is_true()
	for x in [-2.5, 0.0, 2.5]:
		var p := Vector3(x, 0, 10)
		var weight: float = (x + 2.5) / 5.0
		assert_float(field.components(p)[&"zone"]).is_equal_approx(weight, 0.000001)
		assert_float(field.wind_eff(p)).is_equal_approx(3.0 * lerpf(0.8, 0.4, weight), 0.000001)
		var c := field.components(p)
		assert_float(field.effective_temp_c(p)).is_equal_approx(c[&"air"] + c[&"zone"] - c[&"wind_chill"] + c[&"heat"] + c[&"shelter_bonus"], 0.000001)

func test_all_six_zones_and_shared_boundary_normalization() -> void:
	for kind: StringName in SliceTuning.new().thermal_zones:
		var field := ThermalField.new()
		assert_bool(field.register_zone(&"zone", kind, _rectangle(0, 20))).is_true()
		assert_float(field.components(Vector3(10, 0, 10))[&"zone"]).is_equal(field.tuning.thermal_zones[kind].x)
		assert_float(field.wind_eff(Vector3(10, 0, 10))).is_equal_approx(3.0 * field.tuning.thermal_zones[kind].y, 0.000001)
	var shared := ThermalField.new()
	shared.register_zone(&"a", &"forest", _rectangle(-20, 0))
	shared.register_zone(&"b", &"lake", _rectangle(0, 20))
	assert_float(shared.components(Vector3(0, 0, 10))[&"zone"]).is_equal(-1.0)
	assert_float(shared.zone_weights(Vector3.ZERO).values().reduce(func(a: float, b: float) -> float: return a + b, 0.0)).is_equal_approx(1.0, 0.000001)

func test_invalid_zone_and_detached_polygon() -> void:
	var field := ThermalField.new()
	assert_bool(field.register_zone(&"", &"forest", _rectangle(0, 20))).is_false()
	assert_bool(field.register_zone(&"bad", &"unknown", _rectangle(0, 20))).is_false()
	assert_bool(field.register_zone(&"bad", &"forest", PackedVector2Array())).is_false()
	var polygon := _rectangle(0, 20)
	field.register_zone(&"a", &"forest", polygon)
	polygon[0] = Vector2(100, 100)
	assert_float(field.components(Vector3(10, 0, 10))[&"zone"]).is_equal(1.0)

func _rectangle(left: float, right: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(left, 0), Vector2(right, 0), Vector2(right, 20), Vector2(left, 20)])
