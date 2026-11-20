class_name RunCoordinator extends Node3D

signal restart_requested
signal switch_chapter_requested

const PLAYFIELD: PlayfieldTuning = preload("res://assets/data/playfield_defaults.tres")
const VERB_NAMES: Dictionary[StringName, String] = {
	&"gather_sticks": "VERB_GATHER_STICKS", &"chop_log": "VERB_CHOP_LOG", &"strip_bark": "VERB_STRIP_BARK",
	&"gather_grass": "VERB_GATHER_GRASS", &"clear_snow": "VERB_CLEAR_SNOW", &"arrange_tinder": "VERB_ARRANGE_TINDER",
	&"strike": "VERB_STRIKE", &"blow_embers": "VERB_BLOW_EMBERS", &"add_fuel": "VERB_ADD_FUEL",
	&"eat_snow": "VERB_DRINK_SNOW", &"eat": "VERB_EAT_RATION",
	&"eat_hare": "VERB_EAT_HARE",
	ShelterFeature.FRAME: "VERB_BUILD_SHELTER", ShelterFeature.COVER: "VERB_COVER_SHELTER",
	&"sleep": "VERB_SLEEP_SHELTER",
	HareFoodFeature.SET: "VERB_SET_HARE_SNARE", HareFoodFeature.CHECK: "VERB_CHECK_HARE_SNARE",
	HareFoodFeature.COOK: "VERB_COOK_HARE", HareFoodFeature.TAKE: "VERB_TAKE_HARE",
}
var tuning: SliceTuning
var simulation: RunSimulation
var paused: bool = false
var backpack_open: bool = false
var _time_scale: float = 1.0
var _target: WorldInteractable
var _target_fire: FireController
var _site_fires: Dictionary[StringName, FireController] = {}
var _gather_query: Callable
var _verbs: Array[StringName] = []
var _pause_token: int = 0
var _atmosphere: WinterAtmosphere
var _environment: Environment
var _demo: bool = false
var _demo_end: bool = false
var _demo_gather: bool = false
var _smolder_stage: Dictionary[StringName, StringName] = {}
var _survivor_visual: SurvivorVisual
var _footprints: FootprintPool
var _demo_driver: FirstNightDemo
var _shelter: ShelterFeature
var _shelter_target: WorldInteractable
var _shelter_visual: ShelterVisual
var _setup_failed: bool = false
var _food: HareFoodFeature
var _trail_target: WorldInteractable
var _pile_target: WorldInteractable
var _trail_visual: HareTrailVisual

@onready var input_router: InputRouter = $InputRouter
@onready var world: WorldMap = $WorldMap
@onready var survivor: SurvivorController = $Survivor
@onready var camera: SurvivalCamera = $SurvivalCamera
@onready var hud: SurvivalHud = $SurvivalHud
@onready var sun: DirectionalLight3D = $Sun
@onready var environment_node: WorldEnvironment = $WorldEnvironment

func _enter_tree() -> void:
	if tuning != null:
		var run_world := get_node("WorldMap") as WorldMap
		run_world.extra_deadfalls.assign(tuning.extra_deadfalls)
		run_world.chapter_sites = tuning.chapter_needs_enabled

