class_name BodyThermoregulation extends RefCounted

signal stage_changed(stage: StringName)

const STAGES: Array[StringName] = [&"Warm", &"Chilled", &"Cold", &"Hypothermic", &"Critical"]
var tuning: SliceTuning
var core_temp_c: float = 37.0
var wetness: float = 0.0
var stage: StringName = &"Warm"
var rate_c_per_hour: float = 0.0
var _last_felt: float = NAN

func _init(data: SliceTuning = null) -> void:
	tuning = data if data != null else preload("res://assets/data/slice_defaults.tres")

## Integrates B1 once, using pre-step shiver and max activity heat.
func step_minute(felt: float, movement: StringName = &"idle", work: StringName = &"idle") -> void:
	if not is_finite(felt):
		felt = _last_felt
	if not is_finite(felt) or is_dead():
		return
	_last_felt = felt
	var gap := felt - tuning.neutral
	var exchange := tuning.cooling * gap * (1.0 + tuning.wet_loss * wetness) / tuning.insulation if gap < 0 else tuning.warming * gap
	var activity := maxf(tuning.body_heat.get(movement, 0.0), tuning.body_heat.get(work, 0.0))
	rate_c_per_hour = clampf(exchange + activity + (tuning.shiver_heat if is_shivering() else 0.0), tuning.rate_min, tuning.rate_max)
	if core_temp_c >= tuning.max_core and rate_c_per_hour > 0:
		rate_c_per_hour = 0.0
	core_temp_c = clampf(core_temp_c + rate_c_per_hour / 60.0, tuning.death_temp, tuning.max_core)
	refresh_stage()

## Reconciles falling thresholds and rising hysteresis.
func refresh_stage() -> void:
	var index := STAGES.find(stage)
	var previous := stage
	while index < STAGES.size() - 1 and core_temp_c < tuning.body_thresholds[index]:
		index += 1
	while index > 0 and core_temp_c >= tuning.body_thresholds[index - 1] + tuning.body_hysteresis:
		index -= 1
	stage = STAGES[index]
	if stage != previous:
		stage_changed.emit(stage)

## Reports whether the terminal cold threshold has been reached.
func is_dead() -> bool:
	return core_temp_c <= tuning.death_temp

## Reports post-step shivering for Needs.
func is_shivering() -> bool:
	return stage in [&"Chilled", &"Cold"]

## Returns the movement multiplier, including Critical's separate crawl contract.
func move_speed_mult() -> float:
	return tuning.body_move[STAGES.find(stage)]

## Returns the current action duration multiplier.
func action_mult() -> float:
	return tuning.body_action[STAGES.find(stage)]

## Returns the Mishaps cold-hands penalty.
func cold_hands_penalty() -> float:
	return tuning.cold_hands[STAGES.find(stage)]

## Returns detached physiology values for presentation.
func snapshot() -> Dictionary[StringName, Variant]:
	return {&"core_temp_c": core_temp_c, &"wetness": wetness, &"stage": stage, &"is_shivering": is_shivering(), &"rate_c_per_hour": rate_c_per_hour}
