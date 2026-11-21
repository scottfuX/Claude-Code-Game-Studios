extends GdUnitTestSuite

class FailingStore extends SaveStore:
	var fail_write: bool = false
	var fail_rename: bool = false
	var fail_delete: bool = false

	func _write_temp(path: String, contents: String) -> Error:
		return ERR_FILE_CANT_WRITE if fail_write else super._write_temp(path, contents)

	func _rename(from: String, to: String) -> Error:
		return ERR_FILE_CANT_WRITE if fail_rename else super._rename(from, to)

	func _remove(path: String) -> Error:
		return ERR_FILE_CANT_WRITE if fail_delete else super._remove(path)

var _store: FailingStore

func before_test() -> void:
	_store = FailingStore.new("user://test-checkpoints/persistence_" + str(Time.get_ticks_usec()))

func after_test() -> void:
	if DirAccess.dir_exists_absolute(_store.directory):
		for name: String in DirAccess.get_files_at(_store.directory):
			DirAccess.remove_absolute(_store.directory.path_join(name))
		DirAccess.remove_absolute(_store.directory)

func _shell() -> Node:
	var shell: Node = auto_free(preload("res://src/run/app_shell.tscn").instantiate())
	shell.set("save_store", _store)
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	return shell

func _fixture(profile: StringName = &"three_night") -> Dictionary:
	var shell := _shell()
	shell.call("start_run", {&"profile": profile, &"seed": -9223372036854775807})
	var run: RunCoordinator = shell.get("_run")
	run.simulation.inventory.add(&"stick", 9)
	run.simulation.inventory.consume(&"stick", 1)
	run.simulation.rng.draw_unit()
	run.world.interactables[0].gather_node.remaining -= 1
	var fire := run.simulation.create_fire(Vector3(1, 0, 1))
	fire.stage = &"Burning"
	fire.fuel = 77.5
	fire.publish_heat()
	run.add_fire_site(fire)
	run.survivor.position = Vector3(0.5, 0, 0.5)
	run.survivor.facing = Vector3.RIGHT
	run.simulation.position = run.survivor.position
	run.simulation.clock.debt = 0.02
	return RunCheckpoint.capture(run)

func _write_raw(contents: String) -> void:
	DirAccess.make_dir_recursive_absolute(_store.directory)
	var file := FileAccess.open(_store.slot_path(), FileAccess.WRITE)
	file.store_string(contents)
	file.close()

func test_chapter_continue_restores_cover_wire_and_one_spent_hare_site() -> void:
	var shell := _shell()
	assert_bool(shell.call("start_run", {&"profile": &"three_night"})).is_true()
	var run: RunCoordinator = shell.get("_run")
	var simulation := run.simulation
	var shelter: ShelterFeature = run.get("_shelter")
	var food: HareFoodFeature = run.get("_food")
	var focus := func() -> bool: return true
	var feet := func() -> Vector3: return Vector3(3, 0, 3)
	simulation.inventory.add(&"log", 1)
	assert_bool(shelter.start(simulation, ShelterFeature.FRAME, focus)).is_true()
	for minute in 6:
		simulation.update(simulation.clock.seconds_per_minute())
	assert_bool(shelter.start(simulation, ShelterFeature.COVER, focus)).is_true()
	for minute in 4:
		simulation.update(simulation.clock.seconds_per_minute())
	assert_bool(food.start_trail(simulation, HareFoodFeature.SET, focus, feet)).is_true()
	for minute in 3:
		simulation.update(simulation.clock.seconds_per_minute())
	simulation.clock.minute_of_day = 1320
	simulation.inventory.add(&"log", 30)
	assert_bool(food.start_trail(simulation, HareFoodFeature.CHECK, focus, feet)).is_true()
	for minute in 2:
		simulation.update(simulation.clock.seconds_per_minute())
	run.survivor.position = Vector3(25, 0, -23)
	var dto := RunCheckpoint.capture(run)
	assert_int(dto.owners.chapter.hare.bundle.count).is_equal(1)
	assert_bool(_store.save(dto)).is_true()
	var loaded := _store.probe()
	assert_bool(shell.call("start_run", {&"profile": &"three_night", &"restore": loaded})).is_true()
	var continued: RunCoordinator = shell.get("_run")
	var bed := WorldMap.SHELTER_TRANSFORM * Vector3(0, 0, -0.8)
	assert_float(continued.simulation.thermal.components(bed)[&"shelter_bonus"]).is_equal(2.0)
	assert_int(continued.simulation.inventory.count(&"tarp")).is_zero()
	assert_int(continued.simulation.inventory.export_state(true).wire_uses).is_equal(49)
	assert_dict(continued.export_chapter_state()).is_equal(dto.owners.chapter)
	var pile: WorldInteractable = continued.get("_pile_target")
	assert_vector(pile.position).is_equal(feet.call())
	var restored_food: HareFoodFeature = continued.get("_food")
	assert_bool(restored_food.start_trail(continued.simulation, HareFoodFeature.CHECK, focus, feet)).is_false()
	var legacy := dto.duplicate(true)
	legacy.owners.erase("chapter")
	assert_bool(RunCheckpoint.validate(legacy)).is_false()
	var duplicate_catch := dto.duplicate(true)
	duplicate_catch.owners.chapter.hare.bundle.count = 2
	assert_bool(RunCheckpoint.validate(duplicate_catch)).is_false()

