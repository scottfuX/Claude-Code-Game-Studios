class_name GatherCatalog extends RefCounted

const BUSHES: Array[Vector3] = [Vector3(0, 0, -1.6), Vector3(-4, 0, -3), Vector3(5, 0, -4), Vector3(-6, 0, 5), Vector3(7, 0, 5)]
const LOGS: Array[Vector3] = [Vector3(2.8, 0, -2), Vector3(-4, 0, 3), Vector3(6, 0, 1), Vector3(-2, 0, -7)]
const GRASS: Array[Vector3] = [Vector3(-2.4, 0, -1), Vector3(4, 0, 5), Vector3(0, 0, 6), Vector3(4, 0, -7)]

static func id_for(kind: StringName, position: Vector3) -> StringName:
	return StringName("%s:%s:%s" % [kind, position.x, position.z])

## Rebuilds the active profile's immutable reserves from its run seed.
static func create(tuning: SliceTuning, seed_value: int = 20261119) -> Dictionary:
	if tuning.large_map_enabled:
		var result := {}
		for node: Dictionary in LargeMapLayout.new(RunRng.new(seed_value), tuning.world).nodes:
			var entry := GatherNode.new(node.kind, node.remaining, node.bonus_grass, node.bark_remaining, node.sticks_remaining)
			entry.node_id = node.id
			result[node.id] = entry
		return result
	return legacy(tuning)

## Catalog for schema-one saves made before the seeded world chapter.
static func legacy(tuning: SliceTuning) -> Dictionary:
	var data: PlayfieldTuning = preload("res://assets/data/playfield_defaults.tres")
	var result := {}
	for p: Vector3 in BUSHES:
		result[id_for(&"bush", p)] = GatherNode.new(&"bush", data.bush_sticks, data.bush_bonus_grass)
	for p: Vector3 in LOGS + tuning.extra_deadfalls:
		result[id_for(&"deadfall", p)] = GatherNode.new(&"deadfall", data.deadfall_logs, 0, data.deadfall_bark)
	for p: Vector3 in GRASS:
		result[id_for(&"grass", p)] = GatherNode.new(&"grass", data.grass_reserve)
	return result
