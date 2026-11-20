class_name RunSimulation extends RefCounted

signal snapshot_published(snapshot: Dictionary[StringName, Variant])
signal run_ended(cause: StringName)
signal action_resolved(action: StringName, success: bool, cause: StringName)
signal fell_in_water(event: ImmersionEvent)

var tuning: SliceTuning
var clock: Clock
var rng: RunRng
var thermal: ThermalField
var weather: WeatherController
var map_layout: LargeMapLayout
var lake: LakeSurface
var in_water: bool = false
var _contacts: Array[Dictionary] = []
var _travel_remainder: float = 0.0
var _immersion_sequence: int = 0
var _debug_break_next: bool = false
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
var fire_site_eligible: Callable
var _fire_target: FireController
var _gather_target: GatherNode
var _action_delta_s: float = 0.0
var _food_item: StringName = &""
var _food_revision: int = -1
var _feature_valid: Callable
var _feature_commit: Callable

func export_state() -> Dictionary:
	var fire_states: Array = []
	for fire: FireController in fires:
		fire_states.append(fire.export_state())
	return {"clock": clock.export_state(), "body": body.export_state(), "needs": needs.export_state(),
		"inventory": inventory.export_state(tuning.chapter_needs_enabled), "rng": rng.export_state(), "fires": fire_states,
		"run": {"minute_sequence": minute_sequence, "last_felt_temp_c": last_felt_temp_c if is_finite(last_felt_temp_c) else null}}

func restore_state(dto: Dictionary) -> bool:
	if not CheckpointValues.keys(dto, ["clock", "body", "needs", "inventory", "rng", "fires", "run"]):
		return false
	for key: String in ["clock", "body", "needs", "inventory", "rng", "run"]:
		if not dto[key] is Dictionary:
			return false
	if not dto.fires is Array or dto.fires.size() > tuning.max_fire_sites:
		return false
	if not CheckpointValues.keys(dto.run, ["minute_sequence", "last_felt_temp_c"]) or not CheckpointValues.integer(dto.run.minute_sequence, 0, 86400):
		return false
	if dto.run.last_felt_temp_c != null and not CheckpointValues.number(dto.run.last_felt_temp_c, -1000, 1000):
		return false
	var staged := RunSimulation.new(1, tuning)
	if not staged.clock.restore_state(dto.clock) or not staged.body.restore_state(dto.body) or not staged.needs.restore_state(dto.needs) or not staged.inventory.restore_state(dto.inventory, tuning.chapter_needs_enabled) or not staged.rng.restore_state(dto.rng):
		return false
	if staged.needs.is_asleep != (staged.clock.rate_mode == &"sleep") or staged._survived():
		return false
	if not tuning.chapter_needs_enabled and (staged.inventory.count(&"pemmican") > 0 or staged.clock.rate_mode == &"sleep"):
		return false
	for index: int in dto.fires.size():
		if not dto.fires[index] is Dictionary:
			return false
		var fire := staged.create_fire(Vector3.ZERO)
		if not fire.restore_state(dto.fires[index]):
			return false
		for earlier: int in index:
			if staged.fires[earlier].position.distance_to(fire.position) < preload("res://assets/data/playfield_defaults.tres").fire_spacing:
				return false
	clock = staged.clock
	clock.rate_mode_changed.disconnect(staged._on_rate_mode_changed)
	clock.rate_mode_changed.connect(_on_rate_mode_changed)
	body = staged.body
	needs = staged.needs
	inventory = staged.inventory
	rng = staged.rng
	thermal = staged.thermal
	fires = staged.fires
	minute_sequence = int(dto.run.minute_sequence)
	last_felt_temp_c = NAN if dto.run.last_felt_temp_c == null else float(dto.run.last_felt_temp_c)
	thermal.begin_minute(clock.day, clock.minute_of_day / 60.0)
	cancel_action()
	movement = &"idle"
	terminal = &""
	return true

