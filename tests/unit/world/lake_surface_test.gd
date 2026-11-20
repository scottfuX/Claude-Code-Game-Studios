extends GdUnitTestSuite

func test_world_resource_controls_grid_and_ice_break_formula() -> void:
	var world := WorldTuning.new()
	world.lake_bounds = Rect2(0, 0, 8, 8)
	world.ice_cell_size = 1.0
	world.ice_normal_cm = 30
	world.ice_safe_cm = 20
	world.ice_break_k = 0.1
	var lake := LakeSurface.new(RunRng.new(4), world)
	assert_vector(lake.size).is_equal(Vector2i(8, 8))
	var tuning := SliceTuning.new()
	tuning.world = world
	assert_float(MishapResolver.new(tuning).ice_break_chance(10)).is_equal_approx(0.05, 0.000001)

func test_seeded_thin_bands_thickness_and_cell_queries() -> void:
	var rng := RunRng.new(92)
	var lake := LakeSurface.new(rng)
	var other_rng := RunRng.new(92)
	var other := LakeSurface.new(other_rng)
	assert_dict(lake.thin_cells).is_equal(other.thin_cells)
	assert_dict(rng.snapshot()).is_equal(other_rng.snapshot())
	assert_float(float(lake.thin_cells.size()) / (180 * 110)).is_between(0.14, 0.17)
	for cell: Vector2i in lake.thin_cells:
		assert_float(lake.thin_cells[cell]).is_between(5.0, 10.0)
		assert_bool(cell.x < 8 or cell.y < 14).is_true()
	assert_float(lake.surface_at(Vector3(60, 0, 0))[&"ice_thickness_cm"]).is_equal(25.0)
	var p := lake.cell_center(Vector2i(2, 45))
	assert_vector(lake.surface_at(p)[&"cell"]).is_equal(Vector2i(2, 45))
	assert_vector(lake.surface_at(p + Vector3(0.24, 0, 0.24))[&"cell"]).is_equal(Vector2i(2, 45))
	assert_str(lake.surface_at(Vector3.ZERO)[&"kind"]).is_equal("snow")
	assert_str(lake.surface_at(Vector3(INF, 0, 0))[&"kind"]).is_equal("snow")

func test_break_is_once_only_open_water_and_blocks_crossing() -> void:
	var lake := LakeSurface.new(RunRng.new(3))
	var changes: Array[Vector2i] = []
	lake.ice_broken.connect(func(cell: Vector2i) -> void: changes.append(cell))
	var cell := Vector2i(2, 45)
	var p := lake.cell_center(cell)
	assert_bool(lake.break_ice(cell)).is_true()
	assert_bool(lake.break_ice(cell)).is_false()
	assert_bool(lake.break_ice(Vector2i(-1, 0))).is_false()
	assert_bool(lake.break_ice(lake.size)).is_false()
	assert_int(changes.size()).is_equal(1)
	assert_str(lake.surface_at(p)[&"kind"]).is_equal("water")
	assert_bool(lake.can_traverse(p - Vector3.RIGHT, p + Vector3.RIGHT)).is_false()
	assert_bool(lake.can_traverse(p - Vector3.RIGHT * 2, p - Vector3.RIGHT)).is_true()
	var exit := lake.nearest_safe_exit(p)
	var surface := lake.surface_at(exit)
	assert_bool(surface[&"kind"] == &"snow" or (surface[&"kind"] == &"ice" and surface[&"ice_thickness_cm"] >= 15)).is_true()