func _ready() -> void:
	simulation = RunSimulation.new(20261119, tuning)
	var chapter := simulation.tuning.chapter_needs_enabled
	input_router.chapter_actions_enabled = chapter
	_gather_query = simulation.gathering.can_gather
	for argument: String in OS.get_cmdline_user_args():
		if not OS.is_debug_build():
			break
		if argument.begins_with("--time-scale="):
			var value := argument.get_slice("=", 1).to_float()
			if is_finite(value) and value > 0:
				_time_scale = clampf(value, 0.01, 100.0)
		if not chapter and argument == "--demo":
			_demo = true
		if not chapter and argument == "--demo-end":
			_demo_end = true
		if not chapter and argument == "--demo-gather":
			_demo_gather = true
	camera.target = survivor
	camera.position = survivor.position + Vector3.UP * camera.tuning.camera_target_height
	survivor.configure(simulation, input_router, camera)
	if chapter:
		_setup_chapter_sites()
	_footprints = FootprintPool.new()
	add_child(_footprints)
	_survivor_visual = SurvivorVisual.new()
	_survivor_visual.controller = survivor
	_survivor_visual.footprints = _footprints
	survivor.add_child(_survivor_visual)
	input_router.action_pressed.connect(_on_action)
	simulation.action_resolved.connect(_on_action_resolved)
	simulation.needs.sleep_changed.connect(_on_sleep_changed)
	hud.restart_requested.connect(func() -> void: restart_requested.emit())
	hud.switch_chapter_requested.connect(func() -> void: switch_chapter_requested.emit())
	hud.eat_requested.connect(_try_eat)
	hud.eat_hare_requested.connect(_try_eat.bind(HareFoodFeature.COOKED))
	hud.resume_requested.connect(_resume)
	hud.quit_requested.connect(func() -> void: get_tree().quit())
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_COLOR
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_environment.fog_enabled = true
	_environment.fog_density = 0.007
	environment_node.environment = _environment
	_atmosphere = WinterAtmosphere.new()
	sun.directional_shadow_max_distance = _atmosphere.tuning.sun_shadow_distance
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.shadow_opacity = _atmosphere.tuning.sun_shadow_opacity
	_atmosphere.simulation = simulation
	_atmosphere.survivor = survivor
	_atmosphere.environment = _environment
	add_child(_atmosphere)
	_survivor_visual.foot_contact.connect(_atmosphere.footstep)
	if _demo:
		_demo_driver = FirstNightDemo.new(self, _time_scale)
	if _demo_end:
		simulation.clock.day = 2
		simulation.clock.minute_of_day = 512
		simulation.step_minute()
	if _demo_gather:
		simulation.start_action(&"gather_sticks", null, world.interactables[0].gather_node)
	_update_lighting()

func _setup_chapter_sites() -> void:
	var plot := world.shelter_plot(survivor.global_position, FireController.PLACEMENT_RADIUS)
	var route := world.hare_approach(survivor.global_position)
	var cooked_minutes: float = simulation.tuning.eat_minutes.get(HareFoodFeature.COOKED, 0.0)
	var cooked_kcal: float = simulation.tuning.food_kcal.get(HareFoodFeature.COOKED, 0.0)
	if plot.is_empty() or route.is_empty() or not (cooked_minutes >= 0.25 and cooked_minutes <= 30.0 and cooked_kcal >= 250.0 and cooked_kcal <= 450.0):
		push_error("Chapter 2: invalid shelter plot, hare route, or cooked hare data")
		_setup_failed = true
		return
	simulation.inventory.add(&"tarp", 1)
	simulation.fire_site_eligible = world.can_place_fire.bind(FireController.PLACEMENT_RADIUS)
	_shelter = ShelterFeature.new(plot, simulation.inventory, simulation.thermal)
	var site: Transform3D = plot[&"site"]
	_shelter_target = world.add_site(ShelterFeature.ID, site.origin, "TARGET_SHELTER")
	_shelter_target.chapter_target = true
	_shelter_visual = ShelterVisual.new()
	_shelter_visual.transform = site
	world.add_child(_shelter_visual)
	simulation.inventory.equip_snare_wire()
	_food = HareFoodFeature.new(simulation.inventory, simulation.clock, world.can_place_bundle)
	_trail_target = world.add_site(HareFoodFeature.TRAIL, route[-1], "TARGET_HARE_TRAIL")
	_trail_target.chapter_target = true
	_trail_visual = HareTrailVisual.new()
	_trail_visual.route = route
	world.add_child(_trail_visual)

func _exit_tree() -> void:
	if simulation != null:
		simulation.cancel_action()
		simulation.fire_site_eligible = Callable()
	if _shelter != null:
		_shelter.dispose()
	if _food != null:
		_food.dispose()

