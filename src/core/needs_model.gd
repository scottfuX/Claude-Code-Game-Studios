class_name NeedsModel extends RefCounted

signal needs_stage_changed(need: StringName, stage: StringName)
signal sleep_changed(asleep: bool, cause: StringName)

const STORE_EPSILON: float = 0.00000001
const DEFAULTS = preload("res://assets/data/slice_defaults.tres")

var tuning: SliceTuning
var energy: float = 90.0
var stage: StringName = &"Rested"
var hydration: float
var hydration_stage: StringName = &"OK"
var stomach_kcal: float
var weight_kg: float
var fullness_stage: StringName = &"Fed"
var is_asleep: bool = false
var zero_hydration_minutes: int = 0
var empty_minutes: int = 0
var dehydration_due: bool = false
var collapse_due: bool = false
var natural_wake_due: bool = false
var _collapsed: bool = false
var _start_weight_kg: float
var _stomach_capacity_kcal: float

func _init(data: SliceTuning = null) -> void:
	tuning = data if data != null else DEFAULTS
	energy = tuning.energy_start
	hydration = clampf(tuning.hydration_start, 0.0, 100.0)
	_start_weight_kg = tuning.start_weight_kg if is_finite(tuning.start_weight_kg) and tuning.start_weight_kg >= 50.0 else DEFAULTS.start_weight_kg
	_stomach_capacity_kcal = tuning.stomach_capacity_kcal if is_finite(tuning.stomach_capacity_kcal) and tuning.stomach_capacity_kcal > 0.0 else DEFAULTS.stomach_capacity_kcal
	stomach_kcal = clampf(tuning.stomach_start_kcal, 0.0, _stomach_capacity_kcal)
	weight_kg = _start_weight_kg
	if tuning.chapter_needs_enabled:
		_refresh_hydration()
		_refresh_fullness()
		refresh_stage()

## Integrates one minute. Sleep endpoints are applied after the terminal barrier.
func step_minute(movement: StringName = &"idle", shivering: bool = false, resting_at_fire: bool = false, work: StringName = &"idle", body_stage: StringName = &"Warm") -> void:
	var drain := maxf(tuning.energy_drain.get(movement, 1.0), tuning.energy_drain.get(work, 1.0))
	drain += tuning.shiver_energy if shivering else 0.0
	var rate := tuning.rest_energy if resting_at_fire else -drain
	if tuning.chapter_needs_enabled:
		if is_asleep:
			var food_quality := lerpf(tuning.sleep_food_min, 1.0, minf(1.0, fullness() / tuning.sleep_food_full))
			rate = tuning.sleep_energy * tuning.sleep_warmth[body_stage] * food_quality
		elif not resting_at_fire:
			if hydration_stage in [&"Thirsty", &"Parched"]:
				rate *= tuning.thirst_energy_mult
			if fullness_stage == &"Starving":
				rate *= tuning.starving_energy_mult
		_step_stores(movement, work, shivering)
	energy = clampf(energy + rate / 60.0, 0.0, energy_cap())
	if tuning.chapter_needs_enabled:
		if energy <= STORE_EPSILON:
			energy = 0.0
		collapse_due = not is_asleep and energy == 0.0
		natural_wake_due = is_asleep and energy >= energy_cap() - STORE_EPSILON
	refresh_stage()

