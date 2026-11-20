class_name ImmersionEvent extends RefCounted

var sequence: int
var cell: Vector2i
var position: Vector3

func _init(id: int, ice_cell: Vector2i, contact: Vector3) -> void:
	sequence = id
	cell = ice_cell
	position = contact
