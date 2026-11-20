extends GdUnitTestSuite

func test_dimensions_zones_and_safe_camps() -> void:
	var layout := LargeMapLayout.new(RunRng.new(20261119))
	assert_float(LargeMapLayout.DEFAULTS.half_extent * 2).is_equal(240.0)
	assert_bool(layout.contains(Vector3(119.9, 0, -119.9))).is_true()
	assert_bool(layout.contains(Vector3(120.1, 0, 0))).is_false()
	assert_str(layout.zone_at(Vector3.ZERO)).is_equal("open")
	assert_str(layout.zone_at(Vector3(60, 0, -5))).is_equal("lake")
	assert_str(layout.zone_at(Vector3(-60, 0, 0))).is_equal("forest")
	assert_str(layout.zone_at(Vector3(60, 0, 80))).is_equal("forest")
	assert_str(layout.zone_at(Vector3(0, 0, 80))).is_equal("drift")
	assert_str(layout.zone_at(Vector3(0, 0, -115))).is_equal("ridge")
	assert_int(LargeMapLayout.DEFAULTS.camps.size()).is_equal(3)
	for camp: Vector3 in LargeMapLayout.DEFAULTS.camps:
		assert_str(layout.zone_at(camp)).is_equal("lee")
		assert_float(camp.length()).is_less_equal(60.0)
	var field := ThermalField.new()
	layout.publish_zones(field)
	assert_float(field.components(Vector3(60, 0, -5))[&"zone"]).is_equal(-3.0)
	assert_float(field.wind_eff(Vector3(-60, 0, 0))).is_equal_approx(1.2, 0.000001)
	assert_float(field.components(Vector3(22.5, 0, -5))[&"zone"]).is_equal(0.0)
	assert_float(field.components(Vector3(25, 0, -5))[&"zone"]).is_equal(-1.5)
	assert_float(field.components(Vector3(27.5, 0, -5))[&"zone"]).is_equal(-3.0)

func test_seeded_layout_count_ranges_placement_spacing_and_stable_ids() -> void:
	for seed_value in [20261119, 4, 42]:
		var rng := RunRng.new(seed_value)
		var layout := LargeMapLayout.new(rng)
		var other_rng := RunRng.new(seed_value)
		var other := LargeMapLayout.new(other_rng)
		assert_array(layout.nodes).is_equal(other.nodes)
		assert_dict(rng.snapshot()).is_equal(other_rng.snapshot())
		var actual: Dictionary[StringName, int] = {}
		var ids: Dictionary[StringName, bool] = {}
		for i in layout.nodes.size():
			var node: Dictionary = layout.nodes[i]
			var p: Vector3 = node[&"position"]
			var kind: StringName = node[&"kind"]
			var ring: int = node[&"ring"]
			var key := StringName("%d_%s" % [ring, kind])
			actual[key] = actual.get(key, 0) + 1
			assert_bool(ids.has(node[&"id"])).is_false()
			ids[node[&"id"]] = true
			assert_bool(layout.contains(p)).is_true()
			assert_bool(layout.is_in_lake(p)).is_false()
			assert_str(layout.zone_at(p)).is_not_equal("drift")
			assert_float(p.length()).is_greater_equal(LargeMapLayout.DEFAULTS.rings[ring].x)
			assert_float(p.length()).is_less(LargeMapLayout.DEFAULTS.rings[ring].y)
			for j in i:
				var prior: Dictionary = layout.nodes[j]
				assert_float(p.distance_to(prior[&"position"])).is_greater_equal(maxf(LargeMapLayout.DEFAULTS.spacing[kind], LargeMapLayout.DEFAULTS.spacing[prior[&"kind"]]))
		for ring in 3:
			for kind_index in LargeMapLayout.DEFAULTS.kinds.size():
				var key := StringName("%d_%s" % [ring, LargeMapLayout.DEFAULTS.kinds[kind_index]])
				var base: int = LargeMapLayout.DEFAULTS.ring_counts[kind_index][ring]
				assert_int(int(actual.get(key, 0))).is_between(roundi(base * 0.8), roundi(base * 1.2))

func test_guaranteed_deadfalls_and_seeded_yield_ranges() -> void:
	var layout := LargeMapLayout.new(RunRng.new(20261119))
	var first: Dictionary = layout.nodes[0]
	var second: Dictionary = layout.nodes[1]
	assert_str(first[&"id"]).is_equal("0_deadfall_0")
	assert_str(second[&"id"]).is_equal("0_deadfall_1")
	var p: Vector3 = first[&"position"]
	assert_float(p.length()).is_between(20.0, 30.0)
	assert_float(p.normalized().dot(Vector3.FORWARD)).is_equal(1.0)
	assert_float((second[&"position"] as Vector3).length()).is_less(40.0)
	for node: Dictionary in layout.nodes:
		match node[&"kind"]:
			&"bush":
				assert_int(node[&"remaining"]).is_between(3, 8)
				assert_int(node[&"bonus_grass"]).is_between(0, 2)
				assert_int(node[&"bonus_grass"]).is_less_equal(floori(node[&"remaining"] / 3.0))
			&"deadfall":
				assert_int(node[&"remaining"]).is_between(4, 8)
				assert_int(node[&"sticks_remaining"]).is_between(3, 5)
				assert_int(node[&"bark_remaining"]).is_equal(0)
			&"birch": assert_int(node[&"bark_remaining"]).is_between(4, 8)
			&"grass": assert_int(node[&"remaining"]).is_between(2, 4)
			&"stone": assert_int(node[&"remaining"]).is_between(6, 10)

func test_different_seeds_vary_layout() -> void:
	var first := LargeMapLayout.new(RunRng.new(11))
	var second := LargeMapLayout.new(RunRng.new(12))
	assert_bool(first.nodes == second.nodes).is_false()
