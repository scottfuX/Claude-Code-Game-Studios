class_name GatherNode extends RefCounted

var kind: StringName
var remaining: int
var bonus_grass: int
var bark_remaining: int
var _limits: Array[int] = []

func _init(node_kind: StringName = &"bush", reserve: int = 0, grass_reserve: int = 0, bark_reserve: int = 0) -> void:
	kind = node_kind
	remaining = maxi(0, reserve)
	bonus_grass = maxi(0, grass_reserve)
	bark_remaining = maxi(0, bark_reserve)
	_limits.assign([remaining, bonus_grass, bark_remaining])

func export_state() -> Dictionary:
	return {"kind": String(kind), "remaining": remaining, "bonus_grass": bonus_grass, "bark_remaining": bark_remaining}

func restore_state(dto: Dictionary) -> bool:
	if not CheckpointValues.keys(dto, ["kind", "remaining", "bonus_grass", "bark_remaining"]) or not CheckpointValues.text(dto.kind) or dto.kind != String(kind):
		return false
	for i: int in 3:
		if not CheckpointValues.integer(dto[["remaining", "bonus_grass", "bark_remaining"][i]], 0, _limits[i]):
			return false
	remaining = int(dto.remaining)
	bonus_grass = int(dto.bonus_grass)
	bark_remaining = int(dto.bark_remaining)
	return true

## Returns whether the finite primary reserve has been exhausted.
func is_depleted() -> bool:
	return remaining == 0 and bark_remaining == 0
