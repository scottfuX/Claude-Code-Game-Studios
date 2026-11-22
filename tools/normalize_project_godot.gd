extends SceneTree

## Rewrites project.godot in the exact format the Godot editor saves, so opening
## the editor leaves it unchanged and `git pull` is not blocked by local edits.
## Run: godot --headless --path . -s res://tools/normalize_project_godot.gd

func _initialize() -> void:
	var err := ProjectSettings.save()
	if err != OK:
		push_error("ProjectSettings.save() failed: %s" % error_string(err))
	quit(err)
