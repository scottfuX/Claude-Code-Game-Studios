extends GdUnitTestSuite

const SHELL: PackedScene = preload("res://src/run/app_shell.tscn")


func test_survivor_capsule_and_camera_read_custom_playfield_tuning() -> void:
	var tuning := PlayfieldTuning.new()
	tuning.capsule_radius = 0.4
	tuning.capsule_height = 2.0
	tuning.camera_turn_degrees = 30.0
	tuning.camera_distance = 7.0
	tuning.camera_zoom_step = 1.5
	tuning.camera_zoom_min = 5.0
	tuning.camera_zoom_max = 8.0
	var survivor: SurvivorController = auto_free(SurvivorController.new())
	survivor.tuning = tuning
	add_child(survivor)
	var collision := survivor.get_child(0) as CollisionShape3D
	assert_float((collision.shape as CapsuleShape3D).radius).is_equal_approx(0.4, 0.0001)
	assert_float((collision.shape as CapsuleShape3D).height).is_equal(2.0)
	assert_float(collision.position.y).is_equal(1.0)
	var camera: SurvivalCamera = auto_free(SurvivalCamera.new())
	camera.tuning = tuning
	add_child(camera)
	camera.turn(1)
	assert_float(camera.yaw).is_equal_approx(PI / 6.0, 0.0001)
	camera.zoom(1)
	assert_float(camera.distance).is_equal(8.0)
	camera.zoom(-100)
	assert_float(camera.distance).is_equal(5.0)


