extends GdUnitTestSuite

class Rolls extends RunRng:
	var values: Array[float] = [0.0]
	func draw_unit() -> float:
		draw_count += 1
		return values.pop_front()

func _chapter() -> RunSimulation:
	var tuning := preload("res://assets/data/three_day_survival.tres").duplicate() as SliceTuning
	tuning.weather_enabled = false
	var run := RunSimulation.new(39, tuning)
	run.rng = Rolls.new()
	return run

func _contact(run: RunSimulation) -> Vector3:
	var p := run.lake.cell_center(Vector2i(2, 45))
	run.record_travel(p, p + Vector3.FORWARD * 0.71, false)
	return p

func test_immersion_cancels_non_cancellable_critical_work_before_completion() -> void:
	var run := _chapter()
	var fire := run.create_fire(Vector3.ZERO)
	fire.stage = &"Burning"
	fire.fuel = 80
	run.inventory.add(&"log", 1)
	run.inventory.tools.clear()
	run.body.core_temp_c = 31.5
	run.body.refresh_stage()
	assert_bool(run.start_action(&"add_fuel", fire)).is_true()
	run.actions.cancellable = false
	run.actions.elapsed_s = run.actions.duration_s - 0.001
	run.cancel_action(false)
	assert_str(run.actions.action).is_equal("add_fuel")
	var outcomes: Array[StringName] = []
	var falls: Array[ImmersionEvent] = []
	run.action_resolved.connect(func(action: StringName, _success: bool, _cause: StringName) -> void: outcomes.append(action))
	run.fell_in_water.connect(func(event: ImmersionEvent) -> void: falls.append(event))
	_contact(run)
	run.update(0.01)
	assert_bool(run.in_water).is_true()
	assert_str(run.actions.action).is_empty()
	assert_array(outcomes).is_empty()
	assert_float(fire.fuel).is_equal(80.0)
	assert_int(run.inventory.count(&"log")).is_equal(1)
	assert_float(run.inventory.wetness(&"log")).is_equal(1.0)
	assert_float(run.body.wetness).is_equal(1.0)
	assert_int(run.rng.draw_count).is_equal(1)
	assert_int(falls.size()).is_equal(1)
	assert_str(run.lake.surface_at(falls[0].position)[&"kind"]).is_equal("water")
	assert_bool(run.start_action(&"add_fuel", fire)).is_false()
	assert_bool(run.request_sleep()).is_false()
	run.body.wetness = 0.5
	run.body.apply_immersion(falls[0].sequence)
	assert_float(run.body.wetness).is_equal(0.5)

func test_kept_chop_progress_resumes_without_interrupted_result_or_roll() -> void:
	var run := _chapter()
	var node := GatherNode.new(&"deadfall", 4)
	assert_bool(run.start_action(&"chop_log", null, node)).is_true()
	run.actions.elapsed_s = run.actions.duration_s * 0.5
	run.inventory.tools.clear()
	_contact(run)
	run.update(0.01)
	assert_float(node.action_progress[&"chop_log"]).is_equal_approx(0.5, 0.01)
	assert_int(node.remaining).is_equal(4)
	assert_int(run.inventory.count(&"log")).is_equal(0)
	assert_int(run.rng.draw_count).is_equal(1)
	run.leave_water()
	run.inventory.tools.append(&"hatchet")
	assert_bool(run.start_action(&"chop_log", null, node)).is_true()
	assert_float(run.actions.progress()).is_equal_approx(0.5, 0.01)

func test_same_checkpoint_death_beats_immersion_and_all_world_rolls() -> void:
	var run := _chapter()
	run.body.core_temp_c = 30.001
	var falls: Array[ImmersionEvent] = []
	run.fell_in_water.connect(func(event: ImmersionEvent) -> void: falls.append(event))
	_contact(run)
	run.update(run.clock.seconds_per_minute())
	assert_str(run.terminal).is_equal("hypothermia")
	assert_array(falls).is_empty()
	assert_bool(run.in_water).is_false()
	assert_int(run.lake.broken_cells.size()).is_equal(0)
	assert_int(run.rng.draw_count).is_equal(0)

