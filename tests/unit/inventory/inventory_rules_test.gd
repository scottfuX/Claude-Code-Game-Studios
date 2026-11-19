extends GdUnitTestSuite


func test_inventory_rejects_missing_and_negative() -> void:
	var i := InventoryModel.new()
	assert_bool(i.consume(&"stick", 1)).is_false()
	assert_bool(i.add(&"stick", -1)).is_false()
	i.add(&"stick", 4)
	assert_bool(i.consume(&"stick", 3)).is_true()
	assert_int(i.count(&"stick")).is_equal(1)
	assert_bool(i.has_tool(&"hatchet")).is_true()
