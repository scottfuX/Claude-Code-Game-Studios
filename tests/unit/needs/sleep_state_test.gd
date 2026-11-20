extends GdUnitTestSuite

const CHAPTER = preload("res://assets/data/three_day_survival.tres")


func test_sleep_admission_uses_strict_day_and_night_thresholds() -> void:
	var n := NeedsModel.new(CHAPTER)
	assert_bool(n.request_sleep(true)).is_false()
	n.energy = 89.99
	assert_bool(n.request_sleep(true)).is_true()
	assert_bool(n.request_sleep(true)).is_false()
	n.wake(&"normal")
	n.energy = 50.0
	assert_bool(n.request_sleep(false)).is_false()
	n.energy = 49.99
	assert_bool(n.request_sleep(false)).is_true()


func test_sleep_recovery_uses_pre_step_food_and_post_body_warmth() -> void:
	var warm := NeedsModel.new(CHAPTER)
	var chilled := NeedsModel.new(CHAPTER)
	warm.energy = 40.0
	chilled.energy = 40.0
	chilled.stomach_kcal = 0.0
	warm.request_sleep(false)
	chilled.request_sleep(false)
	for i in 60:
		warm.step_minute()
		chilled.step_minute(&"idle", false, false, &"idle", &"Chilled")
	assert_float(warm.energy).is_equal_approx(48.0, 0.00001)
	assert_float(chilled.energy).is_equal_approx(42.8, 0.00001)


func test_collapse_and_simultaneous_wakes_reconcile_once() -> void:
	var n := NeedsModel.new(CHAPTER)
	var causes: Array[StringName] = []
	n.sleep_changed.connect(func(_asleep: bool, cause: StringName) -> void: causes.append(cause))
	n.energy = 0.01
	n.step_minute()
	assert_bool(n.collapse_due).is_true()
	n.apply_collapse()
	assert_bool(n.is_asleep).is_true()
	assert_bool(n.wake(&"cold")).is_true()
	assert_bool(n.wake(&"normal")).is_false()
	assert_float(n.energy).is_equal(5.0)
	n.step_minute()
	assert_bool(n.collapse_due).is_false()
	assert_array(causes).contains_exactly([&"exhaustion", &"cold"])
