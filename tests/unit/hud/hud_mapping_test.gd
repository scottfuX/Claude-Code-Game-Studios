extends GdUnitTestSuite

func _snapshot() -> Dictionary:
	return {&"core_temp_c": 37.0, &"body_stage": &"Warm", &"rate_c_per_hour": 0.0, &"clock": {&"day": 1, &"minute_of_day": 780, &"sunrise_hour": 8.5, &"sunset_hour": 16.5, &"phase": &"Day"}}

func test_h1_fill_clamps_and_rejects_invalid_samples() -> void:
	assert_float(HudModel.band_fill(37)).is_equal(1.0)
	assert_float(HudModel.band_fill(35.5)).is_equal_approx(0.785714, 0.00001)
	assert_float(HudModel.band_fill(32)).is_equal_approx(0.285714, 0.00001)
	assert_float(HudModel.band_fill(29)).is_zero()
	assert_float(HudModel.band_fill(40)).is_equal(1.0)
	assert_bool(is_nan(HudModel.band_fill(NAN))).is_true()

func test_h2_thresholds_select_single_double_or_steady() -> void:
	for rate: float in [-0.81, -0.1]:
		assert_int(HudModel.trend_arrow(rate)).is_equal(-1)
	assert_int(HudModel.trend_arrow(-1.49)).is_equal(-2)
	assert_int(HudModel.trend_arrow(1.6)).is_equal(2)
	assert_int(HudModel.trend_arrow(0.1)).is_equal(1)
	assert_int(HudModel.trend_arrow(0.05)).is_zero()
	assert_int(HudModel.trend_arrow(NAN)).is_zero()

func test_h2_candidate_requires_two_unpaused_seconds_and_resets_on_change() -> void:
	var model := HudModel.new()
	var state := _snapshot()
	state[&"rate_c_per_hour"] = -0.81
	model.update(state, 1.0)
	assert_int(model.arrow).is_zero()
	model.update(state, 10.0, true)
	assert_int(model.arrow).is_zero()
	model.update(state, 1.0)
	assert_int(model.arrow).is_equal(-1)
	state[&"rate_c_per_hour"] = 1.6
	model.update(state, 1.5)
	assert_int(model.arrow).is_equal(-1)
	state[&"rate_c_per_hour"] = 0.1
	model.update(state, 1.0)
	assert_int(model.arrow).is_equal(-1)
	model.update(state, 1.0)
	assert_int(model.arrow).is_equal(1)
	state[&"rate_c_per_hour"] = 0.0
	model.update(state, 2.0)
	assert_int(model.arrow).is_zero()

func test_h5_solar_noon_and_nightfall_midnight_wrapping() -> void:
	var clock: Dictionary = _snapshot()[&"clock"]
	clock[&"minute_of_day"] = 750
	assert_float(HudModel.arc_progress(clock) * 180).is_equal(90.0)
	clock[&"phase"] = &"Dawn"
	clock[&"minute_of_day"] = 480
	assert_float(HudModel.arc_progress(clock)).is_zero()
	clock[&"phase"] = &"Dusk"
	clock[&"minute_of_day"] = 1020
	assert_float(HudModel.arc_progress(clock)).is_equal(1.0)
	clock[&"phase"] = &"Night"
	clock[&"minute_of_day"] = 1035
	assert_float(HudModel.arc_progress(clock)).is_zero()
	clock[&"minute_of_day"] = 30
	assert_float(HudModel.arc_progress(clock)).is_equal_approx(7.25 / 14.5, 0.0001)
	assert_bool(is_nan(HudModel.arc_progress({}))).is_true()

func test_qualitative_quantities_never_return_counts() -> void:
	var model := HudModel.new()
	assert_str(model.quantity_key(0)).is_equal("HUD_QUANTITY_NONE")
	assert_str(model.quantity_key(-1)).is_equal("HUD_QUANTITY_NONE")
	assert_str(model.quantity_key(1)).is_equal("HUD_QUANTITY_FEW")
	assert_str(model.quantity_key(4)).is_equal("HUD_QUANTITY_FEW")
	assert_str(model.quantity_key(5)).is_equal("HUD_QUANTITY_PLENTY")
	assert_str(model.quantity_key(100)).is_equal("HUD_QUANTITY_PLENTY")

func test_controls_hint_latches_on_timeout_and_never_returns() -> void:
	var model := HudModel.new()
	var state := _snapshot()
	model.update(state, 0)
	assert_bool(model.hint_gone).is_false()
	state[&"clock"][&"minute_of_day"] = 789
	model.update(state, 0)
	assert_bool(model.hint_gone).is_false()
	state[&"clock"][&"minute_of_day"] = 790
	model.update(state, 0)
	assert_bool(model.hint_gone).is_true()
	model.update(_snapshot(), 0)
	assert_bool(model.hint_gone).is_true()
	assert_bool(HudModel.new().hint_gone).is_false()

func test_controls_hint_latches_on_first_kindling_even_after_fire_goes_out() -> void:
	var model := HudModel.new()
	var state := _snapshot()
	state[&"fires"] = [{&"stage": &"Smoldering"}]
	model.update(state, 0)
	assert_bool(model.hint_gone).is_false()
	state[&"fires"] = [{&"stage": &"Kindling"}]
	model.update(state, 0)
	assert_bool(model.hint_gone).is_true()
	state[&"fires"] = []
	model.update(state, 0)
	assert_bool(model.hint_gone).is_true()

func test_h3_calm_fade_warning_recovery_and_visibility_precedence() -> void:
	var model := HudModel.new()
	var state := _snapshot()
	model.update(state, 0)
	model.update(state, 8)
	model.update(state, 1.5)
	assert_float(model.opacity).is_equal_approx(0.35, 0.0001)
	state[&"energy_stage"] = &"Tired"
	model.update(state, 0)
	model.update(state, 0.5)
	assert_float(model.opacity).is_equal_approx(1.0, 0.0001)
	model.update(state, 0.1)
	assert_float(model.opacity).is_equal_approx(1.0, 0.0001)
	assert_int(model.energy_level).is_equal(1)
	state[&"energy_stage"] = &"Exhausted"
	model.update(state, 0)
	assert_int(model.energy_level).is_equal(2)
	assert_float(model.band_opacity(&"sleep", true)).is_equal(0.35)
	assert_float(model.band_opacity(&"ritual", true)).is_equal(0.35)
	assert_float(model.band_opacity(&"end", true)).is_zero()
	assert_float(model.band_opacity(&"gameplay", true)).is_equal(1.0)

func test_invalid_or_empty_snapshot_holds_last_valid_band_and_arc() -> void:
	var model := HudModel.new()
	var state := _snapshot()
	state[&"core_temp_c"] = 32.0
	assert_bool(model.update(state, 0)).is_true()
	var previous := model.fill
	var arc := model.arc
	assert_bool(model.update({}, 2)).is_false()
	state[&"core_temp_c"] = NAN
	assert_bool(model.update(state, 2)).is_false()
	assert_float(model.fill).is_equal(previous)
	assert_float(model.arc).is_equal(arc)