func _process(delta: float) -> void:
	if simulation == null:
		return
	paused = input_router.is_paused()
	survivor.frozen = paused or _setup_failed or simulation.needs.is_asleep
	var speed := _demo_driver.advance(delta) if _demo_driver != null and not paused else _time_scale
	simulation.update(delta * speed, paused or _setup_failed)
	if simulation.terminal != &"":
		input_router.set_context(InputRouter.Context.LOCKED)
	_check_smolder()
	_update_target()
	_update_lighting()
	if _trail_visual != null:
		_trail_visual.render_catch(_food.catch_ready())
	hud.set_visibility_context(_hud_context())
	var snapshot := simulation.snapshot()
	snapshot[&"prompt"] = _prompt()
	snapshot[&"real_delta_s"] = delta
	snapshot[&"paused"] = paused
	snapshot[&"felt_temp_c"] = simulation.last_felt_temp_c
	snapshot[&"tools"] = simulation.inventory.tools.duplicate()
	if simulation.tuning.chapter_needs_enabled:
		snapshot[&"chapter_controls"] = tr(&"HUD_CHAPTER_CONTROLS") % [
			input_router.glyph_for(&"sleep"), input_router.glyph_for(&"drink_snow"),
			input_router.glyph_for(&"backpack"), input_router.glyph_for(&"cancel_action")]
	var clock_values: Dictionary = snapshot[&"clock"]
	var twilight := simulation.tuning.twilight
	var shrink := simulation.tuning.daylight_shrink / 2.0
	var hour := simulation.clock.minute_of_day / 60.0
	var after_midnight := hour < simulation.clock.sunrise_hour()
	clock_values[&"nightfall_hour"] = simulation.clock.sunset_hour() + twilight + (shrink if after_midnight and simulation.clock.day > 1 else 0.0)
	clock_values[&"night_end_hour"] = simulation.clock.sunrise_hour() - twilight + (0.0 if after_midnight else shrink)
	hud.render_snapshot(snapshot)

func _on_action(action: StringName) -> void:
	if _setup_failed and action != &"pause_menu":
		return
	if simulation.needs.is_asleep and action not in [&"pause_menu", &"cancel_action", &"debug_overlay"]:
		return
	match action:
		&"pause_menu":
			if simulation.terminal == &"":
				if _pause_token == 0:
					_pause_token = input_router.request_pause(&"pause_menu")
				else:
					input_router.release_pause(_pause_token)
					_pause_token = 0
				_sync_context()
		&"backpack":
			if not paused and simulation.terminal == &"":
				backpack_open = not backpack_open
				_sync_context()
		&"camera_turn_left":
			camera.turn(-1)
		&"camera_turn_right":
			camera.turn(1)
		&"camera_zoom_in":
			camera.zoom(-1)
		&"camera_zoom_out":
			camera.zoom(1)
		&"wait":
			simulation.clock.request_rate_mode(&"normal" if simulation.clock.rate_mode == &"wait" else &"wait")
		&"cancel_action":
			if simulation.needs.is_asleep:
				if not paused:
					simulation.clock.request_rate_mode(&"normal", &"interrupted")
			else:
				simulation.cancel_action()
		&"sleep":
			_try_sleep()
		&"drink_snow":
			_try_snow()
		&"interact":
			_try_action(0)
		&"secondary":
			_try_action(1)
		&"help":
			hud.toggle_help()
		&"debug_overlay":
			hud.toggle_debug()

func _sync_context() -> void:
	input_router.request_ui_context(&"sleep", simulation.needs.is_asleep)
	input_router.request_ui_context(&"backpack", backpack_open and not simulation.needs.is_asleep)
	paused = input_router.is_paused()
	survivor.frozen = paused or simulation.needs.is_asleep

func _hud_context() -> StringName:
	if simulation.terminal != &"":
		return &"end"
	if paused:
		return &"pause"
	if simulation.needs.is_asleep:
		return &"sleep"
	return &"backpack" if backpack_open else &"gameplay"

func _try_sleep() -> void:
	if not simulation.tuning.chapter_needs_enabled or paused or backpack_open or simulation.terminal != &"":
		return
	if simulation.actions.action != &"" or simulation.movement != &"idle":
		_refuse(tr(&"HUD_BUSY"))
		return
	var near_fire := false
	for fire: FireController in simulation.fires:
		if fire.stage not in [&"Site", &"Cleared", &"Laid"] and fire.position.distance_to(survivor.global_position) <= PLAYFIELD.reach:
			near_fire = true
			break
	var in_shelter := _shelter != null and _shelter.can_sleep(survivor.global_position)
	if not near_fire and not in_shelter:
		_refuse(tr(&"HUD_SLEEP_FIRE"))
	elif simulation.body.stage == &"Critical":
		_refuse(tr(&"HUD_TOO_COLD_TIRED"))
	elif not simulation.request_sleep():
		_refuse(tr(&"HUD_NOT_SLEEPY"))