func _init(seed_value: int = 1, data: SliceTuning = null) -> void:
	tuning = data if data != null else preload("res://assets/data/slice_defaults.tres")
	clock = Clock.new(tuning)
	rng = RunRng.new(seed_value)
	if tuning.large_map_enabled:
		map_layout = LargeMapLayout.new(rng, tuning.world)
		lake = LakeSurface.new(rng, tuning.world)
	thermal = ThermalField.new(tuning)
	if map_layout != null:
		map_layout.publish_zones(thermal)
	if tuning.weather_enabled:
		weather = WeatherController.new()
		thermal.register_wind_source(&"weather", 3.0)
		thermal.register_air_offset(&"weather", 0.0)
	body = BodyThermoregulation.new(tuning)
	needs = NeedsModel.new(tuning)
	inventory = InventoryModel.new(tuning)
	if tuning.chapter_needs_enabled:
		for item: StringName in tuning.starting_rations:
			inventory.add(item, tuning.starting_rations[item])
	mishaps = MishapResolver.new(tuning)
	gathering = GatheringResolver.new(tuning)
	actions = ActionRunner.new()
	clock.rate_mode_changed.connect(_on_rate_mode_changed)

## Admits already-selected sleep; control and action bindings are separate.
func request_sleep() -> bool:
	if in_water or terminal != &"" or not needs.request_sleep(clock.phase() == &"Night"):
		return false
	cancel_action()
	clock.request_rate_mode(&"sleep", &"chosen")
	return true

## Starts a handful after checking the snow plane, e.g. [code]run.start_snow_intake(world.is_on_snow(feet))[/code].
func start_snow_intake(on_snow: bool) -> bool:
	if not on_snow or not _can_use_consumables():
		return false
	return actions.start(&"eat_snow", tuning.snow_minutes, 1.0)

## Prepares an owned ration; [code]run.start_eating(&"pemmican")[/code] returns an empty name on acceptance.
func start_eating(item: StringName) -> StringName:
	if not _can_use_consumables() or actions.action != &"":
		return &"unavailable"
	var revision := inventory.stack_revision(item)
	var kcal: float = tuning.food_kcal.get(item, 0.0)
	var minutes: float = tuning.eat_minutes.get(item, 0.0)
	if revision < 0 or not is_finite(kcal) or kcal <= 0.0 or not is_finite(minutes) or minutes <= 0.0:
		return &"no_ration"
	if not needs.can_accept_food(kcal):
		return &"stomach_full"
	if not actions.start(&"eat", minutes, clock.seconds_per_minute(), minf(2.0, body.action_mult() * needs.action_mult())):
		return &"unavailable"
	_food_item = item
	_food_revision = revision
	return &""

## Creates at most two run-owned fire sites; geometry validation belongs to WorldMap.
func create_fire(site_position: Vector3) -> FireController:
	if terminal != &"" or fires.size() >= tuning.max_fire_sites or not site_position.is_finite():
		return null
	if fire_site_eligible.is_valid() and not fire_site_eligible.call(site_position):
		return null
	var fire := FireController.new(StringName("fire_%d" % fires.size()), site_position, thermal, tuning)
	fires.append(fire)
	return fire

## Shares IA1's capped action multiplier with feature eligibility projections.
func action_duration_multiplier() -> float:
	return minf(2.0, body.action_mult() * needs.action_mult())

## Registers one revalidated feature attempt with the ordered completion gate.
## For example, [code]run.start_feature_action(id, minutes, still_eligible, commit)[/code].
func start_feature_action(action: StringName, minutes: float, still_eligible: Callable, commit: Callable) -> bool:
	if not _can_use_consumables() or actions.action != &"" or not _allowed(action) or not still_eligible.is_valid() or not commit.is_valid() or not still_eligible.call():
		return false
	clock.request_rate_mode(&"normal", &"work")
	if not actions.start(action, minutes, clock.seconds_per_minute(), action_duration_multiplier()):
		return false
	_feature_valid = still_eligible
	_feature_commit = commit
	return true

