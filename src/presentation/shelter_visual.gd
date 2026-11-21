class_name ShelterVisual extends Node3D

var _frame: Node3D
var _cover: Node3D

func _ready() -> void:
	var wood := Color("755340")
	for x in [-1.16, 1.16]:
		_box(self, Vector3(x, 0.15, 0), Vector3(0.1, 0.3, 0.1), wood)
		_box(self, Vector3(x, 0.15, -1.44), Vector3(0.1, 0.3, 0.1), wood)
	_frame = Node3D.new()
	add_child(_frame)
	for x in [-1.12, 1.12]:
		_box(_frame, Vector3(x, 0.88, -0.05), Vector3(0.12, 1.76, 0.12), wood)
		var rafter := _box(_frame, Vector3(x, 1.08, -0.75), Vector3(0.12, 0.12, 1.98), wood)
		rafter.rotation.x = -0.72
	_box(_frame, Vector3(0, 1.72, -0.065), Vector3(2.4, 0.12, 0.12), wood)
	_cover = Node3D.new()
	add_child(_cover)
	var tarp := _box(_cover, Vector3(0, 1.13, -0.77), Vector3(2.53, 0.045, 2.02), Color("687646"))
	tarp.rotation.x = -0.72
	_box(_cover, Vector3(0, 0.035, -0.85), Vector3(0.66, 0.07, 1.05), Color("b98162"))
	render_stage(0)

## Changes placeholder visuals only when the committed stage changes.
func render_stage(stage: int) -> void:
	_frame.visible = stage >= 1
	_cover.visible = stage >= 2

func _box(parent: Node3D, point: Vector3, size_value: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	node.mesh = mesh
	node.position = point
	node.material_override = SceneAssets.material(color)
	parent.add_child(node)
	return node
