extends GdUnitTestSuite


func test_gather_partial_failure_and_depletion() -> void:
	var g := GatheringResolver.new()
	var i := InventoryModel.new()
	var node := GatherNode.new(&"bush", 3, 1)
	assert_bool(g.resolve(node, &"gather_sticks", false, i)).is_true()
	assert_int(i.count(&"stick")).is_equal(1)
	assert_int(i.count(&"grass")).is_equal(0)
	assert_int(node.remaining).is_equal(3)
	g.resolve(node, &"gather_sticks", true, i)
	assert_int(node.remaining).is_equal(0)
	assert_int(i.count(&"grass")).is_equal(1)
	assert_bool(g.resolve(node, &"gather_sticks", true, i)).is_false()
	var log_node := GatherNode.new(&"deadfall", 2)
	i.tools.clear()
	assert_bool(g.resolve(log_node, &"chop_log", true, i)).is_false()


func test_gather_deadfall_bark_and_log_reserves_are_separate() -> void:
	var g := GatheringResolver.new()
	var i := InventoryModel.new()
	var node := GatherNode.new(&"deadfall", 1, 0, 2)
	assert_bool(g.resolve(node, &"strip_bark", true, i)).is_true()
	assert_int(i.count(&"bark")).is_equal(2)
	assert_int(node.remaining).is_equal(1)
	g.resolve(node, &"chop_log", false, i)
	assert_int(i.count(&"log")).is_equal(0)
	assert_int(node.remaining).is_equal(1)
	g.resolve(node, &"chop_log", true, i)
	assert_bool(node.is_depleted()).is_true()