## Starts an eligible transaction with target and duration fixed at admission.
func start_action(action: StringName, fire: FireController = null, node: GatherNode = null) -> bool:
	if in_water or terminal != &"" or needs.is_asleep or not tuning.action_minutes.has(action) or not _allowed(action):
		return false
	if fire != null:
		if not fires.has(fire) or not fire.can_act(action, inventory):
			return false
		if action == &"clear_snow" and fire_site_eligible.is_valid() and not fire_site_eligible.call(fire.position):
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
	actions.cancellable = true
	actions.progress_kept = lake != null and action == &"chop_log"
	if node != null and actions.progress_kept:
		actions.elapsed_s = node.action_progress.get(action, 0.0) * actions.duration_s
	return true

## Returns the current fire or gathering target, or null when idle.
func active_action_target() -> RefCounted:
	if actions.action == &"":
		return null
	return _fire_target if _fire_target != null else _gather_target

## Cancels active work and clears the stored target without a result or draw.
func cancel_action(forced: bool = true) -> void:
	if not forced and not actions.cancellable:
		return
	if _gather_target != null and actions.progress_kept and actions.action != &"":
		_gather_target.action_progress[actions.action] = clampf((actions.elapsed_s + _action_delta_s) / actions.duration_s, 0, 1)
	actions.cancel(forced)
	_fire_target = null
	_gather_target = null
	_action_delta_s = 0.0
	_food_item = &""
	_food_revision = -1
	_feature_valid = Callable()
	_feature_commit = Callable()

## Advances unpaused time, arbitrates all owed minutes before committing completion.
func update(delta_s: float, paused: bool = false) -> void:
	if terminal != &"" or paused or not is_finite(delta_s) or delta_s <= 0:
		return
	if _feature_valid.is_valid() and not _feature_valid.call():
		cancel_action()
	if movement != &"idle":
		cancel_action(false)
	if actions.action != &"" and actions.action != &"eat_snow":
		_action_delta_s += delta_s
	clock.accumulate(delta_s)
	var ticks := 0
	while ticks < tuning.max_ticks and terminal == &"" and clock.consume_minute(_integrate_minute):
		ticks += 1
	if terminal == &"" and not clock.minute_owed():
		_resolve_contacts()
		if actions.action != &"eat_snow":
			var completed := actions.advance(_action_delta_s)
			_action_delta_s = 0.0
			if completed != &"":
				_commit_completion(completed)
	snapshot_published.emit(snapshot())

## Advances a single deterministic minute for tests and explicit simulation drivers.
func step_minute() -> void:
	if terminal != &"":
		return
	clock.advance_minute(_integrate_minute)
	_resolve_contacts()
	snapshot_published.emit(snapshot())

func record_travel(from: Vector3, to: Vector3, hurrying: bool) -> void:
	if lake == null or in_water or terminal != &"" or not from.is_finite() or not to.is_finite():
		return
	var distance := Vector2(to.x - from.x, to.z - from.z).length()
	if distance <= 0.0:
		return
	var spacing := tuning.world.footfall_spacing
	var next := spacing - _travel_remainder
	while next <= distance:
		_contacts.append({&"position": from.lerp(to, next / distance), &"hurrying": hurrying})
		next += spacing
	_travel_remainder = fposmod(_travel_remainder + distance, spacing)

func debug_thin_ice_spawn() -> Vector3:
	if not OS.is_debug_build() or lake == null:
		return Vector3.ZERO
	_debug_break_next = true
	return lake.cell_center(Vector2i(2, 45))

func leave_water() -> void:
	in_water = false
	movement = &"idle"
	_travel_remainder = 0.0

