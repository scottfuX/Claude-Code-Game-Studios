class_name ThermalField extends RefCounted

var tuning: SliceTuning
var day: int = 1
var hour: float = 13.0
var _sources: Dictionary[StringName, Dictionary] = {}
var _volumes: Dictionary[StringName, Dictionary] = {}
const BOUNDARY_EPSILON: float = 0.0001

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

## Returns effective wind including a containing insulation record.
func wind_eff(position: Vector3 = Vector3.ZERO) -> float:
	var exposure: float = tuning.exposure
	var inside := false
	for volume: Dictionary in _volumes.values():
		if contains_point(volume[&"site"], volume[&"bounds"], position):
			var override: float = volume[&"exposure"]
			exposure = minf(exposure, override) if inside else override
			inside = true
	return tuning.wind * exposure

## Tests the value volume; e.g. [code]contains_point(site, bounds, feet, true)[/code] for sleep.
static func contains_point(site: Transform3D, bounds: AABB, position: Vector3, strict_xz: bool = false) -> bool:
	if not position.is_finite():
		return false
	var local := site.inverse() * position
	var e := BOUNDARY_EPSILON
	if local.y < bounds.position.y - e or local.y > bounds.end.y + e:
		return false
	if strict_xz:
		return local.x > bounds.position.x + e and local.x < bounds.end.x - e and local.z > bounds.position.z + e and local.z < bounds.end.z - e
	return local.x >= bounds.position.x - e and local.x <= bounds.end.x + e and local.z >= bounds.position.z - e and local.z <= bounds.end.z + e

## Prepares a detached neutral-reflection record, or an empty result on rejection.
func prepare_insulation(id: StringName, revision: int, site: Transform3D, bounds: AABB, exposure: float, bonus: float) -> Dictionary:
	if id == &"" or revision < 1 or _volumes.has(id) or not site.is_finite() or not bounds.is_finite():
		return {}
	if not valid_site_geometry(site, bounds):
		return {}
	if not (exposure >= 0.0 and exposure <= 1.0 and bonus >= 0.0 and bonus <= 10.0):
		return {}
	return {&"id": id, &"revision": revision, &"site": site, &"bounds": bounds, &"exposure": exposure, &"bonus": bonus, &"heat_reflect_mult": 1.0}

## Validates an upright, unscaled authored volume shared by Thermal and plot projection.
static func valid_site_geometry(site: Transform3D, bounds: AABB) -> bool:
	return site.is_finite() and bounds.is_finite() and bounds.size.x > 0.0 and bounds.size.y > 0.0 and bounds.size.z > 0.0 and site.basis.y.is_equal_approx(Vector3.UP) and is_equal_approx(site.basis.determinant(), 1.0) and site.basis.is_equal_approx(site.basis.orthonormalized())

## Installs an immediately prepared record once, without callbacks or caller aliasing.
func apply_insulation(plan: Dictionary) -> void:
	var id: StringName = plan[&"id"]
	assert(not _volumes.has(id))
	_volumes[id] = plan.duplicate()

## Withdraws a record only if the owner revision matches.
func remove_insulation(id: StringName, revision: int) -> void:
	if _volumes.has(id) and _volumes[id][&"revision"] == revision:
		_volumes.erase(id)

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
	for id: StringName in _sources:
		var source: Dictionary = _sources[id]
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
	return air_temp_c() - minf(tuning.chill_cap, tuning.wind_chill_k * wind_eff(position)) + heat_at(position) + _shelter_bonus(position)

## Returns detached TH5 components for debugging and rule fixtures.
func components(position: Vector3) -> Dictionary[StringName, float]:
	return {&"air": air_temp_c(), &"zone": 0.0, &"wind_chill": minf(tuning.chill_cap, tuning.wind_chill_k * wind_eff(position)), &"heat": heat_at(position), &"shelter_bonus": _shelter_bonus(position)}

func _shelter_bonus(position: Vector3) -> float:
	var bonus := 0.0
	for volume: Dictionary in _volumes.values():
		if contains_point(volume[&"site"], volume[&"bounds"], position):
			bonus = maxf(bonus, volume[&"bonus"])
	return bonus
