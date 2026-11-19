class_name FirstNightDemo extends RefCounted

const LOG_ROUTE: Array[int] = [5, 8, 7]
var _run: RunCoordinator
var _night_speed: float
var _phase: int = 0
var _log_index: int = 0
var _first_chop: bool = true
var _lit_s: float = 0.0
var _elapsed_s: float = 0.0
var _reported_end: bool = false
var _aiming: bool = false

func _init(run: RunCoordinator, night_speed: float = 80.0) -> void:
	_run = run
	_night_speed = night_speed if night_speed > 1.0 else 80.0
	_run.simulation.action_resolved.connect(_on_action_resolved)

## Replays movement and interaction only; game rules, supplies and RNG stay intact.
func advance(delta: float) -> float:
	if not OS.is_debug_build():
		return 1.0
	_elapsed_s += delta
	var sim := _run.simulation
	if sim.terminal != &"":
		_run.input_router.drive_debug(Vector2.ZERO)
		if not _reported_end:
			print("DEMO_END t=%.2f outcome=%s core=%.2f logs=%d" % [_elapsed_s, sim.terminal, sim.body.core_temp_c, sim.inventory.count(&"log")])
			_reported_end = true
		return 1.0
	match _phase:
		0:
			if _approach(_run.world.interactables[0].position):
				_next()
			return 1.0
		1:
			if sim.inventory.count(&"stick") >= 6:
				_next()
			else:
				_press(&"interact")
			return 3.0
		2:
			if _approach(_run.world.interactables[9].position):
				_next()
			return 1.0
		3:
			if sim.inventory.count(&"grass") >= 4:
				_next()
			else:
				_press(&"interact")
			return 3.0
		4:
			if _approach(_run.world.interactables[LOG_ROUTE[_log_index]].position, true):
				_next()
			return 1.0
		5:
			var entry := _run.world.interactables[LOG_ROUTE[_log_index]]
			if entry.gather_node.remaining == 0:
				_log_index += 1
				_phase = 4 if _log_index < LOG_ROUTE.size() else 6
				print("DEMO_STOCK t=%.2f logs=%d" % [_elapsed_s, sim.inventory.count(&"log")])
			elif sim.actions.action == &"":
				_first_chop = _first_chop and sim.inventory.count(&"log") == 0
				_press(&"interact")
			return 3.0 if _first_chop else 35.0
		6:
			if _walk(Vector3(-2, 0, 1.5), Vector3(-2, 0, 0.3), true):
				_next()
			return 1.0
		7:
			if sim.fires.is_empty():
				_press(&"secondary")
			else:
				_next()
			return 3.0
		8:
			if sim.actions.action == &"":
				var fire := sim.fires[0]
				if fire.stage == &"Burning" and fire.fuel >= 220:
					_next()
				else:
					_press(&"interact")
			return 3.0
		9:
			if _walk(sim.fires[0].position + Vector3(0, 0, 0.45), sim.fires[0].position):
				_lit_s += delta
				if _lit_s >= 1.5:
					_next()
			return 1.0
		10:
			if sim.fires[0].fuel < 220:
				_press(&"interact")
			return _night_speed
	return 1.0

func _next() -> void:
	_phase += 1
	print("DEMO_PHASE %d t=%.2f day=%d minute=%d" % [_phase, _elapsed_s, _run.simulation.clock.day, _run.simulation.clock.minute_of_day])

func _on_action_resolved(action: StringName, success: bool, cause: StringName) -> void:
	print("DEMO_ACTION t=%.2f action=%s success=%s cause=%s" % [_elapsed_s, action, success, cause])

func _press(action: StringName) -> void:
	_run.input_router.drive_debug(Vector2.ZERO)
	if _run.simulation.actions.action == &"":
		_run.input_router.drive_debug(Vector2.ZERO, action)

func _approach(target: Vector3, hurry: bool = false) -> bool:
	return _walk(target + Vector3(0, 0, 0.85), target, hurry)

func _walk(destination: Vector3, look_at: Vector3, hurry: bool = false) -> bool:
	var offset := destination - _run.survivor.position
	offset.y = 0
	if offset.length() <= 0.12:
		_aiming = true
	if _aiming:
		var facing := (look_at - _run.survivor.position).normalized()
		if _run.survivor.facing.dot(facing) > 0.97:
			_aiming = false
			_run.input_router.drive_debug(Vector2.ZERO)
			return true
		offset = facing * 0.25
	var local := offset.rotated(Vector3.UP, -_run.camera.yaw)
	_run.input_router.drive_debug((Vector2(local.x, local.z) * 2.0).limit_length(1.0), &"", hurry)
	return false
