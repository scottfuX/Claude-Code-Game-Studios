extends GdUnitTestSuite

const CHAPTER: SliceTuning = preload("res://assets/data/three_day_survival.tres")
const CONTENT: ChapterContentTuning = preload("res://assets/data/chapter_content_defaults.tres")
const SCENE: PackedScene = preload("res://src/run/run.tscn")
const YES := true


func test_shelter_commits_two_separate_stages_and_protects_the_next_sample() -> void:
	var run := _run()
	var shelter := _shelter(run)
	run.position = Vector3(0, 0, -0.8)
	assert_bool(shelter.start(run, ShelterFeature.FRAME, _focused)).is_false()
	run.inventory.add(&"log", 2)
	assert_bool(shelter.start(run, ShelterFeature.FRAME, _focused)).is_true()
	_advance(run, 5)
	assert_int(shelter.stage).is_zero()
	_advance(run, 1)
	assert_int(shelter.stage).is_equal(1)
	assert_int(run.inventory.count(&"log")).is_equal(1)
	assert_int(run.inventory.count(&"tarp")).is_equal(1)
	assert_float(run.thermal.components(run.position)[&"shelter_bonus"]).is_zero()
	assert_bool(shelter.can_sleep(run.position)).is_false()
	assert_bool(shelter.start(run, ShelterFeature.COVER, _focused)).is_true()
	_advance(run, 4)
	assert_int(shelter.stage).is_equal(2)
	assert_int(run.inventory.count(&"tarp")).is_zero()
	assert_float(run.last_felt_temp_c).is_less(run.thermal.effective_temp_c(run.position))
	assert_float(run.thermal.components(run.position)[&"shelter_bonus"]).is_equal(2.0)
	assert_bool(shelter.can_sleep(run.position)).is_true()
	assert_bool(shelter.can_sleep(Vector3.ZERO)).is_false()
	run.step_minute()
	assert_float(run.last_felt_temp_c).is_equal(run.thermal.effective_temp_c(run.position))
	shelter.dispose()
	assert_float(run.thermal.components(run.position)[&"shelter_bonus"]).is_zero()
	assert_bool(shelter.can_sleep(run.position)).is_false()


func test_shelter_stale_interrupted_and_rejected_thermal_plan_do_not_spend() -> void:
	var run := _run()
	var shelter := _shelter(run)
	run.inventory.add(&"log", 1)
	assert_bool(shelter.start(run, ShelterFeature.FRAME, _focused)).is_true()
	run.inventory.consume(&"log", 1)
	run.inventory.add(&"log", 1)
	_advance(run, 6)
	assert_int(shelter.stage).is_zero()
	assert_int(run.inventory.count(&"log")).is_equal(1)
	assert_bool(shelter.start(run, ShelterFeature.FRAME, _focused)).is_true()
	_advance(run, 6)
	assert_bool(shelter.start(run, ShelterFeature.COVER, _focused)).is_true()
	run.movement = &"light"
	_advance(run, 4)
	run.movement = &"idle"
	assert_int(shelter.stage).is_equal(1)
	assert_int(run.inventory.count(&"tarp")).is_equal(1)
	run.thermal.apply_insulation(run.thermal.prepare_insulation(ShelterFeature.ID, 2, Transform3D.IDENTITY, WorldMap.SHELTER_BOUNDS, 0.1, 2.0))
	assert_bool(shelter.start(run, ShelterFeature.COVER, _focused)).is_true()
	_advance(run, 4)
	assert_int(shelter.stage).is_equal(1)
	assert_int(run.inventory.count(&"tarp")).is_equal(1)
	run.thermal.remove_insulation(ShelterFeature.ID, 2)
	assert_bool(shelter.start(run, ShelterFeature.COVER, _focused)).is_true()
	_advance(run, 3)
	shelter.dispose()
	_advance(run, 1)
	assert_int(run.inventory.count(&"tarp")).is_equal(1)


