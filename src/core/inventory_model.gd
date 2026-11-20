class_name InventoryModel extends RefCounted

var tools: Array[StringName] = [&"hatchet", &"knife", &"ferro_rod"]
var _counts: Dictionary[StringName, int] = {}
var _revisions: Dictionary[StringName, int] = {}
var _wire_uses: int = 0
var _wire_revision: int = 0
const CARRY_CAPACITY_KG := 25.0
const CHAPTER_MASS_KG: Dictionary[StringName, float] = {
	&"hatchet": 1.0, &"knife": 0.2, &"ferro_rod": 0.1, &"snare_wire": 0.2,
	&"tarp": 1.2, &"pemmican": 0.1, &"stick": 0.2, &"log": 2.5, &"grass": 0.02, &"bark": 0.05,
	&"hare_raw": 0.4, &"hare_cooked": 0.15,
}

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

## Equips the chapter's existing wire with authored durability.
func equip_snare_wire(uses: int = 50) -> void:
	if uses <= 0 or has_tool(&"snare_wire"):
		return
	tools.append(&"snare_wire")
	_wire_uses = uses
	_wire_revision += 1

## Captures the usable wire's current revision, or -1 if unavailable.
func wire_revision() -> int:
	return _wire_revision if _wire_uses > 0 and has_tool(&"snare_wire") else -1

## Charges one authorized use and removes the tool on its last use.
func spend_wire(revision: int) -> bool:
	if revision < 0 or revision != wire_revision():
		return false
	_wire_uses -= 1
	_wire_revision += 1
	if _wire_uses == 0:
		tools.erase(&"snare_wire")
	return true

## Calculates what fits after one optional input spend; caller validates overflow before applying.
func prepare_exchange(input: StringName, revision: int, output: StringName, units: int) -> Dictionary:
	if (input != &"" and (revision < 0 or revision != stack_revision(input) or not CHAPTER_MASS_KG.has(input))) or not CHAPTER_MASS_KG.has(output) or units <= 0:
		return {}
	var carried := 0.0
	for tool: StringName in tools:
		carried += CHAPTER_MASS_KG.get(tool, 0.0)
	for item: StringName in _counts:
		carried += count(item) * float(CHAPTER_MASS_KG.get(item, 0.0))
	if input != &"":
		carried -= CHAPTER_MASS_KG[input]
	var fits := clampi(floori((CARRY_CAPACITY_KG - carried + 0.00001) / CHAPTER_MASS_KG[output]), 0, units)
	return {&"input": input, &"output": output, &"fits": fits, &"overflow": units - fits}

## Applies an exchange immediately after preparation, with no callbacks between effects.
func apply_exchange(plan: Dictionary) -> void:
	if plan[&"input"] != &"":
		var spent := consume(plan[&"input"], 1)
		assert(spent)
	add(plan[&"output"], plan[&"fits"])

## Tests fixed-kit tool ownership.
func has_tool(tool: StringName) -> bool:
	return tools.has(tool)

## Returns a detached counts snapshot.
func snapshot() -> Dictionary[StringName, int]:
	return _counts.duplicate()
