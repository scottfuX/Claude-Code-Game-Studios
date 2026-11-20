class_name MishapResolver extends RefCounted

var tuning: SliceTuning

func _init(data: SliceTuning = null) -> void:
	tuning = data if data != null else preload("res://assets/data/slice_defaults.tres")

## Computes M1 with the sampled material wetness.
func failure_chance(action: StringName, wind: float, cold: float, fatigue: float, wetness: float = 0.0) -> float:
	return clampf(tuning.base_fail.get(action, 0.0) + _wind_term(action, wind) + cold + fatigue + _damp_term(action, wetness), 0.0, tuning.fail_cap)

## Names the dominant physical term, with damp first in a tie.
func cause(action: StringName, wind: float, cold: float, fatigue: float, wetness: float = 0.0) -> StringName:
	var terms: Array[float] = [_damp_term(action, wetness), _wind_term(action, wind), cold, fatigue]
	var highest: float = terms.max()
	if highest < tuning.cause_min:
		return &"fumble"
	return ([&"damp", &"wind", &"cold_hands", &"fatigue"] as Array[StringName])[terms.find(highest)]

## Draws exactly once for a profiled eligible completion; unprofiled work draws none.
func resolve(action: StringName, wind: float, cold: float, fatigue: float, rng: RunRng, wetness: float = 0.0) -> Dictionary[StringName, Variant]:
	if not tuning.base_fail.has(action):
		return {&"success": true, &"cause": &"", &"p_fail": 0.0}
	var chance := failure_chance(action, wind, cold, fatigue, wetness)
	return {&"success": rng.draw_unit() >= chance, &"cause": cause(action, wind, cold, fatigue, wetness), &"p_fail": chance}

func ice_break_chance(thickness_cm: float, load_frac: float = 0.0, hurrying: bool = false) -> float:
	if not is_finite(thickness_cm) or thickness_cm < 0 or thickness_cm >= 15.0:
		return 0.0
	return 0.03 * (15.0 - thickness_cm) / 15.0 * (1.0 + 0.5 * clampf(load_frac, 0, 1)) * (2.0 if hurrying else 1.0)

func check_ice(surface: Dictionary, load_frac: float, hurrying: bool, rng: RunRng) -> bool:
	if surface.get(&"kind", &"") != &"ice":
		return false
	var chance := ice_break_chance(surface.get(&"ice_thickness_cm", 25.0), load_frac, hurrying)
	return chance > 0.0 and rng.draw_unit() < chance

func lost_tool(carried: Array[StringName], rng: RunRng) -> StringName:
	var eligible: Array[StringName] = []
	for tool: StringName in [&"hatchet", &"hatchet", &"knife", &"ferro_rod"]:
		if carried.has(tool):
			eligible.append(tool)
	if eligible.is_empty() or rng.draw_unit() >= 0.10:
		return &""
	return eligible[mini(eligible.size() - 1, floori(rng.draw_unit() * eligible.size()))]

func _damp_term(action: StringName, wetness: float) -> float:
	var scale: float = {&"strike": 0.6, &"blow_embers": 0.5, &"carve_feather_stick": 0.3}.get(action, 0.0)
	return scale * clampf(wetness, 0, 1)

func _wind_term(action: StringName, wind: float) -> float:
	return float(tuning.wind_fail.get(action, 0.0)) * maxf(0.0, wind - tuning.wind_fail_start)
