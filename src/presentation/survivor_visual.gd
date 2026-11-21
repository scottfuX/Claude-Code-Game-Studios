class_name SurvivorVisual extends Node3D

signal foot_contact(where: Vector3, foot: int)
const MODEL: PackedScene = preload("res://assets/models/survivor_rigged.glb")
var tuning: SurvivorVisualTuning = preload("res://assets/data/survivor_visual_defaults.tres")
var controller: SurvivorController
var footprints: FootprintPool
var elapsed: float = 0.0
var state: StringName = &"idle"
var _model: Node3D
var _skeleton: Skeleton3D
var _tree: AnimationTree
var _playback: AnimationNodeStateMachinePlayback
var _speed: float = 0.0
var _last_foot: int = -1
var _last_contact: Vector3 = Vector3.INF
var _feet: PackedInt32Array = []
var _lengths: Dictionary[StringName, float] = {}

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
	SurvivorClips.build(_skeleton, self, player)
	for action: StringName in SurvivorClips.ACTIONS:
		_lengths[action] = player.get_animation(SurvivorClips.ACTIONS[action]).length
	var root := player.get_node(player.root_node)
	for name: StringName in [&"walk", &"walk_tired", &"trudge", &"trudge_tired"]:
		var walk := player.get_animation(name)
		var track := walk.add_track(Animation.TYPE_METHOD)
		walk.track_set_path(track, root.get_path_to(self))
		walk.track_insert_key(track, 0.0, {"method": "_contact", "args": [0]})
		walk.track_insert_key(track, walk.length * 0.5, {"method": "_contact", "args": [1]})
	_feet.append(_skeleton.find_bone(&"LeftFoot"))
	_feet.append(_skeleton.find_bone(&"RightFoot"))
	var machine := AnimationNodeStateMachine.new()
	var states: Array[StringName] = SurvivorClips.STATES.duplicate()
	for clip: StringName in SurvivorClips.ACTIONS.values():
		if clip not in states:
			states.append(clip)
	for name: StringName in states:
		machine.add_node(name, _state_blend(name))
	for from: StringName in states:
		for to: StringName in states:
			if from != to:
				var transition := AnimationNodeStateMachineTransition.new()
				transition.xfade_time = 0.25
				machine.add_transition(from, to, transition)
	_tree = AnimationTree.new()
	_model.add_child(_tree)
	_tree.anim_player = _tree.get_path_to(player)
	_tree.root_node = _tree.get_path_to(root)
	_tree.tree_root = machine
	_tree.callback_mode_method = AnimationMixer.ANIMATION_CALLBACK_MODE_METHOD_IMMEDIATE
	_tree.active = true
	_playback = _tree.get("parameters/playback")
	_playback.start(&"idle")
	var pose := SurvivorPose.new()
	pose.visual = self
	_skeleton.add_child(pose)

func _clip(name: StringName) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = name
	return node

func _state_blend(name: StringName) -> AnimationNodeBlendTree:
	var blend := AnimationNodeBlendTree.new()
	blend.add_node(&"base", _clip(name))
	blend.add_node(&"tired", _clip(StringName(String(name) + "_tired")))
	blend.add_node(&"fatigue", AnimationNodeBlend2.new())
	if name == &"walk":
		blend.add_node(&"deep", _clip(&"trudge"))
		blend.add_node(&"deep_tired", _clip(&"trudge_tired"))
		for pair: StringName in [&"snow", &"snow_tired"]:
			blend.add_node(pair, AnimationNodeBlend2.new())
		blend.connect_node(&"snow", 0, &"base")
		blend.connect_node(&"snow", 1, &"deep")
		blend.connect_node(&"snow_tired", 0, &"tired")
		blend.connect_node(&"snow_tired", 1, &"deep_tired")
		blend.connect_node(&"fatigue", 0, &"snow")
		blend.connect_node(&"fatigue", 1, &"snow_tired")
	else:
		blend.connect_node(&"fatigue", 0, &"base")
		blend.connect_node(&"fatigue", 1, &"tired")
	if name == &"walk":
		blend.add_node(&"cadence", AnimationNodeTimeScale.new())
		blend.connect_node(&"cadence", 0, &"fatigue")
		blend.connect_node(&"output", 0, &"cadence")
	elif SurvivorClips.ACTIONS.has(name):
		blend.add_node(&"phase", AnimationNodeTimeSeek.new())
		blend.connect_node(&"phase", 0, &"fatigue")
		blend.connect_node(&"output", 0, &"phase")
	else:
		blend.connect_node(&"output", 0, &"fatigue")
	return blend

