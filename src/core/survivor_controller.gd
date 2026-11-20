class_name SurvivorController extends CharacterBody3D

const MODEL: PackedScene = preload("res://assets/models/survivor_rigged.glb")
@export var tuning: PlayfieldTuning = preload("res://assets/data/playfield_defaults.tres")
var simulation: RunSimulation
var router: InputRouter
var camera: SurvivalCamera
var frozen: bool = false
var facing: Vector3 = Vector3.FORWARD
var _visual: Node3D
var _animation: AnimationPlayer
var _clip: StringName = &""

## Injects run-scoped ports before physics activation.
func configure(run: RunSimulation, input: InputRouter, view: SurvivalCamera) -> void:
	simulation = run
	router = input
	camera = view

func _ready() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = tuning.capsule_radius
	capsule.height = tuning.capsule_height
	collision.shape = capsule
	collision.position.y = tuning.capsule_height / 2.0
	add_child(collision)
	_visual = MODEL.instantiate()
	_visual.rotation.y = PI
	add_child(_visual)
	SceneAssets.apply_flat(_visual)
	_hide_shadows(_visual)
	_animation = _visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animation != null:
		var library := _animation.get_animation_library(&"").duplicate_deep() as AnimationLibrary
		_animation.remove_animation_library(&"")
		_animation.add_animation_library(&"", library)
		for clip: StringName in [&"idle", &"walk", &"chop", &"strike", &"shiver"]:
			if _animation.has_animation(clip):
				var animation := _animation.get_animation(clip).duplicate() as Animation
				animation.loop_mode = Animation.LOOP_LINEAR
				_animation.get_animation_library(&"").remove_animation(clip)
				_animation.get_animation_library(&"").add_animation(clip, animation)

func _physics_process(delta: float) -> void:
	if simulation == null or router == null or frozen or simulation.terminal != &"":
		velocity = Vector3.ZERO
		return
	var input := router.sample_actions()
	var movement: Vector2 = input[&"move"]
	var direction := camera.move_direction(movement)
	var hurry: bool = input[&"hurry"] and simulation.body.stage in [&"Warm", &"Chilled", &"Cold"] and simulation.needs.stage != &"Exhausted"
	var speed := tuning.critical_speed if simulation.body.stage == &"Critical" else tuning.walk_speed * maxf(tuning.speed_multiplier_floor, simulation.body.move_speed_mult() * simulation.needs.move_speed_mult() * (tuning.hurry_multiplier if hurry else 1.0))
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y = -tuning.grounded_down_speed if is_on_floor() else velocity.y - tuning.gravity * delta
	move_and_slide()
	var horizontal := Vector2(velocity.x, velocity.z).length()
	simulation.movement = &"heavy" if horizontal >= tuning.activity_speed_cutoff and hurry else (&"walk" if horizontal >= tuning.activity_speed_cutoff else &"idle")
	simulation.position = global_position
	if direction.length_squared() > tuning.facing_input_squared:
		facing = direction.normalized()
		_visual.rotation.y = lerp_angle(_visual.rotation.y, atan2(facing.x, facing.z), minf(1.0, delta * tuning.facing_response))
	var desired: StringName = &"walk" if horizontal >= tuning.activity_speed_cutoff else (&"shiver" if simulation.body.is_shivering() else &"idle")
	if simulation.actions.action == &"chop_log":
		desired = &"chop"
	elif simulation.actions.action in [&"strike", &"blow_embers"]:
		desired = &"strike"
	if _animation != null and desired != _clip and _animation.has_animation(desired):
		_animation.play(desired, tuning.animation_blend_seconds)
		_clip = desired

func _hide_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in node.get_children():
		_hide_shadows(child)
