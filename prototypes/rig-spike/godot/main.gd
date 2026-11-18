extends Node3D
# PROTOTYPE — NOT FOR PRODUCTION. Rig/animation spike viewer.
# Six copies of the auto-rigged survivor, one per test case, seen from a
# close camera or the gameplay camera (pitch 50°, fov 30°, distance 22 m or
# 50 m). Args after `--`: --view close|game|far   --capture (quit after
# CAPTURE_FRAMES; use with --write-movie for a PNG sequence).

const FLAT_MAT: Material = preload("res://materials/flat_palette.tres")
const SNOW_MAT: Material = preload("res://materials/snow_ground.tres")
const SURVIVOR: PackedScene = preload("res://assets/survivor_rigged.glb")
const CAPTURE_FRAMES := 180
const PITCH := deg_to_rad(50.0)
const SUN_PITCH := -0.38397
const SUN_YAW := 0.35   # light from the camera side so the navy parka reads
const CHOP_ACTION_S := 5.6   # GDD C7 example: 0.4 + 4 x 1.2 + 0.4
const CHOP_INTRO_S := 0.4
const CHOP_EFFORT_S := 1.2
const UPPER_BODY := ["Spine", "Chest", "UpperChest", "Neck", "Head",
	"LeftShoulder", "LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightShoulder", "RightUpperArm", "RightLowerArm", "RightHand"]
const CASES := [
	["idle", "idle"], ["walk", "walk"], ["chop", "chop"],
	["strike", "strike"], ["shiver", "shiver"],
	["walk+shiver", "walk + shiver"],
]

var _view := "close"
var _capture := false
var _frame := 0
var _chop_player: AnimationPlayer
var _chop_t := 0.0
var _footfalls := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_capture = "--capture" in args
	var vi := args.find("--view")
	if vi >= 0 and vi + 1 < args.size():
		_view = args[vi + 1]
	_build_env()
	var spacing := 1.7 if _view == "close" else 2.6
	for i in CASES.size():
		var x := (i - (CASES.size() - 1) / 2.0) * spacing
		_spawn(CASES[i][0], CASES[i][1], Vector3(x, 0, 0))
	_build_camera()


func _spawn(kind: String, label: String, pos: Vector3) -> void:
	var s: Node3D = SURVIVOR.instantiate()
	s.position = pos
	s.rotation.y = 0.5   # three-quarter view toward the camera
	add_child(s)
	_apply_flat(s)
	var skel: Skeleton3D = s.find_child("Skeleton3D", true, false)
	var ap: AnimationPlayer = s.find_child("AnimationPlayer", true, false)
	if kind == "idle":
		_check_profile(skel)
	for n in ["idle", "walk", "shiver"]:
		ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
	match kind:
		"chop":
			_attach_axe(skel)
			_chop_player = ap
			var a := ap.get_animation("chop")
			a.add_marker("effort_start", CHOP_INTRO_S)
			a.add_marker("effort_end", CHOP_INTRO_S + CHOP_EFFORT_S)
			ap.play("chop")
		"walk":
			_add_footfall_track(ap.get_animation("walk"))
			ap.play("walk")
		"walk+shiver":
			_layer(s, ap, skel)
		_:
			ap.play(kind)
	if _view == "close":
		var l := Label3D.new()
		l.text = label
		l.font_size = 48
		l.pixel_size = 0.004
		l.position = pos + Vector3(0, 2.05, 0)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.modulate = Color(0.12, 0.16, 0.25)
		l.outline_size = 0
		add_child(l)


func _layer(s: Node3D, ap: AnimationPlayer, skel: Skeleton3D) -> void:
	# Locomotion below, shiver overlay on the upper body only: the GDD's
	# layer 3 + layer 1 via an AnimationTree filtered Blend2.
	var tree := AnimationTree.new()
	s.add_child(tree)
	tree.anim_player = tree.get_path_to(ap)
	var bt := AnimationNodeBlendTree.new()
	var walk := AnimationNodeAnimation.new()
	walk.animation = "walk"
	var shiver := AnimationNodeAnimation.new()
	shiver.animation = "shiver"
	var blend := AnimationNodeBlend2.new()
	blend.filter_enabled = true
	var skel_path := String(ap.get_node(ap.root_node).get_path_to(skel))
	for b in UPPER_BODY:
		blend.set_filter_path(NodePath("%s:%s" % [skel_path, b]), true)
	bt.add_node("walk", walk)
	bt.add_node("shiver", shiver)
	bt.add_node("overlay", blend)
	bt.connect_node("overlay", 0, "walk")
	bt.connect_node("overlay", 1, "shiver")
	bt.connect_node("output", 0, "overlay")
	tree.tree_root = bt
	tree.set("parameters/overlay/blend_amount", 1.0)
	tree.active = true


