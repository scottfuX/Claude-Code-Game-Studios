class_name GatheringResolver extends RefCounted

var tuning: SliceTuning

func _init(data: SliceTuning = null) -> void:
	tuning = data if data != null else preload("res://assets/data/slice_defaults.tres")

## Validates target, verb and tools before admission or RNG draws.
func can_gather(node: GatherNode, action: StringName, inventory: InventoryModel) -> bool:
	if node == null or node.is_depleted():
		return false
	match action:
		&"gather_sticks":
			return node.kind == &"bush" and node.remaining > 0
		&"chop_log":
			return node.kind == &"deadfall" and node.remaining > 0 and inventory.has_tool(&"hatchet")
		&"strip_bark":
			return node.kind == &"deadfall" and node.bark_remaining > 0 and inventory.has_tool(&"knife")
		&"gather_grass":
			return node.kind == &"grass" and node.remaining > 0
	return false

## Applies one admitted completion; failures never deplete either reserve.
func resolve(node: GatherNode, action: StringName, success: bool, inventory: InventoryModel) -> bool:
	if not can_gather(node, action, inventory):
		return false
	var take: int = tuning.gather_take[action]
	var item: StringName = {&"gather_sticks": &"stick", &"chop_log": &"log", &"strip_bark": &"bark", &"gather_grass": &"grass"}[action]
	var attempted := mini(take, node.bark_remaining if action == &"strip_bark" else node.remaining)
	var kept := attempted if success else (0 if action == &"chop_log" else attempted / 2)
	inventory.add(item, kept)
	if node.kind == &"bush" and node.bonus_grass > 0:
		inventory.add(&"grass", 1 if success else 0)
		if success:
			node.bonus_grass -= 1
	if success:
		if action == &"strip_bark":
			node.bark_remaining -= attempted
		else:
			node.remaining -= attempted
	return true
