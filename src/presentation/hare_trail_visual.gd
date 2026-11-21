class_name HareTrailVisual extends Node3D

var route := PackedVector3Array()
var _catch: MeshInstance3D

func _ready() -> void:
	var print_material := SceneAssets.material(Color("78869a"))
	var print_mesh := SphereMesh.new()
	print_mesh.radius = 0.11
	print_mesh.height = 0.22
	print_mesh.radial_segments = 8
	print_mesh.rings = 4
	for index in range(1, route.size()):
		var offset := route[index] - route[index - 1]
		var forward := offset.normalized()
		var cross := Vector3.UP.cross(forward)
		var spacing := 2.9 if offset.length() > 4.0 else 0.38
		for hop in maxi(1, ceili(offset.length() / spacing)):
			var center := route[index - 1] + forward * minf(offset.length(), float(hop + 1) * spacing)
			for side: float in [-1.0, 1.0]:
				var track := MeshInstance3D.new()
				track.mesh = print_mesh
				track.material_override = print_material
				track.position = center + cross * side * 0.16 + Vector3.UP * 0.018 + forward * side * 0.11
				track.scale = Vector3(0.86, 0.12, 1.8)
				track.rotation.y = atan2(forward.x, forward.z)
				add_child(track)
	_catch = bundle_mesh()
	_catch.position += route[-1]
	add_child(_catch)
	render_catch(false)

## Shows the abstract catch when the run publishes it as ready.
func render_catch(ready: bool) -> void:
	_catch.visible = ready

## Builds the non-graphic placeholder shared by the catch and pickup.
static func bundle_mesh() -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.24
	mesh.height = 0.48
	mesh.radial_segments = 8
	mesh.rings = 4
	node.mesh = mesh
	node.position.y = 0.14
	node.scale = Vector3(1.0, 0.55, 1.3)
	node.material_override = SceneAssets.material(Color("88705c"))
	return node
