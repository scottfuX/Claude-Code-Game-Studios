class_name RunCoordinator extends Node3D

signal restart_requested
signal switch_chapter_requested
signal title_requested
signal quit_requested
signal phase_changed(phase: StringName)

const MENU: PackedScene = preload("res://src/presentation/navigation_screen.tscn")
var seed_value: int = 20261119
var end_shot_elapsed: float = 0.0
var end_phase: StringName = &""
var navigation: NavigationScreen
var _end_grade: ColorRect
var restore_checkpoint: Dictionary = {}
var initialization_ok: bool = true
var checkpoint_writer: Callable
var checkpoint_deleter: Callable
var checkpoint_available: Callable
var _sunrise_pending: bool = false
var _terminal_deleted: bool = false
var _cleanup_blocked: bool = false
var _loading_token: int = 0
var _loading_elapsed: float = 0.0

const PLAYFIELD: PlayfieldTuning = preload("res://assets/data/playfield_defaults.tres")
const VERB_NAMES: Dictionary[StringName, String] = {
	&"gather_sticks": "VERB_GATHER_STICKS", &"chop_log": "VERB_CHOP_LOG", &"strip_bark": "VERB_STRIP_BARK",
	&"gather_grass": "VERB_GATHER_GRASS", &"clear_snow": "VERB_CLEAR_SNOW", &"arrange_tinder": "VERB_ARRANGE_TINDER",
	&"strike": "VERB_STRIKE", &"blow_embers": "VERB_BLOW_EMBERS", &"add_fuel": "VERB_ADD_FUEL",
	&"eat_snow": "VERB_DRINK_SNOW", &"eat": "VERB_EAT_RATION",
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

@onready var input_router: InputRouter = $InputRouter
@onready var world: WorldMap = $WorldMap
@onready var survivor: SurvivorController = $Survivor
@onready var camera: SurvivalCamera = $SurvivalCamera
@onready var hud: SurvivalHud = $SurvivalHud
@onready var sun: DirectionalLight3D = $Sun
@onready var environment_node: WorldEnvironment = $WorldEnvironment

func _enter_tree() -> void:
	var router := get_node("InputRouter") as InputRouter
	router.set_context(InputRouter.Context.LOCKED)
	router.set_process_input(false)
	(get_node("Survivor") as SurvivorController).set_physics_process(false)
	if tuning != null:
		var run_world := get_node("WorldMap") as WorldMap
		run_world.extra_deadfalls.assign(tuning.extra_deadfalls)

func _ready() -> void:
	simulation = RunSimulation.new(seed_value, tuning)
	if not restore_checkpoint.is_empty():
		initialization_ok = _restore_owners(restore_checkpoint)
		if not initialization_ok:
			return
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
	_footprints = FootprintPool.new()
	add_child(_footprints)
	_survivor_visual = SurvivorVisual.new()
	_survivor_visual.controller = survivor
	_survivor_visual.footprints = _footprints
	survivor.add_child(_survivor_visual)
	input_router.action_pressed.connect(_on_action)
	simulation.clock.sunrise.connect(func() -> void: _sunrise_pending = true)
	simulation.action_resolved.connect(_on_action_resolved)
	simulation.needs.sleep_changed.connect(_on_sleep_changed)
	hud.restart_requested.connect(func() -> void: restart_requested.emit())
	hud.switch_chapter_requested.connect(func() -> void: switch_chapter_requested.emit())
	hud.eat_requested.connect(_try_eat)
	hud.resume_requested.connect(_resume)
	hud.external_navigation = true
	navigation = MENU.instantiate() as NavigationScreen
	add_child(navigation)
	navigation.selected.connect(_on_navigation)
	navigation.back_requested.connect(_resume)
	hud.quit_requested.connect(func() -> void: navigation.ask_confirmation(&"quit_confirmed", &"MENU_QUIT_CONFIRM"))
	var shot_layer := CanvasLayer.new()
	shot_layer.layer = 5
	add_child(shot_layer)
	_end_grade = ColorRect.new()
	_end_grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end_grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_grade.color = Color(0.94, 0.96, 0.98, 0.0)
	shot_layer.add_child(_end_grade)
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
	if not restore_checkpoint.is_empty():
		_loading_token = input_router.request_pause(&"loading")
		input_router.set_context(InputRouter.Context.LOCKED)
		input_router.set_process_input(false)
		_end_grade.color = Color(0.015, 0.025, 0.05, 1.0)
		hud.hide()
	else:
		input_router.set_context(InputRouter.Context.GAMEPLAY)
		input_router.set_process_input(true)
	survivor.set_physics_process(true)
	survivor.frozen = _loading_token != 0 or simulation.needs.is_asleep

func _process(delta: float) -> void:
	if simulation == null:
		return
	if _loading_token != 0:
		advance_loading(delta)
		return
	paused = input_router.is_paused()
	survivor.frozen = paused or simulation.needs.is_asleep or simulation.terminal != &""
	var speed := _demo_driver.advance(delta) if _demo_driver != null and not paused else _time_scale
	simulation.update(delta * speed, paused)
	if simulation.terminal != &"":
		_sunrise_pending = false
		advance_end_shot(delta)
		return
	flush_autosave()
	_update_pause_menu()
	_check_smolder()
	_update_target()
	_update_lighting()
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
	if _loading_token != 0 or not initialization_ok:
		return
	if simulation.terminal != &"":
		if end_phase == &"":
			advance_end_shot(0.0)
		if navigation.visible:
			navigation.handle_action(action)
		elif action == &"pause_menu" and end_phase == &"end_shot":
			_open_pause()
		elif action in [&"interact", &"ui_accept"]:
			skip_end_shot()
		return
	if navigation.visible:
		navigation.handle_action(action)
		return
	if action in InputRouter.UI_ACTIONS:
		if action == &"ui_cancel" and backpack_open:
			backpack_open = false
			_sync_context()
		else:
			hud.handle_ui_action(action)
		return
	if simulation.needs.is_asleep and action not in [&"pause_menu", &"cancel_action", &"debug_overlay"]:
		return
	match action:
		&"pause_menu":
			_open_pause()
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
	if not near_fire:
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

func _try_eat() -> void:
	if paused or not backpack_open or simulation.terminal != &"":
		return
	backpack_open = false
	_sync_context()
	var cause := simulation.start_eating(&"pemmican")
	if cause != &"":
		_on_action_resolved(&"eat", false, cause)

func _on_sleep_changed(asleep: bool, cause: StringName) -> void:
	if asleep:
		backpack_open = false
	_sync_context()
	if not asleep:
		_refuse(tr(&"HUD_WOKE_COLD" if cause == &"cold" else &"HUD_WOKE"))

func _resume() -> void:
	if _pause_token != 0:
		input_router.release_pause(_pause_token)
		_pause_token = 0
		navigation.hide()
	else:
		backpack_open = false
	_sync_context()
	if simulation.terminal != &"":
		input_router.set_context(InputRouter.Context.LOCKED if end_phase == &"end_shot" else InputRouter.Context.UI)
	else:
		phase_changed.emit(&"run")

func _open_pause() -> void:
	if _pause_token == 0:
		_pause_token = input_router.request_pause(&"pause_menu")
	input_router.set_context(InputRouter.Context.UI)
	_sync_context()
	var terminal := simulation.terminal != &""
	var entries: Array = [[&"resume", &"MENU_RESUME_SHOT" if terminal else &"HUD_RESUME"]]
	if not terminal:
		entries.append([&"title", &"MENU_SAVE_RETURN_TITLE"])
		entries.append([&"switch", &"HUD_START_FIRST_NIGHT" if simulation.tuning.chapter_needs_enabled else &"HUD_START_CHAPTER"])
	entries.append([&"quit", &"HUD_QUIT"])
	navigation.show_menu(tr(&"HUD_PAUSED"), "", entries)
	phase_changed.emit(&"end_shot" if terminal else &"paused")

func _update_pause_menu() -> void:
	if input_router.is_paused() and _pause_token != 0 and not navigation.visible:
		_open_pause()

func _on_navigation(action: StringName) -> void:
	if _cleanup_blocked:
		if action == &"cleanup_retry" and ensure_checkpoint_deleted():
			navigation.hide()
			input_router.set_context(InputRouter.Context.LOCKED)
		return
	match action:
		&"resume":
			_resume()
		&"title":
			title_requested.emit()
		&"switch":
			if checkpoint_available.is_valid() and checkpoint_available.call():
				navigation.ask_confirmation(&"switch_confirmed", &"MENU_DISCARD_CONFIRM")
			else:
				switch_chapter_requested.emit()
		&"switch_confirmed":
			switch_chapter_requested.emit()
		&"retry":
			restart_requested.emit()
		&"quit":
			navigation.ask_confirmation(&"quit_confirmed", &"MENU_QUIT_CONFIRM")
		&"quit_confirmed":
			quit_requested.emit()

func advance_end_shot(delta: float) -> void:
	if simulation.terminal == &"":
		return
	if _cleanup_blocked:
		return
	hud.hide()
	camera.set_process(false)
	survivor.frozen = true
	if not ensure_checkpoint_deleted():
		return
	if end_phase == &"":
		end_phase = &"end_shot"
		backpack_open = false
		input_router.terminal_input = true
		input_router.set_context(InputRouter.Context.LOCKED)
		phase_changed.emit(&"end_shot")
	if end_phase != &"end_shot":
		return
	if not input_router.is_paused() and is_finite(delta):
		end_shot_elapsed += maxf(0.0, delta)
	if simulation.terminal != &"dawn_survived":
		_end_grade.color.a = clampf(end_shot_elapsed / 8.0, 0.0, 1.0)
	input_router.enable_terminal_skip(end_shot_elapsed >= 1.0)
	if end_shot_elapsed >= 8.0:
		_show_results()

func skip_end_shot() -> bool:
	if end_phase != &"end_shot" or end_shot_elapsed < 1.0 or input_router.is_paused():
		return false
	_show_results()
	return true

func _show_results() -> void:
	end_phase = &"results"
	input_router.enable_terminal_skip(false)
	input_router.set_context(InputRouter.Context.UI)
	var key: StringName = &"HUD_DEATH"
	if simulation.terminal == &"dehydration":
		key = &"HUD_DEHYDRATION"
	elif simulation.terminal == &"dawn_survived":
		key = &"HUD_CHAPTER_DAWN" if simulation.tuning.chapter_needs_enabled else &"HUD_DAWN"
	navigation.show_menu(tr(key), _nights_lasted(), [[&"retry", &"MENU_TRY_AGAIN"], [&"title", &"MENU_RETURN_TITLE"]])
	phase_changed.emit(&"results")

func _nights_lasted() -> String:
	var hour := simulation.clock.minute_of_day / 60.0
	var night := simulation.clock.day - simulation.tuning.start_day
	if hour >= simulation.clock.sunset_hour():
		night += 1
	var keys: Array[StringName] = [&"MENU_BEFORE_NIGHT", &"MENU_NIGHT_FIRST", &"MENU_NIGHT_SECOND", &"MENU_NIGHT_THIRD"]
	return tr(keys[clampi(night, 0, 3)])

func shutdown() -> void:
	set_process(false)
	input_router.set_context(InputRouter.Context.LOCKED)
	input_router.set_process_input(false)
	simulation.cancel_action()
	if _pause_token != 0:
		input_router.release_pause(_pause_token)
		_pause_token = 0
	if _loading_token != 0:
		input_router.release_pause(_loading_token)
		_loading_token = 0
	if is_instance_valid(navigation):
		navigation.hide()
	survivor.frozen = true

func _restore_owners(dto: Dictionary) -> bool:
	if not RunCheckpoint.validate(dto):
		return false
	var owners: Dictionary = dto.owners.duplicate(true)
	var gathering: Dictionary = owners.gathering
	var survivor_state: Dictionary = owners.survivor
	owners.erase("gathering")
	owners.erase("survivor")
	if not simulation.restore_state(owners) or not survivor.restore_state(survivor_state):
		return false
	for entry: WorldInteractable in world.interactables:
		if entry.gather_node != null and not entry.gather_node.restore_state(gathering[String(entry.site_id)]):
			return false
	simulation.position = survivor.position
	for fire: FireController in simulation.fires:
		add_fire_site(fire)
	return true

func advance_loading(delta: float) -> void:
	if _loading_token == 0 or not is_finite(delta):
		return
	_loading_elapsed += maxf(0.0, delta)
	_end_grade.color.a = clampf(1.0 - _loading_elapsed, 0.0, 1.0)
	if _loading_elapsed >= 1.0:
		input_router.release_pause(_loading_token)
		_loading_token = 0
		_end_grade.color = Color(0.94, 0.96, 0.98, 0.0)
		input_router.set_context(InputRouter.Context.GAMEPLAY)
		_sync_context()
		input_router.set_process_input(true)
		survivor.frozen = input_router.is_paused() or simulation.needs.is_asleep

func flush_autosave() -> void:
	if not _sunrise_pending or simulation.actions.action != &"" or simulation.clock._dispatching:
		return
	_sunrise_pending = false
	if simulation.terminal == &"" and checkpoint_writer.is_valid() and not checkpoint_writer.call(self):
		_refuse(tr(&"MENU_AUTOSAVE_FAILED"))

func ensure_checkpoint_deleted() -> bool:
	if _terminal_deleted:
		return true
	_sunrise_pending = false
	if checkpoint_deleter.is_valid() and not checkpoint_deleter.call():
		_cleanup_blocked = true
		input_router.set_context(InputRouter.Context.UI)
		hud.hide()
		navigation.show_menu(tr(&"MENU_CHECKPOINT_UNAVAILABLE"), tr(&"MENU_DELETE_FAILED"), [[&"cleanup_retry", &"MENU_RETRY"]])
		return false
	_terminal_deleted = true
	_cleanup_blocked = false
	return true

func show_save_error() -> void:
	_open_pause()
	navigation.show_error(&"MENU_SAVE_FAILED")

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
	if _target_fire == null:
		_verbs.assign(_target.gather_verbs(_gather_query, simulation.inventory))
	else:
		for action: StringName in [&"clear_snow", &"arrange_tinder", &"strike", &"blow_embers", &"add_fuel"]:
			if _target_fire.can_act(action, simulation.inventory):
				_verbs.append(action)

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
	if not simulation.start_action(action, _target_fire, _target.gather_node):
		_refuse(tr(&"HUD_TOO_COLD_TIRED"))

func _make_fire() -> void:
	if simulation.body.stage == &"Critical" or simulation.needs.stage == &"Exhausted":
		_refuse(tr(&"HUD_CLEAR_REFUSED"))
		return
	var p := survivor.global_position + survivor.facing * PLAYFIELD.fire_placement_distance
	p.y = 0
	if absf(p.x) > PLAYFIELD.half_extent - PLAYFIELD.edge_inset or absf(p.z) > PLAYFIELD.half_extent - PLAYFIELD.edge_inset:
		_refuse(tr(&"HUD_INSIDE_CLEARING"))
		return
	if not world.can_place_fire(p):
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
	if simulation.actions.action != &"":
		return tr(&"HUD_WORKING") % [tr(VERB_NAMES.get(simulation.actions.action, "VERB_WORKING")), input_router.glyph_for(&"cancel_action")]
	if _target == null:
		return tr(&"HUD_MAKE_FIRE") % input_router.glyph_for(&"secondary") if simulation.fires.size() < simulation.tuning.max_fire_sites else ""
	if _verbs.is_empty():
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