func test_rotated_volume_faces_and_reservation_edges_are_inclusive() -> void:
	var run := _run()
	var site := Transform3D(Basis(Vector3.UP, 0.6), Vector3(2, 0, -1))
	var bounds := WorldMap.SHELTER_BOUNDS
	var on_corner := site * Vector3(1.2, 1.8, -1.5)
	var outside := site * Vector3(1.201, 1.8, -1.5)
	var plan := run.thermal.prepare_insulation(&"test", 1, site, bounds, 0.1, 2.0)
	assert_bool(plan.is_empty()).is_false()
	run.thermal.apply_insulation(plan)
	plan[&"bonus"] = 99.0
	assert_float(run.thermal.components(on_corner)[&"shelter_bonus"]).is_equal(2.0)
	assert_float(run.thermal.components(outside)[&"shelter_bonus"]).is_zero()
	assert_bool(WorldMap.disc_intersects_plot(site * Vector3(2.2, 0, -0.7), 1.0, site, bounds)).is_true()
	assert_bool(WorldMap.disc_intersects_plot(site * Vector3(2.201, 0, -0.7), 1.0, site, bounds)).is_false()
	assert_bool(run.thermal.prepare_insulation(&"bad", 1, site.scaled(Vector3.ONE * 2.0), bounds, 0.1, 2.0).is_empty()).is_true()
	run.thermal.apply_insulation(run.thermal.prepare_insulation(&"overlap", 1, site, bounds, 0.05, 1.0))
	assert_float(run.thermal.wind_eff(on_corner)).is_equal_approx(CHAPTER.wind * 0.05, 0.0001)
	assert_float(run.thermal.components(on_corner)[&"shelter_bonus"]).is_equal(2.0)


func test_authored_chapter_sites_reserve_empty_plot_and_leave_outdoor_fire() -> void:
	var scene: RunCoordinator = auto_free(SCENE.instantiate())
	scene.tuning = CHAPTER
	scene.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(scene)
	var world := scene.world
	var snow := world.get_node("SnowSurface") as SnowSurface
	assert_float(snow.deformation.extent).is_equal(world.half_extent() * 2.0 + 4.0)
	snow.deformation.clear(Vector3(33, 0, -33), 1.0)
	assert_float(snow.deformation.compaction_at(Vector3(33, 0, -33))).is_equal(1.0)
	assert_bool(world.shelter_plot(Vector3.ZERO).is_empty()).is_false()
	assert_int(world.hare_approach(Vector3.ZERO).size()).is_equal(4)
	assert_bool(world.hare_approach(Vector3(0, 5, 0)).is_empty()).is_true()
	assert_bool(world.can_place_fire(WorldMap.SHELTER_APRON)).is_true()
	assert_bool(world.can_place_fire(WorldMap.SHELTER_TRANSFORM.origin)).is_false()
	assert_object(scene.simulation.create_fire(WorldMap.SHELTER_TRANSFORM.origin + Vector3.FORWARD)).is_null()
	var fire := scene.simulation.create_fire(WorldMap.SHELTER_APRON)
	assert_object(fire).is_not_null()
	var drop := world.hare_approach(Vector3.ZERO)
	assert_bool(WorldMap.within_chapter_reach(drop[-2], (drop[-1] - drop[-2]).normalized(), drop[-1])).is_true()
	assert_bool(WorldMap.within_chapter_reach(drop[-2], (drop[-2] - drop[-1]).normalized(), drop[-1])).is_false()


func test_snare_uses_one_wire_charge_and_claims_one_hare_after_crossing() -> void:
	var run := _run()
	run.inventory.equip_snare_wire(1)
	var food := _food(run)
	_set_time(run, 1, 1197)
	assert_bool(food.start_trail(run, HareFoodFeature.SET, _focused, _feet)).is_true()
	_advance(run, 3)
	assert_int(food.armed_minute).is_equal(1200)
	assert_bool(run.inventory.has_tool(&"snare_wire")).is_false()
	assert_bool(food.start_trail(run, HareFoodFeature.CHECK, _focused, _feet)).is_true()
	_advance(run, 2)
	assert_int(run.inventory.count(HareFoodFeature.RAW)).is_zero()
	_set_time(run, 1, 1318)
	assert_bool(food.start_trail(run, HareFoodFeature.CHECK, _focused, _feet)).is_true()
	_advance(run, 2)
	assert_int(run.inventory.count(HareFoodFeature.RAW)).is_equal(1)
	assert_bool(food.start_trail(run, HareFoodFeature.CHECK, _focused, _feet)).is_false()


