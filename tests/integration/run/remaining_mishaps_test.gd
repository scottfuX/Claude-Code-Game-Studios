extends GdUnitTestSuite

class Rolls extends RunRng:
	var roll: float = 0.38
	func draw_unit() -> float:
		draw_count += 1
		return roll

func test_material_quality_changes_strike_result_in_both_profiles() -> void:
	for resource: String in ["res://assets/data/slice_defaults.tres", "res://assets/data/three_day_survival.tres"]:
		var tuning := load(resource).duplicate() as SliceTuning
		tuning.weather_enabled = false
		var run := RunSimulation.new(42, tuning)
		var rng := Rolls.new()
		run.rng = rng
		var fire := run.create_fire(Vector3.ZERO)
		fire.stage = &"Cleared"
		run.inventory.add(&"bark", 2)
		run.inventory.add(&"stick", 4)
		fire.commit_action(&"arrange_tinder", run.inventory)
		assert_bool(run.start_action(&"strike", fire)).is_true()
		run.update(run.actions.duration_s + 0.001)
		assert_str(fire.stage).is_equal("Laid")
		assert_bool(fire.tinder_ready).is_true()
		assert_int(rng.draw_count).is_equal(1)
		rng.roll = 0.99
		assert_bool(run.start_action(&"strike", fire)).is_true()
		run.update(run.actions.duration_s + 0.001)
		assert_str(fire.stage).is_equal("Smoldering")
		rng.roll = 0.0
		assert_bool(run.start_action(&"blow_embers", fire)).is_true()
		run.update(run.actions.duration_s + 0.001)
		assert_bool(fire.tinder_ready).is_false()
		assert_int(fire.kindling_count).is_equal(4)
		assert_float(fire.fuel).is_equal(0.0)
		assert_int(rng.draw_count).is_equal(3)

func test_failure_cues_are_bilingual_and_non_numeric() -> void:
	var english: Translation = load("res://assets/localization/mishaps.en.translation")
	var chinese: Translation = load("res://assets/localization/mishaps.zh.translation")
	for cause: String in ["DAMP", "WIND", "TINDER", "COLD_HANDS", "FATIGUE", "FUMBLE"]:
		var key := StringName("MISHAP_" + cause)
		for translation: Translation in [english, chinese]:
			var message := String(translation.get_message(key))
			assert_str(message).is_not_empty()
			assert_bool(message == String(key)).is_false()
			for digit in "0123456789":
				assert_bool(message.contains(digit)).is_false()
