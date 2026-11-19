extends GdUnitTestSuite


func test_thermal_fixtures_and_registry() -> void:
	var t := ThermalField.new()
	t.begin_minute(1, 2.5)
	assert_float(t.effective_temp_c(Vector3.ZERO)).is_equal_approx(-11.88, 0.001)
	assert_bool(t.register_heat_source(&"fire", Vector3.ZERO, 25.0, 3.0)).is_true()
	assert_float(t.heat_at(Vector3(1.5, 100, 0))).is_equal_approx(18.75, 0.001)
	assert_bool(t.register_heat_source(&"bad", Vector3.ZERO, 25, 0)).is_false()
	t.unregister_heat_source(&"fire")
	assert_float(t.heat_at(Vector3.ZERO)).is_equal(0.0)


func test_thermal_ramp_cap_and_snapshot_isolation() -> void:
	var t := ThermalField.new()
	t.begin_minute(31, 14.5)
	assert_float(t.air_temp_c()).is_equal_approx(-13.0, 0.001)
	t.register_heat_source(&"a", Vector3.ZERO, 25, 3)
	t.register_heat_source(&"b", Vector3.ZERO, 25, 3)
	assert_float(t.heat_at(Vector3.ZERO)).is_equal(30.0)
	var s := RunSimulation.new()
	s.inventory.add(&"stick", 2)
	var values := s.snapshot()
	values[&"inventory"][&"stick"] = 100
	assert_int(s.inventory.count(&"stick")).is_equal(2)
