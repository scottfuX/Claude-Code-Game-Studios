extends GdUnitTestSuite

func test_external_mishap_and_item_coefficients_are_injected() -> void:
	var tuning := SliceTuning.new()
	tuning.tinder_quality = {&"bark": 0.5}
	tuning.tinder_fail = {&"strike": 0.2}
	tuning.damp_fail = {&"strike": 0.1}
	assert_float(InventoryModel.new(tuning).tinder_quality(&"bark")).is_equal(0.5)
	assert_float(MishapResolver.new(tuning).failure_chance(&"strike", 2, 0, 0, 1, 0.5)).is_equal_approx(0.55, 0.000001)

class Rolls extends RunRng:
	var roll: float = 0.0
	func draw_unit() -> float:
		draw_count += 1
		return roll

func test_all_active_profile_bases_and_physical_terms() -> void:
	var m := MishapResolver.new()
	for action: StringName in [&"strike", &"blow_embers", &"chop_log", &"strip_bark", &"gather_sticks"]:
		var base: float = {&"strike": 0.35, &"blow_embers": 0.25, &"chop_log": 0.1, &"strip_bark": 0.1, &"gather_sticks": 0.05}[action]
		assert_float(m.failure_chance(action, 2, 0, 0)).is_equal(base)
		assert_float(m.failure_chance(action, 2, 0.06, 0.08, 0, 1, 0.1)).is_equal_approx(base + 0.24, 0.000001)
		var damp: float = {&"strike": 0.6, &"blow_embers": 0.5}.get(action, 0.0)
		var wind: float = {&"strike": 0.04, &"blow_embers": 0.05}.get(action, 0.0)
		var tinder := 0.4 if action == &"strike" else 0.0
		assert_float(m.failure_chance(action, 2, 0, 0, 0.5)).is_equal_approx(base + damp * 0.5, 0.000001)
		assert_float(m.failure_chance(action, 3, 0, 0)).is_equal_approx(base + wind, 0.000001)
		assert_float(m.failure_chance(action, 2, 0, 0, 0, 0.5)).is_equal_approx(base + tinder * 0.5, 0.000001)
	assert_float(m.failure_chance(&"strike", 2.4, 0, 0, 0, 0.9)).is_equal_approx(0.406, 0.000001)
	assert_float(m.failure_chance(&"strike", 2.4, 0, 0, 0, 0.7)).is_equal_approx(0.486, 0.000001)
	assert_float(m.failure_chance(&"strike", 25, 0.2, 0.15, 1, 0, 0.1)).is_equal(0.9)

func test_cause_threshold_tie_priority_and_morale_is_never_named() -> void:
	var m := MishapResolver.new()
	assert_str(m.cause(&"strike", 2, 0.049, 0)).is_equal("fumble")
	assert_str(m.cause(&"strike", 2, 0.05, 0)).is_equal("cold_hands")
	assert_str(m.cause(&"strike", 7, 0.2, 0.2, 0.5, 0.5)).is_equal("damp")
	assert_str(m.cause(&"strike", 7, 0.2, 0.2, 0, 0.5)).is_equal("wind")
	assert_str(m.cause(&"strike", 2, 0.2, 0.2, 0, 0.5)).is_equal("cold_hands")
	assert_str(m.cause(&"strike", 2, 0, 0.2, 0, 0.5)).is_equal("fatigue")
	assert_str(m.cause(&"strike", 2, 0, 0, 0, 0.5)).is_equal("tinder")
	var rng := Rolls.new()
	assert_str(m.resolve(&"chop_log", 2, 0, 0, rng, 0, 1, 0.1)[&"cause"]).is_equal("fumble")

func test_guard_is_per_action_consumed_once_and_reset_by_success_or_physical_cause() -> void:
	var m := MishapResolver.new()
	var rng := Rolls.new()
	for i in 4:
		assert_float(m.resolve(&"strike", 2, 0, 0, rng)[&"p_fail"]).is_equal(0.35)
	assert_float(m.resolve(&"chop_log", 2, 0, 0, rng)[&"p_fail"]).is_equal(0.1)
	assert_float(m.resolve(&"strike", 2, 0, 0, rng)[&"p_fail"]).is_equal(0.175)
	assert_float(m.resolve(&"strike", 2, 0, 0, rng)[&"p_fail"]).is_equal(0.35)
	rng.roll = 0.99
	m.resolve(&"strike", 2, 0, 0, rng)
	rng.roll = 0.0
	for i in 4:
		assert_float(m.resolve(&"strike", 2, 0, 0, rng)[&"p_fail"]).is_equal(0.35)
	assert_float(m.resolve(&"strike", 2, 0, 0, rng, 1)[&"p_fail"]).is_equal(0.9)
	assert_float(m.resolve(&"strike", 2, 0, 0, rng)[&"p_fail"]).is_equal(0.35)
	assert_float(MishapResolver.new().resolve(&"strike", 2, 0, 0, rng)[&"p_fail"]).is_equal(0.35)

