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
var sunrise_this_minute: bool = false
var _capped: bool = false
var _dispatching: bool = false
var _requested_mode: StringName = &""

const MODE_PRIORITY := {&"": 0, &"wait": 1, &"sleep": 2, &"normal": 3}
const DEBT_EPSILON: float = 0.000000001

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
	if rate_mode == &"sleep":
		return tuning.sleep_seconds
	if rate_mode == &"wait":
		return tuning.wait_seconds
	return tuning.night_seconds if phase() == &"Night" else tuning.day_seconds

## Queues requests during the minute barrier; idle clock requests apply immediately.
func request_rate_mode(mode: StringName, _reason: StringName = &"") -> void:
	if mode == &"" or not MODE_PRIORITY.has(mode) or (mode == &"wait" and rate_mode == &"sleep"):
		return
	if _dispatching:
		if MODE_PRIORITY[mode] > MODE_PRIORITY[_requested_mode]:
			_requested_mode = mode
	else:
		_apply_mode(mode)

func _apply_mode(mode: StringName) -> void:
	if mode == &"" or mode == rate_mode:
		return
	rate_mode = mode
	rate_mode_changed.emit(mode)

func normal_requested() -> bool:
	return _requested_mode == &"normal"

## Accumulates only finite unpaused real delta.
func accumulate(delta_s: float, paused: bool = false) -> void:
	if not paused and is_finite(delta_s) and delta_s > 0 and not _capped:
		debt += delta_s

## Reports whether another minute is owed at the current rate.
func minute_owed() -> bool:
	return not _capped and debt + DEBT_EPSILON >= seconds_per_minute()

## Consumes one owed minute, leaving catch-up policy to the coordinator.
func consume_minute(integrate: Callable = Callable()) -> bool:
	var cost := seconds_per_minute()
	if not minute_owed() or _dispatching:
		return false
	if day == 60 and minute_of_day == 1439:
		return advance_minute()
	debt = maxf(0.0, debt - cost)
	return advance_minute(integrate)

## Advances exactly one minute and publishes boundary notifications.
func advance_minute(integrate: Callable = Callable()) -> bool:
	if _capped or _dispatching:
		return false
	if day == 60 and minute_of_day == 1439:
		_capped = true
		run_day_cap_reached.emit()
		return false
	_dispatching = true
	sunrise_this_minute = false
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
			sunrise_this_minute = true
			sunrise.emit()
	minute_tick.emit()
	if integrate.is_valid():
		integrate.call()
	var next_mode := _requested_mode
	_requested_mode = &""
	_dispatching = false
	_apply_mode(next_mode)
	return true

## Returns detached clock values for presentation.
func snapshot() -> Dictionary[StringName, Variant]:
	return {&"day": day, &"minute_of_day": minute_of_day, &"elapsed_minutes": maxi(0, (day - tuning.start_day) * 1440 + minute_of_day - tuning.start_minute_of_day), &"phase": phase(), &"sunrise_hour": sunrise_hour(), &"sunset_hour": sunset_hour(), &"rate_mode": rate_mode}
