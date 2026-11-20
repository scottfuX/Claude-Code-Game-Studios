class_name FireVisual extends Node3D

const CAMPFIRE: PackedScene = preload("res://assets/models/campfire_flat.glb")
var fire: FireController
var _model: Node3D
var _light: OmniLight3D
var _pulse_s: float = 0.0
var _glow: MeshInstance3D
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
	_glow = MeshInstance3D.new()
	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = 0.22
	glow_mesh.height = 0.10
	_glow.mesh = glow_mesh
	_glow.position.y = 0.2
	_glow.material_override = SceneAssets.material(Color("f09840"), true)
	_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_glow)

func _process(delta: float) -> void:
	if fire == null:
		return
	_pulse_s += delta
	var alive := fire.stage in [&"Kindling", &"Burning", &"Embers", &"Smoldering"]
	_model.visible = fire.stage != &"Site"
	_light.visible = alive
	_light.omni_range = fire.light_radius()
	_light.light_energy = 0.6 if fire.stage == &"Embers" else (2.0 + fire.size_factor() * 3.0)
	_glow.visible = fire.stage == &"Smoldering"
	if _glow.visible:
		var fade := fire.smolder_remaining()
		var pulse := 0.7 + 0.3 * sin(_pulse_s * TAU * fire.tuning.smolder_pulse_hz)
		_glow.scale = Vector3.ONE * fade * pulse
		_light.omni_range = 1.5
		_light.light_energy = fire.tuning.smolder_glow_energy * fade * pulse
	_flames.emitting = fire.stage in [&"Kindling", &"Burning"]
	_flames.scale = Vector3.ONE * (0.6 + 0.4 * fire.size_factor())