func test_round_trip_each_owner_both_profiles_and_rng_continuation() -> void:
	for profile: StringName in [&"first_night", &"three_night"]:
		var dto := _fixture(profile)
		assert_bool(RunCheckpoint.validate(dto)).is_true()
		var owners: Dictionary = dto.owners.duplicate(true)
		var survivor := auto_free(SurvivorController.new()) as SurvivorController
		assert_bool(survivor.restore_state(owners.survivor)).is_true()
		assert_dict(survivor.export_state()).is_equal(owners.survivor)
		var nodes := GatherCatalog.create(RunCheckpoint.tuning_for(String(profile)))
		for id: StringName in nodes:
			assert_bool((nodes[id] as GatherNode).restore_state(owners.gathering[String(id)])).is_true()
			assert_dict((nodes[id] as GatherNode).export_state()).is_equal(owners.gathering[String(id)])
		owners.erase("survivor")
		owners.erase("gathering")
		owners.erase("chapter")
		var restored := RunSimulation.new(2, RunCheckpoint.tuning_for(String(profile)))
		assert_bool(restored.restore_state(owners)).is_true()
		assert_dict(restored.export_state()).is_equal(owners)
		var rng := RunRng.new()
		assert_bool(rng.restore_state(owners.rng)).is_true()
		assert_float(restored.rng.draw_unit()).is_equal(rng.draw_unit())
		assert_float(restored.thermal.heat_at(Vector3(1, 0, 1))).is_greater(0)

func test_atomic_overwrite_failures_preserve_previous_and_ignore_orphan_temp() -> void:
	var dto := _fixture()
	assert_bool(_store.save(dto)).is_true()
	var initial := FileAccess.get_file_as_string(_store.slot_path())
	dto.saved_at_unix += 1
	_store.fail_write = true
	assert_bool(_store.save(dto)).is_false()
	assert_str(FileAccess.get_file_as_string(_store.slot_path())).is_equal(initial)
	_store.fail_write = false
	_store.fail_rename = true
	assert_bool(_store.save(dto)).is_false()
	assert_str(FileAccess.get_file_as_string(_store.slot_path())).is_equal(initial)
	_store.fail_rename = false
	assert_bool(FileAccess.file_exists(_store.slot_path() + ".tmp")).is_true()
	assert_int(int(_store.probe().saved_at_unix)).is_equal(int(dto.saved_at_unix) - 1)
	assert_bool(_store.save(dto)).is_true()
	assert_int(int(_store.probe().saved_at_unix)).is_equal(int(dto.saved_at_unix))
	assert_bool(FileAccess.file_exists(_store.slot_path() + ".tmp")).is_false()

func test_corrupt_schema_unknown_fields_and_failed_quarantine_hide_continue() -> void:
	assert_dict(_store.probe()).is_empty()
	_write_raw("{broken")
	assert_dict(_store.probe()).is_empty()
	assert_bool(FileAccess.file_exists(_store.slot_path() + ".corrupt")).is_true()
	var dto := _fixture()
	dto.schema_version = 2
	_write_raw(JSON.stringify(dto))
	assert_dict(_store.probe()).is_empty()
	assert_bool(FileAccess.file_exists(_store.slot_path() + ".corrupt.1")).is_true()
	dto.schema_version = 1
	dto.owners["unknown"] = {}
	_write_raw(JSON.stringify(dto))
	_store.fail_rename = true
	var shell := _shell()
	var buttons: Array = (shell.get("_menu") as NavigationScreen).get("_buttons")
	assert_bool((buttons[0] as Button).visible).is_false()
	assert_bool(FileAccess.file_exists(_store.slot_path())).is_true()
	dto.owners.erase("unknown")
	assert_bool(_store.save(dto)).is_false()
	shell.call("_on_title_selected", &"new_run")
	assert_object(shell.get("_run")).is_null()
	assert_bool(FileAccess.file_exists(_store.slot_path())).is_true()

