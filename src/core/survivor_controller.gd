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
	if snow != null:
		speed *= snow.deformation.speed_factor(global_position, tuning.fresh_snow_speed_factor)
	velocity.x = move_toward(velocity.x, direction.x * speed, tuning.acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, tuning.acceleration * delta)
	velocity.y = -tuning.grounded_down_speed if is_on_floor() else velocity.y - tuning.gravity * delta
	move_and_slide()
	var horizontal := Vector2(velocity.x, velocity.z).length()
	simulation.movement = &"heavy" if horizontal >= tuning.activity_speed_cutoff and hurry else (&"walk" if horizontal >= tuning.activity_speed_cutoff else &"idle")
	simulation.position = global_position
	if direction.length_squared() > tuning.facing_input_squared:
		facing = direction.normalized()
