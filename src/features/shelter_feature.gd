class_name ShelterFeature extends RefCounted

const ID := &"chapter_shelter"
const FRAME := &"build_shelter_frame"
const COVER := &"cover_shelter"
var stage: int = 0
var _site: Transform3D
var _bounds: AABB
var _inventory: InventoryModel
var _thermal: ThermalField
var _live := true

func _init(plot: Dictionary, inventory: InventoryModel, thermal: ThermalField) -> void:
	_site = plot[&"site"]
	_bounds = plot[&"bounds"]
	_inventory = inventory
	_thermal = thermal

## Returns the current build verb only when the required material is carried.
func offered_action() -> StringName:
	if not _live:
		return &""
	if stage == 0 and _inventory.count(&"log") > 0:
		return FRAME
	if stage == 1 and _inventory.count(&"tarp") > 0:
		return COVER
	return &""

## Prepares a stage attempt with a captured material version and a live target query.
func start(run: RunSimulation, action: StringName, focused: Callable) -> bool:
	if run.inventory != _inventory or run.thermal != _thermal or action == &"" or action != offered_action():
		return false
	var item := &"log" if action == FRAME else &"tarp"
	var revision := _inventory.stack_revision(item)
	var expected_stage := stage
	var valid := func() -> bool:
		return _live and stage == expected_stage and _inventory.stack_revision(item) == revision and focused.is_valid() and focused.call()
	return run.start_feature_action(action, 6.0 if action == FRAME else 4.0, valid, _commit.bind(expected_stage, item, revision))

## Checks both the bedroll and the real Body sample; never moves the survivor.
func can_sleep(position: Vector3) -> bool:
	return _live and stage == 2 and ThermalField.contains_point(_site, _bounds, position, true) and ThermalField.contains_point(_site, _bounds, _site * Vector3(0, 0, -0.8), true)

## Invalidates old attempts and withdraws this run's registered volume.
func dispose() -> void:
	_live = false
	if stage == 2:
		_thermal.remove_insulation(ID, 2)

func _commit(expected_stage: int, item: StringName, revision: int) -> StringName:
	if not _live or stage != expected_stage:
		return &"unavailable"
	var plan: Dictionary = {}
	if expected_stage == 1:
		plan = _thermal.prepare_insulation(ID, 2, _site, _bounds, 0.1, 2.0)
		if plan.is_empty():
			return &"unavailable"
	if not _inventory.consume_prepared(item, revision):
		return &"unavailable"
	stage += 1
	if stage == 2:
		_thermal.apply_insulation(plan)
	return &""