func _try_snow() -> void:
	if not simulation.tuning.chapter_needs_enabled:
		return
	if simulation.actions.action != &"":
		_refuse(tr(&"HUD_BUSY"))
	elif not world.is_on_snow(survivor.global_position):
		_refuse(tr(&"HUD_FIND_SNOW"))
	elif not simulation.start_snow_intake(true):
		_refuse(tr(&"HUD_TOO_COLD_TIRED"))

func _try_eat(item: StringName = &"pemmican") -> void:
	if paused or not backpack_open or simulation.terminal != &"":
		return
	backpack_open = false
	_sync_context()
	var cause := simulation.start_eating(item)
	if cause != &"":
		_on_action_resolved(&"eat_hare" if item == HareFoodFeature.COOKED else &"eat", false, cause)

func _on_sleep_changed(asleep: bool, cause: StringName) -> void:
	if asleep:
		backpack_open = false
	_sync_context()
	if not asleep:
		_refuse(tr(&"HUD_WOKE_COLD" if cause == &"cold" else &"HUD_WOKE"))

func _resume() -> void:
	if paused:
		input_router.release_pause(_pause_token)
		_pause_token = 0
	else:
		backpack_open = false
	_sync_context()

## Wires a run-owned fire to a model-free site; e.g. add_fire_site(simulation.create_fire(p)).
func add_fire_site(fire: FireController) -> WorldInteractable:
	if fire == null or not simulation.fires.has(fire):
		return null
	for existing: WorldInteractable in world.interactables:
		if existing.site_id == fire.id:
			return existing
	var entry := world.add_site(fire.id, fire.position, "TARGET_CAMPFIRE")
	if entry == null:
		return null
	_site_fires[fire.id] = fire
	var visual := FireVisual.new()
	visual.fire = fire
	entry.add_child(visual)
	return entry

func _update_target() -> void:
	_target = world.nearest(survivor.global_position, survivor.facing)
	_target_fire = _site_fires.get(_target.site_id) if _target != null else null
	_verbs.clear()
	if _target == null:
		return
	if _target == _shelter_target:
		if _shelter.can_sleep(survivor.global_position):
			_verbs.append(&"sleep")
		else:
			var offered := _shelter.offered_action()
			if offered != &"":
				_verbs.append(offered)
		return
	if _target == _trail_target:
		if simulation.body.stage != &"Critical":
			if _food.can_set(simulation.action_duration_multiplier()):
				_verbs.append(HareFoodFeature.SET)
			elif _food.state == HareFoodFeature.Trap.ARMED:
				_verbs.append(HareFoodFeature.CHECK)
		return
	if _target == _pile_target:
		if simulation.body.stage != &"Critical":
			_verbs.append(HareFoodFeature.TAKE)
		return
	if _target_fire == null:
		_verbs.assign(_target.gather_verbs(_gather_query, simulation.inventory))
	else:
		for action: StringName in [&"clear_snow", &"arrange_tinder", &"strike", &"blow_embers", &"add_fuel"]:
			if _target_fire.can_act(action, simulation.inventory):
				_verbs.append(action)
		if _food != null and _target_fire.stage == &"Burning" and simulation.body.stage != &"Critical" and simulation.inventory.count(HareFoodFeature.RAW) > 0 and _fire_in_reach(_target):
			_verbs.insert(mini(_verbs.size(), 1), HareFoodFeature.COOK)

func _try_action(index: int) -> void:
	if simulation.actions.action != &"":
		_refuse(tr(&"HUD_BUSY"))
		return
	_update_target()
	if _target == null:
		if index == 1:
			_make_fire()
		return
	if index >= _verbs.size():
		if _target_fire != null:
			_refuse(_fire_requirement())
		return
	var action := _verbs[index]
	if action == &"sleep":
		_try_sleep()
		return
	if _target == _shelter_target:
		if not _shelter.start(simulation, action, _is_focused.bind(_target)):
			_refuse(tr(&"HUD_TOO_COLD_TIRED"))
		return
	if _target == _trail_target:
		if not _food.start_trail(simulation, action, _is_focused.bind(_target), _survivor_position):
			_refuse(tr(&"HUD_TOO_COLD_TIRED"))
		return
	if _target == _pile_target:
		if not _food.start_take(simulation, _is_focused.bind(_target)):
			_refuse(tr(&"HUD_TOO_COLD_TIRED"))
		return
	if action == HareFoodFeature.COOK:
		if not _food.start_cook(simulation, _target_fire, _same_cooking_fire.bind(_target, _target_fire), _survivor_position):
			_refuse(tr(&"HUD_TOO_COLD_TIRED"))
		return
	if not simulation.start_action(action, _target_fire, _target.gather_node):
		_refuse(tr(&"HUD_TOO_COLD_TIRED"))

