extends SceneTree

func _initialize() -> void:
	_smoke.call_deferred()

func _smoke() -> void:
	var run := preload("res://src/run/run.tscn").instantiate() as RunCoordinator
	run.tuning = preload("res://assets/data/three_day_survival.tres")
	run.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(run)
	await process_frame
	await physics_frame
	for minute in 180:
		run.simulation.step_minute()
	var sim := run.simulation
	print("WORLD_MAP_SMOKE nodes=%d size=240x240 minutes=%d day=%d minute=%d weather=%s terminal=%s" % [run.world.interactables.size(), sim.minute_sequence, sim.clock.day, sim.clock.minute_of_day, sim.weather.state, sim.terminal])
	var passed := sim.minute_sequence == 180 and sim.terminal == &"" and run.world.half_extent() == 120
	run.free()
	sim = null
	await process_frame
	quit(0 if passed else 1)