func test_validation_rejects_each_owner_missing_unknown_bad_types_and_bounds() -> void:
	var dto := _fixture()
	for owner: String in dto.owners:
		var bad := dto.duplicate(true)
		bad.owners.erase(owner)
		assert_bool(RunCheckpoint.validate(bad)).is_false()
		bad = dto.duplicate(true)
		bad.owners[owner] = null
		assert_bool(RunCheckpoint.validate(bad)).is_false()
	for owner: String in ["clock", "body", "needs", "inventory", "rng", "run", "survivor"]:
		for key: String in dto.owners[owner]:
			var bad := dto.duplicate(true)
			bad.owners[owner].erase(key)
			assert_bool(RunCheckpoint.validate(bad)).is_false()
			bad = dto.duplicate(true)
			bad.owners[owner][key] = {"wrong": true}
			assert_bool(RunCheckpoint.validate(bad)).is_false()
	var bad := dto.duplicate(true)
	bad.owners.clock.minute = 1440
	assert_bool(RunCheckpoint.validate(bad)).is_false()
	bad = dto.duplicate(true)
	bad.owners.body.stage = "Critical"
	assert_bool(RunCheckpoint.validate(bad)).is_false()
	bad = dto.duplicate(true)
	bad.owners.survivor.position[0] = 9999
	assert_bool(RunCheckpoint.validate(bad)).is_false()
	bad = dto.duplicate(true)
	bad.owners.fires.append(bad.owners.fires[0])
	assert_bool(RunCheckpoint.validate(bad)).is_false()
	bad = dto.duplicate(true)
	bad.owners.rng.state = "9223372036854775808"
	assert_bool(RunCheckpoint.validate(bad)).is_false()
	for key: String in dto.owners.fires[0]:
		bad = dto.duplicate(true)
		bad.owners.fires[0][key] = {"wrong": true}
		assert_bool(RunCheckpoint.validate(bad)).is_false()
	var node_id: String = dto.owners.gathering.keys()[0]
	for key: String in dto.owners.gathering[node_id]:
		bad = dto.duplicate(true)
		bad.owners.gathering[node_id][key] = {"wrong": true}
		assert_bool(RunCheckpoint.validate(bad)).is_false()

func test_sleep_hysteresis_and_grace_timers_round_trip_without_partial_restore() -> void:
	var tuning := RunCheckpoint.tuning_for("three_night")
	var simulation := RunSimulation.new(99, tuning)
	simulation.clock.rate_mode = &"sleep"
	simulation.body.core_temp_c = 35.6
	simulation.body.stage = &"Cold"
	simulation.needs.energy = 5.0
	simulation.needs.stage = &"Exhausted"
	simulation.needs.hydration = 0.0
	simulation.needs.hydration_stage = &"Dehydrated"
	simulation.needs.zero_hydration_minutes = 180
	simulation.needs.stomach_kcal = 0.0
	simulation.needs.empty_minutes = 1440
	simulation.needs.fullness_stage = &"Starving"
	simulation.needs.weight_kg = 69.0
	simulation.needs.is_asleep = true
	simulation.needs._collapsed = true
	var dto := simulation.export_state()
	var restored := RunSimulation.new(1, tuning)
	assert_bool(restored.restore_state(dto)).is_true()
	assert_dict(restored.export_state()).is_equal(dto)
	var bad := dto.duplicate(true)
	bad.needs.zero_hydration_minutes = tuning.dehydration_grace_minutes
	assert_bool(restored.restore_state(bad)).is_false()
	assert_dict(restored.export_state()).is_equal(dto)

func test_continue_visibility_discard_cancel_restore_gate_and_same_time_profile() -> void:
	var dto := _fixture()
	dto.owners.clock.day = 2
	dto.owners.clock.minute = 900
	assert_bool(_store.save(dto)).is_true()
	var shell := _shell()
	var menu: NavigationScreen = shell.get("_menu")
	var buttons: Array = menu.get("_buttons")
	assert_bool((buttons[0] as Button).visible).is_true()
	shell.call("_on_title_selected", &"new_run")
	assert_bool(menu.confirmation).is_true()
	menu.cancel_confirmation()
	assert_dict(_store.probe()).is_not_empty()
	shell.call("_on_title_selected", &"continue")
	var run: RunCoordinator = shell.get("_run")
	assert_int(run.simulation.clock.day).is_equal(2)
	assert_int(run.simulation.clock.minute_of_day).is_equal(900)
	assert_bool(run.simulation.tuning.chapter_needs_enabled).is_true()
	assert_bool(run.input_router.is_paused()).is_true()
	assert_int(run.input_router.context).is_equal(InputRouter.Context.LOCKED)
	assert_bool(run.navigation.visible).is_false()
	assert_bool(run.input_router.is_processing_input()).is_false()
	assert_int(run.seed_value).is_equal(dto.seed.to_int())
	assert_float(run.simulation.fires[0].fuel).is_equal(77.5)
	assert_int(run.simulation.inventory.count(&"stick")).is_equal(8)
	assert_int(run.world.interactables[0].gather_node.remaining).is_equal(11)
	run.call("_process", 0.5)
	assert_int(run.simulation.clock.minute_of_day).is_equal(900)
	var other := run.input_router.request_pause(&"disconnect")
	run.advance_loading(0.5)
	assert_bool(run.input_router.is_paused()).is_true()
	run.input_router.release_pause(other)
	assert_bool(run.input_router.is_paused()).is_false()
	assert_int(run.simulation.clock.minute_of_day).is_equal(900)
	assert_bool(run.survivor.export_state() == dto.owners.survivor).is_true()

