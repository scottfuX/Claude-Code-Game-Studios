class_name SurvivorVisual extends Node3D

signal foot_contact(where: Vector3, foot: int)
const MODEL: PackedScene = preload("res://assets/models/survivor_rigged.glb")
var tuning: SurvivorVisualTuning = preload("res://assets/data/survivor_visual_defaults.tres")
var controller: SurvivorController
var footprints: FootprintPool
var elapsed: float = 0.0
var crouch: float = 0.0
var warming: float = 0.0
var lean: float = 0.0
var _model: Node3D
var _skeleton: Skeleton3D
var _tree: AnimationTree
var _action_node: AnimationNodeAnimation
var _last_action: StringName = &""
var _speed: float = 0.0
var _action_weight: float = 0.0
var _last_foot: int = -1
var _last_contact: Vector3 = Vector3.INF
var _feet: PackedInt32Array = []

func _ready() -> void:
	_model = MODEL.instantiate()
	add_child(_model)
	SceneAssets.apply_flat(_model)
	_hide_shadows(_model)
	_skeleton = _model.find_child("Skeleton3D", true, false) as Skeleton3D
	var player := _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var library := player.get_animation_library(&"").duplicate_deep() as AnimationLibrary
	player.remove_animation_library(&"")
	player.add_animation_library(&"", library)
	for name: StringName in player.get_animation_list():
		if name != &"RESET":
			player.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	var walk := player.get_animation(&"walk")
	var track := walk.add_track(Animation.TYPE_METHOD)
	var root := player.get_node(player.root_node)
	walk.track_set_path(track, root.get_path_to(self))
	walk.track_insert_key(track, walk.length * 0.25, {"method": "_contact", "args": [0]})
	walk.track_insert_key(track, walk.length * 0.75, {"method": "_contact", "args": [1]})
	_feet.append(_skeleton.find_bone(&"LeftFoot"))
	_feet.append(_skeleton.find_bone(&"RightFoot"))
	var blend := AnimationNodeBlendTree.new()
	var locomotion := AnimationNodeBlendSpace1D.new()
	var idle := AnimationNodeAnimation.new()
	idle.animation = &"idle"
	var walking := AnimationNodeAnimation.new()
	walking.animation = &"walk"
	locomotion.add_blend_point(idle, 0.0)
	locomotion.add_blend_point(walking, 1.0)
	_action_node = AnimationNodeAnimation.new()
	_action_node.animation = &"idle"
	blend.add_node(&"locomotion", locomotion)
	blend.add_node(&"action", _action_node)
	blend.add_node(&"cadence", AnimationNodeTimeScale.new())
	blend.connect_node(&"cadence", 0, &"locomotion")
	blend.add_node(&"priority", AnimationNodeBlend2.new())
	blend.connect_node(&"priority", 0, &"cadence")
	blend.connect_node(&"priority", 1, &"action")
	blend.connect_node(&"output", 0, &"priority")
	_tree = AnimationTree.new()
	_model.add_child(_tree)
	_tree.anim_player = _tree.get_path_to(player)
	_tree.root_node = _tree.get_path_to(root)
	_tree.tree_root = blend
	_tree.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	_tree.active = true
	var pose := SurvivorPose.new()
	pose.visual = self
	_skeleton.add_child(pose)

func _process(delta: float) -> void:
	if controller == null or controller.simulation == null:
		return
	var sim := controller.simulation
	_tree.active = not controller.frozen and sim.terminal == &""
	if not _tree.active:
		return
	elapsed += delta
	footprints.advance(delta)
	var speed := Vector2(controller.velocity.x, controller.velocity.z).length()
	_speed = lerpf(_speed, speed / tuning.stride_speed, 1.0 - exp(-tuning.blend_response * delta))
	_tree.set("parameters/locomotion/blend_position", clampf(_speed, 0, 1))
	_tree.set("parameters/cadence/scale", maxf(0.85, _speed))
	var desired_yaw := atan2(controller.facing.x, controller.facing.z)
	var turn := angle_difference(rotation.y, desired_yaw)
	lean = lerpf(lean, clampf(turn, -1, 1) * tuning.turn_lean, 1.0 - exp(-tuning.blend_response * delta))
	rotation.y = lerp_angle(rotation.y, desired_yaw, 1.0 - exp(-tuning.blend_response * delta))
	var action := sim.actions.action
	if action != _last_action:
		_action_node.animation = &"chop" if action in [&"chop_log", &"strip_bark"] else (&"strike" if action in [&"strike", &"blow_embers", &"arrange_tinder"] else &"idle")
		_last_action = action
	_action_weight = move_toward(_action_weight, 0.0 if action == &"" else 1.0, delta * tuning.blend_response)
	_tree.set("parameters/priority/blend_amount", _action_weight)
	crouch = move_toward(crouch, 1.0 if action in [&"gather_sticks", &"gather_grass", &"clear_snow", &"arrange_tinder", &"strike", &"blow_embers", &"add_fuel"] else 0.0, delta * tuning.blend_response)
	var near := false
	for fire: FireController in sim.fires:
		if fire.stage == &"Burning" and fire.position.distance_to(controller.global_position) < tuning.warming_distance:
			near = true
	warming = move_toward(warming, 1.0 if near and action == &"" and speed < 0.1 else 0.0, delta)

func _contact(foot: int) -> void:
	if controller.frozen or controller.simulation.terminal != &"" or controller.simulation.actions.action != &"" or _speed < 0.1 or foot == _last_foot:
		return
	if _last_contact.is_finite() and controller.global_position.distance_to(_last_contact) < tuning.footprint_min_travel:
		return
	_last_foot = foot
	_last_contact = controller.global_position
	var where := _skeleton.to_global(_skeleton.get_bone_global_pose(_feet[foot]).origin)
	footprints.stamp(where, rotation.y)
	foot_contact.emit(where, foot)

func _hide_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in node.get_children():
		_hide_shadows(child)