func _step_stores(movement: StringName, work: StringName, shivering: bool) -> void:
	var water_loss := tuning.hydration_asleep if is_asleep else tuning.hydration_awake
	if movement == &"wade" or work == &"heavy":
		water_loss *= tuning.hydration_work_mult
	var was_dry := hydration <= 0.0
	hydration = _remaining(hydration - water_loss / 60.0)
	if was_dry and hydration == 0.0:
		zero_hydration_minutes += 1
	dehydration_due = hydration == 0.0 and zero_hydration_minutes == tuning.dehydration_grace_minutes
	_refresh_hydration()

	var burn := tuning.calories_asleep if is_asleep else tuning.calories_awake
	burn += maxf(tuning.calorie_activity.get(movement, 0.0), tuning.calorie_activity.get(work, 0.0))
	burn += tuning.calories_shiver if shivering else 0.0
	var was_empty := stomach_kcal <= 0.0
	var balance := stomach_kcal - burn / 60.0
	stomach_kcal = _remaining(balance)
	if balance < 0.0:
		weight_kg = maxf(tuning.weight_floor_kg, weight_kg + balance / tuning.calories_per_kg)
	if was_empty and stomach_kcal == 0.0:
		empty_minutes += 1
	_refresh_fullness()

## Adds valid hydration and resets dehydration grace. For example, [code]needs.accept_drink(3.0)[/code] restores one snow intake.
func accept_drink(amount: float) -> bool:
	if not tuning.chapter_needs_enabled or not is_finite(amount) or amount <= 0.0:
		return false
	hydration = minf(100.0, hydration + amount)
	zero_hydration_minutes = 0
	dehydration_due = false
	_refresh_hydration()
	return true

## Adds calories only if they fit. For example, commit an approved ration only if [code]needs.accept_food(400.0)[/code] succeeds.
func accept_food(kcal: float) -> bool:
	if not can_accept_food(kcal):
		return false
	stomach_kcal += kcal
	empty_minutes = 0
	_refresh_fullness()
	return true

## Checks the calorie side of a meal without mutating state; e.g. [code]needs.can_accept_food(500.0)[/code] before spending a ration.
func can_accept_food(kcal: float) -> bool:
	return tuning.chapter_needs_enabled and is_finite(kcal) and kcal > 0.0 and stomach_kcal + kcal <= _stomach_capacity_kcal

## Commits a completed handful through the Needs owner; e.g. [code]needs.accept_snow()[/code] after the minute barrier.
func accept_snow() -> bool:
	if not tuning.chapter_needs_enabled or not is_finite(tuning.snow_hydration) or tuning.snow_hydration <= 0.0 or not is_finite(tuning.snow_energy) or tuning.snow_energy < 0.0:
		return false
	energy = maxf(0.0, energy - tuning.snow_energy)
	collapse_due = not is_asleep and energy == 0.0
	accept_drink(tuning.snow_hydration)
	refresh_stage()
	return true

## Returns stomach fullness as a percentage; [code]needs.fullness()[/code] starts at 80 with chapter defaults.
func fullness() -> float:
	return 100.0 * stomach_kcal / _stomach_capacity_kcal

## Returns loss relative to starting weight; [code]needs.weight_lost_frac() * 100.0[/code] gives percentage lost.
func weight_lost_frac() -> float:
	return (_start_weight_kg - weight_kg) / _start_weight_kg

## Returns the weight-adjusted ceiling; compare [code]needs.energy >= needs.energy_cap()[/code] to check whether energy is full.
func energy_cap() -> float:
	if not tuning.chapter_needs_enabled:
		return 100.0
	return maxf(tuning.energy_cap_floor, 100.0 * (1.0 - tuning.energy_cap_loss_mult * weight_lost_frac()))

## Admits voluntary sleep for the given phase. Call [code]needs.request_sleep(true)[/code] at night before requesting the sleep rate.
func request_sleep(is_night: bool) -> bool:
	var threshold := tuning.sleep_night_threshold if is_night else tuning.sleep_day_threshold
	if not tuning.chapter_needs_enabled or is_asleep or energy >= threshold:
		return false
	is_asleep = true
	sleep_changed.emit(true, &"chosen")
	return true

## Applies proposed exhaustion only after terminal checks; [code]needs.apply_collapse(&"cold")[/code] immediately reconciles a forced wake.
func apply_collapse(wake_cause: StringName = &"") -> void:
	if not collapse_due or is_asleep:
		return
	collapse_due = false
	_collapsed = true
	is_asleep = true
	if wake_cause != &"":
		wake(wake_cause)
	else:
		sleep_changed.emit(true, &"exhaustion")

