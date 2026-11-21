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

func export_state() -> Dictionary:
	var counts := {}
	var revisions := {}
	for item: StringName in _counts:
		counts[String(item)] = _counts[item]
		revisions[String(item)] = _revisions[item]
	var kit: Array = []
	for tool: StringName in tools:
		kit.append(String(tool))
	return {"tools": kit, "counts": counts, "revisions": revisions}

func restore_state(dto: Dictionary) -> bool:
	if not CheckpointValues.keys(dto, ["tools", "counts", "revisions"]) or not dto.tools is Array or not dto.counts is Dictionary or not dto.revisions is Dictionary:
		return false
	var kit: Array[StringName] = []
	for tool: Variant in dto.tools:
		if not CheckpointValues.text(tool) or tool not in ["hatchet", "knife", "ferro_rod"] or StringName(tool) in kit:
			return false
		kit.append(StringName(tool))
	if dto.counts.size() != dto.revisions.size():
		return false
	for item: Variant in dto.counts:
		if not CheckpointValues.text(item) or item not in ["stick", "log", "grass", "bark", "pemmican"] or not dto.revisions.has(item):
			return false
		if not CheckpointValues.integer(dto.counts[item], 0, 1000000) or not CheckpointValues.integer(dto.revisions[item], 1, 2147483647):
			return false
	tools = kit
	_counts.clear()
	_revisions.clear()
	for item: String in dto.counts:
		_counts[StringName(item)] = int(dto.counts[item])
		_revisions[StringName(item)] = int(dto.revisions[item])
	return true
