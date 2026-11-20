class_name MishapResolver extends RefCounted

var tuning: SliceTuning
var _fumbles: Dictionary[StringName, int] = {}

func _init(data: SliceTuning = null) -> void:
	tuning = data if data != null else preload("res://assets/data/slice_defaults.tres")

## Computes M1 with the sampled material wetness.
func failure_chance(action: StringName, wind: float, cold: float, fatigue: float, wetness: float = 0.0, quality: float = 1.0, morale: float = 0.0) -> float:
	if not tuning.mishap_tags.has(action) or not tuning.base_fail.has(action):
		return 0.0
	return clampf(tuning.base_fail.get(action, 0.0) + _wind_term(action, wind) + cold + fatigue + _damp_term(action, wetness) + _tinder_term(action, quality) + morale, 0.0, tuning.fail_cap)

## Names the dominant physical term, with damp first in a tie.
func cause(action: StringName, wind: float, cold: float, fatigue: float, wetness: float = 0.0, quality: float = 1.0) -> StringName:
	if not tuning.mishap_tags.has(action) or not tuning.base_fail.has(action):
		return &""
	var terms: Array[float] = [_damp_term(action, wetness), _wind_term(action, wind), cold, fatigue, _tinder_term(action, quality)]
	var highest: float = terms.max()
	if highest < tuning.cause_min:
		return &"fumble"
	return ([&"damp", &"wind", &"cold_hands", &"fatigue", &"tinder"] as Array[StringName])[terms.find(highest)]

## Draws exactly once for a profiled eligible completion; unprofiled work draws none.
func resolve(action: StringName, wind: float, cold: float, fatigue: float, rng: RunRng, wetness: float = 0.0, quality: float = 1.0, morale: float = 0.0) -> Dictionary[StringName, Variant]:
	if not tuning.mishap_tags.has(action) or not tuning.base_fail.has(action):
		return {&"success": true, &"cause": &"", &"p_fail": 0.0}
	var chance := failure_chance(action, wind, cold, fatigue, wetness, quality, morale)
	var physical_cause := cause(action, wind, cold, fatigue, wetness, quality)
	var guarded: bool = _fumbles.get(action, 0) >= tuning.fumble_streak and physical_cause == &"fumble"
	if guarded:
		chance *= tuning.fumble_multiplier
	var success := rng.draw_unit() >= chance
	_fumbles[action] = _fumbles.get(action, 0) + 1 if not guarded and not success and physical_cause == &"fumble" else 0
	return {&"success": success, &"cause": physical_cause, &"p_fail": chance, &"severity": tuning.mishap_severity[action], &"tag": tuning.mishap_tags[action], &"base_fail_chance": tuning.base_fail[action]}

func _tinder_term(action: StringName, quality: float) -> float:
	return tuning.tinder_fail.get(action, 0.0) * (1.0 - clampf(quality, 0, 1))

func ice_break_chance(thickness_cm: float, load_frac: float = 0.0, hurrying: bool = false) -> float:
	if not is_finite(thickness_cm) or thickness_cm < 0 or thickness_cm >= tuning.world.ice_safe_cm:
		return 0.0
	return tuning.world.ice_break_k * (tuning.world.ice_safe_cm - thickness_cm) / tuning.world.ice_safe_cm * (1.0 + tuning.world.ice_load_k * clampf(load_frac, 0, 1)) * (tuning.world.ice_hurry_k if hurrying else 1.0)

func check_ice(surface: Dictionary, load_frac: float, hurrying: bool, rng: RunRng) -> bool:
	if surface.get(&"kind", &"") != &"ice":
		return false
	var chance := ice_break_chance(surface.get(&"ice_thickness_cm", tuning.world.ice_normal_cm), load_frac, hurrying)
	return chance > 0.0 and rng.draw_unit() < chance

func lost_tool(carried: Array[StringName], rng: RunRng) -> StringName:
	var eligible: Array[StringName] = []
	for tool: StringName in tuning.world.tool_loss_weights:
		if carried.has(tool):
			for weight in tuning.world.tool_loss_weights[tool]:
				eligible.append(tool)
	if eligible.is_empty() or rng.draw_unit() >= tuning.world.tool_loss_chance:
		return &""
	return eligible[mini(eligible.size() - 1, floori(rng.draw_unit() * eligible.size()))]

func _damp_term(action: StringName, wetness: float) -> float:
	var scale: float = tuning.damp_fail.get(action, 0.0)
	return scale * clampf(wetness, 0, 1)

func _wind_term(action: StringName, wind: float) -> float:
	return float(tuning.wind_fail.get(action, 0.0)) * maxf(0.0, wind - tuning.wind_fail_start)
