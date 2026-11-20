class_name SnowSurface extends MeshInstance3D

var deformation := SnowDeformation.new()
var _survivor: SurvivorController
var _last_press := Vector3.INF
var _cleared_fires: Dictionary = {}

func _ready() -> void:
	name = "SnowSurface"
	var plane := PlaneMesh.new()
	plane.size = Vector2(64, 64)
	plane.subdivide_width = 255
	plane.subdivide_depth = 255
	mesh = plane
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = preload("res://src/presentation/spatial_deep_snow.gdshader")
	material.set_shader_parameter("trail_map", deformation.texture)
	material_override = material
	custom_aabb = AABB(Vector3(-32, -0.1, -32), Vector3(64, 1, 64))
	_initialize_contacts.call_deferred()

func _initialize_contacts() -> void:
	_survivor = get_parent().get_parent().get_node_or_null("Survivor") as SurvivorController
	if _survivor != null:
		_survivor.snow = self
	for child: Node in get_parent().get_children():
		if child == self or not child is Node3D:
			continue
		if child is WorldInteractable or child is StaticBody3D or child is Node3D and child.get_child_count() > 0:
			var p := (child as Node3D).global_position
			if Vector2(p.x, p.z).length() > 0.1:
				deformation.clear(p, 0.85)

func _physics_process(_delta: float) -> void:
	if _survivor == null or _survivor.simulation == null or _survivor.frozen:
		return
	var sim := _survivor.simulation
	var p := _survivor.global_position
	var working := sim.actions.action != &""
	if working or not _last_press.is_finite() or p.distance_to(_last_press) > 0.07:
		deformation.press(p, 0.48 if working else 0.30, 0.95 if working else 0.72)
		_last_press = p
	for fire: FireController in sim.fires:
		if not _cleared_fires.has(fire):
			deformation.clear(fire.position, 1.3)
			_cleared_fires[fire] = true
	if sim.actions.action == &"clear_snow":
		deformation.clear(p + _survivor.facing * 0.7, 1.1)

func _process(delta: float) -> void:
	deformation.upload(delta)
