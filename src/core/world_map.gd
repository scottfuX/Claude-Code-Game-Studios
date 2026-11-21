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
const ATMOSPHERE: AtmosphereTuning = preload("res://assets/data/atmosphere_defaults.tres")
var interactables: Array[WorldInteractable] = []
var extra_deadfalls: Array[Vector3] = []
var chapter_sites: bool = false
var _shelter_reserved: bool = false
var _obstacles: Array[Vector3] = []
var layout: LargeMapLayout
var lake_surface: LakeSurface

func surface_at(p: Vector3) -> Dictionary[StringName, Variant]:
	return lake_surface.surface_at(p) if lake_surface != null else {&"kind": &"snow", &"ice_thickness_cm": 0.0}

func break_ice(cell: Vector2i) -> bool:
	return lake_surface != null and lake_surface.break_ice(cell)

func half_extent() -> float:
	return layout.tuning.half_extent if layout != null else TUNING.half_extent_for(chapter_sites)

func zone_at(p: Vector3) -> StringName:
	return layout.zone_at(p) if layout != null else &"open"

func _ready() -> void:
	_shelter_reserved = chapter_sites
	if layout != null:
		_build_large_map()
		return
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
	return p.is_finite() and absf(p.x) < half_extent() and absf(p.z) < half_extent() and absf(p.y) < TUNING.capsule_radius and zone_at(p) != &"lake"

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
	if layout != null and (not layout.contains(position) or zone_at(position) in [&"lake", &"drift"]):
		return false
	for obstacle: Vector3 in _obstacles:
		if Vector2(position.x - obstacle.x, position.z - obstacle.z).length() < TUNING.fire_clearance:
			return false
	for entry: WorldInteractable in interactables:
		if entry.gather_node != null and Vector2(position.x - entry.position.x, position.z - entry.position.z).length() < TUNING.resource_clearance:
			return false
	return true

func _build_large_map() -> void:
	var extent := layout.tuning.half_extent
	var width := extent * 2
	_plane(Vector3.ZERO, Vector2(width, width), SceneAssets.SNOW)
	_box_collision(Vector3(0, -0.15, 0), Vector3(width, 0.3, width))
	for side in [-1.0, 1.0]:
		_box_collision(Vector3(side * extent, 1, 0), Vector3(0.5, 3, width))
		_box_collision(Vector3(0, 1, side * extent), Vector3(width, 3, 0.5))
	var lake := layout.tuning.lake_bounds
	var ice := SceneAssets.material(Color("72a9d8"))
	ice.roughness = 0.32
	ice.metallic_specular = 0.75
	_plane(Vector3(lake.get_center().x, 0.015, lake.get_center().y), lake.size, ice)
	var shore := ShaderMaterial.new()
	shore.shader = preload("res://src/presentation/spatial_env_ice_shore.gdshader")
	shore.set_shader_parameter("lake_size", lake.size)
	_plane(Vector3(lake.get_center().x, 0.01, lake.get_center().y), lake.size + Vector2(4, 4), shore)
	if lake_surface != null:
		_build_thin_ice()
	for node: Dictionary in layout.nodes:
		var kind: StringName = node[&"kind"]
		var label: String = {&"bush": "TARGET_DRY_BUSH", &"deadfall": "TARGET_DEADFALL", &"birch": "TARGET_BIRCH", &"grass": "TARGET_DRY_GRASS", &"stone": "TARGET_STONE_PILE"}[kind]
		var entry := _gather(kind, label, node[&"position"], node[&"remaining"], node[&"bonus_grass"], node[&"bark_remaining"], node[&"sticks_remaining"])
		entry.site_id = node[&"id"]
		entry.gather_node.node_id = node[&"id"]
		entry.gather_node.sticks_remaining = node[&"sticks_remaining"]
		match kind:
			&"deadfall":
				_stick(entry, Vector3(0, 0.22, 0), Vector3(0, 0.5, PI / 2), 2.4, 0.22)
			&"birch":
				_stick(entry, Vector3(0, 2.2, 0), Vector3(0.03, 0, 0.04), 4.4, 0.17, Color("ddd9ce"))
				for stripe in 5:
					_stick(entry, Vector3(0, 0.7 + stripe * 0.7, 0), Vector3.ZERO, 0.07, 0.175, Color("555b60"))
				_stick(entry, Vector3(0.5, 3.4, 0), Vector3(0, 0, -0.7), 1.8, 0.065, Color("ddd9ce"))
			&"stone":
				var rock := ROCK.instantiate() as Node3D
				rock.scale = Vector3.ONE * 0.55
				entry.add_child(rock)
				SceneAssets.apply_flat(rock)
			_:
				for branch in (5 if kind == &"bush" else 7):
					var angle := branch * TAU / 5.0
					_stick(entry, Vector3(sin(angle) * 0.2, 0.3, cos(angle) * 0.2), Vector3(0.2, angle, 0.3), 0.85 if kind == &"bush" else 0.4, 0.035 if kind == &"bush" else 0.015)
	_build_forest()
	for camp: Vector3 in layout.tuning.camps:
		_place(ROCK, camp + Vector3(-3, 0, -3), 0, 1.5)

