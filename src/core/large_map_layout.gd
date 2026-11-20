class_name LargeMapLayout extends RefCounted

const HALF_EXTENT := 120.0
const LAKE := Rect2(25, -35, 90, 55)
const KINDS: Array[StringName] = [&"bush", &"deadfall", &"birch", &"grass", &"stone"]
const COUNTS: Array[Vector3i] = [Vector3i(8, 20, 30), Vector3i(3, 10, 20), Vector3i(0, 6, 8), Vector3i(4, 10, 12), Vector3i(1, 3, 4)]
const SPACING: Dictionary[StringName, float] = {&"bush": 4.0, &"deadfall": 8.0, &"birch": 3.0, &"grass": 3.0, &"stone": 10.0}
const RINGS: Array[Vector2] = [Vector2(0, 40), Vector2(40, 100), Vector2(100, 170)]
const CAMPS: Array[Vector3] = [Vector3(-19, 0, -18), Vector3(17, 0, -23), Vector3(-19, 0, 24)]
var nodes: Array[Dictionary] = []
var zones: Array[Dictionary] = []
var requested_counts: Dictionary[StringName, int] = {}
var skipped: Array[StringName] = []

func _init(rng: RunRng) -> void:
	_zones()
	_scatter(rng)

func zone_at(p: Vector3) -> StringName:
	var point := Vector2(p.x, p.z)
	for zone: Dictionary in zones:
		if zone[&"bounds"].has_point(point):
			return zone[&"kind"]
	return &"open"

func is_in_lake(p: Vector3) -> bool:
	return LAKE.has_point(Vector2(p.x, p.z))

func contains(p: Vector3) -> bool:
	return p.is_finite() and absf(p.x) <= HALF_EXTENT and absf(p.z) <= HALF_EXTENT

func publish_zones(thermal: ThermalField) -> void:
	for zone: Dictionary in zones:
		var rect: Rect2 = zone[&"bounds"]
		thermal.register_zone(zone[&"id"], zone[&"kind"], PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]))

func _zones() -> void:
	_zone(&"lake", &"lake", LAKE)
	_zone(&"drifts", &"drift", Rect2(-10, 55, 30, 50))
	for i in CAMPS.size():
		var p := CAMPS[i]
		_zone(StringName("lee_%d" % i), &"lee", Rect2(p.x - 4, p.z - 4, 8, 8))
	_zone(&"pines_west", &"forest", Rect2(-115, -105, 85, 210))
	_zone(&"pines_north", &"forest", Rect2(-25, -110, 130, 60))
	_zone(&"pines_approach", &"forest", Rect2(-8, -42, 16, 22))
	_zone(&"birch_stand", &"forest", Rect2(25, 50, 90, 68))
	_zone(&"ridge", &"ridge", Rect2(-115, -119, 230, 8))

func _zone(id: StringName, kind: StringName, rect: Rect2) -> void:
	zones.append({&"id": id, &"kind": kind, &"bounds": rect})

func _scatter(rng: RunRng) -> void:
	for ring in 3:
		for kind_index in KINDS.size():
			var kind := KINDS[kind_index]
			var count := roundi(COUNTS[kind_index][ring] * (1.0 + 0.2 * (2.0 * rng.draw_unit() - 1.0)))
			requested_counts[StringName("%d_%s" % [ring, kind])] = count
	# Mandatory near-ring nodes are included in, not added to, the ring count.
	_append(&"deadfall", 0, 0, Vector3(0, 0, -_uniform(20, 30, rng)), rng)
	_append(&"deadfall", 0, 1, Vector3(-_uniform(31, 37, rng), 0, 0), rng)
	for ring in 3:
		for kind: StringName in KINDS:
			var count: int = requested_counts[StringName("%d_%s" % [ring, kind])]
			for index in range(2 if ring == 0 and kind == &"deadfall" else 0, count):
				var accepted := false
				for retry in 30:
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
		regions = [Rect2(35, 55, 75, 63)]
	elif kind == &"stone":
		regions = [Rect2(-115, -119, 230, 8), Rect2(14, -40, 10, 65), Rect2(25, 21, 90, 12)]
		for camp: Vector3 in CAMPS:
			regions.append(Rect2(camp.x - 4, camp.z - 4, 8, 8))
	else:
		for zone: Dictionary in zones:
			if zone[&"kind"] in [&"forest", &"lee"]:
				regions.append(zone[&"bounds"])
		if kind == &"grass":
			regions.append(Rect2(15, -35, 9, 55))
	var eligible: Array[Rect2] = []
	var total := 0.0
	var outer := minf(HALF_EXTENT - 1.0, RINGS[ring].y)
	for region: Rect2 in regions:
		var clipped := region.intersection(Rect2(-outer, -outer, outer * 2, outer * 2))
		if not clipped.has_area():
			continue
		var nearest := Vector2(clampf(0, clipped.position.x, clipped.end.x), clampf(0, clipped.position.y, clipped.end.y))
		var farthest := Vector2(maxf(absf(clipped.position.x), absf(clipped.end.x)), maxf(absf(clipped.position.y), absf(clipped.end.y)))
		if nearest.length() >= RINGS[ring].y or farthest.length() < RINGS[ring].x:
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
	if not contains(p) or is_in_lake(p) or zone_at(p) == &"drift" or p.length() < RINGS[ring].x or p.length() >= RINGS[ring].y:
		return false
	for camp: Vector3 in CAMPS:
		if p.distance_to(camp) < 2.0:
			return false
	for node: Dictionary in nodes:
		if p.distance_to(node[&"position"]) < maxf(SPACING[kind], SPACING[node[&"kind"]]):
			return false
	return true

func _append(kind: StringName, ring: int, index: int, p: Vector3, rng: RunRng) -> void:
	var primary := 0
	var grass := 0
	var bark := 0
	var sticks := 0
	match kind:
		&"bush":
			primary = _integer(3, 8, rng)
			grass = _integer(0, mini(2, floori(primary / 3.0)), rng)
		&"deadfall":
			sticks = _integer(3, 5, rng)
			primary = _integer(4, 8, rng)
		&"birch": bark = _integer(4, 8, rng)
		&"grass": primary = _integer(2, 4, rng)
		&"stone": primary = _integer(6, 10, rng)
	nodes.append({&"id": StringName("%d_%s_%d" % [ring, kind, index]), &"kind": kind, &"ring": ring, &"position": p, &"remaining": primary, &"bonus_grass": grass, &"bark_remaining": bark, &"sticks_remaining": sticks})

func _uniform(low: float, high: float, rng: RunRng) -> float:
	return lerpf(low, high, rng.draw_unit())

func _integer(low: int, high: int, rng: RunRng) -> int:
	return mini(high, low + floori(rng.draw_unit() * (high - low + 1)))