func test_manual_save_cancels_action_without_draw_and_failure_stays_paused() -> void:
	var shell := _shell()
	shell.call("start_run", {&"profile": &"three_night"})
	var run: RunCoordinator = shell.get("_run")
	assert_bool(run.simulation.start_action(&"gather_sticks", null, run.world.interactables[0].gather_node)).is_true()
	var draws := run.simulation.rng.draw_count
	_store.fail_write = true
	assert_bool(shell.call("return_to_title")).is_false()
	assert_bool(run.input_router.is_paused()).is_true()
	assert_bool(run.navigation.visible).is_true()
	assert_str(run.simulation.actions.action).is_empty()
	assert_int(run.simulation.rng.draw_count).is_equal(draws)
	_store.fail_write = false
	assert_bool(shell.call("return_to_title")).is_true()
	assert_dict(_store.probe()).is_not_empty()

func test_chapter_switch_confirms_checkpoint_discard_and_quit_saves() -> void:
	var dto := _fixture()
	assert_bool(_store.save(dto)).is_true()
	var shell := _shell()
	shell.call("_on_title_selected", &"continue")
	var run: RunCoordinator = shell.get("_run")
	run.advance_loading(1.0)
	run.call("_open_pause")
	run.call("_on_navigation", &"switch")
	assert_bool(run.navigation.confirmation).is_true()
	assert_bool(FileAccess.file_exists(_store.slot_path())).is_true()
	run.call("_on_navigation", &"switch_confirmed")
	await get_tree().process_frame
	run = shell.get("_run")
	assert_bool(run.simulation.tuning.chapter_needs_enabled).is_false()
	assert_bool(FileAccess.file_exists(_store.slot_path())).is_false()
	shell.disconnect("quit_requested", Callable(shell, "_quit_application"))
	var quits: Array[bool] = []
	shell.connect("quit_requested", func() -> void: quits.append(true))
	run.call("_open_pause")
	shell.call("_request_quit")
	assert_int(quits.size()).is_equal(1)
	assert_str(_store.probe().profile).is_equal("first_night")

func test_sunrise_defers_during_action_and_terminal_beats_pending_save() -> void:
	var shell := _shell()
	shell.call("start_run", {&"profile": &"three_night"})
	var run: RunCoordinator = shell.get("_run")
	run.simulation.clock.day = 2
	run.simulation.clock.minute_of_day = ceili(run.simulation.clock.sunrise_hour() * 60.0) - 1
	assert_bool(run.simulation.start_action(&"gather_sticks", null, run.world.interactables[0].gather_node)).is_true()
	run.simulation.step_minute()
	run.flush_autosave()
	assert_bool(FileAccess.file_exists(_store.slot_path())).is_false()
	run.simulation.cancel_action()
	run.flush_autosave()
	assert_int(int(_store.probe().owners.clock.minute)).is_equal(run.simulation.clock.minute_of_day)
	run.simulation.clock.sunrise.emit()
	run.simulation.call("_end", &"hypothermia")
	run.advance_end_shot(0.0)
	run.flush_autosave()
	assert_bool(FileAccess.file_exists(_store.slot_path())).is_false()

func test_death_and_victory_delete_slot_and_deletion_error_blocks_navigation() -> void:
	var dto := _fixture()
	for cause: StringName in [&"hypothermia", &"dawn_survived"]:
		assert_bool(_store.save(dto)).is_true()
		var shell := _shell()
		shell.call("_on_title_selected", &"continue")
		var run: RunCoordinator = shell.get("_run")
		run.advance_loading(1.0)
		_store.fail_delete = true
		run.simulation.call("_end", cause)
		run.advance_end_shot(8.0)
		assert_bool(run.navigation.visible).is_true()
		assert_str(run.end_phase).is_empty()
		assert_bool(shell.call("return_to_title")).is_false()
		assert_bool(FileAccess.file_exists(_store.slot_path())).is_true()
		_store.fail_delete = false
		run.call("_on_navigation", &"cleanup_retry")
		run.advance_end_shot(8.0)
		assert_str(run.end_phase).is_equal("results")
		assert_bool(FileAccess.file_exists(_store.slot_path())).is_false()
