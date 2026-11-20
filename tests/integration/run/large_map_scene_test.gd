extends GdUnitTestSuite

func test_chapter_scene_uses_run_layout_and_legacy_scene_is_unchanged() -> void:
	var scene := preload("res://src/run/run.tscn")
	var chapter: RunCoordinator = auto_free(scene.instantiate())
	chapter.tuning = preload("res://assets/data/three_day_survival.tres")
	chapter.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(chapter)
	assert_float(chapter.world.half_extent()).is_equal(120.0)
	var ground := chapter.world.get_child(0) as MeshInstance3D
	assert_vector((ground.mesh as PlaneMesh).size).is_equal(Vector2(240, 240))
	var ground_body := chapter.world.get_child(1) as StaticBody3D
	var ground_shape := (ground_body.get_child(0) as CollisionShape3D).shape as BoxShape3D
	assert_vector(ground_shape.size).is_equal(Vector3(240, 0.3, 240))
	assert_float(ground_body.position.y + ground_shape.size.y / 2).is_equal(0.0)
	var lake := chapter.world.get_child(6) as MeshInstance3D
	assert_vector((lake.mesh as PlaneMesh).size).is_equal(LargeMapLayout.LAKE.size)
	assert_int((lake.material_override as StandardMaterial3D).shading_mode).is_equal(BaseMaterial3D.SHADING_MODE_UNSHADED)
	assert_object(chapter.world.layout).is_same(chapter.simulation.map_layout)
	assert_int(chapter.world.interactables.size()).is_equal(chapter.simulation.map_layout.nodes.size())
	assert_bool(chapter.world.is_on_snow(Vector3(60, 0, 0))).is_false()
	assert_bool(chapter.world.is_on_snow(Vector3(0, 0, 50))).is_true()
	assert_bool(chapter.world.can_place_fire(Vector3(60, 0, 0))).is_false()
	for camp: Vector3 in LargeMapLayout.CAMPS:
		assert_bool(chapter.world.can_place_fire(camp)).is_true()
	for i in chapter.world.interactables.size():
		assert_str(chapter.world.interactables[i].gather_node.node_id).is_equal(String(chapter.simulation.map_layout.nodes[i][&"id"]))
	var legacy: RunCoordinator = auto_free(scene.instantiate())
	legacy.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(legacy)
	assert_object(legacy.simulation.map_layout).is_null()
	assert_float(legacy.world.half_extent()).is_equal(30.0)
	assert_int(legacy.world.interactables.size()).is_equal(13)
	assert_vector(legacy.world.interactables[0].position).is_equal(Vector3(0, 0, -1.6))

func test_map_rng_finishes_before_weather_initialization() -> void:
	var run := RunSimulation.new(20261119, preload("res://assets/data/three_day_survival.tres"))
	var expected_rng := RunRng.new(20261119)
	var layout := LargeMapLayout.new(expected_rng)
	LakeSurface.new(expected_rng)
	assert_array(run.map_layout.nodes).is_equal(layout.nodes)
	assert_dict(run.rng.snapshot()).is_equal(expected_rng.snapshot())
	assert_float(run.thermal.components(Vector3(60, 0, 0))[&"zone"]).is_equal(-3.0)
	var weather := WeatherController.new()
	weather.step_minute(781, expected_rng)
	run.step_minute()
	assert_dict(run.weather.snapshot()).is_equal(weather.snapshot())
	assert_dict(run.rng.snapshot()).is_equal(expected_rng.snapshot())
