class_name GatherNode extends RefCounted

var kind: StringName
var remaining: int
var bonus_grass: int
var bark_remaining: int

func _init(node_kind: StringName = &"bush", reserve: int = 0, grass_reserve: int = 0, bark_reserve: int = 0) -> void:
	kind = node_kind
	remaining = maxi(0, reserve)
	bonus_grass = maxi(0, grass_reserve)
	bark_remaining = maxi(0, bark_reserve)

## Returns whether the finite primary reserve has been exhausted.
func is_depleted() -> bool:
	return remaining == 0 and bark_remaining == 0
