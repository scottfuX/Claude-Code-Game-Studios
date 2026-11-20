## Deterministic context clips authored for the survivor skeleton.
class_name SurvivorClips extends RefCounted

const ACTIONS: Dictionary[StringName, StringName] = {
	&"gather_sticks": &"gather_sticks", &"gather_grass": &"gather_grass",
	&"gather_stones": &"gather_stones",
	&"chop_log": &"chop_log", &"strip_bark": &"strip_bark",
	&"clear_snow": &"clear_snow", &"arrange_tinder": &"arrange_tinder",
	&"strike": &"strike", &"blow_embers": &"blow_embers", &"add_fuel": &"add_fuel",
	&"eat": &"eat", &"eat_snow": &"eat_snow", &"eat_hare": &"eat",
	ShelterFeature.FRAME: &"add_fuel", ShelterFeature.COVER: &"arrange_tinder",
	HareFoodFeature.SET: &"arrange_tinder", HareFoodFeature.CHECK: &"gather_grass",
	HareFoodFeature.COOK: &"arrange_tinder", HareFoodFeature.TAKE: &"gather_grass",
}
const STATES: Array[StringName] = [&"idle", &"cold_idle", &"warm_hands", &"walk", &"sleep"]
const KNEEL: float = 0.34

## Selects a context, returning an empty name for unmapped work.
static func select(action: StringName, speed: float, core_c: float, near_fire: bool, asleep: bool = false) -> StringName:
	if asleep:
		return &"sleep"
	if action != &"":
		return ACTIONS.get(action, &"")
	if speed > 0.1:
		return &"walk"
	if near_fire:
		return &"warm_hands"
	return &"cold_idle" if core_c < 36.5 else &"idle"

## Returns horizontal target-facing, retaining fallback for coincident targets.
static func facing(origin: Vector3, target: Vector3, fallback: Vector3) -> Vector3:
	var offset := target - origin
	offset.y = 0
	return offset.normalized() if offset.is_finite() and offset.length_squared() > 0.0001 else fallback

## Installs context clips and matching tired variants in the player's library.
static func build(skeleton: Skeleton3D, visual: Node3D, player: AnimationPlayer) -> void:
	var library := player.get_animation_library(&"")
	var clips := _sequences()
	for clip: StringName in clips:
		for tired: bool in [false, true]:
			var name := StringName(String(clip) + ("_tired" if tired else ""))
			if library.has_animation(name):
				library.remove_animation(name)
			library.add_animation(name, _animation(skeleton, visual, player, clips[clip], tired))

static func _stance(depth: float = 0.0, bend: float = 0.0, left: float = -8.0, right: float = -8.0) -> Dictionary:
	return {&"offset": Vector3(0, -depth, 0), &"Spine": Vector3(bend * 0.6, 0, 0),
		&"Chest": Vector3(bend * 0.4, 0, 0), &"Head": Vector3(-bend * 0.3, 0, 0),
		&"LeftUpperLeg": Vector3(-depth * 150, 0, -3), &"RightUpperLeg": Vector3(-depth * 150, 0, 3),
		&"LeftLowerLeg": Vector3(depth * 250, 0, 0), &"RightLowerLeg": Vector3(depth * 250, 0, 0),
		&"LeftFoot": Vector3(-depth * 90, 0, 0), &"RightFoot": Vector3(-depth * 90, 0, 0),
		&"LeftUpperArm": Vector3(left, -8, 8), &"RightUpperArm": Vector3(right, 8, -8),
		&"LeftLowerArm": Vector3(-25, 0, 0), &"RightLowerArm": Vector3(-32, 0, 0)}

static func _with(base: Dictionary, changes: Dictionary) -> Dictionary:
	var pose := base.duplicate()
	pose.merge(changes, true)
	return pose