func _build_forest() -> void:
	for zone: Dictionary in layout.zones:
		if zone[&"kind"] != &"forest":
			continue
		var rect: Rect2 = zone[&"bounds"]
		for x in ceili(rect.size.x / ATMOSPHERE.forest_spacing):
			for z in ceili(rect.size.y / ATMOSPHERE.forest_spacing):
				var key := x * 31 + z * 17
				var point := rect.position + Vector2(x + 0.5, z + 0.5) * ATMOSPHERE.forest_spacing + Vector2(sin(key), cos(key)) * ATMOSPHERE.forest_jitter
				var p := Vector3(point.x, 0, point.y)
				if not rect.has_point(point) or not layout.contains(p) or layout.is_in_lake(p) or p.length() < ATMOSPHERE.forest_clearing_radius or zone_at(p) != &"forest" or not _clear_of_nodes(p, ATMOSPHERE.forest_resource_clearance):
					continue
				var boulder := key % ATMOSPHERE.forest_boulder_stride == 0
				var bare: bool = zone[&"id"] == &"birch_stand" or key % 5 == 0
				var scene := ROCK if boulder else (BARE if bare else PINE)
				var scale_value := lerpf(ATMOSPHERE.forest_scale.x, ATMOSPHERE.forest_scale.y, absf(sin(key)))
				var instance := _place(scene, p, key, scale_value)
				instance.add_to_group(&"forest_decor")

func _clear_of_nodes(p: Vector3, clearance: float) -> bool:
	for entry: WorldInteractable in interactables:
		if entry.position.distance_to(p) < clearance:
			return false
	for camp: Vector3 in layout.tuning.camps:
		if camp.distance_to(p) < 5:
			return false
	return true

func _build_thin_ice() -> void:
	var patches := MultiMeshInstance3D.new()
	var cells := MultiMesh.new()
	cells.transform_format = MultiMesh.TRANSFORM_3D
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * lake_surface.cell_size
	cells.mesh = plane
	cells.instance_count = lake_surface.thin_cells.size()
	var index := 0
	for cell: Vector2i in lake_surface.thin_cells:
		cells.set_instance_transform(index, Transform3D(Basis.IDENTITY, lake_surface.cell_center(cell) + Vector3.UP * 0.02))
		index += 1
	patches.multimesh = cells
	var ice := SceneAssets.material(Color("7f9cb1"))
	ice.roughness = 0.45
	ice.metallic_specular = 0.6
	patches.material_override = ice
	add_child(patches)
	lake_surface.ice_broken.connect(_show_open_water)

func _show_open_water(cell: Vector2i) -> void:
	var water := SceneAssets.material(Color("243d4f"))
	water.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_plane(lake_surface.cell_center(cell) + Vector3.UP * 0.025, Vector2.ONE * lake_surface.cell_size, water)

func _plane(p: Vector3, size: Vector2, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	mesh.mesh = plane
	mesh.material_override = material
	mesh.position = p
	add_child(mesh)

func _gather(kind: StringName, label: String, p: Vector3, reserve: int, bonus: int = 0, bark: int = 0, sticks: int = 0) -> WorldInteractable:
	var entry := WorldInteractable.new()
	entry.site_id = GatherCatalog.id_for(kind, p)
	entry.position = p
	entry.display_name = label
	entry.gather_node = GatherNode.new(kind, reserve, bonus, bark, sticks)
	add_child(entry)
	interactables.append(entry)
	return entry

func _deadfall(p: Vector3) -> void:
	var log_node := _gather(&"deadfall", "TARGET_DEADFALL", p, TUNING.deadfall_logs, 0, TUNING.deadfall_bark)
	_stick(log_node, Vector3(0, 0.2, 0), Vector3(0, 0.5, PI / 2), 2.0, 0.2)
	for branch in 3:
		_stick(log_node, Vector3(branch * 0.5 - 0.4, 0.24, 0), Vector3(0.9, 0, 0.7), 0.9, 0.04)

func _place(scene: PackedScene, p: Vector3, yaw: float, scale_value: float) -> Node3D:
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
	return instance

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
