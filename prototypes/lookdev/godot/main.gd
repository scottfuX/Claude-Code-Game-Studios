extends Node3D

const FLAT_MAT: Material = preload("res://materials/flat_palette.tres")
const PINE: PackedScene = preload("res://assets/pine_flat.glb")
const BARE: PackedScene = preload("res://assets/bare_tree_flat.glb")
const SHELTER: PackedScene = preload("res://assets/shelter_flat.glb")
const SURVIVOR: PackedScene = preload("res://assets/survivor_flat.glb")
const CAMPFIRE: PackedScene = preload("res://assets/campfire_flat.glb")
const ROCK: PackedScene = preload("res://assets/rock_flat.glb")
const SEED := 20261115
const OUT_DIR := "res://../evidence/"

var _capture := false
var _frame := 0
var _shelter: Node3D
var _survivor: Node3D
var _hero_pine: Node3D
var _hero_bare: Node3D
var _campfire: Node3D
var _hero_rock: Node3D
var _fire_light: OmniLight3D
var _dusk := false

@onready var cam_close: Camera3D = $CamClose
@onready var _sun: DirectionalLight3D = $Sun
@onready var _world_env: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	_build_camp()
	var args := OS.get_cmdline_user_args()
	_capture = "--capture" in args
	var pi := args.find("--preset")
	_dusk = pi >= 0 and pi + 1 < args.size() and args[pi + 1] == "dusk"
	if _dusk:
		_apply_dusk()


func _place(scn: PackedScene, pos: Vector3, rot_y: float, s: float = 1.0) -> Node3D:
	var n: Node3D = scn.instantiate()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3(s, s, s)
	add_child(n)
	_apply_flat(n)
	return n


func _build_camp() -> void:
	_shelter = _place(SHELTER, Vector3(0, 0, -0.8), 2.6)
	_survivor = _place(SURVIVOR, Vector3(2.1, 0, 0.9), -1.2)
	_campfire = _place(CAMPFIRE, Vector3(0.4, 0, 0.9), 0.3)
	_build_fire(_campfire.position)
	_hero_rock = _place(ROCK, Vector3(-2.8, 0, 2.4), 0.4, 0.8)
	_place(ROCK, Vector3(4.4, 0, -2.7), 1.7, 1.15)
	_place(ROCK, Vector3(-4.8, 0, -1.4), 2.9, 0.55)
	_hero_pine = _place(PINE, Vector3(-7.5, 0, 3.5), 0.7)
	_hero_bare = _place(BARE, Vector3(8.5, 0, -5.5), 1.9)
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var placed: Array[Vector3] = [_hero_pine.position, _hero_bare.position]
	var pines := 0
	var bares := 0
	var tries := 0
	while pines + bares < 10 and tries < 4000:
		tries += 1
		var ang := rng.randf() * TAU
		var r := 7.0 + rng.randf() * 15.0
		var pos := Vector3(cos(ang) * r, 0, sin(ang) * r)
		if pos.length() < 5.5:
			continue
		var ok := true
		for q in placed:
			if pos.distance_to(q) < 3.5:
				ok = false
				break
		if not ok:
			continue
		var want_bare: bool = bares < 2 and rng.randf() < 0.3
		_place(BARE if want_bare else PINE, pos, rng.randf() * TAU, 0.8 + rng.randf() * 0.45)
		placed.append(pos)
		if want_bare:
			bares += 1
		else:
			pines += 1


func _apply_flat(n: Node) -> void:
	if n is MeshInstance3D:
		n.material_override = FLAT_MAT
	for c in n.get_children():
		_apply_flat(c)


func _build_fire(pos: Vector3) -> void:
	var f := Node3D.new()
	f.position = pos
	add_child(f)
	_fire_light = OmniLight3D.new()
	_fire_light.position = Vector3(0, 0.55, 0)
	_fire_light.light_color = Color(1.0, 0.42, 0.16)
	_fire_light.light_energy = 1.2
	_fire_light.omni_range = 6.0
	_fire_light.omni_attenuation = 1.4
	_fire_light.shadow_enabled = true
	f.add_child(_fire_light)
	var outer := _flame_cone(0.11, 0.36, Color(0.945, 0.274, 0.044))   # warm_orange lin
	outer.position = Vector3(0, 0.32, 0)
	var inner := _flame_cone(0.055, 0.22, Color(1.0, 0.605, 0.146))    # ember_yellow lin
	inner.position = Vector3(0.02, 0.33, 0.01)
	f.add_child(outer)
	f.add_child(inner)


func _flame_cone(radius: float, height: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cone: CylinderMesh = CylinderMesh.new()
	cone.bottom_radius = radius
	cone.top_radius = 0.0
	cone.height = height
	cone.radial_segments = 6
	mi.mesh = cone
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mi.material_override = mat
	return mi


func _apply_dusk() -> void:
	var env := _world_env.environment
	env.ambient_light_color = Color(0.02, 0.10, 0.26)
	env.ambient_light_energy = 1.6
	env.background_color = Color(0.02, 0.05, 0.16)
	env.fog_light_color = Color(0.03, 0.06, 0.18)
	env.fog_light_energy = 0.7
	_sun.light_color = Color(1.0, 0.386, 0.128)   # #FFA764
	_sun.light_energy = 0.08
	_sun.rotation = Vector3(-0.11, -0.61087, 0.0)
	_fire_light.light_energy = 4.5
	_fire_light.light_color = Color(1.0, 0.38, 0.12)


func _aim(node: Node3D, h: float, dir := Vector3(0.55, 0.30, 0.75)) -> void:
	var target := node.position + Vector3(0, h * 0.55, 0)
	cam_close.global_position = target + dir.normalized() * h * 2.0
	cam_close.look_at(target)
	cam_close.make_current()


func _shot(name: String) -> void:
	var path := ProjectSettings.globalize_path(OUT_DIR + name)
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("capture: ", name, " -> ", path, " err=", err)


func _process(_delta: float) -> void:
	if not _capture:
		return
	_frame += 1
	if _dusk:
		match _frame:
			60:
				await RenderingServer.frame_post_draw
				_shot("camp_wide_dusk.png")
			62:
				_aim(_campfire, 0.9, Vector3(0.55, 0.35, 0.75))
			65:
				await RenderingServer.frame_post_draw
				_shot("campfire_close_dusk.png")
			70:
				get_tree().quit()
	else:
		match _frame:
			60:
				await RenderingServer.frame_post_draw
				_shot("camp_wide.png")
			62:
				_aim(_shelter, 1.6)
			65:
				await RenderingServer.frame_post_draw
				_shot("shelter_close.png")
			67:
				_aim(_survivor, 1.75)
			70:
				await RenderingServer.frame_post_draw
				_shot("survivor_close.png")
			72:
				_aim(_hero_bare, 5.0)
			75:
				await RenderingServer.frame_post_draw
				_shot("bare_tree_close.png")
			77:
				_aim(_hero_pine, 6.0)
			80:
				await RenderingServer.frame_post_draw
				_shot("pine_close.png")
			82:
				_aim(_campfire, 0.9, Vector3(0.55, 0.35, 0.75))
			85:
				await RenderingServer.frame_post_draw
				_shot("campfire_close.png")
			87:
				_aim(_hero_rock, 1.0)
			90:
				await RenderingServer.frame_post_draw
				_shot("rock_close.png")
			95:
				get_tree().quit()
