extends Node3D

const TREE_SCENE: PackedScene = preload("res://assets/pine_snowy.glb")
const FLAT_MAT: Material = preload("res://materials/flat_palette.tres")
const SEED := 20261115
const TREE_COUNT := 14
const CLEAR_RADIUS := 9.0
const SCATTER_RADIUS := 22.0
const MIN_SPACING := 3.5
const TREE_HEIGHT := 6.0
const OUT_DIR := "res://../out/"

var _capture := false
var _frame := 0
var _trees: Array[Node3D] = []

@onready var cam_wide: Camera3D = $CamWide
@onready var cam_close: Camera3D = $CamClose


func _ready() -> void:
	_scatter_trees()
	_aim_close_cam()
	_capture = "--capture" in OS.get_cmdline_user_args()


func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var tries := 0
	while _trees.size() < TREE_COUNT and tries < 4000:
		tries += 1
		var ang := rng.randf() * TAU
		var r := CLEAR_RADIUS + rng.randf() * (SCATTER_RADIUS - CLEAR_RADIUS)
		var pos := Vector3(cos(ang) * r, 0.0, sin(ang) * r)
		var blocked := false
		for prev in _trees:
			if pos.distance_to(prev.position) < MIN_SPACING:
				blocked = true
				break
		if blocked:
			continue
		var tree: Node3D = TREE_SCENE.instantiate()
		var s := 0.8 + rng.randf() * 0.45
		tree.position = pos
		tree.rotation.y = rng.randf() * TAU
		tree.scale = Vector3(s, s, s)
		add_child(tree)
		_apply_flat(tree)
		_trees.append(tree)


func _apply_flat(n: Node) -> void:
	if n is MeshInstance3D:
		n.material_override = FLAT_MAT
	for c in n.get_children():
		_apply_flat(c)


func _aim_close_cam() -> void:
	var tree := _trees[0]
	var h := TREE_HEIGHT * tree.scale.y
	var target := tree.position + Vector3(0.0, h * 0.55, 0.0)
	var dir := Vector3(0.55, 0.30, 0.75).normalized()
	cam_close.global_position = target + dir * h * 2.0
	cam_close.look_at(target)


func _process(_delta: float) -> void:
	if not _capture:
		return
	_frame += 1
	if _frame == 60:
		await RenderingServer.frame_post_draw
		_shot("smoke_wide.png")
		cam_close.make_current()
	elif _frame == 90:
		await RenderingServer.frame_post_draw
		_shot("smoke_closeup.png")
		get_tree().quit()


func _shot(name: String) -> void:
	var path := ProjectSettings.globalize_path(OUT_DIR + name)
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("capture: ", name, " -> ", path, " err=", err)