func test_late_and_canceled_set_never_charges_wire() -> void:
	var run := _run()
	run.inventory.equip_snare_wire()
	var food := _food(run)
	_set_time(run, 2, 1198)
	assert_bool(food.can_set(1.0)).is_false()
	_set_time(run, 2, 1197)
	var wire := run.inventory.wire_revision()
	assert_bool(food.start_trail(run, HareFoodFeature.SET, _focused, _feet)).is_true()
	_set_time(run, 2, 1201)
	run.update(run.actions.duration_s)
	assert_int(run.inventory.wire_revision()).is_equal(wire)
	assert_int(food.state).is_equal(HareFoodFeature.Trap.UNSET)
	_set_time(run, 1, 780)
	assert_bool(food.start_trail(run, HareFoodFeature.SET, _focused, _feet)).is_true()
	run.cancel_action()
	_advance(run, 3)
	assert_int(run.inventory.wire_revision()).is_equal(wire)
	assert_int(food.state).is_equal(HareFoodFeature.Trap.UNSET)


func test_first_crossing_missed_catch_waits_and_overflow_is_atomic() -> void:
	var run := _run()
	run.inventory.equip_snare_wire()
	run.inventory.add(&"log", 10)
	var placement: Array[bool] = [false]
	var food := HareFoodFeature.new(run.inventory, run.clock, func(_point: Vector3) -> bool: return placement[0])
	_set_time(run, 1, 1198)
	assert_bool(food.start_trail(run, HareFoodFeature.SET, _focused, _feet)).is_true()
	_advance(run, 3)
	_set_time(run, 1, 1320)
	assert_bool(food.catch_ready()).is_false()
	_set_time(run, 2, 1320)
	assert_bool(food.catch_ready()).is_true()
	assert_bool(food.start_trail(run, HareFoodFeature.CHECK, _focused, _feet)).is_true()
	_advance(run, 2)
	assert_bool(food.catch_ready()).is_true()
	assert_int(food.bundle_count).is_zero()
	placement[0] = true
	assert_bool(food.start_trail(run, HareFoodFeature.CHECK, _focused, _feet)).is_true()
	_advance(run, 2)
	assert_int(food.state).is_equal(HareFoodFeature.Trap.SPENT)
	assert_int(food.bundle_count).is_equal(1)
	assert_int(run.inventory.count(HareFoodFeature.RAW)).is_zero()
	run.inventory.consume(&"log", 2)
	assert_bool(food.start_take(run, _focused)).is_true()
	_advance(run, 1)
	assert_int(food.bundle_count).is_zero()
	assert_int(run.inventory.count(HareFoodFeature.RAW)).is_equal(1)


func test_cook_checks_burning_focus_and_stack_then_eat_admits_nutrition_once() -> void:
	var run := _run()
	var food := _food(run)
	var fire := run.create_fire(Vector3.ZERO)
	run.inventory.add(HareFoodFeature.RAW, 1)
	assert_str(run.start_eating(HareFoodFeature.RAW)).is_equal("no_ration")
	assert_bool(food.start_cook(run, fire, _focused, _feet)).is_false()
	fire.stage = &"Burning"
	fire.fuel = 160.0
	var focus: Array[bool] = [true]
	assert_bool(food.start_cook(run, fire, func() -> bool: return focus[0], _feet)).is_true()
	_advance(run, 9)
	focus[0] = false
	_advance(run, 1)
	assert_int(run.inventory.count(HareFoodFeature.RAW)).is_equal(1)
	assert_bool(food.start_cook(run, fire, _focused, _feet)).is_true()
	run.inventory.consume(HareFoodFeature.RAW, 1)
	run.inventory.add(HareFoodFeature.RAW, 1)
	_advance(run, 10)
	assert_int(run.inventory.count(HareFoodFeature.COOKED)).is_zero()
	assert_bool(food.start_cook(run, fire, _focused, _feet)).is_true()
	_advance(run, 9)
	fire.fuel = 0.0
	_advance(run, 1)
	assert_int(run.inventory.count(HareFoodFeature.RAW)).is_equal(1)
	fire.stage = &"Burning"
	fire.fuel = 160.0
	assert_bool(food.start_cook(run, fire, _focused, _feet)).is_true()
	_advance(run, 10)
	assert_int(run.inventory.count(HareFoodFeature.RAW)).is_zero()
	assert_int(run.inventory.count(HareFoodFeature.COOKED)).is_equal(2)
	run.needs.stomach_kcal = 1151.0
	assert_str(run.start_eating(HareFoodFeature.COOKED)).is_equal("stomach_full")
	run.needs.stomach_kcal = 200.0
	assert_str(run.start_eating(HareFoodFeature.COOKED)).is_empty()
	_advance(run, 5)
	assert_int(run.inventory.count(HareFoodFeature.COOKED)).is_equal(1)
	assert_float(run.needs.stomach_kcal).is_equal_approx(550.0 - 5.0 * CHAPTER.calories_awake / 60.0, 0.0001)