## Wakes an active sleeper once. For example, [code]needs.wake(&"interrupted")[/code] reconciles a switch to normal speed.
func wake(cause: StringName) -> bool:
	if not is_asleep:
		return false
	is_asleep = false
	natural_wake_due = false
	if _collapsed:
		energy = maxf(energy, tuning.forced_wake_energy)
		_collapsed = false
		refresh_stage()
	sleep_changed.emit(false, cause)
	return true

## Reconciles N6 energy stages with two-point rising hysteresis.
func refresh_stage() -> void:
	var old := stage
	if energy < tuning.exhausted_threshold:
		stage = &"Exhausted"
	elif stage == &"Exhausted" and energy < tuning.exhausted_threshold + tuning.needs_hysteresis:
		pass
	elif energy < tuning.tired_threshold:
		stage = &"Tired"
	elif stage != &"Rested" and energy < tuning.tired_threshold + tuning.needs_hysteresis:
		stage = &"Tired"
	else:
		stage = &"Rested"
	if stage != old:
		needs_stage_changed.emit(&"energy", stage)

## Returns the current movement multiplier.
func move_speed_mult() -> float:
	return tuning.needs_move[_stage_index()]

## Returns the current action duration multiplier.
func action_mult() -> float:
	return tuning.needs_action[_stage_index()] * (tuning.parched_action_mult if hydration_stage == &"Parched" else 1.0)

## Returns the fatigue contribution to Mishaps.
func fatigue_penalty() -> float:
	return tuning.fatigue[_stage_index()] + (tuning.parched_fatigue if hydration_stage == &"Parched" else 0.0)

## Returns detached needs values; preserves the first-night snapshot shape.
func snapshot() -> Dictionary[StringName, Variant]:
	var values: Dictionary[StringName, Variant] = {&"energy": energy, &"stage": stage}
	if tuning.chapter_needs_enabled:
		values.merge({&"stomach_kcal": stomach_kcal, &"fullness": fullness(), &"fullness_stage": fullness_stage,
			&"weight_kg": weight_kg, &"start_weight_kg": _start_weight_kg, &"weight_lost_frac": weight_lost_frac(),
			&"hydration": hydration, &"hydration_stage": hydration_stage, &"energy_cap": energy_cap(), &"is_asleep": is_asleep})
	return values

func _refresh_hydration() -> void:
	var old := hydration_stage
	if hydration <= 0.0:
		hydration_stage = &"Dehydrated"
	elif hydration < tuning.parched_threshold or (old in [&"Parched", &"Dehydrated"] and hydration < tuning.parched_threshold + tuning.needs_hysteresis):
		hydration_stage = &"Parched"
	elif hydration < tuning.thirsty_threshold or (old != &"OK" and hydration < tuning.thirsty_threshold + tuning.needs_hysteresis):
		hydration_stage = &"Thirsty"
	else:
		hydration_stage = &"OK"
	if old != hydration_stage:
		needs_stage_changed.emit(&"hydration", hydration_stage)

func _refresh_fullness() -> void:
	var old := fullness_stage
	if stomach_kcal <= 0.0:
		fullness_stage = &"Starving" if empty_minutes >= tuning.starving_minutes else &"Empty"
	elif fullness() < tuning.hungry_threshold or (old != &"Fed" and fullness() < tuning.hungry_threshold + tuning.needs_hysteresis):
		fullness_stage = &"Hungry"
	else:
		fullness_stage = &"Fed"
	if old != fullness_stage:
		needs_stage_changed.emit(&"fullness", fullness_stage)

func _remaining(balance: float) -> float:
	return balance if balance > STORE_EPSILON else 0.0

func _stage_index() -> int:
	return 2 if stage == &"Exhausted" else (1 if stage == &"Tired" else 0)
