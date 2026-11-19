class_name RunSimulation extends RefCounted

signal snapshot_published(snapshot: Dictionary[StringName, Variant])
signal run_ended(cause: StringName)
signal action_resolved(action: StringName, success: bool, cause: StringName)

var tuning: SliceTuning
var clock: Clock
var rng: RunRng
var thermal: ThermalField
var body: BodyThermoregulation
var needs: NeedsModel
var inventory: InventoryModel
var mishaps: MishapResolver
var gathering: GatheringResolver
var actions: ActionRunner
var fires: Array[FireController] = []
var position: Vector3 = Vector3.ZERO
var movement: StringName = &"idle"
var terminal: StringName = &""
var last_felt_temp_c: float = NAN
var minute_sequence: int = 0
var _fire_target: FireController
var _gather_target: GatherNode
var _action_delta_s: float = 0.0

func _init(seed_value: int = 1, data: SliceTuning = null) -> void:
	tuning = data if data != null else preload("res://assets/data/slice_defaults.tres")
	clock = Clock.new(tuning)
	rng = RunRng.new(seed_value)
	thermal = ThermalField.new(tuning)
	body = BodyThermoregulation.new(tuning)
	needs = NeedsModel.new(tuning)
	inventory = InventoryModel.new()
	mishaps = MishapResolver.new(tuning)
	gathering = GatheringResolver.new(tuning)
	actions = ActionRunner.new()

## Creates at most two run-owned fire sites; geometry validation belongs to WorldMap.
func create_fire(site_position: Vector3) -> FireController:
	if terminal != &"" or fires.size() >= tuning.max_fire_sites or not site_position.is_finite():
		return null
	var fire := FireController.new(StringName("fire_%d" % fires.size()), site_position, thermal, tuning)
	fires.append(fire)
	return fire

## Starts an eligible transaction with target and duration fixed at admission.
func start_action(action: StringName, fire: FireController = null, node: GatherNode = null) -> bool:
	if terminal != &"" or not tuning.action_minutes.has(action) or not _allowed(action):
		return false
	if fire != null:
		if not fires.has(fire) or not fire.can_act(action, inventory):
			return false
	elif node != null:
		if not gathering.can_gather(node, action, inventory):
			return false
	else:
		return false
	if not actions.start(action, tuning.action_minutes[action], clock.seconds_per_minute(), body.action_mult() * needs.action_mult()):
		return false
	_fire_target = fire
	_gather_target = node
	return true

## Cancels active work and clears the stored target without a result or draw.
func cancel_action() -> void:
	actions.cancel()
	_fire_target = null
	_gather_target = null
	_action_delta_s = 0.0

## Advances unpaused time, arbitrates all owed minutes before committing completion.
func update(delta_s: float, paused: bool = false) -> void:
	if terminal != &"" or paused or not is_finite(delta_s) or delta_s <= 0:
		return
	if movement != &"idle":
		cancel_action()
	if actions.action != &"":
		_action_delta_s += delta_s
	clock.accumulate(delta_s)
	var ticks := 0
	while ticks < tuning.max_ticks and terminal == &"" and clock.consume_minute():
		_integrate_minute()
		ticks += 1
	if terminal == &"" and clock.debt < clock.seconds_per_minute():
		var completed := actions.advance(_action_delta_s)
		_action_delta_s = 0.0
		if completed != &"":
			_commit_completion(completed)
	snapshot_published.emit(snapshot())

## Advances a single deterministic minute for tests and explicit simulation drivers.
func step_minute() -> void:
	if terminal != &"":
		return
	clock.advance_minute()
	_integrate_minute()
	snapshot_published.emit(snapshot())

## Returns detached values for presentation; contains no live owner objects.
func snapshot() -> Dictionary[StringName, Variant]:
	var fire_values: Array[Dictionary] = []
	for fire: FireController in fires:
		fire_values.append(fire.snapshot())
	return {&"clock": clock.snapshot(), &"core_temp_c": body.core_temp_c, &"body_stage": body.stage, &"rate_c_per_hour": body.rate_c_per_hour, &"energy": needs.energy, &"energy_stage": needs.stage, &"inventory": inventory.snapshot(), &"fires": fire_values, &"terminal": terminal, &"action": actions.action, &"progress": actions.progress()}

func _integrate_minute() -> void:
	minute_sequence += 1
	var work := _work_activity(actions.action)
	thermal.begin_minute(clock.day, clock.minute_of_day / 60.0)
	for fire: FireController in fires:
		fire.step_minute(position)
	thermal.seal_sources(minute_sequence)
	last_felt_temp_c = thermal.effective_temp_c(position)
	body.step_minute(last_felt_temp_c, movement, work)
	var resting := false
	if movement == &"idle" and work == &"idle":
		for fire: FireController in fires:
			if fire.stage == &"Burning" and position.distance_to(fire.position) < fire.warm_radius():
				resting = true
	needs.step_minute(movement, body.is_shivering(), resting, work)
	if body.is_dead():
		_end(&"hypothermia")
	elif clock.day >= 2 and clock.minute_of_day / 60.0 >= clock.sunrise_hour():
		_end(&"dawn_survived")
	elif actions.action != &"" and not _allowed(actions.action):
		cancel_action()

func _end(cause: StringName) -> void:
	terminal = cause
	cancel_action()
	run_ended.emit(cause)

func _allowed(action: StringName) -> bool:
	if body.stage == &"Critical" and action not in [&"add_fuel", &"blow_embers"]:
		return false
	return not (needs.stage == &"Exhausted" and _work_activity(action) == &"heavy")

func _work_activity(action: StringName) -> StringName:
	if action == &"":
		return &"idle"
	return &"heavy" if action in [&"clear_snow", &"chop_log"] else &"light"

func _commit_completion(action: StringName) -> void:
	if not _allowed(action):
		cancel_action()
		return
	var eligible := _fire_target.can_act(action, inventory) if _fire_target != null else gathering.can_gather(_gather_target, action, inventory)
	if not eligible:
		cancel_action()
		return
	var result := mishaps.resolve(action, thermal.wind_eff(position), body.cold_hands_penalty(), needs.fatigue_penalty(), rng)
	if _fire_target != null:
		_fire_target.commit_action(action, inventory, result[&"success"])
	else:
		gathering.resolve(_gather_target, action, result[&"success"], inventory)
	action_resolved.emit(action, result[&"success"], result[&"cause"])
	_fire_target = null
	_gather_target = null
