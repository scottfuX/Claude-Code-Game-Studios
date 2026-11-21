class_name GatherNode extends RefCounted

var kind: StringName
var remaining: int
var bonus_grass: int
var bark_remaining: int
var _limits: Array[int] = []
var sticks_remaining: int = 0
var node_id: StringName = &""
var action_progress: Dictionary[StringName, float] = {}

func _init(node_kind: StringName = &"bush", reserve: int = 0, grass_reserve: int = 0, bark_reserve: int = 0, sticks: int = 0) -> void:
	kind = node_kind
	remaining = maxi(0, reserve)
	bonus_grass = maxi(0, grass_reserve)
	bark_remaining = maxi(0, bark_reserve)
	sticks_remaining = maxi(0, sticks)
	_limits.assign([remaining, bonus_grass, bark_remaining, sticks_remaining])

func export_state() -> Dictionary:
	var progress := {}
	for action: StringName in action_progress:
		progress[String(action)] = action_progress[action]
	return {"kind": String(kind), "remaining": remaining, "bonus_grass": bonus_grass, "bark_remaining": bark_remaining, "sticks_remaining": sticks_remaining, "action_progress": progress}

func restore_state(dto: Dictionary) -> bool:
	var shape := dto.duplicate()
	shape.erase("sticks_remaining")
	shape.erase("action_progress")
	if not CheckpointValues.keys(shape, ["kind", "remaining", "bonus_grass", "bark_remaining"]) or not CheckpointValues.text(dto.kind) or dto.kind != String(kind):
		return false
	if not CheckpointValues.integer(dto.get("sticks_remaining", _limits[3]), 0, _limits[3]):
		return false
	for i: int in 3:
		if not CheckpointValues.integer(dto[["remaining", "bonus_grass", "bark_remaining"][i]], 0, _limits[i]):
			return false
	var progress: Variant = dto.get("action_progress", {})
	if not progress is Dictionary:
		return false
	for action: Variant in progress:
		if not CheckpointValues.text(action) or action != "chop_log" or kind != &"deadfall" or not CheckpointValues.number(progress[action], 0, 1):
			return false
	remaining = int(dto.remaining)
	bonus_grass = int(dto.bonus_grass)
	bark_remaining = int(dto.bark_remaining)
	sticks_remaining = int(dto.get("sticks_remaining", _limits[3]))
	action_progress.clear()
	for action: String in progress:
		action_progress[StringName(action)] = float(progress[action])
	return true

## Returns whether the finite primary reserve has been exhausted.
func is_depleted() -> bool:
	return remaining == 0 and bark_remaining == 0 and sticks_remaining == 0
