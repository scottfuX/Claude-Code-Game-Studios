extends GdUnitTestSuite

func test_fi5_damp_fuel_amount_mixing_and_capacity_use_same_effective_units() -> void:
	var inventory := InventoryModel.new()
	inventory.add(&"log", 1)
	inventory.soak_carried(1)
	inventory.add(&"log", 1)
	var fire := FireController.new(&"fire", Vector3.ZERO, ThermalField.new())
	fire.stage = &"Burning"
	fire.fuel = 240
	assert_bool(fire.commit_action(&"add_fuel", inventory)).is_true()
	assert_float(fire.fuel).is_equal(291.0)
	assert_float(fire.burning_wetness).is_equal_approx(0.5 * 51.0 / 291.0, 0.000001)
	fire.fuel = 249
	assert_bool(fire.can_act(&"add_fuel", inventory)).is_true()
	fire.fuel = 250
	assert_bool(fire.can_act(&"add_fuel", inventory)).is_false()
	assert_int(inventory.count(&"log")).is_equal(1)

func test_mixed_stack_consumption_preserves_sampled_moisture() -> void:
	var inventory := InventoryModel.new()
	inventory.add(&"log", 1)
	inventory.soak_carried(1)
	inventory.add(&"log", 1)
	var fire := FireController.new(&"fire", Vector3.ZERO, ThermalField.new())
	fire.stage = &"Burning"
	fire.fuel = 60
	assert_bool(fire.commit_action(&"add_fuel", inventory)).is_true()
	assert_float(inventory.wetness(&"log")).is_equal(0.5)
	assert_int(inventory.count(&"log")).is_equal(1)
	assert_bool(inventory.consume(&"log", 2)).is_false()
	assert_float(inventory.wetness(&"log")).is_equal(0.5)
	inventory.consume(&"log", 1)
	assert_float(inventory.wetness(&"log")).is_equal(0.0)
	inventory.add(&"log", 1)
	assert_float(inventory.wetness(&"log")).is_equal(0.0)

func test_wet_fire_penalty_survives_publication_and_reaches_body() -> void:
	var wet := RunSimulation.new()
	var dry := RunSimulation.new()
	for run: RunSimulation in [wet, dry]:
		run.body.core_temp_c = 35
		var fire := run.create_fire(Vector3.ZERO)
		fire.stage = &"Burning"
		fire.fuel = 120
	wet.fires[0].burning_wetness = 1.0
	wet.step_minute()
	dry.step_minute()
	assert_float(wet.fires[0].burning_wetness).is_equal_approx(0.95, 0.00001)
	assert_float(wet.last_felt_temp_c).is_less(dry.last_felt_temp_c)
	assert_float(wet.body.core_temp_c).is_less(dry.body.core_temp_c)
	for minute in 25:
		wet.fires[0].step_minute()
	assert_float(wet.fires[0].burning_wetness).is_equal(0.0)


func test_add_fuel_chooses_largest_available_item_that_fits() -> void:
	var fire := FireController.new(&"fire", Vector3.ZERO, ThermalField.new())
	var inventory := InventoryModel.new()
	fire.stage = &"Burning"
	fire.fuel = 280.0
	assert_bool(fire.can_act(&"add_fuel", inventory)).is_false()
	inventory.add(&"log", 2)
	inventory.add(&"stick", 2)
	assert_bool(fire.can_act(&"add_fuel", inventory)).is_true()
	assert_bool(fire.commit_action(&"add_fuel", inventory)).is_true()
	assert_float(fire.fuel).is_equal(286.0)
	assert_int(inventory.count(&"stick")).is_equal(1)
	assert_int(inventory.count(&"log")).is_equal(2)
	fire.fuel = 240.0
	assert_bool(fire.commit_action(&"add_fuel", inventory)).is_true()
	assert_float(fire.fuel).is_equal(300.0)
	assert_int(inventory.count(&"log")).is_equal(1)
	assert_bool(fire.can_act(&"add_fuel", inventory)).is_false()
	assert_bool(fire.commit_action(&"add_fuel", inventory)).is_false()
	assert_int(inventory.count(&"stick")).is_equal(1)
	assert_int(inventory.count(&"log")).is_equal(1)


func test_fire_fuel_heat_cap_and_expiry() -> void:
	var t := ThermalField.new()
	var f := FireController.new(&"fire", Vector3.ZERO, t)
	var i := InventoryModel.new()
	f.stage = &"Burning"
	f.fuel = 120
	f.publish_heat()
	assert_float(f.heat_c()).is_equal_approx(24.2106, 0.001)
	assert_float(f.warm_radius()).is_equal_approx(3.0481, 0.001)
	assert_float(f.burn_rate()).is_equal_approx(0.894, 0.001)
	i.add(&"log", 4)
	f.fuel = 280
	assert_bool(f.commit_action(&"add_fuel", i)).is_false()
	assert_int(i.count(&"log")).is_equal(4)
	f.stage = &"Embers"
	f.fuel = 0
	for minute in 90:
		f.step_minute()
	assert_str(f.stage).is_equal("Out")
	assert_float(t.heat_at(Vector3.ZERO)).is_equal(0.0)


func test_fire_lighting_consumption_and_smolder_timeout() -> void:
	var f := FireController.new(&"fire", Vector3.ZERO, ThermalField.new())
	var i := InventoryModel.new()
	i.add(&"stick", 4)
	i.add(&"bark", 2)
	assert_bool(f.commit_action(&"clear_snow", i)).is_true()
	assert_bool(f.commit_action(&"arrange_tinder", i)).is_true()
	assert_int(i.count(&"stick")).is_equal(0)
	assert_bool(f.commit_action(&"strike", i)).is_true()
	for minute in f.tuning.smolder_life:
		f.step_minute()
	assert_str(f.stage).is_equal("Laid")
	assert_bool(f.tinder_ready).is_false()
	assert_int(f.kindling_count).is_equal(4)
	i.add(&"grass", 3)
	assert_bool(f.commit_action(&"arrange_tinder", i)).is_true()
	f.commit_action(&"strike", i)
	f.commit_action(&"blow_embers", i)
	assert_str(f.stage).is_equal("Kindling")
	assert_float(f.fuel).is_equal(25.5)


func test_fire_transitions_exact_publication_and_failed_blow() -> void:
	var t := ThermalField.new()
	var f := FireController.new(&"fire", Vector3.ZERO, t)
	var i := InventoryModel.new()
	assert_bool(f.commit_action(&"arrange_tinder", i)).is_false()
	f.stage = &"Burning"
	f.fuel = 30.1
	f.step_minute()
	assert_str(f.stage).is_equal("Kindling")
	assert_float(t.heat_at(Vector3.ZERO)).is_equal(f.heat_c())
	f.fuel = 5.01
	f.step_minute()
	assert_str(f.stage).is_equal("Embers")
	i.add(&"log", 1)
	f.commit_action(&"add_fuel", i)
	assert_str(f.stage).is_equal("Embers")
	f.commit_action(&"blow_embers", i, false)
	assert_str(f.stage).is_equal("Embers")
	f.commit_action(&"blow_embers", i, true)
	assert_str(f.stage).is_equal("Burning")
	var tiny_before := t.heat_at(Vector3.ZERO)
	f.fuel += 0.01
	f.publish_heat()
	assert_float(t.heat_at(Vector3.ZERO)).is_greater(tiny_before)
