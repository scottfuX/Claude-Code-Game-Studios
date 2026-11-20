class_name LakeSurface extends RefCounted

signal ice_broken(cell: Vector2i)

const CELL_SIZE := 0.5
const SIZE := Vector2i(180, 110)
const BOUNDS := LargeMapLayout.LAKE
var thin_cells: Dictionary[Vector2i, float] = {}
var broken_cells: Dictionary[Vector2i, bool] = {}

func _init(rng: RunRng) -> void:
	for x in SIZE.x:
		var inlet_width := 10 + mini(4, floori(rng.draw_unit() * 5))
		for z in SIZE.y:
			if z < inlet_width or x < 8:
				thin_cells[Vector2i(x, z)] = 5.0 + 5.0 * rng.draw_unit()

func surface_at(p: Vector3) -> Dictionary[StringName, Variant]:
	if not p.is_finite() or not BOUNDS.has_point(Vector2(p.x, p.z)):
		return {&"kind": &"snow", &"ice_thickness_cm": 0.0}
	var cell := Vector2i(floori((p.x - BOUNDS.position.x) / CELL_SIZE), floori((p.z - BOUNDS.position.y) / CELL_SIZE))
	return {&"kind": &"water" if broken_cells.has(cell) else &"ice", &"cell": cell, &"ice_thickness_cm": thin_cells.get(cell, 25.0)}

func cell_center(cell: Vector2i) -> Vector3:
	return Vector3(BOUNDS.position.x + (cell.x + 0.5) * CELL_SIZE, 0, BOUNDS.position.y + (cell.y + 0.5) * CELL_SIZE)

func break_ice(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= SIZE.x or cell.y >= SIZE.y or broken_cells.has(cell):
		return false
	broken_cells[cell] = true
	ice_broken.emit(cell)
	return true

func can_traverse(from: Vector3, to: Vector3) -> bool:
	if not from.is_finite() or not to.is_finite():
		return false
	var steps := maxi(1, ceili(from.distance_to(to) / (CELL_SIZE * 0.5)))
	for i in range(1, steps + 1):
		if surface_at(from.lerp(to, float(i) / steps))[&"kind"] == &"water":
			return false
	return true

func nearest_safe_exit(p: Vector3) -> Vector3:
	var candidates: Array[Vector3] = [Vector3(BOUNDS.position.x - 0.6, 0, clampf(p.z, BOUNDS.position.y, BOUNDS.end.y)), Vector3(BOUNDS.end.x + 0.6, 0, clampf(p.z, BOUNDS.position.y, BOUNDS.end.y)), Vector3(clampf(p.x, BOUNDS.position.x, BOUNDS.end.x), 0, BOUNDS.position.y - 0.6), Vector3(clampf(p.x, BOUNDS.position.x, BOUNDS.end.x), 0, BOUNDS.end.y + 0.6)]
	var best := candidates[0]
	for candidate: Vector3 in candidates:
		if candidate.distance_squared_to(p) < best.distance_squared_to(p):
			best = candidate
	for x in SIZE.x:
		for z in SIZE.y:
			var cell := Vector2i(x, z)
			if thin_cells.has(cell) or broken_cells.has(cell):
				continue
			var candidate := cell_center(cell)
			if candidate.distance_squared_to(p) < best.distance_squared_to(p):
				best = candidate
	return best
