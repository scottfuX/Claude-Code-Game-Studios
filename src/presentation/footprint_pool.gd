class_name FootprintPool extends Node3D

var tuning: SurvivorVisualTuning = preload("res://assets/data/survivor_visual_defaults.tres")
var _marks: Array[MeshInstance3D] = []
var _ages: PackedFloat32Array = []
var _cursor: int = 0

func _ready() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = tuning.footprint_size
	var material := ShaderMaterial.new()
	material.shader = preload("res://src/presentation/spatial_snow_footprint.gdshader")
	for i in tuning.footprint_count:
		var mark := MeshInstance3D.new()
		mark.mesh = mesh
		mark.material_override = material
		mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mark.visible = false
		add_child(mark)
		_marks.append(mark)
		_ages.append(tuning.footprint_life_s)

## Reuses one fixed slot for a cosmetic contact; e.g. stamp(foot_position, yaw).
func stamp(where: Vector3, yaw: float) -> void:
	if _marks.is_empty() or not where.is_finite() or not is_finite(yaw):
		return
	var mark := _marks[_cursor]
	mark.global_position = Vector3(where.x, 0.012 + _cursor * 0.00001, where.z)
	mark.rotation.y = yaw
	mark.transparency = 0.0
	mark.visible = true
	_ages[_cursor] = 0.0
	_cursor = (_cursor + 1) % _marks.size()

## Ages existing slots without creating geometry; e.g. advance(delta).
func advance(delta: float) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	for i in _marks.size():
		_ages[i] += delta
		_marks[i].visible = _ages[i] < tuning.footprint_life_s
		_marks[i].transparency = smoothstep(tuning.footprint_life_s * 0.55, tuning.footprint_life_s, _ages[i])
