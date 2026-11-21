extends SceneTree

func _initialize() -> void:
	if not OS.is_debug_build() or "--checkpoint-demo" not in OS.get_cmdline_user_args():
		quit(1)
		return
	_record.call_deferred()

func _frames(count: int) -> void:
	for frame: int in count:
		await process_frame

func _key(code: Key, frames: int = 1) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(frames)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(2)

func _record() -> void:
	var shell := preload("res://src/run/app_shell.tscn").instantiate()
	var store := SaveStore.new("user://checkpoint-demo")
	if not store.delete_checkpoint():
		quit(1)
		return
	shell.set("save_store", store)
	root.add_child(shell)
	await _frames(60)
	await _key(KEY_ENTER)
	await _frames(30)
	await _key(KEY_W, 90)
	await _frames(90)
	await _key(KEY_ESCAPE)
	await _frames(60)
	await _key(KEY_DOWN)
	await _key(KEY_ENTER)
	await _frames(90)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("HOME").path_join("shots/title-continue.png"))
	print("CAPTURED title-continue.png")
	await _key(KEY_ENTER)
	await _frames(90)
	await _key(KEY_D, 90)
	var run: RunCoordinator = shell.get("_run")
	run.simulation.body.core_temp_c = run.simulation.tuning.death_temp
	run.simulation.step_minute()
	await _frames(270)
	await _frames(90)
	await _key(KEY_DOWN)
	await _key(KEY_ENTER)
	await _frames(60)
	print("CHECKPOINT DEMO COMPLETE: title state=", shell.get("state"), " slot exists=", FileAccess.file_exists(store.slot_path()))
	shell.free()
	quit()