func test_cooking_fits_after_raw_removal_and_terminal_beats_catch() -> void:
	var inventory := InventoryModel.new()
	inventory.add(&"log", 9)
	inventory.add(&"stick", 4)
	inventory.add(HareFoodFeature.RAW, 1)
	var plan := inventory.prepare_exchange(HareFoodFeature.RAW, inventory.stack_revision(HareFoodFeature.RAW), HareFoodFeature.COOKED, 2)
	assert_int(plan[&"fits"]).is_equal(2)
	assert_int(plan[&"overflow"]).is_zero()
	var run := _run()
	run.inventory.equip_snare_wire()
	var food := _food(run)
	assert_bool(food.start_trail(run, HareFoodFeature.SET, _focused, _feet)).is_true()
	_advance(run, 3)
	_set_time(run, 1, 1320)
	assert_bool(food.start_trail(run, HareFoodFeature.CHECK, _focused, _feet)).is_true()
	_advance(run, 1)
	run.body.core_temp_c = 29.9
	_advance(run, 1)
	assert_str(run.terminal).is_equal("hypothermia")
	assert_int(food.state).is_equal(HareFoodFeature.Trap.ARMED)
	assert_int(run.inventory.count(HareFoodFeature.RAW)).is_zero()


func test_chapter_resources_supply_work_durations_and_reject_invalid_values() -> void:
	var data: ChapterContentTuning = CONTENT.duplicate()
	assert_bool(data.is_valid()).is_true()
	data.frame_minutes = 2.0
	var run := _run()
	var shelter := ShelterFeature.new({&"site": Transform3D.IDENTITY, &"bounds": WorldMap.SHELTER_BOUNDS}, run.inventory, run.thermal, data)
	run.inventory.add(&"log", 1)
	assert_bool(shelter.start(run, ShelterFeature.FRAME, _focused)).is_true()
	_advance(run, 2)
	assert_int(shelter.stage).is_equal(1)
	data.cook_minutes = NAN
	assert_bool(data.is_valid()).is_false()


func _run() -> RunSimulation:
	return RunSimulation.new(20261119, CHAPTER)


func _shelter(run: RunSimulation) -> ShelterFeature:
	run.inventory.add(&"tarp", 1)
	return ShelterFeature.new({&"site": Transform3D.IDENTITY, &"bounds": WorldMap.SHELTER_BOUNDS}, run.inventory, run.thermal)


func _food(run: RunSimulation) -> HareFoodFeature:
	return HareFoodFeature.new(run.inventory, run.clock, func(_point: Vector3) -> bool: return true)


func _focused() -> bool:
	return YES


func _feet() -> Vector3:
	return Vector3.ZERO


func _set_time(run: RunSimulation, day: int, minutes: int) -> void:
	run.clock.day = day
	run.clock.minute_of_day = minutes


func _advance(run: RunSimulation, minutes: int) -> void:
	for i in minutes:
		run.update(run.clock.seconds_per_minute())