func _is_focused(target: WorldInteractable) -> bool:
	return is_instance_valid(target) and world.nearest(survivor.global_position, survivor.facing) == target

func _fire_in_reach(target: WorldInteractable) -> bool:
	return WorldMap.within_chapter_reach(survivor.global_position, survivor.facing, target.global_position)

func _same_cooking_fire(target: WorldInteractable, fire: FireController) -> bool:
	return _is_focused(target) and _fire_in_reach(target) and simulation.fires.has(fire) and _site_fires.get(target.site_id) == fire

func _survivor_position() -> Vector3:
	return survivor.global_position

func _make_fire() -> void:
	if simulation.body.stage == &"Critical" or simulation.needs.stage == &"Exhausted":
		_refuse(tr(&"HUD_CLEAR_REFUSED"))
		return
	var p := survivor.global_position + survivor.facing * PLAYFIELD.fire_placement_distance
	p.y = 0
	if absf(p.x) > world.half_extent() - PLAYFIELD.edge_inset or absf(p.z) > world.half_extent() - PLAYFIELD.edge_inset:
		_refuse(tr(&"HUD_INSIDE_CLEARING"))
		return
	if not world.can_place_fire(p, FireController.PLACEMENT_RADIUS):
		_refuse(tr(&"HUD_OPEN_GROUND"))
		return
	for existing: FireController in simulation.fires:
		if existing.position.distance_to(p) < PLAYFIELD.fire_spacing:
			_refuse(tr(&"HUD_FIRE_HERE"))
			return
	var fire := simulation.create_fire(p)
	if fire == null:
		_refuse(tr(&"HUD_FIRE_LIMIT"))
		return
	add_fire_site(fire)
	if not simulation.start_action(&"clear_snow", fire):
		_refuse(tr(&"HUD_CLEAR_REFUSED"))

func _prompt() -> String:
	if simulation.terminal != &"" or paused or backpack_open:
		return ""
	if _setup_failed:
		return tr(&"HUD_CHAPTER_INVALID")
	if simulation.actions.action != &"":
		return tr(&"HUD_WORKING") % [tr(VERB_NAMES.get(simulation.actions.action, "VERB_WORKING")), input_router.glyph_for(&"cancel_action")]
	if _target == null:
		return tr(&"HUD_MAKE_FIRE") % input_router.glyph_for(&"secondary") if simulation.fires.size() < simulation.tuning.max_fire_sites else ""
	if _verbs.is_empty():
		if _target == _shelter_target:
			match _shelter.stage:
				0: return tr(&"HUD_SHELTER_LOG")
				1: return tr(&"HUD_SHELTER_TARP")
				_: return tr(&"HUD_SHELTER_INSIDE")
		if _target == _trail_target:
			if simulation.body.stage == &"Critical":
				return tr(&"HUD_TOO_COLD_TIRED")
			if _food.state == HareFoodFeature.Trap.SPENT:
				return tr(&"HUD_HARE_SPENT")
			return tr(&"HUD_HARE_WIRE" if simulation.inventory.wire_revision() < 0 else &"HUD_HARE_MISSED")
		if _target == _pile_target:
			return tr(&"HUD_TOO_COLD_TIRED")
		return _fire_requirement() if _target_fire != null else tr(&"HUD_NEED_TINDER") % tr(_target.display_name)
	if _target_fire != null and _target_fire.stage == &"Smoldering":
		return tr(&"HUD_VERB") % [input_router.glyph_for(&"interact"), tr(&"HUD_BLOW_NOW")]
	var result: String = tr(&"HUD_VERB") % [input_router.glyph_for(&"interact"), tr(VERB_NAMES[_verbs[0]])]
	if _verbs.size() > 1:
		result += "     " + tr(&"HUD_VERB") % [input_router.glyph_for(&"secondary"), tr(VERB_NAMES[_verbs[1]])]
	return result

