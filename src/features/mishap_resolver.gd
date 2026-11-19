class_name MishapResolver extends RefCounted

var tuning: SliceTuning

func _init(data: SliceTuning = null) -> void:
	tuning = data if data != null else preload("res://assets/data/slice_defaults.tres")

## Computes slice M1 with zero damp/tinder terms.
func failure_chance(action: StringName, wind: float, cold: float, fatigue: float) -> float:
	return clampf(tuning.base_fail.get(action, 0.0) + _wind_term(action, wind) + cold + fatigue, 0.0, tuning.fail_cap)

## Names the dominant physical term, preserving wind/cold/fatigue tie order.
func cause(action: StringName, wind: float, cold: float, fatigue: float) -> StringName:
	var terms: Array[float] = [_wind_term(action, wind), cold, fatigue]
	var highest := maxf(terms[0], maxf(cold, fatigue))
	if highest < tuning.cause_min:
		return &"fumble"
	return ([&"wind", &"cold_hands", &"fatigue"] as Array[StringName])[terms.find(highest)]

## Draws exactly once for a profiled eligible completion; unprofiled work draws none.
func resolve(action: StringName, wind: float, cold: float, fatigue: float, rng: RunRng) -> Dictionary[StringName, Variant]:
	if not tuning.base_fail.has(action):
		return {&"success": true, &"cause": &"", &"p_fail": 0.0}
	var chance := failure_chance(action, wind, cold, fatigue)
	return {&"success": rng.draw_unit() >= chance, &"cause": cause(action, wind, cold, fatigue), &"p_fail": chance}

func _wind_term(action: StringName, wind: float) -> float:
	return float(tuning.wind_fail.get(action, 0.0)) * maxf(0.0, wind - tuning.wind_fail_start)
