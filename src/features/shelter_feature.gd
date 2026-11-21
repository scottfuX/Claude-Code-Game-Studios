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
var _tuning: ChapterContentTuning

func _init(plot: Dictionary, inventory: InventoryModel, thermal: ThermalField, tuning: ChapterContentTuning = null) -> void:
	_site = plot[&"site"]
	_bounds = plot[&"bounds"]
	_inventory = inventory
	_thermal = thermal
	_tuning = tuning if tuning != null else preload("res://assets/data/chapter_content_defaults.tres")

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
	return run.start_feature_action(action, _tuning.frame_minutes if action == FRAME else _tuning.cover_minutes, valid, _commit.bind(expected_stage, item, revision))

## Checks both the bedroll and the real Body sample; never moves the survivor.
func can_sleep(position: Vector3) -> bool:
	return _live and stage == 2 and ThermalField.contains_point(_site, _bounds, position, true) and ThermalField.contains_point(_site, _bounds, _site * Vector3(0, 0, -0.8), true)

## Rebuilds insulation from a validated stage without spending materials again.
func restore_stage(saved_stage: int) -> bool:
	if not _live or stage != 0 or saved_stage < 0 or saved_stage > 2:
		return false
	if saved_stage == 2:
		var plan := _thermal.prepare_insulation(ID, 2, _site, _bounds, _tuning.shelter_exposure, _tuning.shelter_bonus_c)
		if plan.is_empty():
			return false
		_thermal.apply_insulation(plan)
	stage = saved_stage
	return true

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
		plan = _thermal.prepare_insulation(ID, 2, _site, _bounds, _tuning.shelter_exposure, _tuning.shelter_bonus_c)
		if plan.is_empty():
			return &"unavailable"
	if not _inventory.consume_prepared(item, revision):
		return &"unavailable"
	stage += 1
	if stage == 2:
		_thermal.apply_insulation(plan)
	return &""
