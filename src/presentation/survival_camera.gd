class_name SurvivalCamera extends Node3D

@export var tuning: PlayfieldTuning = preload("res://assets/data/playfield_defaults.tres")
var target: Node3D
var yaw: float = 0.0
var distance: float = tuning.camera_distance
var _camera: Camera3D

func _ready() -> void:
	_camera = Camera3D.new()
	distance = tuning.camera_distance
	_camera.fov = tuning.camera_fov
	_camera.current = true
	_camera.far = tuning.camera_far
	add_child(_camera)

## Returns camera-relative movement projected onto the ground.
func move_direction(input: Vector2) -> Vector3:
	return (Vector3.RIGHT.rotated(Vector3.UP, yaw) * input.x + Vector3.BACK.rotated(Vector3.UP, yaw) * input.y).limit_length(1.0)

## Rotates the follow camera by the tuned step.
func turn(direction: float) -> void:
	yaw += direction * deg_to_rad(tuning.camera_turn_degrees)

## Zooms within the playable framing limits.
func zoom(direction: float) -> void:
	distance = clampf(distance + direction * tuning.camera_zoom_step, tuning.camera_zoom_min, tuning.camera_zoom_max)

func _process(delta: float) -> void:
	if target == null:
		return
	var centre := target.global_position + Vector3.UP * tuning.camera_target_height
	global_position = global_position.lerp(centre, 1.0 - exp(-tuning.camera_follow_response * delta))
	var offset := Vector3(0, sin(deg_to_rad(tuning.camera_pitch_degrees)) * distance, cos(deg_to_rad(tuning.camera_pitch_degrees)) * distance).rotated(Vector3.UP, yaw)
	_camera.global_position = global_position + offset
	_camera.look_at(global_position, Vector3.UP)
