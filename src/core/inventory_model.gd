class_name InventoryModel extends RefCounted

var tools: Array[StringName] = [&"hatchet", &"knife", &"ferro_rod"]
var _counts: Dictionary[StringName, int] = {}

## Returns the owned count, zero for an absent item.
func count(item: StringName) -> int:
	return _counts.get(item, 0)

## Adds nonnegative produce without capacity limits in this slice.
func add(item: StringName, amount: int) -> bool:
	if item == &"" or amount < 0:
		return false
	_counts[item] = count(item) + amount
	return true

## Consumes only when the whole request is available.
func consume(item: StringName, amount: int) -> bool:
	if amount < 0 or count(item) < amount:
		return false
	_counts[item] = count(item) - amount
	return true

## Tests fixed-kit tool ownership.
func has_tool(tool: StringName) -> bool:
	return tools.has(tool)

## Returns a detached counts snapshot.
func snapshot() -> Dictionary[StringName, int]:
	return _counts.duplicate()