func _resolve_contacts() -> void:
	if terminal != &"" or lake == null:
		_contacts.clear()
		return
	if body.is_dead():
		_end(&"hypothermia")
		_contacts.clear()
		return
	for contact: Dictionary in _contacts:
		if in_water:
			break
		var p: Vector3 = contact[&"position"]
		var surface := lake.surface_at(p)
		var debug_break: bool = OS.is_debug_build() and _debug_break_next and surface[&"kind"] == &"ice" and surface[&"ice_thickness_cm"] < tuning.world.ice_safe_cm
		if not debug_break and not mishaps.check_ice(surface, 0.0, contact[&"hurrying"], rng):
			continue
		_debug_break_next = false
		if not lake.break_ice(surface[&"cell"]):
			continue
		_immersion_sequence += 1
		var event := ImmersionEvent.new(_immersion_sequence, surface[&"cell"], p)
		cancel_action(true)
		body.apply_immersion(event.sequence)
		inventory.soak_carried(event.sequence)
		var tool := mishaps.lost_tool(inventory.tools, rng)
		if tool != &"":
			inventory.lose_tool(tool)
		in_water = true
		needs.wake(&"fell_in_water")
		clock.request_rate_mode(&"normal", &"fell_in_water")
		movement = &"wade"
		fell_in_water.emit(event)
	_contacts.clear()

## Returns detached values for presentation; contains no live owner objects.
func snapshot() -> Dictionary[StringName, Variant]:
	var fire_values: Array[Dictionary] = []
	for fire: FireController in fires:
		fire_values.append(fire.snapshot())
	var values: Dictionary[StringName, Variant] = {&"clock": clock.snapshot(), &"core_temp_c": body.core_temp_c, &"body_stage": body.stage, &"rate_c_per_hour": body.rate_c_per_hour, &"energy": needs.energy, &"energy_stage": needs.stage, &"inventory": inventory.snapshot(), &"fires": fire_values, &"terminal": terminal, &"action": actions.action, &"progress": actions.progress()}
	if tuning.chapter_needs_enabled:
		values[&"needs"] = needs.snapshot()
		values[&"night_goal"] = tuning.survival_day - tuning.start_day
		values[&"nights_survived"] = maxi(0, clock.day - tuning.start_day - int(clock.minute_of_day < ceili(clock.sunrise_hour() * 60.0)))
	if weather != null:
		values[&"weather"] = weather.snapshot()
	return values

func _integrate_minute() -> void:
	minute_sequence += 1
	var was_asleep := needs.is_asleep
	var old_stage := body.stage
	var was_skipping := was_asleep or clock.rate_mode == &"wait"
	var activity := &"idle" if was_asleep else movement
	var work := &"idle" if was_asleep else _work_activity(actions.action)
	var snowfall_gain := 0.0
	if weather != null:
		weather.step_minute((clock.day - 1) * 1440 + clock.minute_of_day, rng)
		var conditions := weather.snapshot()
		thermal.update_wind_source(&"weather", conditions[&"wind_mps"])
		thermal.update_air_offset(&"weather", conditions[&"air_offset_c"])
		if thermal.components(position)[&"shelter_bonus"] <= 0.0:
			snowfall_gain = conditions[&"wetness_per_hour"]
	thermal.begin_minute(clock.day, clock.minute_of_day / 60.0)
	for fire: FireController in fires:
		fire.step_minute(position)
	thermal.seal_sources(minute_sequence)
	last_felt_temp_c = thermal.effective_temp_c(position)
	body.step_minute(last_felt_temp_c, activity, work, snowfall_gain)
	var resting := false
	if activity == &"idle" and actions.action == &"" and (not tuning.chapter_needs_enabled or clock.rate_mode == &"wait"):
		for fire: FireController in fires:
			if fire.stage == &"Burning" and position.distance_to(fire.position) < fire.warm_radius():
				resting = true
	needs.step_minute(activity, body.is_shivering(), resting, work, body.stage)
	if body.is_dead():
		_end(&"hypothermia")
	elif needs.dehydration_due:
		_end(&"dehydration")
	elif _survived():
		_end(&"dawn_survived")
	else:
		if actions.action != &"" and (needs.collapse_due or not _allowed(actions.action) or (_feature_valid.is_valid() and not _feature_valid.call())):
			cancel_action()
		if _contacts.is_empty() and actions.action == &"eat_snow" and actions.advance(1.0) == &"eat_snow":
			var accepted := needs.accept_snow()
			action_resolved.emit(&"eat_snow", accepted, &"" if accepted else &"unavailable")
		if tuning.chapter_needs_enabled:
			_reconcile_sleep(body.cold_wake_due(old_stage, was_skipping))

