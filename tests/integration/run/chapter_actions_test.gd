extends GdUnitTestSuite

const CHAPTER: SliceTuning = preload("res://assets/data/three_day_survival.tres")
const SHELL: PackedScene = preload("res://src/run/app_shell.tscn")


func test_snow_commits_after_three_integrated_minutes_at_either_rate() -> void:
	for rate: StringName in [&"normal", &"wait"]:
		var run := _chapter()
		assert_bool(run.start_snow_intake(false)).is_false()
		run.needs.hydration = 50.0
		run.needs.energy = 50.0
		run.clock.request_rate_mode(rate)
		assert_bool(run.start_snow_intake(true)).is_true()
		_step(run, 2)
		assert_str(run.actions.action).is_equal("eat_snow")
		assert_float(run.needs.hydration).is_less(50.0)
		_step(run, 1)
		assert_str(run.actions.action).is_empty()
		assert_float(run.needs.hydration).is_equal_approx(53.0 - 3.0 * CHAPTER.hydration_awake / 60.0, 0.0001)
		assert_float(run.needs.energy).is_between(48.0, 49.0)


func test_cancelled_snow_critical_refusal_and_terminal_never_commit() -> void:
	var run := _chapter()
	run.needs.hydration = 50.0
	assert_bool(run.start_snow_intake(true)).is_true()
	_step(run, 2)
	run.cancel_action()
	_step(run, 1)
	assert_float(run.needs.hydration).is_less(50.0)
	run.body.core_temp_c = 31.0
	run.body.refresh_stage()
	assert_bool(run.start_snow_intake(true)).is_false()
	run.body.core_temp_c = 33.0
	run.body.refresh_stage()
	assert_bool(run.start_snow_intake(true)).is_true()
	_step(run, 2)
	run.body.core_temp_c = 29.9
	_step(run, 1)
	assert_str(run.terminal).is_equal("hypothermia")
	assert_float(run.needs.hydration).is_less(50.0)


func test_consuming_by_a_fire_does_not_also_recover_energy_from_wait() -> void:
	var run := _chapter()
	var fire := run.create_fire(Vector3.ZERO)
	fire.stage = &"Burning"
	fire.fuel = 180.0
	run.needs.energy = 50.0
	run.needs.stomach_kcal = 200.0
	run.clock.request_rate_mode(&"wait")
	_step(run, 1)
	assert_float(run.needs.energy).is_greater(50.0)
	var before_meal := run.needs.energy
	assert_str(run.start_eating(&"pemmican")).is_empty()
	_step(run, 5)
	assert_float(run.needs.energy).is_less(before_meal)
	var before_snow := run.needs.energy
	assert_bool(run.start_snow_intake(true)).is_true()
	_step(run, 3)
	assert_float(run.needs.energy).is_less(before_snow - CHAPTER.snow_energy)


func test_meal_capacity_duration_and_exactly_one_commit() -> void:
	var run := _chapter()
	assert_int(run.inventory.count(&"pemmican")).is_equal(8)
	assert_str(run.start_eating(&"pemmican")).is_equal("stomach_full")
	assert_str(run.start_eating(&"missing")).is_equal("no_ration")
	run.needs.stomach_kcal = 200.0
	assert_str(run.start_eating(&"pemmican")).is_empty()
	_step(run, 4)
	assert_int(run.inventory.count(&"pemmican")).is_equal(8)
	_step(run, 1)
	assert_int(run.inventory.count(&"pemmican")).is_equal(7)
	assert_float(run.needs.stomach_kcal).is_equal_approx(700.0 - 5.0 * CHAPTER.calories_awake / 60.0, 0.0001)
	_step(run, 5)
	assert_int(run.inventory.count(&"pemmican")).is_equal(7)


func test_interrupted_stale_and_no_longer_eligible_meals_preserve_the_ration() -> void:
	var run := _chapter()
	run.needs.stomach_kcal = 200.0
	assert_str(run.start_eating(&"pemmican")).is_empty()
	run.cancel_action()
	_step(run, 5)
	assert_int(run.inventory.count(&"pemmican")).is_equal(8)
	assert_str(run.start_eating(&"pemmican")).is_empty()
	run.inventory.consume(&"pemmican", 1)
	run.inventory.add(&"pemmican", 1)
	_step(run, 5)
	assert_int(run.inventory.count(&"pemmican")).is_equal(8)
	assert_float(run.needs.stomach_kcal).is_less(200.0)
	assert_str(run.start_eating(&"pemmican")).is_empty()
	run.needs.stomach_kcal = 1400.0
	_step(run, 5)
	assert_int(run.inventory.count(&"pemmican")).is_equal(8)
	assert_float(run.needs.stomach_kcal).is_less(1400.0)


