class_name WorldInteractable extends Node3D

var gather_node: GatherNode
var display_name: String = ""
var fire: FireController

## Returns eligible gather verbs in primary/secondary order.
func gather_verbs(resolver: GatheringResolver, inventory: InventoryModel) -> Array[StringName]:
	var result: Array[StringName] = []
	if gather_node == null:
		return result
	for action: StringName in [&"gather_sticks", &"chop_log", &"strip_bark", &"gather_grass"]:
		if resolver.can_gather(gather_node, action, inventory):
			result.append(action)
	return result
