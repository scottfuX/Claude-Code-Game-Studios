extends GdUnitTestSuite

const SHELL: PackedScene = preload("res://src/run/app_shell.tscn")

func _shell() -> Node:
	var shell: Node = auto_free(SHELL.instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	return shell

func _press(router: InputRouter, action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	router.call("_input", event)

func test_title_initial_focus_hidden_continue_and_invalid_start() -> void:
	var shell := _shell()
	assert_str(shell.get("state")).is_equal("title")
	assert_object(shell.get("_run")).is_null()
	var menu: NavigationScreen = shell.get("_menu")
	assert_bool(menu.visible).is_true()
	var buttons: Array = menu.get("_buttons")
	assert_bool((buttons[0] as Button).visible).is_false()
	assert_bool((buttons[1] as Button).has_focus()).is_true()
	assert_bool(shell.call("start_run", {&"profile": &"missing"})).is_false()
	assert_bool(shell.call("start_run", {&"restore": {&"invalid": true}})).is_false()
	assert_str(shell.get("state")).is_equal("title")
	assert_object(shell.get("_run")).is_null()
	var status: Label = menu.get("_status")
	assert_str(status.text).is_equal(tr(&"MENU_START_ERROR"))

func test_cli_bypass_selects_expected_profile_and_default_boot_shows_title() -> void:
	var shell := _shell()
	for argument: String in ["--three-day", "--demo"]:
		shell.call("boot", PackedStringArray([argument]))
		var run: RunCoordinator = shell.get("_run")
		assert_str(shell.get("state")).is_equal("run")
		assert_bool(run.simulation.tuning.chapter_needs_enabled).is_equal(argument == "--three-day")
		assert_bool((shell.get("_menu") as NavigationScreen).visible).is_false()
	shell.call("boot", PackedStringArray())
	assert_str(shell.get("state")).is_equal("title")

func test_title_routed_pad_accept_starts_chapter_and_keyboard_tab_wraps() -> void:
	var shell := _shell()
	var router: InputRouter = shell.get("_router")
	_press(router, &"ui_down")
	var accept := InputEventJoypadButton.new()
	accept.button_index = JOY_BUTTON_A
	accept.pressed = true
	router.call("_input", accept)
	var run: RunCoordinator = shell.get("_run")
	assert_bool(run.simulation.tuning.chapter_needs_enabled).is_true()
	assert_int(run.simulation.clock.minute_of_day).is_equal(780)
	assert_int(run.simulation.inventory.count(&"pemmican")).is_equal(8)

func test_terminal_timer_pause_skip_and_same_profile_retry_then_title() -> void:
	var shell := _shell()
	shell.call("start_run", {&"profile": &"three_night", &"seed": 7})
	var run: RunCoordinator = shell.get("_run")
	run.simulation.call("_end", &"dehydration")
	run.advance_end_shot(0.0)
	assert_str(shell.get("state")).is_equal("end_shot")
	assert_bool(run.hud.visible).is_false()
	assert_bool(run.camera.is_processing()).is_false()
	assert_bool(run.skip_end_shot()).is_false()
	run.advance_end_shot(0.5)
	_press(run.input_router, &"ui_accept")
	assert_str(run.end_phase).is_equal("end_shot")
	_press(run.input_router, &"pause_menu")
	assert_bool(run.input_router.is_paused()).is_true()
	run.advance_end_shot(20.0)
	assert_float(run.end_shot_elapsed).is_equal(0.5)
	assert_bool(run.skip_end_shot()).is_false()
	_press(run.input_router, &"pause_menu")
	assert_bool(run.input_router.is_paused()).is_false()
	run.advance_end_shot(0.5)
	_press(run.input_router, &"interact")
	assert_str(shell.get("state")).is_equal("results")
	var heading: Label = run.navigation.get("_heading")
	assert_str(heading.text).is_equal(tr(&"HUD_DEHYDRATION"))
	var old_id := run.get_instance_id()
	_press(run.input_router, &"ui_accept")
	await get_tree().process_frame
	assert_bool(is_instance_id_valid(old_id)).is_false()
	run = shell.get("_run")
	assert_bool(run.simulation.tuning.chapter_needs_enabled).is_true()
	assert_str(run.simulation.terminal).is_empty()
	run.simulation.call("_end", &"dawn_survived")
	run.advance_end_shot(8.0)
	assert_str(shell.get("state")).is_equal("results")
	heading = run.navigation.get("_heading")
	assert_str(heading.text).is_equal(tr(&"HUD_CHAPTER_DAWN"))
	_press(run.input_router, &"ui_down")
	_press(run.input_router, &"ui_accept")
	await get_tree().process_frame
	assert_str(shell.get("state")).is_equal("title")
	assert_object(shell.get("_run")).is_null()

func test_pause_return_to_title_cancels_work_and_frees_old_subtree() -> void:
	var shell := _shell()
	shell.call("start_run", {})
	var run: RunCoordinator = shell.get("_run")
	assert_bool(run.simulation.start_action(&"gather_sticks", null, run.world.interactables[0].gather_node)).is_true()
	var simulation := run.simulation
	var old_id := run.get_instance_id()
	_press(run.input_router, &"pause_menu")
	assert_str(shell.get("state")).is_equal("paused")
	_press(run.input_router, &"ui_down")
	_press(run.input_router, &"ui_accept")
	await get_tree().process_frame
	assert_bool(is_instance_id_valid(old_id)).is_false()
	assert_str(simulation.actions.action).is_empty()
	assert_int(shell.get_child_count()).is_equal(2)
	assert_str(shell.get("state")).is_equal("title")

func test_quit_confirmation_requires_second_intent_and_cancel_restores_focus() -> void:
	var shell := _shell()
	var menu: NavigationScreen = shell.get("_menu")
	shell.disconnect("quit_requested", Callable(shell, "_quit_application"))
	var quits: Array[bool] = []
	shell.connect("quit_requested", func() -> void: quits.append(true))
	var router: InputRouter = shell.get("_router")
	_press(router, &"ui_up")
	_press(router, &"ui_accept")
	assert_bool(menu.confirmation).is_true()
	assert_int(quits.size()).is_zero()
	_press(router, &"ui_accept")
	assert_bool(menu.confirmation).is_false()
	assert_int(quits.size()).is_zero()
	_press(router, &"ui_accept")
	_press(router, &"ui_down")
	_press(router, &"ui_accept")
	assert_int(quits.size()).is_equal(1)

func test_cold_results_copy_and_held_confirm_requires_release_after_skip_gate() -> void:
	var shell := _shell()
	shell.call("start_run", {})
	var run: RunCoordinator = shell.get("_run")
	run.simulation.clock.minute_of_day = 720
	run.simulation.call("_end", &"hypothermia")
	Input.action_press(&"ui_accept")
	run.advance_end_shot(1.0)
	_press(run.input_router, &"ui_accept")
	assert_str(run.end_phase).is_equal("end_shot")
	Input.action_release(&"ui_accept")
	var release := InputEventAction.new()
	release.action = &"ui_accept"
	release.pressed = false
	run.input_router.call("_input", release)
	_press(run.input_router, &"ui_accept")
	assert_str(run.end_phase).is_equal("results")
	var heading: Label = run.navigation.get("_heading")
	assert_str(heading.text).is_equal(tr(&"HUD_DEATH"))
	var detail: Label = run.navigation.get("_detail")
	assert_str(detail.text).is_equal(tr(&"MENU_BEFORE_NIGHT"))

func test_tab_reverse_focus_and_run_quit_confirmation_leave_simulation_paused() -> void:
	var shell := _shell()
	var router: InputRouter = shell.get("_router")
	var menu: NavigationScreen = shell.get("_menu")
	var tab := InputEventKey.new()
	tab.physical_keycode = KEY_TAB
	tab.keycode = KEY_TAB
	tab.pressed = true
	router.call("_input", tab)
	var buttons: Array = menu.get("_buttons")
	assert_bool((buttons[2] as Button).has_focus()).is_true()
	tab.shift_pressed = true
	router.call("_input", tab)
	assert_bool((buttons[1] as Button).has_focus()).is_true()
	shell.call("start_run", {})
	shell.disconnect("quit_requested", Callable(shell, "_quit_application"))
	var quits: Array[bool] = []
	shell.connect("quit_requested", func() -> void: quits.append(true))
	var run: RunCoordinator = shell.get("_run")
	_press(run.input_router, &"pause_menu")
	_press(run.input_router, &"ui_up")
	_press(run.input_router, &"ui_accept")
	assert_bool(run.navigation.confirmation).is_true()
	_press(run.input_router, &"ui_cancel")
	assert_bool(run.navigation.confirmation).is_false()
	assert_bool(run.input_router.is_paused()).is_true()
	_press(run.input_router, &"ui_accept")
	_press(run.input_router, &"ui_down")
	_press(run.input_router, &"ui_accept")
	assert_int(quits.size()).is_equal(1)
	assert_bool(run.input_router.is_paused()).is_true()

func test_stop_invalidates_pending_restart_and_is_idempotent() -> void:
	var shell := _shell()
	shell.call("start_run", {})
	var run: RunCoordinator = shell.get("_run")
	var old_id := run.get_instance_id()
	run.restart_requested.emit()
	shell.call("return_to_title")
	shell.call("stop_run", &"already_stopped")
	await get_tree().process_frame
	assert_bool(is_instance_id_valid(old_id)).is_false()
	assert_object(shell.get("_run")).is_null()
	assert_str(shell.get("state")).is_equal("title")