static func _sequences() -> Dictionary:
	var stand := _stance()
	var ready := _stance(0.05, 12, -24, -32)
	var low := _stance(KNEEL, 34, -55, -65)
	var reach := _stance(0.26, 48, -65, -80)
	var tuck := _stance(0.10, 15, -38, -42)
	tuck = _with(tuck, {&"LeftLowerArm": Vector3(-95, 0, 0), &"RightLowerArm": Vector3(-105, 0, 0)})
	var snap := _with(tuck, {&"Chest": Vector3(8, -12, 0), &"LeftUpperArm": Vector3(-40, -24, 12), &"RightUpperArm": Vector3(-35, 30, -18)})
	var scoop := _with(low, {&"Chest": Vector3(18, -22, 0), &"LeftUpperArm": Vector3(-72, -24, 12), &"RightUpperArm": Vector3(-78, -10, -10)})
	var toss := _with(low, {&"Chest": Vector3(10, 28, 0), &"LeftUpperArm": Vector3(-38, 34, 28), &"RightUpperArm": Vector3(-48, 40, 10), &"offset": Vector3(0.06, -KNEEL, 0)})
	var place := _with(low, {&"LeftUpperArm": Vector3(-82, -6, 6), &"RightUpperArm": Vector3(-85, 9, -6), &"LeftLowerArm": Vector3(-12, 0, 0), &"RightLowerArm": Vector3(-18, 0, 0)})
	var strike_ready := _with(low, {&"LeftUpperArm": Vector3(-64, 0, 8), &"LeftLowerArm": Vector3(-18, 0, 0), &"RightUpperArm": Vector3(-38, 12, -8), &"RightLowerArm": Vector3(-95, 0, 0)})
	var strike_hit := _with(strike_ready, {&"Chest": Vector3(17, 4, 0), &"RightUpperArm": Vector3(-78, 6, -8), &"RightLowerArm": Vector3(-15, 0, 0)})
	var cup := _with(low, {&"LeftUpperArm": Vector3(-55, -15, 18), &"RightUpperArm": Vector3(-58, 15, -18), &"LeftLowerArm": Vector3(-80, 0, 0), &"RightLowerArm": Vector3(-85, 0, 0)})
	var blow := _with(cup, {&"Spine": Vector3(33, 0, 0), &"Chest": Vector3(22, 0, 0), &"Head": Vector3(5, 0, 0), &"offset": Vector3(0, -0.38, 0.04)})
	var warm := _with(_stance(0.06, 12, -65, -70), {&"LeftLowerArm": Vector3(-42, 0, 0), &"RightLowerArm": Vector3(-48, 0, 0)})
	var hug := _with(_stance(0.04, 24, -32, -38), {&"LeftUpperArm": Vector3(-32, -45, 28), &"RightUpperArm": Vector3(-38, 45, -28), &"LeftLowerArm": Vector3(-110, 0, 0), &"RightLowerArm": Vector3(-115, 0, 0)})
	var windup := _with(ready, {&"Spine": Vector3(-12, -12, 0), &"LeftUpperArm": Vector3(-145, -10, 12), &"RightUpperArm": Vector3(-155, 8, -12), &"LeftLowerArm": Vector3(-35, 0, 0), &"RightLowerArm": Vector3(-45, 0, 0)})
	var impact := _with(_stance(0.16, 48, -72, -82), {&"Chest": Vector3(22, 8, 0), &"LeftLowerArm": Vector3(-8, 0, 0), &"RightLowerArm": Vector3(-12, 0, 0)})
	var bark_hold := _with(_stance(0.16, 30, -62, -48), {&"LeftLowerArm": Vector3(-25, 0, 0), &"RightLowerArm": Vector3(-95, 0, 0)})
	var bark_pull := _with(bark_hold, {&"Chest": Vector3(10, 14, 0), &"RightUpperArm": Vector3(-24, 18, -12), &"RightLowerArm": Vector3(-60, 0, 0)})
	var mouth := _with(stand, {&"RightUpperArm": Vector3(-55, 12, -8), &"RightLowerArm": Vector3(-125, 0, 0), &"Head": Vector3(8, 0, 0)})
	var sleep := _with(_stance(0.42, 40, -15, -20), {&"Head": Vector3(25, 0, 12), &"LeftLowerArm": Vector3(-100, 0, 0), &"RightLowerArm": Vector3(-105, 0, 0)})
	var gather := [[0.0, ready], [0.4, reach], [0.72, _with(reach, {&"Chest": Vector3(24, -10, 0)})], [0.92, tuck], [1.25, tuck], [1.8, ready]]
	return {
		&"idle": [[0.0, stand], [1.0, _with(stand, {&"offset": Vector3(0.018, 0, 0), &"Head": Vector3(0, 4, 0)})], [2.4, stand]],
		&"cold_idle": [[0.0, hug], [0.7, hug], [0.95, _with(hug, {&"LeftUpperLeg": Vector3(-24, 0, -3), &"LeftLowerLeg": Vector3(45, 0, 0)})], [1.1, hug], [1.8, hug], [2.1, _with(hug, {&"RightUpperLeg": Vector3(-22, 0, 3), &"RightLowerLeg": Vector3(42, 0, 0)})], [2.3, hug], [3.0, hug]],
		&"warm_hands": [[0.0, warm], [0.6, _with(warm, {&"LeftUpperArm": Vector3(-60, -18, 12), &"RightUpperArm": Vector3(-64, 18, -12)})], [0.9, warm], [1.3, _with(warm, {&"LeftLowerArm": Vector3(-58, 0, 0), &"RightLowerArm": Vector3(-38, 0, 0)})], [1.6, warm], [2.4, warm]],
		&"gather_sticks": [[0.0, ready], [0.35, reach], [0.65, reach], [1.05, tuck], [1.25, snap], [1.38, tuck], [1.7, tuck], [2.1, ready]],
		&"gather_grass": gather, &"gather_stones": gather,
		&"clear_snow": [[0.0, low], [0.4, scoop], [0.7, scoop], [1.05, toss], [1.3, toss], [1.8, low]],
		&"arrange_tinder": [[0.0, low], [0.4, cup], [0.9, place], [1.2, place], [1.7, low]],
		&"add_fuel": [[0.0, low], [0.25, cup], [0.65, place], [0.9, place], [1.25, low]],
		&"strike": [[0.0, strike_ready], [0.32, strike_ready], [0.42, strike_hit], [0.55, strike_hit], [0.95, strike_ready]],
		&"blow_embers": [[0.0, cup], [0.55, blow], [1.15, blow], [1.6, cup], [2.0, cup]],
		&"chop_log": [[0.0, ready], [0.55, windup], [0.8, windup], [1.0, impact], [1.15, impact], [1.8, ready]],
		&"strip_bark": [[0.0, bark_hold], [0.35, bark_hold], [0.85, bark_pull], [1.1, bark_pull], [1.7, bark_hold]],
		&"eat": [[0.0, stand], [0.5, mouth], [1.2, mouth], [1.8, stand]],
		&"eat_snow": [[0.0, ready], [0.45, reach], [0.7, reach], [1.25, mouth], [1.7, mouth], [2.2, ready]],
		&"sleep": [[0.0, sleep], [3.0, sleep]],
		&"walk": _walk(false), &"trudge": _walk(true),
	}

