class_name RunCheckpoint extends RefCounted

const SCHEMA_VERSION: int = 1
const OWNER_VERSIONS := {"clock": 1, "body": 1, "needs": 1, "inventory": 1, "fires": 1, "rng": 1, "run": 1, "gathering": 1, "survivor": 1}

static func tuning_for(profile: String) -> SliceTuning:
	return preload("res://assets/data/three_day_survival.tres") if profile == "three_night" else preload("res://assets/data/slice_defaults.tres")

static func capture(run: RunCoordinator) -> Dictionary:
	if run.simulation.terminal != &"" or run.simulation.actions.action != &"" or run.simulation.clock._dispatching:
		return {}
	var owners := run.simulation.export_state()
	var gathering := {}
	for entry: WorldInteractable in run.world.interactables:
		if entry.gather_node != null:
			gathering[String(entry.site_id)] = entry.gather_node.export_state()
	owners["gathering"] = gathering
	owners["survivor"] = run.survivor.export_state()
	return {"schema_version": SCHEMA_VERSION, "profile": "three_night" if run.simulation.tuning.chapter_needs_enabled else "first_night",
		"seed": str(run.seed_value), "saved_at_unix": int(Time.get_unix_time_from_system()), "owners": owners}

static func validate(dto: Variant) -> bool:
	if not CheckpointValues.keys(dto, ["schema_version", "profile", "seed", "saved_at_unix", "owners"]):
		return false
	if not CheckpointValues.integer(dto.schema_version, SCHEMA_VERSION, SCHEMA_VERSION) or not CheckpointValues.text(dto.profile) or dto.profile not in ["first_night", "three_night"]:
		return false
	if not CheckpointValues.decimal(dto.seed) or not CheckpointValues.integer(dto.saved_at_unix, 0, 9007199254740991) or not CheckpointValues.keys(dto.owners, OWNER_VERSIONS.keys()):
		return false
	var owners: Dictionary = dto.owners
	if not owners.survivor is Dictionary or not SurvivorController.validate_state(owners.survivor) or not owners.gathering is Dictionary:
		return false
	var tuning := tuning_for(String(dto.profile))
	var nodes := GatherCatalog.create(tuning)
	if not CheckpointValues.keys(owners.gathering, nodes.keys()):
		return false
	for id: StringName in nodes:
		if not owners.gathering[String(id)] is Dictionary or not (nodes[id] as GatherNode).restore_state(owners.gathering[String(id)]):
			return false
	var state := owners.duplicate(true)
	state.erase("survivor")
	state.erase("gathering")
	var simulation := RunSimulation.new(dto.seed.to_int(), tuning)
	if not simulation.restore_state(state) or simulation.rng.export_state().seed != dto.seed:
		return false
	return true