func _fire_requirement() -> String:
	if _target_fire == null or _target_fire.stage not in [&"Cleared", &"Out", &"Laid"]:
		return ""
	var sticks := _target_fire.missing_sticks(simulation.inventory)
	var tinder := _target_fire.missing_tinder(simulation.inventory)
	if sticks > 0:
		return tr(&"HUD_NEED_BOTH" if tinder else &"HUD_NEED_STICKS") % sticks
	return tr(&"HUD_NEED_TINDER_KIND") if tinder else ""

func _check_smolder() -> void:
	for fire: FireController in simulation.fires:
		if _smolder_stage.get(fire.id, &"") == &"Smoldering" and fire.stage == &"Laid":
			hud.show_cue(tr(&"HUD_EMBER_EXPIRED"))
		_smolder_stage[fire.id] = fire.stage

func _on_action_resolved(action: StringName, success: bool, cause: StringName) -> void:
	if success and action in [ShelterFeature.FRAME, ShelterFeature.COVER]:
		_shelter_visual.render_stage(_shelter.stage)
		if _shelter.stage == 2:
			_shelter_target.position += Vector3(0, 0, -0.8)
	if cause == &"nothing_yet":
		_refuse(tr(&"HUD_HARE_NOTHING"))
		return
	if cause == &"piled":
		_pile_target = world.add_site(HareFoodFeature.BUNDLE, _food.bundle_position, "TARGET_HARE_PILE")
		_pile_target.chapter_target = true
		_pile_target.add_child(HareTrailVisual.bundle_mesh())
		_refuse(tr(&"HUD_HARE_PILED"))
		return
	if cause == &"wire_broken":
		_refuse(tr(&"HUD_HARE_WIRE_BROKE"))
		return
	if action == HareFoodFeature.TAKE and success and _food.bundle_count == 0 and _pile_target != null:
		world.interactables.erase(_pile_target)
		_pile_target.queue_free()
		_pile_target = null
	if action == &"blow_embers":
		for fire: FireController in simulation.fires:
			_smolder_stage[fire.id] = fire.stage
	var verb := tr(VERB_NAMES.get(action, "VERB_WORKING"))
	_refuse(tr(&"HUD_DONE") % verb if success else tr(&"HUD_FAILED") % [verb, tr(StringName("CAUSE_" + String(cause).to_upper()))])

func _refuse(message: String) -> void:
	hud.show_cue(message)

func _update_lighting() -> void:
	var hour := simulation.clock.minute_of_day / 60.0
	var dawn := simulation.clock.sunrise_hour()
	var sunset := simulation.clock.sunset_hour()
	var daylight := 1.0
	if hour < dawn:
		daylight = clampf((hour - dawn + simulation.tuning.twilight) / simulation.tuning.twilight, 0, 1)
	elif hour > sunset:
		daylight = 1.0 - clampf((hour - sunset) / simulation.tuning.twilight, 0, 1)
	var sun_progress := clampf((hour - dawn) / (sunset - dawn), 0, 1)
	var sun_rotation := Vector3(-deg_to_rad(6 + 16 * sin(PI * sun_progress)), -0.6 + sun_progress * 1.2, 0)
	sun.rotation = Vector3(-deg_to_rad(42), -deg_to_rad(65), 0).lerp(sun_rotation, daylight)
	var sun_color := Color(1.0, 0.39, 0.13).lerp(Color(1.0, 0.885, 0.63), daylight)
	sun.light_color = Color("9fbfe9").lerp(sun_color, daylight)
	sun.light_energy = lerpf(_atmosphere.tuning.moon_energy, 0.85, daylight)
	sun.shadow_opacity = _atmosphere.tuning.sun_shadow_opacity * daylight
	sun.shadow_enabled = true
	var night := Color(0.07, 0.13, 0.27)
	_environment.ambient_light_color = night.lerp(Color(0.799, 0.828, 0.835), daylight)
	_environment.ambient_light_energy = lerpf(0.65, 0.6, daylight)
	_environment.background_color = Color(0.02, 0.04, 0.10).lerp(Color(0.6939, 0.7835, 0.8963), daylight)
	_environment.fog_light_energy = lerpf(0.45, 1.0, daylight)
	_atmosphere.set_daylight(daylight)
