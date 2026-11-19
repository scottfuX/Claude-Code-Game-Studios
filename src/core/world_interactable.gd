class_name WorldInteractable extends Node3D

var gather_node: GatherNode
var display_name: String = ""
var fire: FireController
const GATHER_ACTIONS: Array[StringName] = [&"gather_sticks", &"chop_log", &"strip_bark", &"gather_grass"]
var _verbs: Array[StringName] = []
var _cached_node: GatherNode
var _cached_resolver: GatheringResolver
var _kind: StringName
var _remaining: int = -1
var _bark: int = -1
var _hatchet: bool = false
var _knife: bool = false

## Borrows cached verbs until reserves, kind or tools change; e.g. gather_verbs(resolver, inventory).
func gather_verbs(resolver: GatheringResolver, inventory: InventoryModel) -> Array[StringName]:
	if gather_node == null or resolver == null or inventory == null:
		_cached_node = null
		_verbs.clear()
		return _verbs
	var hatchet := inventory.has_tool(&"hatchet")
	var knife := inventory.has_tool(&"knife")
	if _cached_node == gather_node and _cached_resolver == resolver and _kind == gather_node.kind and _remaining == gather_node.remaining and _bark == gather_node.bark_remaining and _hatchet == hatchet and _knife == knife:
		return _verbs
	_cached_node = gather_node
	_cached_resolver = resolver
	_kind = gather_node.kind
	_remaining = gather_node.remaining
	_bark = gather_node.bark_remaining
	_hatchet = hatchet
	_knife = knife
	_verbs.clear()
	for action: StringName in GATHER_ACTIONS:
		if resolver.can_gather(gather_node, action, inventory):
			_verbs.append(action)
	return _verbs
