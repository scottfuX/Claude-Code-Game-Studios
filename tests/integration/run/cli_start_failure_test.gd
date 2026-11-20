extends GdUnitTestSuite

class QuarantineDeniedStore extends SaveStore:
	func _rename(_from: String, _to: String) -> Error:
		return ERR_FILE_CANT_WRITE

func test_direct_launch_failure_falls_back_to_title_with_error() -> void:
	for flag: String in ["--three-day", "--demo"]:
		var store := QuarantineDeniedStore.new("user://test-checkpoints/cli_failure_" + str(Time.get_ticks_usec()))
		var shell: Node = auto_free(preload("res://src/run/app_shell.tscn").instantiate())
		shell.set("save_store", store)
		shell.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(shell)
		var menu: NavigationScreen = shell.get("_menu")
		menu.hide()
		shell.set("state", &"boot")
		DirAccess.make_dir_recursive_absolute(store.directory)
		var file := FileAccess.open(store.slot_path(), FileAccess.WRITE)
		file.store_string("{broken")
		file.close()
		shell.call("boot", PackedStringArray([flag]))
		assert_object(shell.get("_run")).is_null()
		assert_str(shell.get("state")).is_equal("title")
		assert_bool(menu.visible).is_true()
		var status: Label = menu.get("_status")
		assert_str(status.text).is_equal(tr(&"MENU_CHECKPOINT_UNAVAILABLE"))
		var buttons: Array = menu.get("_buttons")
		assert_bool((buttons[0] as Button).visible).is_false()
		assert_bool(FileAccess.file_exists(store.slot_path())).is_true()
		DirAccess.remove_absolute(store.slot_path())
		DirAccess.remove_absolute(store.directory)
