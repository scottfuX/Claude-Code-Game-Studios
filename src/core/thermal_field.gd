class_name ThermalField extends RefCounted

var tuning: SliceTuning
var day: int = 1
var hour: float = 13.0
var _sources: Dictionary[StringName, Dictionary] = {}

func _init(data: SliceTuning = null) -> void:
	tuning = data if data != null else preload("res://assets/data/slice_defaults.tres")

## Captures this minute's clock inputs before Fire publication.
func begin_minute(new_day: int, new_hour: float) -> void:
	day = new_day
	hour = new_hour

## Marks the synchronous source-publication barrier.
func seal_sources(_minute_sequence: int = 0) -> void:
	pass

## Returns TH1-TH2 air temperature in the open zone.
func air_temp_c() -> float:
	return maxf(tuning.air_floor, tuning.air_start - tuning.air_ramp * (day - 1)) + tuning.air_swing * cos(TAU * (hour - tuning.solar_noon - tuning.peak_lag) / 24.0)

## Returns effective open-zone wind.
func wind_eff(_position: Vector3 = Vector3.ZERO) -> float:
	return tuning.wind * tuning.exposure

## Registers a unique valid source; rejected records contribute nothing.
func register_heat_source(id: StringName, position: Vector3, heat: float, radius: float, enabled: bool = true) -> bool:
	if _sources.has(id):
		return false
	return update_heat_source(id, position, heat, radius, enabled)

## Publishes an exact source record synchronously.
func update_heat_source(id: StringName, position: Vector3, heat: float, radius: float, enabled: bool = true) -> bool:
	if id == &"" or not position.is_finite() or not is_finite(heat) or not is_finite(radius) or radius <= 0 or heat < 0:
		return false
	_sources[id] = {&"position": position, &"heat": heat, &"radius": radius, &"enabled": enabled}
	return true

## Removes a source harmlessly if already absent.
func unregister_heat_source(id: StringName) -> void:
	_sources.erase(id)

## Returns TH4 summed/capped horizontal heat at a point.
func heat_at(position: Vector3) -> float:
	var total := 0.0
	for source: Dictionary in _sources.values():
		if not source[&"enabled"]:
			continue
		var offset: Vector3 = position - source[&"position"]
		var distance_squared := offset.x * offset.x + offset.z * offset.z
		var radius: float = source[&"radius"]
		if distance_squared < radius * radius:
			total += float(source[&"heat"]) * (1.0 - distance_squared / (radius * radius))
	return minf(tuning.heat_cap, total)

## Returns TH5 felt temperature without per-point mutable state.
func effective_temp_c(position: Vector3) -> float:
	return air_temp_c() - minf(tuning.chill_cap, tuning.wind_chill_k * wind_eff(position)) + heat_at(position)

## Returns detached TH5 components for debugging and rule fixtures.
func components(position: Vector3) -> Dictionary[StringName, float]:
	return {&"air": air_temp_c(), &"zone": 0.0, &"wind_chill": minf(tuning.chill_cap, tuning.wind_chill_k * wind_eff(position)), &"heat": heat_at(position), &"shelter_bonus": 0.0}