func _survived() -> bool:
	if tuning.chapter_needs_enabled:
		return clock.day >= tuning.survival_day and clock.sunrise_this_minute
	return clock.day >= tuning.survival_day and clock.minute_of_day / 60.0 >= clock.sunrise_hour()

func _reconcile_sleep(cold: bool) -> void:
	if in_water:
		return
	cold = cold or (needs.collapse_due and body.cold_or_worse())
	var wake_cause := &""
	if cold:
		wake_cause = &"cold"
	elif needs.natural_wake_due:
		wake_cause = &"rested"
	elif clock.normal_requested():
		wake_cause = &"interrupted"
	if needs.collapse_due:
		cancel_action()
		needs.apply_collapse(wake_cause)
		if needs.is_asleep:
			clock.request_rate_mode(&"sleep", &"exhaustion")
	elif wake_cause != &"":
		needs.wake(wake_cause)
	if cold:
		body.publish_cold_wake()
	if wake_cause != &"":
		clock.request_rate_mode(&"normal", wake_cause)

func _on_rate_mode_changed(mode: StringName) -> void:
	if mode == &"normal" and terminal == &"":
		needs.wake(&"interrupted")

func _end(cause: StringName) -> void:
	terminal = cause
	cancel_action()
	run_ended.emit(cause)

func _allowed(action: StringName) -> bool:
	if body.stage == &"Critical" and action not in [&"add_fuel", &"blow_embers"]:
		return false
	return not (needs.stage == &"Exhausted" and _work_activity(action) == &"heavy")

func _work_activity(action: StringName) -> StringName:
	if action in [&"", &"eat", &"eat_snow"]:
		return &"idle"
	return &"heavy" if action in [&"clear_snow", &"chop_log", &"gather_stones", &"build_shelter_frame"] else &"light"

func _commit_completion(action: StringName) -> void:
	if not _allowed(action):
		cancel_action()
		return
	if _feature_commit.is_valid():
		var valid: bool = _feature_valid.is_valid() and _feature_valid.call()
		var commit := _feature_commit
		cancel_action()
		if valid:
			var cause: StringName = commit.call()
			action_resolved.emit(action, cause in [&"", &"nothing_yet", &"piled", &"wire_broken"], cause)
		return
	if action == &"eat":
		var item := _food_item
		var revision := _food_revision
		_food_item = &""
		_food_revision = -1
		var kcal: float = tuning.food_kcal.get(item, 0.0)
		var cause := &""
		if not needs.can_accept_food(kcal):
			cause = &"stomach_full"
		elif not inventory.consume_prepared(item, revision):
			cause = &"no_ration"
		else:
			needs.accept_food(kcal)
		action_resolved.emit(&"eat_hare" if item == &"hare_cooked" else action, cause == &"", cause)
		return
	var eligible := _fire_target.can_act(action, inventory) if _fire_target != null else gathering.can_gather(_gather_target, action, inventory)
	if action == &"clear_snow" and _fire_target != null and fire_site_eligible.is_valid():
		eligible = eligible and fire_site_eligible.call(_fire_target.position)
	if not eligible:
		cancel_action()
		return
	var wetness := _fire_target.material_wetness(action) if _fire_target != null else 0.0
	var quality := _fire_target.material_quality(action) if _fire_target != null else 1.0
	var attempt_position := _fire_target.position if _fire_target != null else position
	var result := mishaps.resolve(action, thermal.wind_eff(attempt_position), body.cold_hands_penalty(), needs.fatigue_penalty(), rng, wetness, quality)
	if _fire_target != null:
		_fire_target.commit_action(action, inventory, result[&"success"])
	else:
		gathering.resolve(_gather_target, action, result[&"success"], inventory)
		_gather_target.action_progress.erase(action)
	action_resolved.emit(action, result[&"success"], result[&"cause"])
	_fire_target = null
	_gather_target = null

func _can_use_consumables() -> bool:
	return not in_water and tuning.chapter_needs_enabled and terminal == &"" and not needs.is_asleep and body.stage != &"Critical" and movement == &"idle"
