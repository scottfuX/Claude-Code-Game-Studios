class_name InventoryModel extends RefCounted

signal item_lost(tool: StringName)

var tools: Array[StringName] = [&"hatchet", &"knife", &"ferro_rod"]
var _counts: Dictionary[StringName, int] = {}
var _revisions: Dictionary[StringName, int] = {}
var _wire_uses: int = 0
var _wire_revision: int = 0
var _chapter_data: ChapterContentTuning

var _wet_counts: Dictionary[StringName, float] = {}
var _immersions: Dictionary[int, bool] = {}
const SOAKABLE: Array[StringName] = [&"stick", &"log", &"bark", &"grass"]
const TINDER_QUALITY: Dictionary[StringName, float] = {&"bark": 0.9, &"grass": 0.7, &"stick": 0.3}

func tinder_quality(item: StringName) -> float:
	return TINDER_QUALITY.get(item, 0.0)

func _init(chapter_data: ChapterContentTuning = null) -> void:
	_chapter_data = chapter_data if chapter_data != null else preload("res://assets/data/chapter_content_defaults.tres")

func soak_carried(event_id: int) -> void:
	if event_id < 0 or _immersions.has(event_id):
		return
	_immersions[event_id] = true
	for item: StringName in SOAKABLE:
		_wet_counts[item] = count(item)

func wetness(item: StringName) -> float:
	return float(_wet_counts.get(item, 0)) / count(item) if count(item) > 0 else 0.0

func lose_tool(tool: StringName) -> bool:
	if not tools.has(tool):
		return false
	tools.erase(tool)
	item_lost.emit(tool)
	return true

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
		var remaining_wet := wetness(item) * (count(item) - amount)
		_counts[item] = count(item) - amount
		_wet_counts[item] = remaining_wet
		_revisions[item] = _revisions.get(item, 0) + 1
	return true

## Captures a nonempty stack version; e.g. save [code]inventory.stack_revision(&"pemmican")[/code] when opening a meal.
func stack_revision(item: StringName) -> int:
	return _revisions.get(item, -1) if count(item) > 0 else -1

## Spends one unit only from the prepared stack, e.g. [code]inventory.consume_prepared(&"pemmican", version)[/code].
func consume_prepared(item: StringName, revision: int) -> bool:
	return revision >= 0 and revision == stack_revision(item) and consume(item, 1)

## Equips the chapter's existing wire with authored durability.
func equip_snare_wire(uses: int = -1) -> void:
	if uses == -1:
		uses = _chapter_data.wire_durability
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
	var mass := _chapter_data.item_mass_kg
	if (input != &"" and (revision < 0 or revision != stack_revision(input) or not mass.has(input))) or not mass.has(output) or units <= 0:
		return {}
	var output_mass: float = mass[output]
	if not is_finite(output_mass) or output_mass <= 0.0:
		return {}
	var carried := 0.0
	for tool: StringName in tools:
		carried += mass.get(tool, 0.0)
	for item: StringName in _counts:
		carried += count(item) * float(mass.get(item, 0.0))
	if input != &"":
		carried -= mass[input]
	var fits := clampi(floori((_chapter_data.carry_capacity_kg - carried + 0.00001) / output_mass), 0, units)
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

func export_state(chapter: bool = false) -> Dictionary:
	var counts := {}
	var revisions := {}
	for item: StringName in _counts:
		counts[String(item)] = _counts[item]
		revisions[String(item)] = _revisions[item]
	var kit: Array = []
	for tool: StringName in tools:
		kit.append(String(tool))
	var dto := {"tools": kit, "counts": counts, "revisions": revisions}
	if chapter:
		dto["wire_uses"] = _wire_uses
	return dto

func restore_state(dto: Dictionary, chapter: bool = false) -> bool:
	var keys := ["tools", "counts", "revisions"]
	if chapter:
		keys.append("wire_uses")
	if not CheckpointValues.keys(dto, keys) or not dto.tools is Array or not dto.counts is Dictionary or not dto.revisions is Dictionary:
		return false
	var wire_uses := 0
	if chapter:
		if not CheckpointValues.integer(dto.wire_uses, 0, _chapter_data.wire_durability):
			return false
		wire_uses = int(dto.wire_uses)
	var tool_ids := ["hatchet", "knife", "ferro_rod"]
	if wire_uses > 0:
		tool_ids.append("snare_wire")
	var kit: Array[StringName] = []
	for tool: Variant in dto.tools:
		if not CheckpointValues.text(tool) or tool not in tool_ids or StringName(tool) in kit:
			return false
		kit.append(StringName(tool))
	if kit.has(&"snare_wire") != (wire_uses > 0):
		return false
	if dto.counts.size() != dto.revisions.size():
		return false
	var item_ids := ["stick", "log", "grass", "bark", "pemmican"]
	if chapter:
		item_ids.append_array(["tarp", "hare_raw", "hare_cooked"])
	for item: Variant in dto.counts:
		if not CheckpointValues.text(item) or item not in item_ids or not dto.revisions.has(item):
			return false
		if not CheckpointValues.integer(dto.counts[item], 0, 1000000) or not CheckpointValues.integer(dto.revisions[item], 1, 2147483647):
			return false
	tools = kit
	_wire_uses = wire_uses
	_wire_revision += 1
	_counts.clear()
	_revisions.clear()
	for item: String in dto.counts:
		_counts[StringName(item)] = int(dto.counts[item])
		_revisions[StringName(item)] = int(dto.revisions[item])
	return true
