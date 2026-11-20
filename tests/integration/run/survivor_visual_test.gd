extends GdUnitTestSuite

func test_footprints_are_bounded_fade_and_ignore_invalid_contacts() -> void:
	var pool: FootprintPool = auto_free(FootprintPool.new())
	var data := SurvivorVisualTuning.new()
	data.footprint_count = 4
	data.footprint_life_s = 2.0
	pool.tuning = data
	add_child(pool)
	pool.stamp(Vector3.INF, 0)
	assert_bool(pool.get_child(0).visible).is_false()
	for i in 10:
		pool.stamp(Vector3(i, 0, i), 0)
	assert_int(pool.get_child_count()).is_equal(4)
	pool.advance(-1)
	assert_bool(pool.get_child(0).visible).is_true()
	pool.advance(2.1)
	for mark: Node3D in pool.get_children():
		assert_bool(mark.visible).is_false()

func test_visual_contacts_alternate_and_pause_blocks_them() -> void:
	var shell: Node = auto_free(preload("res://src/run/app_shell.tscn").instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	var run := shell.get_child(0) as RunCoordinator
	var visual: SurvivorVisual = run.get("_survivor_visual")
	var contacts: Array[int] = []
	visual.foot_contact.connect(func(_p: Vector3, foot: int) -> void: contacts.append(foot))
	visual.set("_speed", 1.0)
	visual.call("_contact", 0)
	visual.call("_contact", 0)
	run.survivor.position.x += 1.0
	visual.call("_contact", 1)
	run.survivor.frozen = true
	run.survivor.position.x += 1.0
	visual.call("_contact", 0)
	assert_int(contacts.size()).is_equal(2)
	assert_int(contacts[0]).is_zero()
	assert_int(contacts[1]).is_equal(1)
	assert_str(run.simulation.actions.action).is_empty()
	assert_int(run.simulation.rng.draw_count).is_zero()

func test_dedicated_crouch_clip_lowers_hips_without_moving_physics_root() -> void:
	var shell: Node = auto_free(preload("res://src/run/app_shell.tscn").instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	var run := shell.get_child(0) as RunCoordinator
	var visual: SurvivorVisual = run.get("_survivor_visual")
	var skeleton: Skeleton3D = visual.get("_skeleton")
	var model: Node3D = visual.get("_model")
	var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var tree: AnimationTree = visual.get("_tree")
	tree.active = false
	var hips := skeleton.find_bone(&"Hips")
	var before := skeleton.to_global(skeleton.get_bone_global_pose(hips).origin)
	var root_position := run.survivor.global_position
	player.play(&"clear_snow")
	player.seek(0.4, true)
	var after := skeleton.to_global(skeleton.get_bone_global_pose(hips).origin)
	assert_float(after.y).is_less(before.y - 0.3)
	assert_float(after.x).is_equal_approx(before.x, 0.001)
	assert_float(after.z).is_equal_approx(before.z, 0.001)
	assert_vector(run.survivor.global_position).is_equal(root_position)

func test_context_selection_has_no_work_fallback() -> void:
	var tuning := SliceTuning.new()
	for action: StringName in tuning.action_minutes:
		assert_bool(SurvivorClips.ACTIONS.has(action)).is_true()
		assert_str(SurvivorClips.select(action, 0, 37, false)).is_equal(String(action))
	for action: StringName in [&"eat", &"eat_snow"]:
		assert_str(SurvivorClips.select(action, 0, 37, false)).is_equal(String(action))
	assert_str(SurvivorClips.select(&"unknown", 0, 37, false)).is_empty()
	assert_str(SurvivorClips.select(&"", 0, 37, false)).is_equal("idle")
	assert_str(SurvivorClips.select(&"", 0, 35, false)).is_equal("cold_idle")
	assert_str(SurvivorClips.select(&"", 0, 35, true)).is_equal("warm_hands")
	assert_str(SurvivorClips.select(&"", 1, 35, true)).is_equal("walk")
	assert_str(SurvivorClips.select(&"strike", 0, 35, true)).is_equal("strike")
	assert_str(SurvivorClips.select(&"", 0, 35, true, true)).is_equal("sleep")

func test_work_faces_admitted_target_and_warming_faces_burning_fire() -> void:
	var shell: Node = auto_free(preload("res://src/run/app_shell.tscn").instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	var run := shell.get_child(0) as RunCoordinator
	var visual: SurvivorVisual = run.get("_survivor_visual")
	var bush := run.world.interactables[1]
	run.survivor.facing = Vector3.RIGHT
	assert_bool(run.simulation.start_action(&"gather_sticks", null, bush.gather_node)).is_true()
	var expected := SurvivorClips.facing(run.survivor.position, bush.position, Vector3.RIGHT)
	assert_vector(visual.action_facing()).is_equal(expected)
	visual.call("_process", 0.5)
	assert_float(Vector3(sin(visual.rotation.y), 0, cos(visual.rotation.y)).dot(expected)).is_greater(0.98)
	run.simulation.cancel_action()
	var fire := run.simulation.create_fire(Vector3(1, 0, 0))
	assert_object(visual.warming_fire()).is_null()
	fire.stage = &"Burning"
	assert_object(visual.warming_fire()).is_same(fire)
	assert_vector(visual.action_facing(fire)).is_equal(Vector3.RIGHT)
	assert_vector(SurvivorClips.facing(Vector3.ZERO, Vector3.ZERO, Vector3.FORWARD)).is_equal(Vector3.FORWARD)

func test_all_contexts_have_complete_clips_and_fatigue_variants() -> void:
	var shell: Node = auto_free(preload("res://src/run/app_shell.tscn").instantiate())
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	var visual: SurvivorVisual = shell.get_child(0).get("_survivor_visual")
	var model: Node3D = visual.get("_model")
	var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var contexts: Array[StringName] = SurvivorClips.STATES.duplicate()
	contexts.append_array(SurvivorClips.ACTIONS.values())
	contexts.append(&"trudge")
	for context: StringName in contexts:
		for suffix: String in ["", "_tired"]:
			var clip := player.get_animation(StringName(String(context) + suffix))
			assert_object(clip).is_not_null()
			assert_float(clip.length).is_greater(0.0)
			assert_int(clip.get_track_count()).is_greater_equal(24)
