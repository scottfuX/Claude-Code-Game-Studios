class_name HudModel extends RefCounted

var tuning: HudTuning
var fill: float = 1.0
var arrow: int = 0
var arc: float = 0.5
var moon: bool = false
var twilight: bool = false
var energy_level: int = 0
var opacity: float = 1.0
var hint_gone: bool = false
var elapsed_s: float = 0.0
var _candidate: int = 0
var _candidate_s: float = 0.0
var _calm_s: float = 0.0
var _previous_stage: StringName = &""
var _fade_from: float = 1.0
var _fade_target: float = 1.0
var _fade_s: float = 0.0
var _fade_duration: float = 0.5

func _init(data: HudTuning = null) -> void:
	tuning = data if data != null else preload("res://assets/data/hud_defaults.tres")

## Maps H1 to a finite clamped fraction; invalid samples remain detectable.
static func band_fill(core: float) -> float:
	return clampf((core - 30.0) / 7.0, 0.0, 1.0) if is_finite(core) else NAN

## Selects H2's signed single/double-arrow candidate without temporal filtering.
static func trend_arrow(rate: float) -> int:
	if not is_finite(rate) or absf(rate) < 0.1:
		return 0
	return (2 if absf(rate) >= 1.0 else 1) * (1 if rate > 0 else -1)

## Maps H5 to a left-to-right semicircle fraction, including midnight wrapping.
static func arc_progress(clock: Dictionary) -> float:
	var minute: float = clock.get(&"minute_of_day", NAN)
	var rise: float = clock.get(&"sunrise_hour", NAN)
	var setting: float = clock.get(&"sunset_hour", NAN)
	if not is_finite(minute) or not is_finite(rise) or not is_finite(setting) or setting <= rise:
		return NAN
	var hour := minute / 60.0
	if clock.get(&"phase", &"Day") != &"Night":
		return clampf((hour - rise) / (setting - rise), 0, 1)
	var nightfall: float = clock.get(&"nightfall_hour", setting + 0.75)
	var night_end: float = clock.get(&"night_end_hour", rise - 0.75)
	var length := fposmod(night_end - nightfall, 24.0)
	if length <= 0 or not is_finite(length):
		return NAN
	return clampf(fposmod(hour - nightfall, 24.0) / length, 0, 1)

## Returns a localization key, never an exact inventory count.
func quantity_key(count: int) -> StringName:
	if count <= 0:
		return &"HUD_QUANTITY_NONE"
	return &"HUD_QUANTITY_FEW" if count < tuning.plenty_threshold else &"HUD_QUANTITY_PLENTY"

## Consumes detached display state. Invalid required fields hold the last valid view.
func update(snapshot: Dictionary, delta_s: float, paused: bool = false) -> bool:
	var core: float = snapshot.get(&"core_temp_c", NAN)
	var rate: float = snapshot.get(&"rate_c_per_hour", 0.0)
	var clock: Dictionary = snapshot.get(&"clock", {})
	var next_arc := arc_progress(clock)
	if not is_finite(core) or not is_finite(rate) or not is_finite(next_arc):
		return false
	var dt := delta_s if not paused and is_finite(delta_s) and delta_s > 0 else 0.0
	elapsed_s += dt
	fill = band_fill(core)
	arc = next_arc
	moon = clock.get(&"phase", &"") == &"Night"
	twilight = clock.get(&"phase", &"") in [&"Dawn", &"Dusk"]
	var candidate := trend_arrow(rate)
	if candidate != _candidate:
		_candidate = candidate
		_candidate_s = 0.0
	_candidate_s += dt
	if _candidate_s >= tuning.trend_hold_s:
		arrow = candidate
	var energy: StringName = snapshot.get(&"energy_stage", &"")
	energy_level = 2 if energy == &"Exhausted" else (1 if energy == &"Tired" else 0)
	var stage: StringName = snapshot.get(&"body_stage", &"")
	var calm := stage == &"Warm" and candidate == 0 and energy_level == 0 and String(snapshot.get(&"prompt", "")).is_empty() and stage == _previous_stage
	_calm_s = _calm_s + dt if calm else 0.0
	_previous_stage = stage
	var target := tuning.calm_alpha if _calm_s >= tuning.calm_s else 1.0
	var fade_dt := dt
	if target != _fade_target:
		_fade_from = opacity
		_fade_target = target
		_fade_s = 0.0
		_fade_duration = tuning.fade_up_s if target > opacity else tuning.fade_down_s
		fade_dt = 0.0
	_fade_s += fade_dt
	opacity = lerpf(_fade_from, target, smoothstep(0.0, 1.0, minf(1.0, _fade_s / _fade_duration)))
	hint_gone = hint_gone or int(clock.get(&"elapsed_minutes", 0)) >= tuning.hint_minutes
	for fire: Dictionary in snapshot.get(&"fires", []):
		if fire.get(&"stage", &"") in [&"Kindling", &"Burning", &"Embers", &"Out"]:
			hint_gone = true
	return true

## Resolves visibility precedence without exposing simulation owners.
func band_opacity(context: StringName, critical: bool) -> float:
	if context == &"end":
		return 0.0
	if context in [&"sleep", &"ritual"]:
		return tuning.calm_alpha
	return 1.0 if critical else opacity
