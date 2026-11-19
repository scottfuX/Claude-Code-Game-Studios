class_name NeedsModel extends RefCounted

signal needs_stage_changed(need: StringName, stage: StringName)

var tuning: SliceTuning
var energy: float = 90.0
var stage: StringName = &"Rested"

func _init(data: SliceTuning = null) -> void:
	tuning = data if data != null else preload("res://assets/data/slice_defaults.tres")
	energy = tuning.energy_start

## Integrates energy only; sleep/food/hydration are deferred by slice decision.
func step_minute(movement: StringName = &"idle", shivering: bool = false, resting_at_fire: bool = false, work: StringName = &"idle") -> void:
	var drain := maxf(tuning.energy_drain.get(movement, 1.0), tuning.energy_drain.get(work, 1.0))
	var rate := tuning.rest_energy if resting_at_fire else -(drain + (tuning.shiver_energy if shivering else 0.0))
	energy = clampf(energy + rate / 60.0, 0.0, 100.0)
	refresh_stage()

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
	return tuning.needs_action[_stage_index()]

## Returns the fatigue contribution to Mishaps.
func fatigue_penalty() -> float:
	return tuning.fatigue[_stage_index()]

## Returns detached energy values, without deferred needs.
func snapshot() -> Dictionary[StringName, Variant]:
	return {&"energy": energy, &"stage": stage}

func _stage_index() -> int:
	return 2 if stage == &"Exhausted" else (1 if stage == &"Tired" else 0)
