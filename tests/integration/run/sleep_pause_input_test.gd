extends GdUnitTestSuite

func _sleeping_run() -> RunCoordinator:
	var run: RunCoordinator = auto_free(preload("res://src/run/run.tscn").instantiate()) as RunCoordinator
	run.tuning = preload("res://assets/data/three_day_survival.tres")
	run.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(run)
	run.simulation.needs.energy = 40
	run.simulation.needs.refresh_stage()
	assert_bool(run.simulation.request_sleep()).is_true()
	run.call("_sync_context")
	assert_bool(run.simulation.needs.is_asleep).is_true()
	assert_int(run.input_router.context).is_equal(InputRouter.Context.UI)
	return run

func test_physical_escape_pauses_sleep_without_waking() -> void:
	var run := _sleeping_run()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_ESCAPE
	key.keycode = KEY_ESCAPE
	key.pressed = true
	run.input_router.call("_input", key)
	assert_bool(run.input_router.is_paused()).is_true()
	assert_bool(run.navigation.visible).is_true()
	assert_bool(run.simulation.needs.is_asleep).is_true()
	var minute := run.simulation.clock.minute_of_day
	run.call("_process", 5.0)
	assert_int(run.simulation.clock.minute_of_day).is_equal(minute)

func test_gamepad_start_pauses_sleep_without_waking() -> void:
	var run := _sleeping_run()
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_START
	button.pressed = true
	run.input_router.call("_input", button)
	assert_bool(run.input_router.is_paused()).is_true()
	assert_bool(run.navigation.visible).is_true()
	assert_bool(run.simulation.needs.is_asleep).is_true()
