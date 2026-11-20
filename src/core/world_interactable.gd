class_name WorldInteractable extends Node3D

var gather_node: GatherNode
var display_name: String = ""
var site_id: StringName = &""
var chapter_target: bool = false
const GATHER_ACTIONS: Array[StringName] = [&"gather_sticks", &"chop_log", &"strip_bark", &"gather_grass"]
var _verbs: Array[StringName] = []
var _cached_node: GatherNode
var _cached_query: Callable
var _kind: StringName
var _remaining: int = -1
var _bark: int = -1
var _hatchet: bool = false
var _knife: bool = false

## Borrows read-only verbs for a reserve/tool-only policy; e.g. gather_verbs(policy.can_gather, inventory).
func gather_verbs(query: Callable, inventory: InventoryModel) -> Array[StringName]:
	if gather_node == null or not query.is_valid() or inventory == null:
		_cached_node = null
		_verbs.clear()
		return _verbs
	var hatchet := inventory.has_tool(&"hatchet")
	var knife := inventory.has_tool(&"knife")
	if _cached_node == gather_node and _cached_query == query and _kind == gather_node.kind and _remaining == gather_node.remaining and _bark == gather_node.bark_remaining and _hatchet == hatchet and _knife == knife:
		return _verbs
	_cached_node = gather_node
	_cached_query = query
	_kind = gather_node.kind
	_remaining = gather_node.remaining
	_bark = gather_node.bark_remaining
	_hatchet = hatchet
	_knife = knife
	_verbs.clear()
	for action: StringName in GATHER_ACTIONS:
		if query.call(gather_node, action, inventory):
			_verbs.append(action)
	return _verbs
