class_name WorldMap extends Node3D

const PINE: PackedScene = preload("res://assets/models/pine_flat.glb")
const BARE: PackedScene = preload("res://assets/models/bare_tree_flat.glb")
const ROCK: PackedScene = preload("res://assets/models/rock_flat.glb")
const TUNING: PlayfieldTuning = preload("res://assets/data/playfield_defaults.tres")
const SHELTER_TRANSFORM := Transform3D(Basis.IDENTITY, Vector3(-7, 0, -2.1))
const SHELTER_BOUNDS := AABB(Vector3(-1.2, 0, -1.5), Vector3(2.4, 1.8, 1.5))
const SHELTER_APRON := Vector3(-7, 0, -0.85)
const HARE_TRAIL := Vector3(31, 0, -31)
const HARE_APPROACH := Vector3(16, 0, -7)
const HARE_STANCE := Vector3(30.3, 0, -30.3)
var interactables: Array[WorldInteractable] = []
var extra_deadfalls: Array[Vector3] = []
var chapter_sites: bool = false
var _shelter_reserved: bool = false
var _obstacles: Array[Vector3] = []

func _ready() -> void:
	var extent := half_extent()
	var ground := SnowSurface.new(extent * 2.0 + 4.0)
	add_child(ground)
	_box_collision(Vector3(0, -0.15, 0), Vector3(extent * 2, 0.3, extent * 2))
	for side in [-1.0, 1.0]:
		_box_collision(Vector3(side * extent, 1, 0), Vector3(0.5, 3, extent * 2))
		_box_collision(Vector3(0, 1, side * extent), Vector3(extent * 2, 3, 0.5))
	for i in 24:
		var angle := TAU * i / 24.0
		var p := Vector3(sin(angle) * (18 + i % 4), 0, cos(angle) * (18 + i % 4))
		_place(PINE if i % 3 != 0 else BARE, p, i * 1.7, 1.1 + (i % 4) * 0.15)
	for p: Vector3 in [Vector3(-7, 0, -5), Vector3(9, 0, -9), Vector3(-12, 0, 6), Vector3(12, 0, 12)]:
		_place(ROCK, p, p.x, 1.2)
	for p: Vector3 in [Vector3(-10, 0, 9), Vector3(12, 0, 8), Vector3(-11, 0, -11)]:
		_place(PINE, p, p.x, 1.3)
	var bushes: Array[Vector3] = GatherCatalog.BUSHES
	for p: Vector3 in bushes:
		var bush := _gather(&"bush", "TARGET_DRY_BUSH", p, TUNING.bush_sticks, TUNING.bush_bonus_grass)
		for branch in 5:
			var angle := branch * TAU / 5.0
			_stick(bush, Vector3(sin(angle) * 0.2, 0.4, cos(angle) * 0.2), Vector3(0.2, angle, 0.3), 0.85, 0.035)
	var logs: Array[Vector3] = GatherCatalog.LOGS
	for p: Vector3 in logs:
		_deadfall(p)
	for p: Vector3 in GatherCatalog.GRASS:
		var grass := _gather(&"grass", "TARGET_DRY_GRASS", p, TUNING.grass_reserve)
		for blade in 7:
			_stick(grass, Vector3((blade % 3) * 0.1, 0.18, (blade / 3) * 0.1), Vector3(0.2, blade, 0.2), 0.4, 0.015, Color("8c805c"))
	for p: Vector3 in extra_deadfalls:
		_deadfall(p)
	if chapter_sites:
		for p: Vector3 in [Vector3(32.6, 0, -28), Vector3(32.9, 0, -31), Vector3(28.5, 0, -32.8)]:
			_place(PINE, p, p.x, 1.3)
		_shelter_reserved = true

## Returns the extent of the active authored clearing.
func half_extent() -> float:
	return maxf(TUNING.half_extent, 34.0) if chapter_sites else TUNING.half_extent