func test_shell_restart_replaces_all_mutable_run_state() -> void:
	var shell: Node = auto_free(SHELL.instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var old_run := shell.get("_run") as RunCoordinator
	old_run.simulation.inventory.add(&"log", 2)
	var fire := old_run.simulation.create_fire(Vector3(1, 0, 0))
	old_run.add_fire_site(fire)
	assert_bool(old_run.simulation.start_action(&"clear_snow", fire)).is_true()
	var old_id := old_run.get_instance_id()
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var fresh := shell.get("_run") as RunCoordinator
	assert_bool(is_instance_id_valid(old_id)).is_false()
	assert_int(shell.get_child_count()).is_equal(3)
	assert_int(fresh.simulation.inventory.count(&"log")).is_zero()
	assert_int(fresh.simulation.fires.size()).is_zero()
	assert_str(fresh.simulation.actions.action).is_empty()
	assert_int(fresh.simulation.clock.minute_of_day).is_equal(990)
	assert_int(fresh.input_router.context).is_equal(InputRouter.Context.GAMEPLAY)


func test_scene_routes_gathering_and_backpack_keeps_work_and_time_running() -> void:
	var shell: Node = auto_free(SHELL.instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var run := shell.get("_run") as RunCoordinator
	run.input_router.action_pressed.emit(&"interact")
	assert_str(run.simulation.actions.action).is_equal("gather_sticks")
	run.input_router.action_pressed.emit(&"backpack")
	assert_int(run.input_router.context).is_equal(InputRouter.Context.UI)
	var tick := run.simulation.clock.seconds_per_minute()
	run.call("_process", tick)
	assert_int(run.simulation.clock.minute_of_day).is_equal(991)
	assert_float(run.simulation.actions.elapsed_s).is_equal(tick)
	run.input_router.action_pressed.emit(&"pause_menu")
	assert_int(run.input_router.context).is_equal(InputRouter.Context.UI)
	run.call("_process", 10.0)
	assert_int(run.simulation.clock.minute_of_day).is_equal(991)
	assert_float(run.simulation.actions.elapsed_s).is_equal(tick)
	run.input_router.action_pressed.emit(&"pause_menu")
	assert_int(run.input_router.context).is_equal(InputRouter.Context.UI)
	run.call("_process", 4.0)
	assert_int(run.simulation.inventory.count(&"stick")).is_greater(0)
	assert_str(run.simulation.actions.action).is_empty()


func test_world_interaction_respects_facing_reach_and_finite_reserves() -> void:
	var world: WorldMap = auto_free(WorldMap.new())
	add_child(world)
	assert_object(world.nearest(Vector3.ZERO, Vector3.FORWARD)).is_not_null()
	assert_object(world.nearest(Vector3.ZERO, Vector3.BACK)).is_null()
	assert_object(world.nearest(Vector3(20, 0, 20), Vector3.FORWARD)).is_null()
	assert_bool(world.can_place_fire(Vector3.ZERO)).is_true()
	assert_bool(world.can_place_fire(Vector3(-7, 0, -5))).is_false()
	assert_bool(world.can_place_fire(Vector3(2.8, 0, -2))).is_false()
	for entry: WorldInteractable in world.interactables:
		entry.gather_node.remaining = 0
		entry.gather_node.bark_remaining = 0
	assert_object(world.nearest(Vector3.ZERO, Vector3.FORWARD)).is_null()
	assert_int(world.interactables.size()).is_equal(13)


func test_gather_verb_cache_reuses_storage_and_invalidates_on_reserves_and_tools() -> void:
	var entry: WorldInteractable = auto_free(WorldInteractable.new())
	var resolver := GatheringResolver.new()
	var inventory := InventoryModel.new()
	assert_array(entry.gather_verbs(resolver.can_gather, inventory)).is_empty()
	entry.gather_node = GatherNode.new(&"deadfall", 2, 0, 2)
	var verbs := entry.gather_verbs(resolver.can_gather, inventory)
	assert_int(verbs.size()).is_equal(2)
	assert_bool(is_same(verbs, entry.gather_verbs(resolver.can_gather, inventory))).is_true()
	inventory.tools.erase(&"hatchet")
	assert_array(entry.gather_verbs(resolver.can_gather, inventory)).contains_exactly([&"strip_bark"])
	entry.gather_node.bark_remaining = 0
	assert_array(entry.gather_verbs(resolver.can_gather, inventory)).is_empty()
	inventory.tools.append(&"hatchet")
	assert_array(entry.gather_verbs(resolver.can_gather, inventory)).contains_exactly([&"chop_log"])
	entry.gather_node.remaining = 0
	assert_array(entry.gather_verbs(resolver.can_gather, inventory)).is_empty()
	entry.gather_node = GatherNode.new(&"bush", 1)
	assert_array(entry.gather_verbs(resolver.can_gather, inventory)).contains_exactly([&"gather_sticks"])


func test_open_ground_creates_only_two_sites_and_rejects_busy_or_critical_work() -> void:
	var shell: Node = auto_free(SHELL.instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var run := shell.get("_run") as RunCoordinator
	run.survivor.facing = Vector3.BACK
	run.input_router.action_pressed.emit(&"secondary")
	assert_int(run.simulation.fires.size()).is_equal(1)
	assert_str(run.simulation.actions.action).is_equal("clear_snow")
	run.input_router.action_pressed.emit(&"secondary")
	assert_int(run.simulation.fires.size()).is_equal(1)
	run.input_router.action_pressed.emit(&"cancel_action")
	run.survivor.position = Vector3(15, 0, 0)
	run.input_router.action_pressed.emit(&"secondary")
	assert_int(run.simulation.fires.size()).is_equal(2)
	run.input_router.action_pressed.emit(&"cancel_action")
	run.survivor.position = Vector3(-15, 0, 0)
	run.input_router.action_pressed.emit(&"secondary")
	assert_int(run.simulation.fires.size()).is_equal(2)
	run.simulation.body.core_temp_c = 31.0
	run.simulation.body.refresh_stage()
	assert_bool(run.simulation.start_action(&"clear_snow", run.simulation.fires[1])).is_false()


func test_critical_survivor_cannot_spend_a_site_on_impossible_snow_clear() -> void:
	var shell: Node = auto_free(SHELL.instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var run := shell.get("_run") as RunCoordinator
	run.survivor.facing = Vector3.BACK
	run.simulation.body.stage = &"Critical"
	run.input_router.action_pressed.emit(&"secondary")
	assert_int(run.simulation.fires.size()).is_zero()
	assert_str(run.simulation.actions.action).is_empty()


func test_camera_projects_diagonal_input_to_unit_ground_vector() -> void:
	var camera: SurvivalCamera = auto_free(SurvivalCamera.new())
	assert_float(camera.move_direction(Vector2(-1, -1)).length()).is_equal_approx(1.0, 0.0001)
	assert_vector(camera.move_direction(Vector2.ZERO)).is_equal(Vector3.ZERO)
	camera.turn(2)
	assert_vector(camera.move_direction(Vector2.UP)).is_equal_approx(Vector3.LEFT, Vector3.ONE * 0.0001)


func test_fire_adapter_tracks_stage_and_exact_fi6_light_radius() -> void:
	var shell: Node = auto_free(SHELL.instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var run := shell.get("_run") as RunCoordinator
	var fire := run.simulation.create_fire(Vector3.ZERO)
	var entry := run.add_fire_site(fire)
	assert_str(entry.site_id).is_equal(fire.id)
	assert_bool(run.add_fire_site(fire) == entry).is_true()
	assert_int(entry.get_child_count()).is_equal(1)
	assert_object(run.add_fire_site(null)).is_null()
	var visual := entry.get_child(0) as FireVisual
	visual.call("_process", 0.0)
	var light := visual.get_child(1) as OmniLight3D
	var particles := visual.get_child(2) as CPUParticles3D
	assert_bool(light.visible).is_false()
	assert_bool(particles.emitting).is_false()
	fire.stage = &"Burning"
	fire.fuel = 100.0
	visual.call("_process", 0.0)
	assert_bool(light.visible).is_true()
	assert_bool(particles.emitting).is_true()
	assert_float(light.omni_range).is_equal_approx(fire.light_radius(), 0.0001)
	fire.stage = &"Embers"
	visual.call("_process", 0.0)
	assert_bool(particles.emitting).is_false()
	assert_float(light.omni_range).is_equal_approx(1.5, 0.0001)
	fire.stage = &"Out"
	visual.call("_process", 0.0)
	assert_bool(light.visible).is_false()


func test_world_registers_site_data_without_constructing_models_or_visuals() -> void:
	var world: WorldMap = auto_free(WorldMap.new())
	add_child(world)
	assert_object(world.add_site(&"", Vector3.ZERO, "Camp")).is_null()
	assert_object(world.add_site(&"bad", Vector3(INF, 0, 0), "Camp")).is_null()
	var entry := world.add_site(&"camp", Vector3.ONE, "Camp")
	assert_str(entry.site_id).is_equal("camp")
	assert_vector(entry.position).is_equal(Vector3.ONE)
	assert_int(entry.get_child_count()).is_zero()
	assert_int(world.interactables.size()).is_equal(14)


func test_fine_gather_meshes_do_not_cast_fire_shadow_rays_but_logs_do() -> void:
	var world: WorldMap = auto_free(WorldMap.new())
	add_child(world)
	for mesh: Node in world.interactables[0].get_children():
		assert_int((mesh as MeshInstance3D).cast_shadow).is_equal(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var log_mesh := world.interactables[5].get_child(0) as MeshInstance3D
	assert_int(log_mesh.cast_shadow).is_equal(GeometryInstance3D.SHADOW_CASTING_SETTING_ON)


func test_survival_hud_clears_prompts_and_replaces_cues_without_model_access() -> void:
	var hud: SurvivalHud = auto_free(SurvivalHud.new())
	add_child(hud)
	var state := RunSimulation.new().snapshot()
	state[&"real_delta_s"] = 0.0
	state[&"prompt"] = "Gather"
	hud.render_snapshot(state)
	var prompt: Label = hud.get("_prompt")
	assert_str(prompt.text).is_equal("Gather")
	state[&"prompt"] = ""
	hud.render_snapshot(state)
	assert_bool(prompt.visible).is_false()
	hud.show_cue("First")
	hud.show_cue("Newest")
	state[&"paused"] = true
	state[&"real_delta_s"] = 10.0
	hud.render_snapshot(state)
	var cue: Label = hud.get("_cue")
	assert_str(cue.text).is_equal("Newest")
	assert_bool(cue.visible).is_true()
	state[&"paused"] = false
	state[&"real_delta_s"] = 1.5
	hud.render_snapshot(state)
	assert_bool(cue.visible).is_false()
	state[&"terminal"] = &"dawn_survived"
	hud.render_snapshot(state)
	var menu: Label = hud.get("_menu_text")
	assert_str(menu.text).is_equal("You saw the dawn")
	assert_float(hud.model.band_opacity(&"end", true)).is_zero()


func test_f3_toggles_numeric_debug_surface_only_in_debug_builds() -> void:
	var shell: Node = auto_free(SHELL.instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var run := shell.get("_run") as RunCoordinator
	var debug: Label = run.hud.get("_debug")
	assert_bool(debug.visible).is_false()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F3
	key.pressed = true
	run.input_router.call("_input", key)
	run.call("_process", run.simulation.clock.seconds_per_minute())
	if OS.is_debug_build():
		assert_bool(debug.visible).is_true()
		assert_str(debug.text).contains("Core")
		assert_str(debug.text).contains("Felt")
		assert_str(debug.text).contains("Energy")
		assert_str(debug.text).contains("16:31")
		run.input_router.call("_input", key)
		run.call("_process", 0.0)
		assert_bool(debug.visible).is_false()
	else:
		assert_bool(debug.visible).is_false()


func test_demo_arrival_latches_while_turning_without_teleporting_or_seeding() -> void:
	var shell: Node = auto_free(SHELL.instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var run := shell.get("_run") as RunCoordinator
	var demo := FirstNightDemo.new(run)
	assert_int(run.simulation.fires.size()).is_zero()
	assert_int(run.simulation.inventory.count(&"log")).is_zero()
	run.survivor.position = Vector3(0, 0, 0.11)
	run.survivor.facing = Vector3.BACK
	assert_bool(demo.call("_walk", Vector3.ZERO, Vector3.FORWARD)).is_false()
	assert_vector(run.survivor.position).is_equal(Vector3(0, 0, 0.11))
	run.survivor.position = Vector3(0, 0, -0.2)
	run.survivor.facing = Vector3.FORWARD
	assert_bool(demo.call("_walk", Vector3.ZERO, Vector3.FORWARD)).is_true()
	assert_vector(run.input_router.sample_actions()[&"move"]).is_equal(Vector2.ZERO)


func test_lit_fire_without_an_available_verb_never_requests_tinder() -> void:
	var shell: Node = auto_free(SHELL.instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var run := shell.get("_run") as RunCoordinator
	var fire := run.simulation.create_fire(Vector3(0, 0, 1))
	run.add_fire_site(fire)
	fire.stage = &"Burning"
	fire.fuel = 300.0
	run.simulation.inventory.add(&"log", 1)
	run.survivor.facing = Vector3.BACK
	run.call("_update_target")
	assert_str(run.call("_prompt")).is_empty()
	fire.fuel = 200.0
	run.call("_update_target")
	assert_str(run.call("_prompt")).contains("Add fuel")
	run.simulation.inventory.consume(&"log", 1)
	run.call("_update_target")
	assert_str(run.call("_prompt")).is_empty()

func test_missing_material_prompt_and_help_reopen() -> void:
	var shell: Node = auto_free(SHELL.instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var run := shell.get("_run") as RunCoordinator
	var fire := run.simulation.create_fire(Vector3(0, 0, -1))
	fire.stage = &"Cleared"
	run.add_fire_site(fire)
	run.call("_update_target")
	assert_str(run.call("_prompt")).contains("4 more sticks")
	run.simulation.inventory.add(&"stick", 2)
	assert_str(run.call("_prompt")).contains("2 more sticks")
	run.simulation.inventory.add(&"grass", 3)
	assert_str(run.call("_prompt")).not_contains("grass")
	fire.stage = &"Smoldering"
	run.call("_update_target")
	assert_str(run.call("_prompt")).contains("Blow embers now")
	assert_bool(InputMap.action_has_event(&"help", InputMap.action_get_events(&"help")[0])).is_true()
	run.input_router.action_pressed.emit(&"help")
	assert_bool(run.hud.get("_help_open")).is_true()
