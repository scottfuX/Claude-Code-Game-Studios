class_name HareFoodFeature extends RefCounted

const TRAIL := &"hare_trail"
const BUNDLE := &"hare_bundle"
const SET := &"set_hare_snare"
const CHECK := &"check_hare_snare"
const COOK := &"cook_hare"
const TAKE := &"take_hare"
const RAW := &"hare_raw"
const COOKED := &"hare_cooked"
const DAY_MINUTES := 1440

enum Trap { UNSET, ARMED, SPENT }

var state: Trap = Trap.UNSET
var armed_minute: int = -1
var bundle_count: int = 0
var bundle_position: Vector3
var _bundle_item: StringName
var _bundle_revision: int = 0
var _inventory: InventoryModel
var _clock: Clock
var _place_bundle: Callable
var _live := true
var _tuning: ChapterContentTuning

func _init(inventory: InventoryModel, clock: Clock, can_place_bundle: Callable, tuning: ChapterContentTuning = null) -> void:
	_inventory = inventory
	_clock = clock
	_place_bundle = can_place_bundle
	_tuning = tuning if tuning != null else preload("res://assets/data/chapter_content_defaults.tres")

## Rejects an unset attempt that cannot finish before either authored opening.
func can_set(duration_multiplier: float) -> bool:
	return _live and state == Trap.UNSET and _inventory.wire_revision() >= 0 and _closing_minute(_now() + floori(_tuning.set_minutes * duration_multiplier)) >= 0

## Projects readiness from settled Clock time; checking readiness never claims produce.
func catch_ready() -> bool:
	if not _live or state != Trap.ARMED:
		return false
	var closing := _closing_minute(armed_minute)
	return closing >= 0 and _now() >= closing

## Starts an authored trail action; one captured wire revision authorizes one use.
func start_trail(run: RunSimulation, action: StringName, focused: Callable, feet: Callable) -> bool:
	var wire := _inventory.wire_revision()
	var expected := state
	if not _owns_run(run) or not focused.is_valid() or not ((action == SET and can_set(run.action_duration_multiplier())) or (action == CHECK and state == Trap.ARMED)):
		return false
	var valid := func() -> bool:
		return _live and state == expected and focused.call() and (action != SET or _inventory.wire_revision() == wire)
	if action == SET:
		return run.start_feature_action(SET, _tuning.set_minutes, valid, _arm.bind(wire))
	return run.start_feature_action(CHECK, _tuning.check_minutes, valid, _check.bind(feet))

## Starts cooking at one captured Burning fire and raw stack without consuming fuel directly.
func start_cook(run: RunSimulation, fire: FireController, focused: Callable, feet: Callable) -> bool:
	var raw_revision := _inventory.stack_revision(RAW)
	if not _owns_run(run) or not focused.is_valid() or raw_revision < 0 or not run.fires.has(fire) or fire.stage != &"Burning":
		return false
	var fire_revision := fire.interaction_revision
	var valid := func() -> bool:
		return _live and fire.stage == &"Burning" and fire.interaction_revision == fire_revision and _inventory.stack_revision(RAW) == raw_revision and focused.call()
	return run.start_feature_action(COOK, _tuning.cook_minutes, valid, _cook.bind(raw_revision, feet))

## Picks up as much of the captured bundle as fits, leaving the rest in place.
func start_take(run: RunSimulation, focused: Callable) -> bool:
	if not _owns_run(run) or not focused.is_valid() or bundle_count <= 0:
		return false
	var revision := _bundle_revision
	var valid := func() -> bool:
		return _live and _bundle_revision == revision and focused.call()
	return run.start_feature_action(TAKE, _tuning.pickup_minutes, valid, _take)

## Invalidates pending work and disables the world placement port.
func dispose() -> void:
	_live = false
	_place_bundle = Callable()

func _now() -> int:
	return (_clock.day - 1) * DAY_MINUTES + _clock.minute_of_day

func _owns_run(run: RunSimulation) -> bool:
	return _live and run.inventory == _inventory and run.clock == _clock

func _closing_minute(armed: int) -> int:
	for day_offset in 2:
		var opening := day_offset * DAY_MINUTES + _tuning.crossing_start_minute
		if armed <= opening:
			return opening + _tuning.crossing_length_minutes
	return -1

func _arm(wire: int) -> StringName:
	var now := _now()
	if _closing_minute(now) < 0:
		return &"missed_window"
	if not _inventory.spend_wire(wire):
		return &"unavailable"
	armed_minute = now
	state = Trap.ARMED
	return &"wire_broken" if _inventory.wire_revision() < 0 else &""

func _check(feet: Callable) -> StringName:
	if not catch_ready():
		return &"nothing_yet"
	var cause := _exchange(&"", -1, RAW, 1, feet)
	if cause in [&"", &"piled"]:
		state = Trap.SPENT
	return cause

func _cook(revision: int, feet: Callable) -> StringName:
	return _exchange(RAW, revision, COOKED, 2, feet)

func _take() -> StringName:
	var plan := _inventory.prepare_exchange(&"", -1, _bundle_item, bundle_count)
	if plan.is_empty() or int(plan[&"fits"]) <= 0:
		return &"pack_full"
	_inventory.apply_exchange(plan)
	bundle_count = plan[&"overflow"]
	_bundle_revision += 1
	return &""

func _exchange(input: StringName, revision: int, output: StringName, amount: int, feet: Callable) -> StringName:
	var plan := _inventory.prepare_exchange(input, revision, output, amount)
	if plan.is_empty():
		return &"unavailable"
	var overflow: int = plan[&"overflow"]
	var point := Vector3.ZERO
	if overflow > 0:
		if bundle_count > 0 or not feet.is_valid() or not _place_bundle.is_valid():
			return &"pack_full"
		point = feet.call()
		if not _place_bundle.call(point):
			return &"pack_full"
	_inventory.apply_exchange(plan)
	if overflow > 0:
		bundle_position = point
		bundle_count = overflow
		_bundle_item = output
		_bundle_revision += 1
		return &"piled"
	return &""
