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
	shell.set("save_store", SaveStore.new("user://test-checkpoints/visual_" + str(Time.get_ticks_usec())))
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var run := shell.get("_run") as RunCoordinator
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

func test_crouch_respects_imported_skeleton_basis_and_leaves_physics_root_alone() -> void:
	var shell: Node = auto_free(preload("res://src/run/app_shell.tscn").instantiate())
	shell.set("save_store", SaveStore.new("user://test-checkpoints/visual_" + str(Time.get_ticks_usec())))
	shell.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shell)
	shell.call("start_run", {&"profile": &"first_night", &"seed": 20261119})
	var run := shell.get("_run") as RunCoordinator
	var visual: SurvivorVisual = run.get("_survivor_visual")
	var skeleton: Skeleton3D = visual.get("_skeleton")
	var pose: SurvivorPose = skeleton.get_child(skeleton.get_child_count() - 1)
	var hips := skeleton.find_bone(&"Hips")
	var before := skeleton.to_global(skeleton.get_bone_global_pose(hips).origin)
	var root_position := run.survivor.global_position
	visual.crouch = 1.0
	pose.call("_process_modification")
	var after := skeleton.to_global(skeleton.get_bone_global_pose(hips).origin)
	assert_float(after.y).is_less(before.y - 0.3)
	assert_float(after.x).is_equal_approx(before.x, 0.001)
	assert_float(after.z).is_equal_approx(before.z, 0.001)
	assert_vector(run.survivor.global_position).is_equal(root_position)
