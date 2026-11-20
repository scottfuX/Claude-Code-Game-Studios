extends GdUnitTestSuite

class Rolls extends RunRng:
	var values: Array[float] = []
	func draw_unit() -> float:
		draw_count += 1
		return values.pop_front()

func test_m4_fixtures_and_no_draw_surfaces() -> void:
	var mishaps := MishapResolver.new()
	assert_float(mishaps.ice_break_chance(25)).is_equal(0.0)
	assert_float(mishaps.ice_break_chance(8, 0.276)).is_equal_approx(0.015932, 0.000001)
	assert_float(mishaps.ice_break_chance(5, 1, true)).is_equal_approx(0.06, 0.000001)
	var rng := RunRng.new(1)
	for surface: Dictionary in [{}, {&"kind": &"snow"}, {&"kind": &"water", &"ice_thickness_cm": 5.0}, {&"kind": &"ice", &"ice_thickness_cm": 25.0}, {&"kind": &"ice", &"ice_thickness_cm": NAN}]:
		assert_bool(mishaps.check_ice(surface, 1, true, rng)).is_false()
	assert_int(rng.draw_count).is_equal(0)
	var rolls := Rolls.new()
	rolls.values = [0.0, 0.99]
	assert_bool(mishaps.check_ice({&"kind": &"ice", &"ice_thickness_cm": 5.0}, 0, false, rolls)).is_true()
	assert_bool(mishaps.check_ice({&"kind": &"ice", &"ice_thickness_cm": 5.0}, 0, false, rolls)).is_false()
	assert_int(rolls.draw_count).is_equal(2)

func test_tool_loss_chance_weights_and_empty_kit_draws() -> void:
	var mishaps := MishapResolver.new()
	var rng := Rolls.new()
	assert_str(mishaps.lost_tool([], rng)).is_empty()
	assert_int(rng.draw_count).is_equal(0)
	for selection in [0.0, 0.4999, 0.5, 0.7499, 0.75, 0.9999]:
		rng.values = [0.05, selection]
		var expected := &"hatchet" if selection < 0.5 else (&"knife" if selection < 0.75 else &"ferro_rod")
		assert_str(mishaps.lost_tool([&"knife", &"ferro_rod", &"hatchet"], rng)).is_equal(String(expected))
	rng.values = [0.10]
	assert_str(mishaps.lost_tool([&"knife"], rng)).is_empty()
	assert_int(rng.draw_count).is_equal(13)
	rng.values = [0.0, 0.99]
	assert_str(mishaps.lost_tool([&"knife"], rng)).is_equal("knife")

func test_wet_tinder_and_kindling_feed_damp_and_fire_heat() -> void:
	var inventory := InventoryModel.new()
	inventory.add(&"bark", 2)
	inventory.add(&"stick", 4)
	inventory.add(&"log", 1)
	inventory.add(&"stone", 2)
	inventory.soak_carried(1)
	assert_float(inventory.wetness(&"bark")).is_equal(1.0)
	assert_float(inventory.wetness(&"stone")).is_equal(0.0)
	inventory.add(&"log", 1)
	inventory.soak_carried(1)
	assert_float(inventory.wetness(&"log")).is_equal(0.5)
	var fire := FireController.new(&"wet_fire", Vector3.ZERO, ThermalField.new())
	fire.stage = &"Cleared"
	assert_bool(fire.commit_action(&"arrange_tinder", inventory)).is_true()
	assert_float(fire.material_wetness(&"strike")).is_equal(1.0)
	var mishaps := MishapResolver.new()
	assert_float(mishaps.failure_chance(&"strike", 0, 0, 0, fire.material_wetness(&"strike"))).is_equal(0.9)
	assert_str(mishaps.cause(&"strike", 0, 0, 0, 1)).is_equal("damp")
	fire.commit_action(&"strike", inventory)
	assert_float(fire.material_wetness(&"blow_embers")).is_equal(1.0)
	fire.commit_action(&"blow_embers", inventory)
	assert_float(fire.burning_wetness).is_equal(1.0)
	var wet_heat := fire.heat_c()
	fire.burning_wetness = 0.0
	assert_float(fire.heat_c()).is_greater(wet_heat)
	assert_bool(inventory.lose_tool(&"knife")).is_true()
	assert_bool(inventory.lose_tool(&"knife")).is_false()