func _attach_axe(skel: Skeleton3D) -> void:
	var att := BoneAttachment3D.new()
	att.bone_name = "RightHand"
	skel.add_child(att)
	var axe := Node3D.new()
	axe.position = Vector3(0, 0.07, 0)
	axe.rotation = Vector3(0, 0, PI / 2)
	att.add_child(axe)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("6B4A3A")
	wood.roughness = 1.0
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("8C97A8")
	steel.roughness = 1.0
	var handle := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(0.05, 0.75, 0.05)
	handle.mesh = hb
	handle.material_override = wood
	handle.position = Vector3(0, 0.22, 0)
	axe.add_child(handle)
	var head := MeshInstance3D.new()
	var hd := BoxMesh.new()
	hd.size = Vector3(0.22, 0.12, 0.05)
	head.mesh = hd
	head.material_override = steel
	head.position = Vector3(0.08, 0.55, 0)
	axe.add_child(head)


func _add_footfall_track(a: Animation) -> void:
	# GDD rule 8: foot contacts are animation events (glTF carries no
	# events, so the method track is added on the Godot side).
	var t := a.add_track(Animation.TYPE_METHOD)
	a.track_set_path(t, NodePath(".."))
	for k in [[0.3, "left"], [0.9, "right"]]:
		a.track_insert_key(t, k[0], {"method": "_on_footfall", "args": [k[1]]})


func _on_footfall(foot: String) -> void:
	_footfalls += 1
	if _footfalls <= 4:
		print("footfall ", foot)


func _check_profile(skel: Skeleton3D) -> void:
	var prof := SkeletonProfileHumanoid.new()
	var hit := 0
	var missing: PackedStringArray = []
	for i in prof.bone_size:
		var n := prof.get_bone_name(i)
		if skel.find_bone(n) >= 0:
			hit += 1
		else:
			missing.append(n)
	print("skeleton: %d bones; humanoid profile %d/%d matched; missing: %s" % [
		skel.get_bone_count(), hit, prof.bone_size,
		", ".join(missing) if missing.size() < 40 else "(fingers + others)"])


func _process(delta: float) -> void:
	_drive_chop(delta)
	if _capture:
		_frame += 1
		if _frame >= CAPTURE_FRAMES:
			print("footfalls: ", _footfalls)
			get_tree().quit()


func _drive_chop(delta: float) -> void:
	# GDD C7: intro once, effort section looped to fill the action, outro.
	if _chop_player == null:
		return
	_chop_t += delta
	var loops := roundi((CHOP_ACTION_S - 2 * CHOP_INTRO_S) / CHOP_EFFORT_S)
	var pos := _chop_player.current_animation_position
	var effort_end := CHOP_INTRO_S + CHOP_EFFORT_S
	var outro_at := CHOP_INTRO_S + loops * CHOP_EFFORT_S
	if _chop_t < outro_at and pos >= effort_end:
		_chop_player.seek(pos - CHOP_EFFORT_S, true)
	elif _chop_t >= CHOP_ACTION_S + 0.6:   # short rest, then repeat
		_chop_t = 0.0
		_chop_player.play("chop")
		_chop_player.seek(0.0, true)


func _apply_flat(n: Node) -> void:
	if n is MeshInstance3D:
		n.material_override = FLAT_MAT
	for c in n.get_children():
		_apply_flat(c)


func _build_env() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.6939, 0.7835, 0.8963)
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.799, 0.828, 0.835)
	env.ambient_light_energy = 1.3
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.light_color = Color(1.0, 0.885, 0.630)
	sun.light_energy = 1.5
	sun.rotation = Vector3(SUN_PITCH, SUN_YAW, 0.0)
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	ground.mesh = pm
	ground.material_override = SNOW_MAT
	add_child(ground)


func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.far = 400.0
	var pitch := PITCH
	var dist := 22.0
	var target := Vector3(0, 0.9, 0)
	if _view == "close":
		pitch = deg_to_rad(12.0)
		dist = 12.5
	elif _view == "far":
		dist = 50.0
	cam.position = target + Vector3(0, sin(pitch) * dist, cos(pitch) * dist)
	cam.rotation.x = -pitch
	add_child(cam)
	cam.make_current()
