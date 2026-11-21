class_name SurvivorController extends CharacterBody3D

@export var tuning: PlayfieldTuning = preload("res://assets/data/playfield_defaults.tres")
var simulation: RunSimulation
var router: InputRouter
var camera: SurvivalCamera
var frozen: bool = false
var facing: Vector3 = Vector3.FORWARD
var snow: SnowSurface

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

func _physics_process(delta: float) -> void:
	if simulation == null or router == null or frozen or simulation.terminal != &"":
		velocity = Vector3.ZERO
		return
	var input := router.sample_actions()
	var movement: Vector2 = input[&"move"]
	var direction := camera.move_direction(movement)
	var hurry: bool = input[&"hurry"] and simulation.body.stage in [&"Warm", &"Chilled", &"Cold"] and simulation.needs.stage != &"Exhausted"
	var speed := tuning.critical_speed if simulation.body.stage == &"Critical" else tuning.walk_speed * maxf(tuning.speed_multiplier_floor, simulation.body.move_speed_mult() * simulation.needs.move_speed_mult() * (tuning.hurry_multiplier if hurry else 1.0))
	speed *= snow_speed_factor(direction)
	velocity.x = move_toward(velocity.x, direction.x * speed, tuning.acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, tuning.acceleration * delta)
	velocity.y = -tuning.grounded_down_speed if is_on_floor() else velocity.y - tuning.gravity * delta
	move_and_slide()
	var horizontal := Vector2(velocity.x, velocity.z).length()
	simulation.movement = &"heavy" if horizontal >= tuning.activity_speed_cutoff and hurry else (&"walk" if horizontal >= tuning.activity_speed_cutoff else &"idle")
	simulation.position = global_position
	if direction.length_squared() > tuning.facing_input_squared:
		facing = direction.normalized()

func export_state() -> Dictionary:
	return {"position": CheckpointValues.encode_vector(position), "facing": CheckpointValues.encode_vector(facing)}

func restore_state(dto: Dictionary, chapter: bool = false) -> bool:
	if not validate_state(dto, chapter):
		return false
	position = CheckpointValues.decode_vector(dto.position)
	facing = CheckpointValues.decode_vector(dto.facing)
	velocity = Vector3.ZERO
	return true

static func validate_state(dto: Dictionary, chapter: bool = false) -> bool:
	if not CheckpointValues.keys(dto, ["position", "facing"]) or not CheckpointValues.vector(dto.position) or not CheckpointValues.vector(dto.facing):
		return false
	var p := CheckpointValues.decode_vector(dto.position)
	var direction := CheckpointValues.decode_vector(dto.facing)
	var data: PlayfieldTuning = preload("res://assets/data/playfield_defaults.tres")
	var limit := data.half_extent_for(chapter) - data.capsule_radius
	return absf(p.x) < limit and absf(p.z) < limit and p.y >= -data.capsule_radius and p.y <= data.capsule_height and absf(direction.y) < 0.0001 and absf(direction.length() - 1.0) < 0.0001

## Samples incoming ground beyond the survivor's current contact patch.
func snow_speed_factor(direction: Vector3) -> float:
	if snow == null:
		return 1.0
	var ahead := Vector3(direction.x, 0, direction.z).normalized() * tuning.snow_speed_probe_distance
	return snow.deformation.speed_factor(global_position + ahead, tuning.fresh_snow_speed_factor)
