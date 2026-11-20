class_name LargeMapLayout extends RefCounted

const DEFAULTS: WorldTuning = preload("res://assets/data/world_defaults.tres")
var tuning: WorldTuning
var nodes: Array[Dictionary] = []
var zones: Array[Dictionary] = []
var requested_counts: Dictionary[StringName, int] = {}
var skipped: Array[StringName] = []

func _init(rng: RunRng, data: WorldTuning = null) -> void:
	tuning = data if data != null else DEFAULTS
	_zones()
	_scatter(rng)

func zone_at(p: Vector3) -> StringName:
	var point := Vector2(p.x, p.z)
	for zone: Dictionary in zones:
		if zone[&"bounds"].has_point(point):
			return zone[&"kind"]
	return &"open"

func is_in_lake(p: Vector3) -> bool:
	return tuning.lake_bounds.has_point(Vector2(p.x, p.z))

func contains(p: Vector3) -> bool:
	return p.is_finite() and absf(p.x) <= tuning.half_extent and absf(p.z) <= tuning.half_extent

func publish_zones(thermal: ThermalField) -> void:
	for zone: Dictionary in zones:
		var rect: Rect2 = zone[&"bounds"]
		thermal.register_zone(zone[&"id"], zone[&"kind"], PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]))

func _zones() -> void:
	_zone(&"lake", &"lake", tuning.lake_bounds)
	var drift: Dictionary = tuning.zone_definitions[0]
	_zone(drift[&"id"], drift[&"kind"], drift[&"bounds"])
	for i in tuning.camps.size():
		var p := tuning.camps[i]
		var r := tuning.camp_half_size
		_zone(StringName("lee_%d" % i), &"lee", Rect2(p.x - r, p.z - r, r * 2, r * 2))
	for zone: Dictionary in tuning.zone_definitions.slice(1):
		_zone(zone[&"id"], zone[&"kind"], zone[&"bounds"])

func _zone(id: StringName, kind: StringName, rect: Rect2) -> void:
	zones.append({&"id": id, &"kind": kind, &"bounds": rect})

func _scatter(rng: RunRng) -> void:
	for ring in tuning.rings.size():
		for kind_index in tuning.kinds.size():
			var kind := tuning.kinds[kind_index]
			var count := roundi(tuning.ring_counts[kind_index][ring] * (1.0 + tuning.count_variance * (2.0 * rng.draw_unit() - 1.0)))
			requested_counts[StringName("%d_%s" % [ring, kind])] = count
	# Mandatory near-ring nodes are included in, not added to, the ring count.
	_append(&"deadfall", 0, 0, Vector3(0, 0, -_uniform(tuning.facing_deadfall_distance.x, tuning.facing_deadfall_distance.y, rng)), rng)
	_append(&"deadfall", 0, 1, Vector3(-_uniform(tuning.second_deadfall_distance.x, tuning.second_deadfall_distance.y, rng), 0, 0), rng)
	for ring in tuning.rings.size():
		for kind: StringName in tuning.kinds:
			var count: int = requested_counts[StringName("%d_%s" % [ring, kind])]
			for index in range(2 if ring == 0 and kind == &"deadfall" else 0, count):
				var accepted := false
				for retry in tuning.placement_retries:
					var p := _candidate(kind, ring, rng)
					if _valid_position(p, kind, ring):
						_append(kind, ring, index, p, rng)
						accepted = true
						break
				if not accepted:
					var id := StringName("%d_%s_%d" % [ring, kind, index])
					skipped.append(id)
					push_warning("Map placement exhausted 30 retries: %s" % id)

func _candidate(kind: StringName, ring: int, rng: RunRng) -> Vector3:
	var regions: Array[Rect2] = []
	if kind == &"birch":
		regions = tuning.birch_regions.duplicate()
	elif kind == &"stone":
		regions = tuning.stone_regions.duplicate()
		for camp: Vector3 in tuning.camps:
			var r := tuning.camp_half_size
			regions.append(Rect2(camp.x - r, camp.z - r, r * 2, r * 2))
	else:
		for zone: Dictionary in zones:
			if zone[&"kind"] in [&"forest", &"lee"]:
				regions.append(zone[&"bounds"])
		if kind == &"grass":
			regions.append(tuning.grass_shore)
	var eligible: Array[Rect2] = []
	var total := 0.0
	var outer := minf(tuning.half_extent - tuning.placement_margin, tuning.rings[ring].y)
	for region: Rect2 in regions:
		var clipped := region.intersection(Rect2(-outer, -outer, outer * 2, outer * 2))
		if not clipped.has_area():
			continue
		var nearest := Vector2(clampf(0, clipped.position.x, clipped.end.x), clampf(0, clipped.position.y, clipped.end.y))
		var farthest := Vector2(maxf(absf(clipped.position.x), absf(clipped.end.x)), maxf(absf(clipped.position.y), absf(clipped.end.y)))
		if nearest.length() >= tuning.rings[ring].y or farthest.length() < tuning.rings[ring].x:
			continue
		eligible.append(clipped)
		total += clipped.get_area()
	var choice := rng.draw_unit() * total
	var region: Rect2 = eligible.back()
	for candidate: Rect2 in eligible:
		choice -= candidate.get_area()
		if choice <= 0:
			region = candidate
			break
	return Vector3(_uniform(region.position.x, region.end.x, rng), 0, _uniform(region.position.y, region.end.y, rng))

func _valid_position(p: Vector3, kind: StringName, ring: int) -> bool:
	if not contains(p) or is_in_lake(p) or zone_at(p) == &"drift" or p.length() < tuning.rings[ring].x or p.length() >= tuning.rings[ring].y:
		return false
	for camp: Vector3 in tuning.camps:
		if p.distance_to(camp) < tuning.camp_clearance:
			return false
	for node: Dictionary in nodes:
		if p.distance_to(node[&"position"]) < maxf(tuning.spacing[kind], tuning.spacing[node[&"kind"]]):
			return false
	return true

func _append(kind: StringName, ring: int, index: int, p: Vector3, rng: RunRng) -> void:
	var primary := 0
	var grass := 0
	var bark := 0
	var sticks := 0
	match kind:
		&"bush":
			primary = _integer(tuning.primary_yields[kind].x, tuning.primary_yields[kind].y, rng)
			grass = _integer(tuning.bonus_grass_yield.x, mini(tuning.bonus_grass_yield.y, floori(primary / tuning.sticks_per_bonus_grass)), rng)
		&"deadfall":
			sticks = _integer(tuning.branch_yield.x, tuning.branch_yield.y, rng)
			primary = _integer(tuning.primary_yields[kind].x, tuning.primary_yields[kind].y, rng)
		&"birch": bark = _integer(tuning.bark_yield.x, tuning.bark_yield.y, rng)
		&"grass", &"stone": primary = _integer(tuning.primary_yields[kind].x, tuning.primary_yields[kind].y, rng)
	nodes.append({&"id": StringName("%d_%s_%d" % [ring, kind, index]), &"kind": kind, &"ring": ring, &"position": p, &"remaining": primary, &"bonus_grass": grass, &"bark_remaining": bark, &"sticks_remaining": sticks})

func _uniform(low: float, high: float, rng: RunRng) -> float:
	return lerpf(low, high, rng.draw_unit())

func _integer(low: int, high: int, rng: RunRng) -> int:
	return mini(high, low + floori(rng.draw_unit() * (high - low + 1)))
