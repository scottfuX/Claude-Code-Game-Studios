extends GdUnitTestSuite

func test_slice_pacing_and_smolder_budget() -> void:
	var data: SliceTuning = preload("res://assets/data/slice_defaults.tres")
	var clock := Clock.new(data)
	var seconds := 0.0
	while clock.day < 2 or clock.minute_of_day / 60.0 < clock.sunrise_hour():
		seconds += clock.seconds_per_minute()
		clock.advance_minute()
	assert_float(seconds).is_between(420.0, 480.0)
	assert_float(data.smolder_life * data.night_seconds).is_between(6.0, 8.0)

func test_missing_recipe_reports_only_unsatisfied_materials() -> void:
	var fire := FireController.new(&"test", Vector3.ZERO, ThermalField.new())
	var pack := InventoryModel.new()
	fire.stage = &"Cleared"
	assert_int(fire.missing_sticks(pack)).is_equal(4)
	assert_bool(fire.missing_tinder(pack)).is_true()
	pack.add(&"stick", 2)
	pack.add(&"bark", 2)
	assert_int(fire.missing_sticks(pack)).is_equal(2)
	assert_bool(fire.missing_tinder(pack)).is_false()
	pack.add(&"stick", 2)
	assert_bool(fire.can_act(&"arrange_tinder", pack)).is_true()

func test_one_initial_log_cannot_carry_idle_survivor_warm_to_dawn() -> void:
	var sim := RunSimulation.new()
	var fire := sim.create_fire(Vector3.ZERO)
	fire.stage = &"Kindling"
	fire.fuel = 26.0
	sim.inventory.add(&"log", 1)
	assert_bool(fire.commit_action(&"add_fuel", sim.inventory)).is_true()
	while sim.terminal == &"":
		sim.step_minute()
	assert_bool(sim.terminal != &"dawn_survived" or sim.body.stage != &"Warm").is_true()

func test_energy_fill_and_trend_ignore_invalid_and_paused_samples() -> void:
	var hud := HudModel.new()
	var state := {&"core_temp_c": 37.0, &"energy": 90.0, &"clock": Clock.new().snapshot()}
	hud.update(state, 1.0)
	state[&"energy"] = 80.0
	hud.update(state, 1.0)
	assert_int(hud.energy_trend).is_equal(-1)
	assert_float(hud.energy_fill).is_equal(0.8)
	state[&"energy"] = 95.0
	hud.update(state, 1.0, true)
	assert_int(hud.energy_trend).is_equal(-1)
	hud.update(state, 1.0)
	assert_int(hud.energy_trend).is_equal(1)
	assert_bool(hud.update({}, 1.0)).is_false()
