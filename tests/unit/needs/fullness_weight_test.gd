extends GdUnitTestSuite

const CHAPTER = preload("res://assets/data/three_day_survival.tres")
const DEFAULTS = preload("res://assets/data/slice_defaults.tres")


func test_invalid_weight_and_capacity_use_default_tuning() -> void:
	var tuning := CHAPTER.duplicate() as SliceTuning
	tuning.start_weight_kg = NAN
	tuning.stomach_capacity_kcal = 0.0
	var n := NeedsModel.new(tuning)
	assert_float(n.weight_kg).is_equal(DEFAULTS.start_weight_kg)
	assert_float(n.energy_cap()).is_equal(100.0)
	assert_float(n.fullness()).is_equal_approx(100.0 * tuning.stomach_start_kcal / DEFAULTS.stomach_capacity_kcal, 0.00001)
	assert_bool(n.accept_food(DEFAULTS.stomach_capacity_kcal - n.stomach_kcal)).is_true()
	assert_float(n.fullness()).is_equal(100.0)


func test_stomach_pays_first_and_activity_uses_highest_effort() -> void:
	var idle := NeedsModel.new(CHAPTER)
	var work := NeedsModel.new(CHAPTER)
	assert_float(idle.stomach_kcal).is_equal(1200.0)
	for i in 60:
		idle.step_minute()
		work.step_minute(&"walk", true, false, &"heavy")
	assert_float(idle.stomach_kcal).is_equal_approx(1090.0, 0.00001)
	assert_float(idle.fullness()).is_equal_approx(72.667, 0.001)
	assert_float(idle.weight_kg).is_equal(72.0)
	assert_float(work.stomach_kcal).is_equal_approx(810.0, 0.00001)
	assert_bool(work.accept_food(800.0)).is_false()
	assert_float(work.stomach_kcal).is_equal_approx(810.0, 0.00001)


func test_empty_burn_lowers_weight_and_energy_cap_to_their_floors() -> void:
	var tuning := CHAPTER.duplicate() as SliceTuning
	tuning.stomach_start_kcal = 0.0
	tuning.calories_awake = 3530.0
	var n := NeedsModel.new(tuning)
	for i in 60:
		n.step_minute()
	assert_float(72.0 - n.weight_kg).is_equal_approx(0.458, 0.002)
	n.weight_kg = 72.0 * 0.9
	assert_float(n.energy_cap()).is_equal_approx(80.0, 0.00001)
	n.weight_kg = 72.0 * 0.8
	assert_float(n.energy_cap()).is_equal_approx(60.0, 0.00001)
	n.weight_kg = 40.001
	n.step_minute()
	assert_float(n.weight_kg).is_equal(40.0)
	assert_float(n.energy_cap()).is_equal(60.0)


func test_empty_clock_starts_at_crossing_and_accepted_food_resets_it() -> void:
	var n := NeedsModel.new(CHAPTER)
	n.stomach_kcal = 0.1
	n.step_minute()
	assert_int(n.empty_minutes).is_zero()
	for i in 1439:
		n.step_minute()
	assert_str(n.fullness_stage).is_equal("Empty")
	n.step_minute()
	assert_str(n.fullness_stage).is_equal("Starving")
	var previous := n.energy
	n.step_minute()
	assert_float(previous - n.energy).is_equal_approx(1.2 / 60.0, 0.00001)
	assert_bool(n.accept_food(1501.0)).is_false()
	assert_str(n.fullness_stage).is_equal("Starving")
	assert_bool(n.accept_food(400.0)).is_true()
	assert_int(n.empty_minutes).is_zero()
	assert_str(n.fullness_stage).is_equal("Hungry")
