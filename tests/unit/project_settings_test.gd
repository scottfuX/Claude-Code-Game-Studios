extends GdUnitTestSuite


func test_project_settings_identify_lonefire() -> void:
	var project_name := String(ProjectSettings.get_setting("application/config/name", ""))
	assert_str(project_name).is_equal("Lonefire")
