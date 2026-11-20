class_name SurvivorPose extends SkeletonModifier3D

var visual: SurvivorVisual
var _chest: int = -1

func _ready() -> void:
	_chest = get_skeleton().find_bone(&"Chest")

func _process_modification() -> void:
	if visual == null or _chest < 0 or visual.controller.simulation == null:
		return
	var sim := visual.controller.simulation
	var data := visual.tuning
	var breath := sin(visual.elapsed * TAU * data.breath_hz) * data.breath_radians * 0.35
	var cold := clampf((36.5 - sim.body.core_temp_c) / 2.0, 0.0, 1.0)
	var shiver := sin(visual.elapsed * TAU * data.shiver_hz) * data.shiver_radians * 0.3 * cold if sim.body.is_shivering() else 0.0
	var skeleton := get_skeleton()
	skeleton.set_bone_pose_rotation(_chest, skeleton.get_bone_pose_rotation(_chest) * Quaternion.from_euler(Vector3(breath, shiver, 0)))
