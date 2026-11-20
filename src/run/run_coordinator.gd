class_name RunCoordinator extends Node3D

signal restart_requested

const PLAYFIELD: PlayfieldTuning = preload("res://assets/data/playfield_defaults.tres")
const VERB_NAMES: Dictionary[StringName, String] = {
	&"gather_sticks": "VERB_GATHER_STICKS", &"chop_log": "VERB_CHOP_LOG", &"strip_bark": "VERB_STRIP_BARK",
	&"gather_grass": "VERB_GATHER_GRASS", &"clear_snow": "VERB_CLEAR_SNOW", &"arrange_tinder": "VERB_ARRANGE_TINDER",
	&"strike": "VERB_STRIKE", &"blow_embers": "VERB_BLOW_EMBERS", &"add_fuel": "VERB_ADD_FUEL",
}
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

func _ready() -> void:
	simulation = RunSimulation.new(20261119)
	_gather_query = simulation.gathering.can_gather
	for argument: String in OS.get_cmdline_user_args():
		if not OS.is_debug_build():
			break
		if argument.begins_with("--time-scale="):
			var value := argument.get_slice("=", 1).to_float()
			if is_finite(value) and value > 0:
				_time_scale = clampf(value, 0.01, 100.0)
		if argument == "--demo":
			_demo = true
		if argument == "--demo-end":
			_demo_end = true
		if argument == "--demo-gather":
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
	simulation.action_resolved.connect(_on_action_resolved)
	hud.restart_requested.connect(func() -> void: restart_requested.emit())
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
	_atmosphere.sunlight = sun
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

func _process(delta: float) -> void:
	if simulation == null:
		return
	paused = input_router.is_paused()
	survivor.frozen = paused
	var speed := _demo_driver.advance(delta) if _demo_driver != null and not paused else _time_scale
	simulation.update(delta * speed, paused)
	if simulation.terminal != &"":
		input_router.set_context(InputRouter.Context.LOCKED)
	_check_smolder()
	_update_target()
	_update_lighting()
	hud.set_visibility_context(&"end" if simulation.terminal != &"" else (&"pause" if paused else (&"backpack" if backpack_open else &"gameplay")))
	var snapshot := simulation.snapshot()
	snapshot[&"prompt"] = _prompt()
	snapshot[&"real_delta_s"] = delta
	snapshot[&"paused"] = paused
	snapshot[&"felt_temp_c"] = simulation.last_felt_temp_c
	snapshot[&"tools"] = simulation.inventory.tools.duplicate()
	var clock_values: Dictionary = snapshot[&"clock"]
	var twilight := simulation.tuning.twilight
	var shrink := simulation.tuning.daylight_shrink / 2.0
	var hour := simulation.clock.minute_of_day / 60.0
	var after_midnight := hour < simulation.clock.sunrise_hour()
	clock_values[&"nightfall_hour"] = simulation.clock.sunset_hour() + twilight + (shrink if after_midnight and simulation.clock.day > 1 else 0.0)
	clock_values[&"night_end_hour"] = simulation.clock.sunrise_hour() - twilight + (0.0 if after_midnight else shrink)
	hud.render_snapshot(snapshot)

func _on_action(action: StringName) -> void:
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
			simulation.cancel_action()
		&"interact":
			_try_action(0)
		&"secondary":
			_try_action(1)
		&"help":
			hud.toggle_help()
		&"debug_overlay":
			hud.toggle_debug()

func _sync_context() -> void:
	input_router.request_ui_context(&"backpack", backpack_open)
	paused = input_router.is_paused()
	survivor.frozen = paused

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
	sun.rotation = Vector3(-deg_to_rad(6 + 16 * sin(PI * sun_progress)), -0.6 + sun_progress * 1.2, 0)
	sun.light_color = Color(1.0, 0.39, 0.13).lerp(Color(1.0, 0.885, 0.63), daylight)
	sun.light_energy = 0.85 * daylight
	var night := Color(0.07, 0.13, 0.27)
	_environment.ambient_light_color = night.lerp(Color(0.799, 0.828, 0.835), daylight)
	_environment.ambient_light_energy = lerpf(0.65, 0.6, daylight)
	_environment.background_color = Color(0.02, 0.04, 0.10).lerp(Color(0.6939, 0.7835, 0.8963), daylight)
	_environment.fog_light_color = _environment.background_color
	_environment.fog_light_energy = lerpf(0.45, 1.0, daylight)
	_atmosphere.set_daylight(daylight)