static func _walk(deep: bool) -> Array:
	var poses: Array = []
	for i in 9:
		var phase := i % 8
		var left := phase < 4
		var beat := phase % 4
		var swing := [0.0, 1.0, 0.4, -0.65][beat] as float
		var lift := [0.0, 1.0, 0.25, 0.0][beat] as float
		var p := _stance(0.015, 12 if deep else 6, 12 * swing, -16 * swing)
		var lead := "Left" if left else "Right"
		var trail := "Right" if left else "Left"
		p[StringName(lead + "UpperLeg")] = Vector3(-swing * (42 if deep else 26), 0, 0)
		p[StringName(lead + "LowerLeg")] = Vector3(lift * (78 if deep else 38), 0, 0)
		p[StringName(trail + "UpperLeg")] = Vector3(swing * 20, 0, 0)
		p[&"offset"] = Vector3(0.018 * (1 if left else -1), -0.015 + lift * (0.035 if deep else 0.012), 0)
		poses.append([i * 0.15, p])
	return poses

static func _animation(skeleton: Skeleton3D, visual: Node3D, player: AnimationPlayer, keys: Array, tired: bool) -> Animation:
	var animation := Animation.new()
	animation.length = keys[-1][0]
	animation.loop_mode = Animation.LOOP_LINEAR
	var path := String(player.get_node(player.root_node).get_path_to(skeleton))
	var frame := skeleton.global_basis.inverse() * visual.global_basis
	for bone in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(bone)
		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath(path + ":" + bone_name))
		var rest := skeleton.get_bone_rest(bone)
		var global_rest := skeleton.get_bone_global_rest(bone).basis.orthonormalized()
		for key: Array in keys:
			var angles: Vector3 = key[1].get(StringName(bone_name), Vector3.ZERO)
			if bone_name == "LeftUpperArm":
				angles.z -= 35.0
			elif bone_name == "RightUpperArm":
				angles.z += 35.0
			if tired and bone_name in ["Spine", "Chest", "Head"]:
				angles.x += 7 if bone_name != "Head" else 10
			var rotation := Basis.from_euler(angles * PI / 180.0)
			var delta := global_rest.inverse() * frame * rotation * frame.inverse() * global_rest
			animation.rotation_track_insert_key(track, key[0], (rest.basis.orthonormalized() * delta).get_rotation_quaternion())
			animation.track_set_key_transition(track, animation.track_get_key_count(track) - 1, 2.0)
	var hips := skeleton.find_bone("Hips")
	var track := animation.add_track(Animation.TYPE_POSITION_3D)
	animation.track_set_path(track, NodePath(path + ":Hips"))
	var parent := skeleton.get_bone_parent(hips)
	var parent_basis := skeleton.get_bone_global_rest(parent).basis if parent >= 0 else Basis.IDENTITY
	for key: Array in keys:
		var offset: Vector3 = key[1].get(&"offset", Vector3.ZERO)
		animation.position_track_insert_key(track, key[0], skeleton.get_bone_rest(hips).origin + parent_basis.inverse() * frame * offset)
		animation.track_set_key_transition(track, animation.track_get_key_count(track) - 1, 2.0)
	return animation
