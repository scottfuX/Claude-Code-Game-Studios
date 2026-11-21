extends GdUnitTestSuite

var _store: SaveStore

func before_test() -> void:
	_store = SaveStore.new("user://test-checkpoints/router_resume_" + str(Time.get_ticks_usec()))

func after_test() -> void:
	Input.action_release(&"ui_accept")
	_store.delete_checkpoint()
	DirAccess.remove_absolute(_store.directory)

func _shell() -> Node:
	var shell: Node = auto_free(preload("res://src/run/app_shell.tscn").instantiate())
	shell.set("save_store", _store)
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	return shell

func _accept(router: InputRouter) -> void:
	var event := InputEventAction.new()
	event.action = &"ui_accept"
	event.pressed = true
	router.call("_input", event)

func test_first_confirm_after_mouse_save_return_to_title_is_not_stale_blocked() -> void:
	var shell := _shell()
	var router: InputRouter = shell.get("_router")
	Input.action_press(&"ui_accept")
	_accept(router)
	assert_bool(router.is_processing_input()).is_false()
	Input.action_release(&"ui_accept")
	var run: RunCoordinator = shell.get("_run")
	run.call("_open_pause")
	var buttons: Array = run.navigation.get("_buttons")
	(buttons[1] as Button).pressed.emit()
	await get_tree().process_frame
	assert_str(shell.get("state")).is_equal("title")
	_accept(router)
	assert_str(shell.get("state")).is_equal("run")

func test_return_to_title_still_blocks_confirm_that_is_physically_held() -> void:
	var shell := _shell()
	shell.call("start_run", {})
	Input.action_press(&"ui_accept")
	assert_bool(shell.call("return_to_title")).is_true()
	var router: InputRouter = shell.get("_router")
	_accept(router)
	assert_str(shell.get("state")).is_equal("title")
	Input.action_release(&"ui_accept")
	var release := InputEventAction.new()
	release.action = &"ui_accept"
	router.call("_input", release)
	_accept(router)
	assert_str(shell.get("state")).is_equal("run")