func _process(delta: float) -> void:
	if controller == null or controller.simulation == null:
		return
	var sim := controller.simulation
	_tree.active = not controller.router.is_paused() and (not controller.frozen or sim.needs.is_asleep) and sim.terminal == &""
	if not _tree.active:
		return
	elapsed += delta
	footprints.advance(delta)
	var speed := Vector2(controller.velocity.x, controller.velocity.z).length()
	_speed = lerpf(_speed, speed / tuning.stride_speed, 1.0 - exp(-tuning.blend_response * delta))
	var fire := warming_fire()
	var next := SurvivorClips.select(sim.actions.action, speed, sim.body.core_temp_c, fire != null, sim.needs.is_asleep)
	if next == &"":
		push_error("Missing survivor animation for action: %s" % sim.actions.action)
		return
	if next != state:
		state = next
		_playback.travel(state)
	var fatigue := clampf((45.0 - sim.needs.energy) / 35.0, 0.0, 1.0)
	_tree.set("parameters/%s/fatigue/blend_amount" % state, fatigue)
	if SurvivorClips.ACTIONS.has(sim.actions.action):
		_tree.set("parameters/%s/phase/seek_request" % state, sim.actions.progress() * _lengths[sim.actions.action])
	var fresh := 1.0 - controller.snow.deformation.compaction_at(controller.global_position) if controller.snow != null else 0.0
	_tree.set("parameters/walk/snow/blend_amount", fresh)
	_tree.set("parameters/walk/snow_tired/blend_amount", fresh)
	_tree.set("parameters/walk/cadence/scale", clampf(_speed, 0.4, 1.5))
	var direction := action_facing(fire if state == &"warm_hands" else null)
	var desired_yaw := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, desired_yaw, 1.0 - exp(-tuning.blend_response * delta))

## Finds the nearest burning fire within hand-warming range.
func warming_fire() -> FireController:
	var nearest: FireController
	var distance := tuning.warming_distance
	for fire: FireController in controller.simulation.fires:
		var reach := fire.position.distance_to(controller.global_position)
		if fire.stage == &"Burning" and reach < distance:
			nearest = fire
			distance = reach
	return nearest

## Resolves work or warming targets, falling back to movement-facing.
func action_facing(warm_fire: FireController = null) -> Vector3:
	var target: RefCounted = controller.simulation.active_action_target()
	if warm_fire != null:
		target = warm_fire
	if target is FireController:
		return SurvivorClips.facing(controller.global_position, target.position, controller.facing)
	if target is GatherNode:
		var world := controller.get_parent().get_node("WorldMap") as WorldMap
		for entry: WorldInteractable in world.interactables:
			if entry.gather_node == target:
				return SurvivorClips.facing(controller.global_position, entry.global_position, controller.facing)
	return controller.facing

func _contact(foot: int) -> void:
	if controller.frozen or controller.simulation.terminal != &"" or controller.simulation.actions.action != &"" or _speed < 0.1 or foot == _last_foot:
		return
	if _last_contact.is_finite() and controller.global_position.distance_to(_last_contact) < tuning.footprint_min_travel:
		return
	_last_foot = foot
	_last_contact = controller.global_position
	var where := _skeleton.to_global(_skeleton.get_bone_global_pose(_feet[foot]).origin)
	if controller.snow != null:
		controller.snow.deformation.press(where, tuning.snow_foot_press_radius, tuning.snow_foot_press_strength, tuning.snow_foot_press_aspect, rotation.y)
	else:
		footprints.stamp(where, rotation.y)
	foot_contact.emit(where, foot)

func _hide_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in node.get_children():
		_hide_shadows(child)
