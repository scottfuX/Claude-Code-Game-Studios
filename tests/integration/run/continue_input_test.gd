extends GdUnitTestSuite

var _store: SaveStore

func before_test() -> void:
	_store = SaveStore.new("user://test-checkpoints/continue_input_" + str(Time.get_ticks_usec()))

func after_test() -> void:
	_store.delete_checkpoint()
	DirAccess.remove_absolute(_store.directory)

func _continue() -> RunCoordinator:
	var shell: Node = auto_free(preload("res://src/run/app_shell.tscn").instantiate())
	shell.set("save_store", _store)
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {})
	assert_bool(shell.call("return_to_title")).is_true()
	shell.call("_on_title_selected", &"continue")
	return shell.get("_run") as RunCoordinator

func test_continue_loading_completion_restores_gameplay_movement() -> void:
	var run := _continue()
	assert_int(run.input_router.context).is_equal(InputRouter.Context.LOCKED)
	run.advance_loading(1.0)
	assert_int(run.input_router.context).is_equal(InputRouter.Context.GAMEPLAY)
	run.input_router.drive_debug(Vector2.RIGHT)
	assert_vector(run.input_router.sample_actions()[&"move"]).is_equal(Vector2.RIGHT)

func test_continue_loading_completion_preserves_other_pause_owner() -> void:
	var run := _continue()
	var token := run.input_router.request_pause(&"disconnect")
	run.advance_loading(1.0)
	assert_bool(run.input_router.is_paused()).is_true()
	assert_int(run.input_router.context).is_equal(InputRouter.Context.UI)
	assert_bool(run.navigation.visible).is_false()
	run.input_router.release_pause(token)
	assert_int(run.input_router.context).is_equal(InputRouter.Context.GAMEPLAY)