func test_chapter_switch_pack_and_sleep_bind_through_the_scene() -> void:
	var shell: Node = auto_free(SHELL.instantiate())
	shell.set("save_store", SaveStore.new("user://test-checkpoints/chapter_" + str(Time.get_ticks_usec())))
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var run := shell.get("_run") as RunCoordinator
	assert_int(run.simulation.inventory.count(&"pemmican")).is_zero()
	run.switch_chapter_requested.emit()
	await get_tree().process_frame
	run = shell.get("_run") as RunCoordinator
	assert_int(run.simulation.clock.minute_of_day).is_equal(780)
	assert_int(run.world.interactables.size()).is_equal(19)
	assert_bool(run.world.is_on_snow(Vector3.ZERO)).is_true()
	assert_bool(run.world.is_on_snow(Vector3(0, 4, 0))).is_false()
	run.simulation.needs.stomach_kcal = 200.0
	run.input_router.action_pressed.emit(&"backpack")
	run.hud.eat_requested.emit()
	assert_str(run.simulation.actions.action).is_equal("eat")
	assert_bool(run.backpack_open).is_false()
	run.simulation.cancel_action()
	run.simulation.needs.energy = 35.0
	run.input_router.action_pressed.emit(&"sleep")
	assert_bool(run.simulation.needs.is_asleep).is_false()
	var fire := run.simulation.create_fire(Vector3(0, 0, -0.6))
	fire.stage = &"Out"
	run.input_router.action_pressed.emit(&"sleep")
	assert_bool(run.survivor.frozen).is_true()
	assert_str(run.simulation.clock.rate_mode).is_equal("sleep")
	run.input_router.call("_dispatch", &"cancel_action")
	run.simulation.update(run.simulation.clock.seconds_per_minute())
	assert_bool(run.simulation.needs.is_asleep).is_false()
	assert_bool(run.survivor.frozen).is_false()
	assert_int(run.input_router.context).is_equal(InputRouter.Context.GAMEPLAY)


func test_chapter_hud_consumes_stage_warnings_and_hides_raw_physiology() -> void:
	var run := _chapter()
	run.needs.hydration_stage = &"Thirsty"
	run.needs.fullness_stage = &"Hungry"
	var hud: SurvivalHud = auto_free(SurvivalHud.new())
	add_child(hud)
	var snapshot := run.snapshot()
	hud.render_snapshot(snapshot)
	var canvas := hud.get_child(0) as HudCanvas
	var warnings: Array = canvas.view[&"needs"]
	assert_int(warnings.size()).is_equal(2)
	assert_str(warnings[0][&"stage"]).is_equal("Thirsty")
	assert_str(warnings[1][&"stage"]).is_equal("Hungry")
	assert_int(canvas.view[&"night_goal"]).is_equal(3)
	assert_int(canvas.view[&"nights_survived"]).is_zero()
	assert_bool(canvas.view.has(&"weight_kg")).is_false()
	assert_str(hud.tr(&"ITEM_PEMMICAN")).is_equal("pemmican rations")


func test_ration_button_stays_visible_between_backpack_draws() -> void:
	var hud: SurvivalHud = auto_free(SurvivalHud.new())
	add_child(hud)
	var snapshot := _chapter().snapshot()
	hud.set_visibility_context(&"backpack")
	hud.render_snapshot(snapshot)
	var ration_button: Button
	for child: Node in hud.find_children("*", "Button", true, false):
		var button := child as Button
		if button.text == hud.tr(&"VERB_EAT_RATION"):
			ration_button = button
			break
	assert_object(ration_button).is_not_null()
	assert_bool(ration_button.is_visible_in_tree()).is_true()
	var changes: Array[bool] = []
	ration_button.visibility_changed.connect(func() -> void: changes.append(ration_button.visible))
	hud.render_snapshot(snapshot)
	assert_int(changes.size()).is_zero()


func _chapter() -> RunSimulation:
	return RunSimulation.new(20261119, CHAPTER)


func _step(run: RunSimulation, minutes: int) -> void:
	for i in minutes:
		run.update(run.clock.seconds_per_minute())