## Validates a walking corridor against the same flat ground and obstacle data used by Jolt.
func clear_approach(points: PackedVector3Array) -> bool:
	for index in points.size():
		var point := points[index]
		if not is_on_snow(point):
			return false
		if index == 0:
			continue
		for obstacle: Vector3 in _obstacles:
			var nearest_point := Geometry3D.get_closest_point_to_segment(obstacle, points[index - 1], point)
			if obstacle.distance_to(nearest_point) <= TUNING.obstacle_radius + TUNING.capsule_radius:
				return false
	return points.size() > 1

## Returns the authored approach only on a valid route within the chapter's travel range.
func hare_approach(drop: Vector3) -> PackedVector3Array:
	var route := PackedVector3Array([drop, HARE_APPROACH, HARE_STANCE, HARE_TRAIL])
	var distance := drop.distance_to(HARE_APPROACH) + HARE_APPROACH.distance_to(HARE_STANCE) + HARE_STANCE.distance_to(HARE_TRAIL)
	return route if chapter_sites and distance >= 40.0 and distance <= 60.0 and clear_approach(route) else PackedVector3Array()

## Determines if a produce bundle has clear ground for placement at the player's feet.
func can_place_bundle(point: Vector3) -> bool:
	if not is_on_snow(point):
		return false
	for obstacle: Vector3 in _obstacles:
		if Vector2(point.x - obstacle.x, point.z - obstacle.z).length() <= TUNING.obstacle_radius + TUNING.capsule_radius:
			return false
	return true

## Returns the authored plot only after geometry, approach and outdoor apron checks.
func shelter_plot(drop: Vector3) -> Dictionary:
	var site := SHELTER_TRANSFORM.origin
	var center := SHELTER_TRANSFORM * SHELTER_BOUNDS.get_center()
	center.y = 0
	if not _shelter_reserved or not ThermalField.valid_site_geometry(SHELTER_TRANSFORM, SHELTER_BOUNDS) or drop.distance_to(site) + site.distance_to(center) > 15.0:
		return {}
	if not clear_approach(PackedVector3Array([drop, site, center])) or not can_place_fire(SHELTER_APRON):
		return {}
	for obstacle: Vector3 in _obstacles:
		if disc_intersects_plot(obstacle, TUNING.obstacle_radius, SHELTER_TRANSFORM, SHELTER_BOUNDS):
			return {}
	return {&"site": SHELTER_TRANSFORM, &"bounds": SHELTER_BOUNDS}

## Tests disc/rectangle intersection in plot-local XZ, including edge contact.
static func disc_intersects_plot(point: Vector3, radius: float, transform_value: Transform3D, bounds: AABB) -> bool:
	if not point.is_finite() or not is_finite(radius) or radius <= 0.0 or not ThermalField.valid_site_geometry(transform_value, bounds):
		return true
	var local := transform_value.inverse() * point
	var clamped := Vector2(clampf(local.x, bounds.position.x, bounds.end.x), clampf(local.z, bounds.position.z, bounds.end.z))
	return Vector2(local.x, local.z).distance_to(clamped) <= radius + ThermalField.BOUNDARY_EPSILON

## Checks the snow plane at the player's feet, e.g. [code]world.is_on_snow(survivor.global_position)[/code].
func is_on_snow(feet: Vector3) -> bool:
	var p := to_local(feet)
	return p.is_finite() and absf(p.x) < half_extent() and absf(p.z) < half_extent() and absf(p.y) < TUNING.capsule_radius

## Selects the nearest live interactable within reach and in the facing hemisphere.
func nearest(position: Vector3, facing: Vector3) -> WorldInteractable:
	var selected: WorldInteractable
	var nearest_distance := TUNING.reach
	for entry: WorldInteractable in interactables:
		if entry.gather_node != null and entry.gather_node.is_depleted():
			continue
		if entry.chapter_target and not within_chapter_reach(position, facing, entry.global_position):
			continue
		var offset := entry.global_position - position
		offset.y = 0
		var distance := offset.length()
		if distance <= nearest_distance and (distance < TUNING.near_reach or offset.normalized().dot(facing) > TUNING.facing_dot):
			nearest_distance = distance
			selected = entry
	return selected

