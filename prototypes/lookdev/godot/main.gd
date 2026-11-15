extends Node3D

const FLAT_MAT: Material = preload("res://materials/flat_palette.tres")
const PINE: PackedScene = preload("res://assets/pine_flat.glb")
const BARE: PackedScene = preload("res://assets/bare_tree_flat.glb")
const SHELTER: PackedScene = preload("res://assets/shelter_flat.glb")
const SURVIVOR: PackedScene = preload("res://assets/survivor_flat.glb")
const SEED := 20261115
const OUT_DIR := "res://../evidence/"

var _capture := false
var _frame := 0
var _shelter: Node3D
var _survivor: Node3D
var _hero_pine: Node3D
var _hero_bare: Node3D

@onready var cam_close: Camera3D = $CamClose


func _ready() -> void:
	_build_camp()
	_capture = "--capture" in OS.get_cmdline_user_args()


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
		85:
			get_tree().quit()