func test_unprofiled_actions_cannot_fail_or_consume_rng_even_with_penalties() -> void:
	var m := MishapResolver.new()
	var rng := Rolls.new()
	for action: StringName in [&"gather_grass", &"gather_stones", &"clear_snow", &"place_stones", &"arrange_tinder", &"add_fuel", &"eat", &"eat_snow", &"sit_warm", &"rest", &"pick_up", &"drop", &"carve_feather_stick", &"unknown", &""]:
		assert_float(m.failure_chance(action, 25, 1, 1, 1, 0, 1)).is_equal(0.0)
		var result := m.resolve(action, 25, 1, 1, rng, 1, 0, 1)
		assert_bool(result[&"success"]).is_true()
		assert_str(result[&"cause"]).is_empty()
	assert_int(rng.draw_count).is_equal(0)

func test_failure_metadata_and_gather_consequences() -> void:
	var m := MishapResolver.new()
	var rng := Rolls.new()
	for action: StringName in [&"strike", &"blow_embers", &"chop_log", &"strip_bark", &"gather_sticks"]:
		var result := m.resolve(action, 2, 0, 0, rng)
		assert_bool(result[&"success"]).is_false()
		assert_str(result[&"severity"]).is_equal("moderate" if action == &"blow_embers" else "minor")
		assert_str(result[&"tag"]).is_equal("disappointment" if action in [&"blow_embers", &"strip_bark", &"gather_sticks"] else "helplessness")
		assert_float(result[&"base_fail_chance"]).is_equal(m.tuning.base_fail[action])
	var inventory := InventoryModel.new()
	var gathering := GatheringResolver.new()
	var wood := GatherNode.new(&"deadfall", 4, 0, 4)
	gathering.resolve(wood, &"chop_log", false, inventory)
	assert_int(inventory.count(&"log")).is_equal(0)
	gathering.resolve(wood, &"strip_bark", false, inventory)
	assert_int(inventory.count(&"bark")).is_equal(1)
	gathering.resolve(GatherNode.new(&"bush", 6), &"gather_sticks", false, inventory)
	assert_int(inventory.count(&"stick")).is_equal(1)

func test_fire_uses_selected_material_quality_and_failure_keeps_only_kindling() -> void:
	for material: StringName in [&"bark", &"grass"]:
		var inventory := InventoryModel.new()
		inventory.add(material, 3)
		inventory.add(&"stick", 4)
		inventory.soak_carried(1)
		var fire := FireController.new(&"fire", Vector3.ZERO, ThermalField.new())
		fire.stage = &"Cleared"
		assert_bool(fire.commit_action(&"arrange_tinder", inventory)).is_true()
		assert_float(fire.material_quality(&"strike")).is_equal(0.9 if material == &"bark" else 0.7)
		assert_float(fire.material_wetness(&"strike")).is_equal(1.0)
		assert_bool(fire.commit_action(&"strike", inventory, false)).is_true()
		assert_bool(fire.tinder_ready).is_true()
		assert_str(fire.stage).is_equal("Laid")
		fire.commit_action(&"strike", inventory, true)
		assert_float(fire.material_wetness(&"blow_embers")).is_equal(1.0)
		fire.commit_action(&"blow_embers", inventory, false)
		assert_bool(fire.tinder_ready).is_false()
		assert_float(fire.fuel).is_equal(0.0)
		assert_int(fire.kindling_count).is_equal(4)
		assert_int(inventory.count(&"stick")).is_equal(0)
		inventory.add(material, 3)
		assert_bool(fire.commit_action(&"arrange_tinder", inventory)).is_true()
		assert_int(inventory.count(&"stick")).is_equal(0)
