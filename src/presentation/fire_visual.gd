class_name FireVisual extends Node3D

const CAMPFIRE: PackedScene = preload("res://assets/models/campfire_flat.glb")
var fire: FireController
var _model: Node3D
var _light: OmniLight3D
var _flames: CPUParticles3D

func _ready() -> void:
	_model = CAMPFIRE.instantiate()
	add_child(_model)
	SceneAssets.apply_flat(_model)
	_light = OmniLight3D.new()
	_light.position.y = 0.7
	_light.light_color = Color(1.0, 0.40, 0.12)
	_light.shadow_enabled = true
	add_child(_light)
	_flames = CPUParticles3D.new()
	_flames.position.y = 0.25
	_flames.amount = 36
	_flames.lifetime = 0.7
	_flames.direction = Vector3.UP
	_flames.spread = 18.0
	_flames.gravity = Vector3(0, 0.4, 0)
	_flames.initial_velocity_min = 0.5
	_flames.initial_velocity_max = 1.1
	_flames.scale_amount_min = 0.04
	_flames.scale_amount_max = 0.13
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	_flames.mesh = mesh
	var material := SceneAssets.material(Color(1, 0.35, 0.04, 0.8), true)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flames.material_override = material
	add_child(_flames)

func _process(_delta: float) -> void:
	if fire == null:
		return
	var alive := fire.stage in [&"Kindling", &"Burning", &"Embers", &"Smoldering"]
	_model.visible = fire.stage != &"Site"
	_light.visible = alive
	_light.omni_range = fire.light_radius()
	_light.light_energy = 0.6 if fire.stage == &"Embers" else (2.0 + fire.size_factor() * 3.0)
	_flames.emitting = fire.stage in [&"Kindling", &"Burning"]
	_flames.scale = Vector3.ONE * (0.6 + 0.4 * fire.size_factor())