## IA2 reach and facing used by authored Chapter 2 interactions.
static func within_chapter_reach(position: Vector3, facing: Vector3, anchor: Vector3) -> bool:
	var offset := anchor - position
	offset.y = 0
	var distance := offset.length()
	return distance <= 1.5 and (is_zero_approx(distance) or offset.normalized().dot(facing) >= cos(deg_to_rad(50.0)))

## Registers data without model or visual ownership; e.g. add_site(&"camp", Vector3.ZERO, "Camp").
func add_site(site_id: StringName, position: Vector3, label: String) -> WorldInteractable:
	if site_id == &"" or not position.is_finite():
		return null
	var entry := WorldInteractable.new()
	entry.site_id = site_id
	entry.display_name = label
	entry.position = position
	add_child(entry)
	interactables.append(entry)
	return entry

## Rejects occupied ground while leaving authoritative site limits to the simulation.
func can_place_fire(position: Vector3) -> bool:
	var footprint := TUNING.fire_placement_radius
	if _shelter_reserved and disc_intersects_plot(position, footprint, SHELTER_TRANSFORM, SHELTER_BOUNDS):
		return false
	if chapter_sites and (not is_on_snow(position) or position.distance_to(HARE_TRAIL) <= footprint + TUNING.resource_clearance):
		return false
	for obstacle: Vector3 in _obstacles:
		if Vector2(position.x - obstacle.x, position.z - obstacle.z).length() < TUNING.fire_clearance:
			return false
	for entry: WorldInteractable in interactables:
		if entry.gather_node != null and Vector2(position.x - entry.position.x, position.z - entry.position.z).length() < TUNING.resource_clearance:
			return false
	return true

func _gather(kind: StringName, label: String, p: Vector3, reserve: int, bonus: int = 0, bark: int = 0) -> WorldInteractable:
	var entry := WorldInteractable.new()
	entry.site_id = GatherCatalog.id_for(kind, p)
	entry.position = p
	entry.display_name = label
	entry.gather_node = GatherNode.new(kind, reserve, bonus, bark)
	add_child(entry)
	interactables.append(entry)
	return entry

func _deadfall(p: Vector3) -> void:
	var log_node := _gather(&"deadfall", "TARGET_DEADFALL", p, TUNING.deadfall_logs, 0, TUNING.deadfall_bark)
	_stick(log_node, Vector3(0, 0.2, 0), Vector3(0, 0.5, PI / 2), 2.0, 0.2)
	for branch in 3:
		_stick(log_node, Vector3(branch * 0.5 - 0.4, 0.24, 0), Vector3(0.9, 0, 0.7), 0.9, 0.04)

func _place(scene: PackedScene, p: Vector3, yaw: float, scale_value: float) -> void:
	var instance := scene.instantiate() as Node3D
	instance.position = p
	instance.rotation.y = yaw
	instance.scale = Vector3.ONE * scale_value
	add_child(instance)
	SceneAssets.apply_flat(instance)
	_obstacles.append(p)
	var body := StaticBody3D.new()
	body.position = p + Vector3.UP * TUNING.obstacle_radius
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = TUNING.obstacle_radius
	collision.shape = sphere
	body.add_child(collision)
	add_child(body)

func _box_collision(p: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = p
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)

func _stick(parent: Node3D, p: Vector3, rotation_value: Vector3, height: float, radius: float, color: Color = Color("6b4a3a")) -> void:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.height = height
	cylinder.top_radius = radius * 0.7
	cylinder.bottom_radius = radius
	cylinder.radial_segments = 5
	mesh.mesh = cylinder
	if radius < 0.1:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.material_override = SceneAssets.material(color)
	mesh.position = p
	mesh.rotation = rotation_value
	parent.add_child(mesh)
