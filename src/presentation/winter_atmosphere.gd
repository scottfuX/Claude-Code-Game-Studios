class_name WinterAtmosphere extends Node3D

const AUDIBLE_FIRE: Array[StringName] = [&"Kindling", &"Burning", &"Embers"]
const CHOP: Array[StringName] = [&"chop_log", &"strip_bark"]
var simulation: RunSimulation
var survivor: SurvivorController
var sunlight: DirectionalLight3D
var environment: Environment
var tuning: AtmosphereTuning = preload("res://assets/data/atmosphere_defaults.tres")
var low_quality: bool = false
var _snow: CPUParticles3D
var _drift: CPUParticles3D
var _sky: ProceduralSkyMaterial
var _wind: AudioStreamPlayer
var _fire: AudioStreamPlayer
var _foley: AudioStreamPlayer
var _steps: AudioStreamPlayer
var _chop: AudioStreamWAV
var _gather: AudioStreamWAV
var _work_elapsed: float = 0.0
var _work_action: StringName = &""
var _last_daylight: float = NAN

func _ready() -> void:
	var adapter := RenderingServer.get_video_adapter_name()
	low_quality = tuning.uses_low_quality(adapter)
	var ambient_audio := tuning.ambient_audio_for(adapter)
	_sky = ProceduralSkyMaterial.new()
	_sky.sky_curve = 0.35
	_sky.ground_curve = 0.35
	var sky := Sky.new()
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	sky.sky_material = _sky
	environment.sky = sky
	environment.background_mode = Environment.BG_SKY
	_snow = _particles(tuning.snow_count, false)
	_drift = _particles(tuning.drift_count, true)
	_wind = _audio(SynthAudio.create(&"wind") if ambient_audio else null)
	_fire = _audio(SynthAudio.create(&"fire") if ambient_audio else null)
	_steps = _audio(SynthAudio.create(&"step"))
	_steps.stop()
	_steps.volume_db = tuning.foley_volume_db
	_foley = _audio(null)
	_foley.volume_db = tuning.foley_volume_db
	_chop = SynthAudio.create(&"chop")
	_gather = SynthAudio.create(&"gather")

## Updates the shared sky palette; e.g. set_daylight(daylight_fraction).
func set_daylight(daylight: float) -> void:
	var light := clampf(daylight, 0, 1)
	sunlight.shadow_enabled = light > 0.001
	if light <= 0.001:
		sunlight.rotation_degrees = Vector3(-42, -65, 0)
		sunlight.light_color = Color("9fbfe9")
		sunlight.light_energy = tuning.moon_energy
	if is_equal_approx(light, _last_daylight):
		return
	_last_daylight = light
	_sky.sky_top_color = Color("101e3c").lerp(Color("556f91"), light)
	_sky.sky_horizon_color = Color("536681").lerp(Color("dcac83"), light)
	_sky.ground_horizon_color = _sky.sky_horizon_color
	_sky.ground_bottom_color = Color("293e59").lerp(Color("a5b9c9"), light)
	environment.fog_light_color = _sky.sky_horizon_color
	environment.fog_density = lerpf(tuning.night_fog_density, tuning.dusk_fog_density, light)

## Shares the visual contact's one-shot sound, never creating a second foot clock.
func footstep(_where: Vector3, foot: int) -> void:
	_steps.pitch_scale = 0.94 if foot == 0 else 1.06
	_steps.play()

func _process(delta: float) -> void:
	if simulation == null:
		return
	var paused := survivor.frozen or simulation.terminal != &""
	_wind.stream_paused = paused
	_fire.stream_paused = paused
	_foley.stream_paused = paused
	_steps.stream_paused = paused
	_snow.speed_scale = 0.0 if paused else 1.0
	_drift.speed_scale = _snow.speed_scale
	if paused:
		return
	global_position = Vector3(survivor.global_position.x, 0, survivor.global_position.z)
	_wind.volume_db = tuning.wind_volume_db + linear_to_db(maxf(0.01, simulation.tuning.exposure))
	var loudest := 0.0
	for fire: FireController in simulation.fires:
		if fire.stage in AUDIBLE_FIRE:
			var distance := survivor.global_position.distance_to(fire.position)
			loudest = maxf(loudest, fire.size_factor() / maxf(1, distance))
	_fire.volume_db = tuning.fire_volume_db + linear_to_db(maxf(0.0001, loudest))
	var action := simulation.actions.action
	if action != _work_action:
		_work_elapsed = tuning.work_sound_interval_s
		_work_action = action
	_work_elapsed += delta
	if action != &"" and _work_elapsed >= tuning.work_sound_interval_s:
		_foley.stream = _chop if action in CHOP else _gather
		_foley.play()
		_work_elapsed = 0.0

func _particles(count: int, ground: bool) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.amount = count
	particles.lifetime = 7.0 if ground else 10.0
	particles.preprocess = particles.lifetime
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(14, 0.1, 14) if ground else tuning.snow_extent
	particles.position.y = 0.15 if ground else 6.0
	particles.direction = tuning.wind_direction if ground else Vector3(0.3, -1, 0.1)
	particles.initial_velocity_min = 0.6
	particles.initial_velocity_max = 1.4
	particles.gravity = tuning.wind_direction * 0.1 if ground else Vector3(0.08, -0.12, 0)
	particles.scale_amount_min = 0.12 if ground else 0.045
	particles.scale_amount_max = 0.35 if ground else 0.085
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.6, 0.2) if ground else Vector2.ONE
	particles.mesh = mesh
	var material := SceneAssets.material(Color(0.8, 0.86, 0.95, 0.12 if ground else 0.7))
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.billboard_keep_scale = true
	material.albedo_texture = soft_particle()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	particles.material_override = material
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
	return particles

func _audio(stream: AudioStream) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	if stream != null:
		player.play()
	return player

## Builds one soft particle texture at setup, shared by all particles in its emitter.
static func soft_particle() -> GradientTexture2D:
	var texture := GradientTexture2D.new()
	texture.width = 32
	texture.height = 32
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1, 0.5)
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	texture.gradient = gradient
	return texture
