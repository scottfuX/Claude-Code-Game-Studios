extends GdUnitTestSuite


func test_input_contexts_filter_gameplay_but_allow_closing_ui() -> void:
	var router: InputRouter = auto_free(InputRouter.new())
	var received: Array[StringName] = []
	router.action_pressed.connect(func(action: StringName) -> void: received.append(action))
	add_child(router)
	var event := InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	router.call("_input", event)
	assert_int(received.size()).is_equal(1)
	router.set_context(InputRouter.Context.UI)
	router.call("_input", event)
	assert_int(received.size()).is_equal(1)
	assert_vector(router.sample_actions()[&"move"]).is_equal(Vector2.ZERO)
	event.action = &"backpack"
	router.call("_input", event)
	assert_int(received.size()).is_equal(2)
	router.set_context(InputRouter.Context.LOCKED)
	router.call("_input", event)
	assert_int(received.size()).is_equal(2)


func test_input_ignores_unknown_and_keyboard_echo_events() -> void:
	var router: InputRouter = auto_free(InputRouter.new())
	var received: Array[StringName] = []
	router.action_pressed.connect(func(action: StringName) -> void: received.append(action))
	add_child(router)
	var unknown := InputEventAction.new()
	unknown.action = &"unknown_action"
	unknown.pressed = true
	router.call("_input", unknown)
	var repeat := InputEventKey.new()
	repeat.physical_keycode = KEY_E
	repeat.pressed = true
	repeat.echo = true
	router.call("_input", repeat)
	assert_int(received.size()).is_zero()


func test_pause_tokens_preserve_backpack_context_and_other_pause_sources() -> void:
	var router: InputRouter = auto_free(InputRouter.new())
	router.request_ui_context(&"backpack", true)
	var menu := router.request_pause(&"menu")
	var other := router.request_pause(&"other")
	router.release_pause(menu)
	assert_bool(router.is_paused()).is_true()
	router.release_pause(other)
	assert_bool(router.is_paused()).is_false()
	assert_int(router.context).is_equal(InputRouter.Context.UI)
	router.release_pause(-1)
	router.request_ui_context(&"backpack", false)
	assert_int(router.context).is_equal(InputRouter.Context.GAMEPLAY)


func test_context_closure_requires_held_movement_release_before_rearming() -> void:
	var router: InputRouter = auto_free(InputRouter.new())
	Input.action_press(&"move_forward")
	router.request_ui_context(&"backpack", true)
	router.request_ui_context(&"backpack", false)
	assert_vector(router.sample_actions()[&"move"]).is_equal(Vector2.ZERO)
	Input.action_release(&"move_forward")
	var release := InputEventAction.new()
	release.action = &"move_forward"
	release.pressed = false
	router.call("_input", release)
	Input.action_press(&"move_forward")
	assert_vector(router.sample_actions()[&"move"]).is_equal(Vector2.UP)
	Input.action_release(&"move_forward")


func test_debug_commands_share_context_gates_and_reject_unknown_or_invalid_input() -> void:
	var router: InputRouter = auto_free(InputRouter.new())
	var received: Array[StringName] = []
	router.action_pressed.connect(func(action: StringName) -> void: received.append(action))
	router.drive_debug(Vector2(3, 4), &"interact")
	if OS.is_debug_build():
		var movement: Vector2 = router.sample_actions()[&"move"]
		assert_float(movement.length()).is_equal_approx(1.0, 0.0001)
		assert_int(received.size()).is_equal(1)
	router.drive_debug(Vector2(NAN, INF), &"unknown_action")
	assert_vector(router.sample_actions()[&"move"]).is_equal(Vector2.ZERO)
	var previous := received.size()
	router.request_ui_context(&"backpack", true)
	router.drive_debug(Vector2.ONE, &"interact")
	assert_int(received.size()).is_equal(previous)
	assert_vector(router.sample_actions()[&"move"]).is_equal(Vector2.ZERO)
	router.set_context(InputRouter.Context.LOCKED)
	router.drive_debug(Vector2.ONE, &"secondary")
	assert_int(received.size()).is_equal(previous)
