class_name SceneAssets extends RefCounted

const FLAT: Material = preload("res://assets/materials/flat_palette.tres")
const SNOW: Material = preload("res://assets/materials/snow_ground.tres")

## Applies the vertex-colour palette material to every imported mesh.
static func apply_flat(node: Node) -> void:
	if node is MeshInstance3D:
		node.material_override = FLAT
	for child: Node in node.get_children():
		apply_flat(child)

## Creates a rough flat-colour material for procedural world geometry.
static func material(color: Color, emission: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 1.0
	result.metallic_specular = 0.0
	if emission:
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = 2.0
	return result
