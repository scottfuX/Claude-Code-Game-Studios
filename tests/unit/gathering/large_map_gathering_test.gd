extends GdUnitTestSuite

func test_retained_chop_checkpoint_progress_and_legacy_default() -> void:
	for fraction: float in [0.0, 0.4, 1.0]:
		var node := GatherNode.new(&"deadfall", 4)
		node.action_progress[&"chop_log"] = fraction
		var restored := GatherNode.new(&"deadfall", 4)
		assert_bool(restored.restore_state(JSON.parse_string(JSON.stringify(node.export_state())))).is_true()
		assert_float(restored.action_progress.get(&"chop_log", -1.0)).is_equal(fraction)
		var legacy := node.export_state()
		legacy.erase("action_progress")
		assert_bool(restored.restore_state(legacy)).is_true()
		assert_dict(restored.action_progress).is_empty()

func test_invalid_retained_progress_does_not_mutate_node() -> void:
	var node := GatherNode.new(&"deadfall", 4)
	node.action_progress[&"chop_log"] = 0.4
	var initial := node.export_state()
	for progress: Variant in [{"chop_log": -0.1}, {"chop_log": 1.1}, {"chop_log": NAN}, {"chop_log": INF}, {"chop_log": "0.5"}, {"strip_bark": 0.5}, {"unknown": 0.5}, []]:
		var bad := initial.duplicate(true)
		bad.action_progress = progress
		assert_bool(node.restore_state(bad)).is_false()
		assert_dict(node.export_state()).is_equal(initial)
	var stone := GatherNode.new(&"stone", 4)
	var bad := stone.export_state()
	bad.action_progress = {"chop_log": 0.5}
	assert_bool(stone.restore_state(bad)).is_false()

func test_birch_stones_and_deadfall_reserves() -> void:
	var resolver := GatheringResolver.new()
	var inventory := InventoryModel.new()
	var birch := GatherNode.new(&"birch", 0, 0, 4)
	assert_bool(resolver.resolve(birch, &"strip_bark", true, inventory)).is_true()
	assert_int(inventory.count(&"bark")).is_equal(2)
	assert_int(birch.bark_remaining).is_equal(2)
	assert_bool(resolver.resolve(birch, &"chop_log", true, inventory)).is_false()
	var stone := GatherNode.new(&"stone", 2)
	assert_bool(resolver.resolve(stone, &"gather_stones", true, inventory)).is_true()
	assert_int(inventory.count(&"stone")).is_equal(1)
	assert_int(stone.remaining).is_equal(1)
	var deadfall := GatherNode.new(&"deadfall", 4)
	deadfall.sticks_remaining = 3
	inventory.tools.clear()
	assert_bool(resolver.resolve(deadfall, &"gather_sticks", true, inventory)).is_true()
	assert_int(inventory.count(&"stick")).is_equal(2)
	assert_int(deadfall.sticks_remaining).is_equal(1)
	assert_int(deadfall.remaining).is_equal(4)
	assert_bool(resolver.can_gather(deadfall, &"chop_log", inventory)).is_false()

func test_empty_missing_tools_and_failed_gathers_preserve_reserves() -> void:
	var resolver := GatheringResolver.new()
	var inventory := InventoryModel.new()
	var birch := GatherNode.new(&"birch", 0, 0, 4)
	resolver.resolve(birch, &"strip_bark", false, inventory)
	assert_int(birch.bark_remaining).is_equal(4)
	assert_int(inventory.count(&"bark")).is_equal(1)
	inventory.tools.clear()
	assert_bool(resolver.can_gather(birch, &"strip_bark", inventory)).is_false()
	assert_bool(resolver.resolve(GatherNode.new(&"stone"), &"gather_stones", true, inventory)).is_false()
	assert_bool(resolver.resolve(null, &"gather_stones", true, inventory)).is_false()
	assert_bool(resolver.resolve(GatherNode.new(&"unknown", 2), &"gather_stones", true, inventory)).is_false()

func test_stone_completion_has_no_mishap_roll_and_empties_once() -> void:
	var run := RunSimulation.new()
	var node := GatherNode.new(&"stone", 1)
	assert_bool(run.start_action(&"gather_stones", null, node)).is_true()
	run.update(run.clock.seconds_per_minute())
	assert_int(run.inventory.count(&"stone")).is_equal(1)
	assert_int(run.rng.draw_count).is_equal(0)
	assert_bool(node.is_depleted()).is_true()
	assert_bool(run.start_action(&"gather_stones", null, node)).is_false()
