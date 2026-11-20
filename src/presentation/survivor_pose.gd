class_name SurvivorPose extends SkeletonModifier3D

var visual: SurvivorVisual
var _bones: Dictionary[StringName, int] = {}
const FEET: Array[StringName] = [&"LeftFoot", &"RightFoot"]
const NAMES: Array[StringName] = [&"Hips", &"Chest", &"LeftUpperLeg", &"RightUpperLeg", &"LeftLowerLeg", &"RightLowerLeg", &"LeftUpperArm", &"RightUpperArm", &"LeftLowerArm", &"RightLowerArm", &"LeftFoot", &"RightFoot"]

func _ready() -> void:
	for bone: StringName in NAMES:
		_bones[bone] = get_skeleton().find_bone(bone)

func _process_modification() -> void:
	if visual == null:
		return
	var sim := visual.controller.simulation
	if sim == null:
		return
	var t := visual.elapsed
	var data := visual.tuning
	var breath := sin(t * TAU * data.breath_hz) * data.breath_radians
	var cold := sim.body.stage in [&"Cold", &"Hypothermic", &"Critical"]
	var shiver := sin(t * TAU * data.shiver_hz) * data.shiver_radians if cold else 0.0
	var fatigue := data.fatigue_radians if sim.needs.stage in [&"Tired", &"Exhausted"] else 0.0
	var crouch := visual.crouch
	_rotate(&"Chest", Vector3(breath + fatigue + crouch * 0.35, shiver, visual.lean))
	_rotate(&"LeftUpperLeg", Vector3(-crouch * 0.8, 0, 0))
	_rotate(&"RightUpperLeg", Vector3(-crouch * 0.8, 0, 0))
	_rotate(&"LeftLowerLeg", Vector3(crouch * 1.4, 0, 0))
	_rotate(&"RightLowerLeg", Vector3(crouch * 1.4, 0, 0))
	var reach := crouch * 0.8 + visual.warming * 0.6
	_rotate(&"LeftUpperArm", Vector3(-reach + shiver, 0, -reach * 0.25))
	_rotate(&"RightUpperArm", Vector3(-reach - shiver, 0, reach * 0.25))
	_rotate(&"LeftLowerArm", Vector3(-reach * 0.6, 0, 0))
	_rotate(&"RightLowerArm", Vector3(-reach * 0.6, 0, 0))
	var hips: int = _bones[&"Hips"]
	if hips >= 0:
		var p := get_skeleton().get_bone_pose_position(hips)
		get_skeleton().set_bone_pose_position(hips, p + Vector3(0, -crouch * 0.24, 0))
	for foot: StringName in FEET:
		var index: int = _bones[foot]
		if index >= 0 and crouch < 0.1:
			var pose := get_skeleton().get_bone_global_pose(index)
			var world := get_skeleton().to_global(pose.origin)
			if world.y < 0.10:
				world.y = 0.10
				pose.origin = get_skeleton().to_local(world)
				get_skeleton().set_bone_global_pose(index, pose)

func _rotate(bone: StringName, euler: Vector3) -> void:
	var index: int = _bones[bone]
	if index >= 0:
		var skeleton := get_skeleton()
		skeleton.set_bone_pose_rotation(index, skeleton.get_bone_pose_rotation(index) * Quaternion.from_euler(euler))
