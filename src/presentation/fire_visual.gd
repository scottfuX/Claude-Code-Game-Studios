class_name FireVisual extends Node3D

const CAMPFIRE: PackedScene = preload("res://assets/models/campfire_flat.glb")
const SPARK_STAGES: Array[StringName] = [&"Kindling", &"Burning", &"Embers"]
const SMOKE_STAGES: Array[StringName] = [&"Kindling", &"Burning", &"Smoldering"]
const LIGHT_STAGES: Array[StringName] = [&"Kindling", &"Burning", &"Embers", &"Smoldering"]
const FLAME_STAGES: Array[StringName] = [&"Kindling", &"Burning"]
var fire: FireController
const ATMOSPHERE: AtmosphereTuning = preload("res://assets/data/atmosphere_defaults.tres")
var _sparks: CPUParticles3D
var _smoke: CPUParticles3D
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
	_sparks = _particles(false)
	_smoke = _particles(true)

func _process(delta: float) -> void:
	if fire == null:
		return
	_pulse_s += delta
	_sparks.emitting = fire.stage in SPARK_STAGES
	_smoke.emitting = fire.stage in SMOKE_STAGES
	var alive := fire.stage in LIGHT_STAGES
	_model.visible = fire.stage != &"Site"
	_light.visible = alive
	_light.omni_range = fire.light_radius()
	_light.light_energy = 0.6 if fire.stage == &"Embers" else (2.0 + fire.size_factor() * 3.0)
	_light.light_energy *= 1.0 + ATMOSPHERE.fire_flicker * sin(_pulse_s * 17.0) * sin(_pulse_s * 7.0)
	_glow.visible = fire.stage == &"Smoldering"
	if _glow.visible:
		var fade := fire.smolder_remaining()
		var pulse := 0.7 + 0.3 * sin(_pulse_s * TAU * fire.tuning.smolder_pulse_hz)
		_glow.scale = Vector3.ONE * fade * pulse
		_light.omni_range = 1.5
		_light.light_energy = fire.tuning.smolder_glow_energy * fade * pulse
	_flames.emitting = fire.stage in FLAME_STAGES
	_flames.scale = Vector3.ONE * (0.6 + 0.4 * fire.size_factor())

func _particles(smoke: bool) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.amount = ATMOSPHERE.smoke_count if smoke else ATMOSPHERE.spark_count
	particles.lifetime = 3.5 if smoke else 1.8
	particles.position.y = 0.4
	particles.direction = Vector3.UP
	particles.spread = 25
	particles.initial_velocity_min = 0.4
	particles.initial_velocity_max = 0.8 if smoke else 1.8
	particles.gravity = Vector3(0.12, 0.1, 0)
	particles.scale_amount_min = 0.12 if smoke else 0.012
	particles.scale_amount_max = 0.4 if smoke else 0.035
	var mesh := QuadMesh.new()
	mesh.size = Vector2.ONE
	particles.mesh = mesh
	var material := SceneAssets.material(Color(0.25, 0.29, 0.35, 0.12) if smoke else Color(1, 0.6, 0.1, 0.8), not smoke)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.billboard_keep_scale = true
	material.albedo_texture = WinterAtmosphere.soft_particle()
	particles.material_override = material
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
	return particles
