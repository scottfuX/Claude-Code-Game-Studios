class_name MishapResolver extends RefCounted

var tuning: SliceTuning
var _fumbles: Dictionary[StringName, int] = {}
const PROFILES: Dictionary[StringName, Array] = {
	&"strike": [&"minor", &"helplessness"],
	&"blow_embers": [&"moderate", &"disappointment"],
	&"chop_log": [&"minor", &"helplessness"],
	&"strip_bark": [&"minor", &"disappointment"],
	&"gather_sticks": [&"minor", &"disappointment"]
}

func _init(data: SliceTuning = null) -> void:
	tuning = data if data != null else preload("res://assets/data/slice_defaults.tres")

## Computes M1 with the sampled material wetness.
func failure_chance(action: StringName, wind: float, cold: float, fatigue: float, wetness: float = 0.0, quality: float = 1.0, morale: float = 0.0) -> float:
	if not PROFILES.has(action):
		return 0.0
	return clampf(tuning.base_fail.get(action, 0.0) + _wind_term(action, wind) + cold + fatigue + _damp_term(action, wetness) + _tinder_term(action, quality) + morale, 0.0, tuning.fail_cap)

## Names the dominant physical term, with damp first in a tie.
func cause(action: StringName, wind: float, cold: float, fatigue: float, wetness: float = 0.0, quality: float = 1.0) -> StringName:
	if not PROFILES.has(action):
		return &""
	var terms: Array[float] = [_damp_term(action, wetness), _wind_term(action, wind), cold, fatigue, _tinder_term(action, quality)]
	var highest: float = terms.max()
	if highest < tuning.cause_min:
		return &"fumble"
	return ([&"damp", &"wind", &"cold_hands", &"fatigue", &"tinder"] as Array[StringName])[terms.find(highest)]

## Draws exactly once for a profiled eligible completion; unprofiled work draws none.
func resolve(action: StringName, wind: float, cold: float, fatigue: float, rng: RunRng, wetness: float = 0.0, quality: float = 1.0, morale: float = 0.0) -> Dictionary[StringName, Variant]:
	if not PROFILES.has(action):
		return {&"success": true, &"cause": &"", &"p_fail": 0.0}
	var chance := failure_chance(action, wind, cold, fatigue, wetness, quality, morale)
	var physical_cause := cause(action, wind, cold, fatigue, wetness, quality)
	var guarded: bool = _fumbles.get(action, 0) >= 4 and physical_cause == &"fumble"
	if guarded:
		chance *= 0.5
	var success := rng.draw_unit() >= chance
	_fumbles[action] = _fumbles.get(action, 0) + 1 if not guarded and not success and physical_cause == &"fumble" else 0
	return {&"success": success, &"cause": physical_cause, &"p_fail": chance, &"severity": PROFILES[action][0], &"tag": PROFILES[action][1], &"base_fail_chance": tuning.base_fail[action]}

func _tinder_term(action: StringName, quality: float) -> float:
	return 0.4 * (1.0 - clampf(quality, 0, 1)) if action == &"strike" else 0.0

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
