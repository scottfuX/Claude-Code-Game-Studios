class_name WeatherTuning extends Resource

@export var wind_mps: Dictionary[StringName, float] = {&"Clear": 3.0, &"Windy": 7.0, &"Snowing": 4.0}
@export var dwell_min: int = 120
@export var dwell_max: int = 360
@export var snowfall_m_per_hour: float = 0.01
@export var snowfall_wetness_per_hour: float = 0.05
@export var snap_chance: float = 0.35
@export var snap_offset_c: float = -8.0
@export var snap_min: int = 360
@export var snap_max: int = 720
@export var snap_start_minute: int = 360
@export var transition_first_chance: Dictionary[StringName, float] = {&"Clear": 0.5, &"Windy": 0.4, &"Snowing": 0.5}
@export var next_states: Dictionary[StringName, Array] = {&"Clear": [&"Windy", &"Snowing"], &"Windy": [&"Clear", &"Snowing"], &"Snowing": [&"Clear", &"Windy"]}

func is_valid() -> bool:
	if dwell_min < 1 or dwell_max < dwell_min or snap_min < 1 or snap_max < snap_min:
		return false
	for state: StringName in [&"Clear", &"Windy", &"Snowing"]:
		if not transition_first_chance.has(state) or not is_finite(transition_first_chance[state]) or transition_first_chance[state] < 0 or transition_first_chance[state] > 1 or not next_states.has(state) or next_states[state].size() != 2:
			return false
		for next: StringName in next_states[state]:
			if not wind_mps.has(next):
				return false
		if not wind_mps.has(state) or not is_finite(wind_mps[state]) or wind_mps[state] < 0 or wind_mps[state] > 25:
			return false
	return is_finite(snap_chance) and snap_chance >= 0 and snap_chance <= 1 and is_finite(snap_offset_c) and snap_offset_c <= 0 and is_finite(snowfall_m_per_hour) and snowfall_m_per_hour >= 0 and is_finite(snowfall_wetness_per_hour) and snowfall_wetness_per_hour >= 0 and snowfall_wetness_per_hour <= 0.2
