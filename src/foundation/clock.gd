class_name Clock extends RefCounted

signal minute_tick
signal hour_changed(hour: int)
signal day_changed(day: int)
signal phase_changed(phase: StringName)
signal nightfall
signal sunrise
signal rate_mode_changed(mode: StringName)
signal run_day_cap_reached

var tuning: SliceTuning
var day: int = 1
var minute_of_day: int = 0
var rate_mode: StringName = &"normal"
var debt: float = 0.0
var _capped: bool = false

func _init(data: SliceTuning = null) -> void:
	tuning = data if data != null else preload("res://assets/data/slice_defaults.tres")
	day = tuning.start_day
	minute_of_day = tuning.start_minute_of_day

## Returns this day's sunrise in decimal hours.
func sunrise_hour() -> float:
	return tuning.solar_noon - maxf(tuning.daylight_min, tuning.daylight_start - tuning.daylight_shrink * (day - 1)) / 2.0

## Returns this day's sunset in decimal hours.
func sunset_hour() -> float:
	return 2.0 * tuning.solar_noon - sunrise_hour()

## Returns the current lighting phase.
func phase() -> StringName:
	var hour := minute_of_day / 60.0
	if hour < sunrise_hour() - tuning.twilight or hour >= sunset_hour() + tuning.twilight:
		return &"Night"
	if hour < sunrise_hour():
		return &"Dawn"
	if hour < sunset_hour():
		return &"Day"
	return &"Dusk"

## Returns the current real seconds per game minute.
func seconds_per_minute() -> float:
	if rate_mode == &"wait":
		return tuning.wait_seconds
	return tuning.night_seconds if phase() == &"Night" else tuning.day_seconds

## Applies a supported rate mode; sleep is outside this slice.
func request_rate_mode(mode: StringName, _reason: StringName = &"") -> void:
	if mode not in [&"normal", &"wait"] or mode == rate_mode:
		return
	rate_mode = mode
	rate_mode_changed.emit(mode)

## Accumulates only finite unpaused real delta.
func accumulate(delta_s: float, paused: bool = false) -> void:
	if not paused and is_finite(delta_s) and delta_s > 0 and not _capped:
		debt += delta_s

## Consumes one owed minute, leaving catch-up policy to the coordinator.
func consume_minute() -> bool:
	var cost := seconds_per_minute()
	if _capped or debt < cost:
		return false
	debt -= cost
	advance_minute()
	return true

## Advances exactly one minute and publishes boundary notifications.
func advance_minute() -> void:
	if _capped:
		return
	if day == 60 and minute_of_day == 1439:
		_capped = true
		run_day_cap_reached.emit()
		return
	var old_phase := phase()
	var old_hour := minute_of_day / 60
	minute_of_day += 1
	if minute_of_day == 1440:
		minute_of_day = 0
		day += 1
		day_changed.emit(day)
	if minute_of_day / 60 != old_hour:
		hour_changed.emit(minute_of_day / 60)
	if old_phase != phase():
		phase_changed.emit(phase())
		if phase() == &"Night":
			nightfall.emit()
		if old_phase == &"Dawn" and phase() == &"Day":
			sunrise.emit()
	minute_tick.emit()

## Returns detached clock values for presentation.
func snapshot() -> Dictionary[StringName, Variant]:
	return {&"day": day, &"minute_of_day": minute_of_day, &"elapsed_minutes": maxi(0, (day - tuning.start_day) * 1440 + minute_of_day - tuning.start_minute_of_day), &"phase": phase(), &"sunrise_hour": sunrise_hour(), &"sunset_hour": sunset_hour(), &"rate_mode": rate_mode}
