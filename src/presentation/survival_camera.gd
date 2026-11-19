class_name SurvivalCamera extends Node3D

var target: Node3D
var yaw: float = 0.0
var distance: float = 19.0
var _camera: Camera3D

func _ready() -> void:
	_camera = Camera3D.new()
	_camera.fov = 45.0
	_camera.current = true
	_camera.far = 150.0
	add_child(_camera)

## Returns camera-relative movement projected onto the ground.
func move_direction(input: Vector2) -> Vector3:
	return (Vector3.RIGHT.rotated(Vector3.UP, yaw) * input.x + Vector3.BACK.rotated(Vector3.UP, yaw) * input.y).limit_length(1.0)

## Rotates the follow camera by an authored quarter turn.
func turn(direction: float) -> void:
	yaw += direction * PI / 4.0

## Zooms within the playable framing limits.
func zoom(direction: float) -> void:
	distance = clampf(distance + direction * 2.0, 12.0, 30.0)

func _process(delta: float) -> void:
	if target == null:
		return
	var centre := target.global_position + Vector3.UP * 0.75
	global_position = global_position.lerp(centre, 1.0 - exp(-8.0 * delta))
	var offset := Vector3(0, sin(deg_to_rad(48)) * distance, cos(deg_to_rad(48)) * distance).rotated(Vector3.UP, yaw)
	_camera.global_position = global_position + offset
	_camera.look_at(global_position, Vector3.UP)