func test_in_water_struggles_then_exits_and_ignores_duplicate_event() -> void:
	var run := _chapter()
	run.inventory.tools.clear()
	var controller: SurvivorController = auto_free(SurvivorController.new())
	controller.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(controller)
	controller.configure(run, null, null)
	var events: Array[ImmersionEvent] = []
	run.fell_in_water.connect(func(event: ImmersionEvent) -> void: events.append(event))
	_contact(run)
	run.update(0.01)
	assert_str(controller.state).is_equal("In-water")
	var initial := controller.position
	controller.step_in_water(3.0)
	assert_vector(Vector2(controller.position.x, controller.position.z)).is_equal(Vector2(initial.x, initial.z))
	controller.step_in_water(0.9)
	assert_bool(run.in_water).is_true()
	controller.step_in_water(0.6)
	assert_float(Vector2(controller.position.x - initial.x, controller.position.z - initial.z).length()).is_equal_approx(0.6, 0.0001)
	controller.step_in_water(10.0)
	assert_str(controller.state).is_equal("Free")
	assert_bool(run.in_water).is_false()
	assert_float(controller.position.y).is_equal(0.0)
	assert_bool(run.lake.can_traverse(controller.position, events[0].position)).is_false()
	run.fell_in_water.emit(events[0])
	assert_str(controller.state).is_equal("Free")
	var draws := run.rng.draw_count
	run.record_travel(events[0].position - Vector3.FORWARD * 0.71, events[0].position, false)
	run.update(0.01)
	assert_int(run.rng.draw_count).is_equal(draws)

func test_travel_cadence_safe_ice_no_contacts_and_first_night_are_draw_free() -> void:
	var run := _chapter()
	var safe := Vector3(60, 0, 0)
	run.update(0.01)
	run.record_travel(safe, safe + Vector3.FORWARD * 0.69, true)
	run.update(0.01)
	assert_int(run.rng.draw_count).is_equal(0)
	run.record_travel(safe + Vector3.FORWARD * 0.69, safe + Vector3.FORWARD * 1.4, true)
	run.update(0.01)
	assert_int(run.rng.draw_count).is_equal(0)
	var legacy := RunSimulation.new()
	assert_object(legacy.lake).is_null()
	legacy.record_travel(Vector3(26, 0, 0), Vector3(27, 0, 0), true)
	legacy.update(0.01)
	assert_int(legacy.rng.draw_count).is_equal(0)
	assert_bool(legacy.in_water).is_false()
	assert_vector(legacy.debug_thin_ice_spawn()).is_equal(Vector3.ZERO)
	var node := GatherNode.new(&"deadfall", 4)
	assert_bool(legacy.start_action(&"chop_log", null, node)).is_true()
	legacy.actions.elapsed_s = legacy.actions.duration_s * 0.5
	legacy.cancel_action()
	assert_dict(node.action_progress).is_empty()

func test_debug_recording_hook_and_ice_localizations() -> void:
	var scene := preload("res://src/run/run.tscn")
	var chapter: RunCoordinator = auto_free(scene.instantiate())
	chapter.tuning = preload("res://assets/data/three_day_survival.tres")
	chapter.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(chapter)
	var spawn := chapter.simulation.debug_thin_ice_spawn()
	assert_str(chapter.world.surface_at(spawn)[&"kind"]).is_equal("ice")
	assert_float(chapter.world.surface_at(spawn)[&"ice_thickness_cm"]).is_less(15.0)
	chapter.simulation.inventory.tools.clear()
	chapter.simulation.record_travel(spawn, spawn + Vector3.FORWARD * 0.71, false)
	chapter.simulation.update(0.01)
	assert_str(chapter.survivor.state).is_equal("In-water")
	assert_int(chapter.simulation.lake.broken_cells.size()).is_equal(1)
	var english: Translation = load("res://assets/localization/ice.en.translation")
	var chinese: Translation = load("res://assets/localization/ice.zh.translation")
	assert_str(english.get_message(&"HUD_ICE_BROKE")).is_equal("The ice gave way!")
	assert_str(chinese.get_message(&"HUD_ICE_BROKE")).is_equal("冰裂了！")
