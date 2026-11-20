class_name InventoryModel extends RefCounted

var tools: Array[StringName] = [&"hatchet", &"knife", &"ferro_rod"]
var _counts: Dictionary[StringName, int] = {}
var _revisions: Dictionary[StringName, int] = {}

## Returns the owned count, zero for an absent item.
func count(item: StringName) -> int:
	return _counts.get(item, 0)

## Adds nonnegative produce without capacity limits in this slice.
func add(item: StringName, amount: int) -> bool:
	if item == &"" or amount < 0:
		return false
	if amount > 0:
		_counts[item] = count(item) + amount
		_revisions[item] = _revisions.get(item, 0) + 1
	return true

## Consumes only when the whole request is available.
func consume(item: StringName, amount: int) -> bool:
	if amount < 0 or count(item) < amount:
		return false
	if amount > 0:
		_counts[item] = count(item) - amount
		_revisions[item] = _revisions.get(item, 0) + 1
	return true

## Captures a nonempty stack version; e.g. save [code]inventory.stack_revision(&"pemmican")[/code] when opening a meal.
func stack_revision(item: StringName) -> int:
	return _revisions.get(item, -1) if count(item) > 0 else -1

## Spends one unit only from the prepared stack, e.g. [code]inventory.consume_prepared(&"pemmican", version)[/code].
func consume_prepared(item: StringName, revision: int) -> bool:
	return revision >= 0 and revision == stack_revision(item) and consume(item, 1)

## Tests fixed-kit tool ownership.
func has_tool(tool: StringName) -> bool:
	return tools.has(tool)

## Returns a detached counts snapshot.
func snapshot() -> Dictionary[StringName, int]:
	return _counts.duplicate()
