class_name BodyThermoregulation extends RefCounted

signal stage_changed(stage: StringName)
signal wake_request(cause: StringName)

const STAGES: Array[StringName] = [&"Warm", &"Chilled", &"Cold", &"Hypothermic", &"Critical"]
var tuning: SliceTuning
var core_temp_c: float = 37.0
var wetness: float = 0.0
var stage: StringName = &"Warm"
var rate_c_per_hour: float = 0.0
var _last_felt: float = NAN
var _immersions: Dictionary[int, bool] = {}

func _init(data: SliceTuning = null) -> void:
	tuning = data if data != null else preload("res://assets/data/slice_defaults.tres")

## Integrates B1 once, using pre-step shiver and max activity heat.
func step_minute(felt: float, movement: StringName = &"idle", work: StringName = &"idle", snowfall_gain: float = 0.0) -> void:
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
	var gain := tuning.body_wade_wetness_per_hour if movement == &"wade" else 0.0
	if is_finite(snowfall_gain):
		gain += clampf(snowfall_gain, 0.0, tuning.snowfall_wetness_cap)
	var drying := tuning.body_hot_drying_per_hour if felt >= tuning.body_hot_drying_threshold else (tuning.body_warm_drying_per_hour if felt >= tuning.body_warm_drying_threshold else 0.0)
	wetness = clampf(wetness + (gain - drying) / 60.0, 0.0, 1.0)
	refresh_stage()

## Applies an accepted run-local immersion event once, even after drying.
func apply_immersion(event_id: int = 0) -> void:
	if event_id < 0 or _immersions.has(event_id) or is_dead():
		return
	_immersions[event_id] = true
	wetness = 1.0

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

## Tests the forced-wake stage floor; [code]body.cold_or_worse()[/code] is true at Cold, Hypothermic and Critical.
func cold_or_worse() -> bool:
	return STAGES.find(stage) >= STAGES.find(&"Cold")

## Reports a post-step worsening during a skip; for example, [code]body.cold_wake_due(&"Chilled", true)[/code] in Cold.
func cold_wake_due(previous_stage: StringName, skipping: bool) -> bool:
	return skipping and STAGES.find(stage) > STAGES.find(previous_stage)

## Publishes Body's accepted alarm. Call [code]body.publish_cold_wake()[/code] once if cold won and the run continues.
func publish_cold_wake() -> void:
	wake_request.emit(&"cold")

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

func export_state() -> Dictionary:
	return {"core_temp_c": core_temp_c, "wetness": wetness, "stage": String(stage), "rate_c_per_hour": rate_c_per_hour, "last_felt": _last_felt if is_finite(_last_felt) else null}

func restore_state(dto: Dictionary) -> bool:
	if not CheckpointValues.keys(dto, ["core_temp_c", "wetness", "stage", "rate_c_per_hour", "last_felt"]):
		return false
	if not CheckpointValues.number(dto.core_temp_c, tuning.death_temp, tuning.max_core) or dto.core_temp_c <= tuning.death_temp or not CheckpointValues.number(dto.wetness, 0, 1) or not CheckpointValues.number(dto.rate_c_per_hour, tuning.rate_min, tuning.rate_max):
		return false
	if not CheckpointValues.text(dto.stage) or StringName(dto.stage) not in STAGES or (dto.last_felt != null and not CheckpointValues.number(dto.last_felt, -1000, 1000)):
		return false
	var staged := BodyThermoregulation.new(tuning)
	staged.core_temp_c = float(dto.core_temp_c)
	staged.stage = StringName(dto.stage)
	staged.refresh_stage()
	if staged.stage != StringName(dto.stage):
		return false
	core_temp_c = staged.core_temp_c
	stage = staged.stage
	wetness = float(dto.wetness)
	rate_c_per_hour = float(dto.rate_c_per_hour)
	_last_felt = NAN if dto.last_felt == null else float(dto.last_felt)
	return true
