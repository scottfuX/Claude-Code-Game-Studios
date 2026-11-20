class_name LakeSurface extends RefCounted

signal ice_broken(cell: Vector2i)

var tuning: WorldTuning
var cell_size: float
var size: Vector2i
var bounds: Rect2
var thin_cells: Dictionary[Vector2i, float] = {}
var broken_cells: Dictionary[Vector2i, bool] = {}

func _init(rng: RunRng, data: WorldTuning = null) -> void:
	tuning = data if data != null else preload("res://assets/data/world_defaults.tres")
	cell_size = tuning.ice_cell_size
	bounds = tuning.lake_bounds
	size = Vector2i(roundi(bounds.size.x / cell_size), roundi(bounds.size.y / cell_size))
	for x in size.x:
		var width_count := tuning.inlet_width_cells.y - tuning.inlet_width_cells.x + 1
		var inlet_width := tuning.inlet_width_cells.x + mini(width_count - 1, floori(rng.draw_unit() * width_count))
		for z in size.y:
			if z < inlet_width or x < tuning.thin_shore_cells:
				thin_cells[Vector2i(x, z)] = lerpf(tuning.thin_ice_cm.x, tuning.thin_ice_cm.y, rng.draw_unit())

func surface_at(p: Vector3) -> Dictionary[StringName, Variant]:
	if not p.is_finite() or not bounds.has_point(Vector2(p.x, p.z)):
		return {&"kind": &"snow", &"ice_thickness_cm": 0.0}
	var cell := Vector2i(floori((p.x - bounds.position.x) / cell_size), floori((p.z - bounds.position.y) / cell_size))
	return {&"kind": &"water" if broken_cells.has(cell) else &"ice", &"cell": cell, &"ice_thickness_cm": thin_cells.get(cell, tuning.ice_normal_cm)}

func cell_center(cell: Vector2i) -> Vector3:
	return Vector3(bounds.position.x + (cell.x + 0.5) * cell_size, 0, bounds.position.y + (cell.y + 0.5) * cell_size)

func break_ice(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y or broken_cells.has(cell):
		return false
	broken_cells[cell] = true
	ice_broken.emit(cell)
	return true

func can_traverse(from: Vector3, to: Vector3) -> bool:
	if not from.is_finite() or not to.is_finite():
		return false
	var steps := maxi(1, ceili(from.distance_to(to) / (cell_size * 0.5)))
	for i in range(1, steps + 1):
		if surface_at(from.lerp(to, float(i) / steps))[&"kind"] == &"water":
			return false
	return true

func nearest_safe_exit(p: Vector3) -> Vector3:
	var candidates: Array[Vector3] = [Vector3(bounds.position.x - tuning.shore_clearance, 0, clampf(p.z, bounds.position.y, bounds.end.y)), Vector3(bounds.end.x + tuning.shore_clearance, 0, clampf(p.z, bounds.position.y, bounds.end.y)), Vector3(clampf(p.x, bounds.position.x, bounds.end.x), 0, bounds.position.y - tuning.shore_clearance), Vector3(clampf(p.x, bounds.position.x, bounds.end.x), 0, bounds.end.y + tuning.shore_clearance)]
	var best := candidates[0]
	for candidate: Vector3 in candidates:
		if candidate.distance_squared_to(p) < best.distance_squared_to(p):
			best = candidate
	for x in size.x:
		for z in size.y:
			var cell := Vector2i(x, z)
			if thin_cells.has(cell) or broken_cells.has(cell):
				continue
			var candidate := cell_center(cell)
			if candidate.distance_squared_to(p) < best.distance_squared_to(p):
				best = candidate
	return best
