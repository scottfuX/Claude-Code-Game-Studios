class_name WorldMap extends Node3D

const PINE: PackedScene = preload("res://assets/models/pine_flat.glb")
const BARE: PackedScene = preload("res://assets/models/bare_tree_flat.glb")
const ROCK: PackedScene = preload("res://assets/models/rock_flat.glb")
const TUNING: PlayfieldTuning = preload("res://assets/data/playfield_defaults.tres")
var interactables: Array[WorldInteractable] = []
var _obstacles: Array[Vector3] = []

func _ready() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(64, 64)
	ground.mesh = plane
	ground.material_override = SceneAssets.SNOW
	add_child(ground)
	_box_collision(Vector3(0, -0.15, 0), Vector3(TUNING.half_extent * 2, 0.3, TUNING.half_extent * 2))
	for side in [-1.0, 1.0]:
		_box_collision(Vector3(side * TUNING.half_extent, 1, 0), Vector3(0.5, 3, TUNING.half_extent * 2))
		_box_collision(Vector3(0, 1, side * TUNING.half_extent), Vector3(TUNING.half_extent * 2, 3, 0.5))
	for i in 24:
		var angle := TAU * i / 24.0
		var p := Vector3(sin(angle) * (18 + i % 4), 0, cos(angle) * (18 + i % 4))
		_place(PINE if i % 3 != 0 else BARE, p, i * 1.7, 1.1 + (i % 4) * 0.15)
	for p: Vector3 in [Vector3(-7, 0, -5), Vector3(9, 0, -9), Vector3(-12, 0, 6), Vector3(12, 0, 12)]:
		_place(ROCK, p, p.x, 1.2)
	for p: Vector3 in [Vector3(-10, 0, 9), Vector3(12, 0, 8), Vector3(-11, 0, -11)]:
		_place(PINE, p, p.x, 1.3)
	var bushes: Array[Vector3] = [Vector3(0, 0, -1.6), Vector3(-4, 0, -3), Vector3(5, 0, -4), Vector3(-6, 0, 5), Vector3(7, 0, 5)]
	for p: Vector3 in bushes:
		var bush := _gather(&"bush", "TARGET_DRY_BUSH", p, TUNING.bush_sticks, TUNING.bush_bonus_grass)
		for branch in 5:
			var angle := branch * TAU / 5.0
			_stick(bush, Vector3(sin(angle) * 0.2, 0.4, cos(angle) * 0.2), Vector3(0.2, angle, 0.3), 0.85, 0.035)
	var logs: Array[Vector3] = [Vector3(2.8, 0, -2), Vector3(-4, 0, 3), Vector3(6, 0, 1), Vector3(-2, 0, -7)]
	for p: Vector3 in logs:
		var log_node := _gather(&"deadfall", "TARGET_DEADFALL", p, TUNING.deadfall_logs, 0, TUNING.deadfall_bark)
		_stick(log_node, Vector3(0, 0.2, 0), Vector3(0, 0.5, PI / 2), 2.0, 0.2)
		for branch in 3:
			_stick(log_node, Vector3(branch * 0.5 - 0.4, 0.24, 0), Vector3(0.9, 0, 0.7), 0.9, 0.04)
	for p: Vector3 in [Vector3(-2.4, 0, -1), Vector3(4, 0, 5), Vector3(0, 0, 6), Vector3(4, 0, -7)]:
		var grass := _gather(&"grass", "TARGET_DRY_GRASS", p, TUNING.grass_reserve)
		for blade in 7:
			_stick(grass, Vector3((blade % 3) * 0.1, 0.18, (blade / 3) * 0.1), Vector3(0.2, blade, 0.2), 0.4, 0.015, Color("8c805c"))

## Selects the nearest live interactable within reach and in the facing hemisphere.
func nearest(position: Vector3, facing: Vector3) -> WorldInteractable:
	var selected: WorldInteractable
	var nearest_distance := TUNING.reach
	for entry: WorldInteractable in interactables:
		if entry.gather_node != null and entry.gather_node.is_depleted():
			continue
		var offset := entry.global_position - position
		offset.y = 0
		var distance := offset.length()
		if distance <= nearest_distance and (distance < TUNING.near_reach or offset.normalized().dot(facing) > TUNING.facing_dot):
			nearest_distance = distance
			selected = entry
	return selected

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
	for obstacle: Vector3 in _obstacles:
		if Vector2(position.x - obstacle.x, position.z - obstacle.z).length() < TUNING.fire_clearance:
			return false
	for entry: WorldInteractable in interactables:
		if entry.gather_node != null and Vector2(position.x - entry.position.x, position.z - entry.position.z).length() < TUNING.resource_clearance:
			return false
	return true

func _gather(kind: StringName, label: String, p: Vector3, reserve: int, bonus: int = 0, bark: int = 0) -> WorldInteractable:
	var entry := WorldInteractable.new()
	entry.position = p
	entry.display_name = label
	entry.gather_node = GatherNode.new(kind, reserve, bonus, bark)
	add_child(entry)
	interactables.append(entry)
	return entry

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
