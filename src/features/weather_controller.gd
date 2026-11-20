class_name WeatherController extends RefCounted

signal weather_changed(weather: Dictionary[StringName, Variant])

var tuning: WeatherTuning
var state: StringName = &"Clear"
var _last_minute: int = -1
var _transition_minute: int = -1
var _snap_end: int = -1

func _init(data: WeatherTuning = null) -> void:
	tuning = data if data != null and data.is_valid() else WeatherTuning.new()

## Receives absolute game minutes, with day one's midnight at zero.
func step_minute(minute: int, rng: RunRng) -> void:
	if minute < 0 or minute <= _last_minute or rng == null:
		return
	if _last_minute < 0:
		_last_minute = minute - 1
		_transition_minute = minute + _duration(tuning.dwell_min, tuning.dwell_max, rng)
	for now in range(_last_minute + 1, minute + 1):
		var changed := false
		if _snap_end >= 0 and now >= _snap_end:
			_snap_end = -1
			changed = true
		if now >= _transition_minute:
			var roll := rng.draw_unit()
			state = tuning.next_states[state][0 if roll < tuning.transition_first_chance[state] else 1]
			_transition_minute = now + _duration(tuning.dwell_min, tuning.dwell_max, rng)
			changed = true
		if now >= 1440 and now % 1440 == tuning.snap_start_minute and rng.draw_unit() < tuning.snap_chance:
			_snap_end = now + _duration(tuning.snap_min, tuning.snap_max, rng)
			changed = true
		_last_minute = now
		if changed:
			weather_changed.emit(snapshot())

func snapshot() -> Dictionary[StringName, Variant]:
	return {&"state": state, &"wind_mps": tuning.wind_mps[state], &"snowfall_m_per_hour": tuning.snowfall_m_per_hour if state == &"Snowing" else 0.0, &"wetness_per_hour": tuning.snowfall_wetness_per_hour if state == &"Snowing" else 0.0, &"air_offset_c": tuning.snap_offset_c if _snap_end >= 0 else 0.0, &"cold_snap": _snap_end >= 0, &"transition_minute": _transition_minute, &"snap_end_minute": _snap_end}

func _duration(low: int, high: int, rng: RunRng) -> int:
	return mini(high, low + floori(rng.draw_unit() * (high - low + 1)))
