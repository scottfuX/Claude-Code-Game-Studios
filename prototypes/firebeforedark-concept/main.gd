# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is "gather wood and light a fire before dark, or freeze" tense and readable from the high far camera for ~10 minutes?
# Date: 2026-11-15
extends Node3D

const FLAT_MAT: Material = preload("res://materials/flat_palette.tres")
const SNOW_MAT: Material = preload("res://materials/snow_ground.tres")
const PINE: PackedScene = preload("res://assets/pine_flat.glb")
const BARE: PackedScene = preload("res://assets/bare_tree_flat.glb")
const SHELTER: PackedScene = preload("res://assets/shelter_flat.glb")
const SURVIVOR: PackedScene = preload("res://assets/survivor_flat.glb")
const ROCK: PackedScene = preload("res://assets/rock_flat.glb")
const CAMPFIRE: PackedScene = preload("res://assets/campfire_flat.glb")
const SEED := 20261115
const OUT_DIR := "res://evidence/"

# ---- tunables ----
const WALK_SPEED := 3.2
const RUN_SPEED := 5.5
const CAM_PITCH := deg_to_rad(50.0)
const CAM_DIST := 22.0
const INTERACT_R := 2.6
const GH_SECONDS := 120.0          # 1 game hour = 2 real minutes
const START_HOUR := 15.0
const WIN_HOUR := 30.0             # 06:00 next day (elapsed game hours)
const DRAIN_DAY := 0.30            # degC per (scaled) minute
const DRAIN_NIGHT := 0.80
const DRAIN_RUN_MULT := 1.3
const WARM_REGEN := 0.6            # degC/min toward 37 inside warmth radius
const HYPO_T := 35.0
const DEATH_T := 32.0
const STICK_CAP := 8
const TINDER_CAP := 3
const LOG_CAP := 4
const EMBER_LIFE := 20.0
const FUEL_STICK := 40.0
const FUEL_LOG := 150.0
const FUEL_CAP := 400.0
const STRIKE_CHANCE := 0.35

var _autoplay := false
var _autoplay_nofire := false
var _shots := {}
var _frame := 0

# lighting presets (copied from lookdev main.gd / main.tscn)
const DAY := {
	"sun_color": Color(1.0, 0.885, 0.630), "sun_energy": 1.5, "sun_pitch": -0.38397,
	"amb_color": Color(0.799, 0.828, 0.835), "amb_energy": 1.3,
	"bg": Color(0.6939, 0.7835, 0.8963), "fog_color": Color(0.6939, 0.7835, 0.8963), "fog_energy": 1.0,
}
const DUSK := {
	"sun_color": Color(1.0, 0.386, 0.128), "sun_energy": 0.08, "sun_pitch": -0.11,
	"amb_color": Color(0.02, 0.10, 0.26), "amb_energy": 1.6,
	"bg": Color(0.02, 0.05, 0.16), "fog_color": Color(0.03, 0.06, 0.18), "fog_energy": 0.7,
}

var rng := RandomNumberGenerator.new()
var strike_rng := RandomNumberGenerator.new()

# world / player
var _player: CharacterBody3D
var _visual: Node3D
var _cam_pivot: Node3D
var _cam: Camera3D
var _cam_dist := CAM_DIST
var _cam_yaw := 0.0
var _cam_yaw_target := 0.0
var _sun: DirectionalLight3D
var _world_env: WorldEnvironment
var _shelter_pos := Vector3(0, 0, -0.8)

var _piles: Array[Node3D] = []        # each has meta charges
var _trees: Array[Node3D] = []        # bare trees; meta bark_left, chopped
var _site: Node3D = null
var _site_stage := -1                 # -1 none,0 needs clear,1 needs lay,2 ready,3 embers,4 burning,5 out
var _fire_visual: Node3D = null
var _fire_light: OmniLight3D = null
var _embers_left := 0.0
var _embers_sticks := 0
var _fuel := 0.0
var _strike_t := -1.0

var sticks := 0
var tinder := 0
var logs := 0
var _temp := 37.0
var _elapsed_gh := 0.0               # game hours since 15:00
var _dead := false
var _won := false
var _end_t := 0.0

# input action names
const A_FWD := "move_forward"
const A_BACK := "move_back"
const A_LEFT := "move_left"
const A_RIGHT := "move_right"
const A_RUN := "run"
const A_USE := "interact"
const A_FIRE := "build_fire"
const A_ROT_L := "rotate_left"
const A_ROT_R := "rotate_right"
const A_RESTART := "restart"

# bot
var _bot_state := ""
var _bot_goal := Vector3.ZERO
var _bot_hold := false
var _bot_press := false
var _bot_press_f := false
var _bot_stuck_t := 0.0
var _bot_last_pos := Vector3.ZERO
var _bot_pulse := 0
var _bot_detour := Vector3.ZERO
var _bot_detour_t := 0.0
var _bot_restock := false
var _bot_esc := 0
var _dbg_f := 0
var _hour_log := -1
var _idle_t := 0.0
var _start_ms := 0

# HUD
var _hud: CanvasLayer
var _lbl_temp: Label
var _lbl_clock: Label
var _lbl_counts: Label
var _lbl_prompt: Label
var _lbl_end: Label
var _bar_bg: ColorRect
var _bar: ColorRect
var _vignette: TextureRect
var _fade: ColorRect
var _font: Font

# gather/hold state
var _hold_t := 0.0
var _hold_target: Node3D = null
var _hold_kind := ""
var _anim_t := 0.0
var _bob_phase := 0.0
var _foot_acc := 0.0
var _moving := false
var _running := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_autoplay = "--autoplay" in args
	_autoplay_nofire = "--autoplay-nofire" in args
	rng.seed = SEED
	strike_rng.seed = 1234
	_make_actions()
	_build_env()
	_build_ground()
	_build_world()
	_build_player()
	_build_camera()
	_build_hud()
	if _autoplay or _autoplay_nofire:
		Engine.time_scale = 8.0
		_start_ms = Time.get_ticks_msec()
		_bot_state = "GATHER_STICKS" if _autoplay else "IDLE"
		print("autoplay start  ts=", Engine.time_scale, "  state=", _bot_state)


func _make_actions() -> void:
	# Actions are created at runtime so logic stays key-agnostic (InputMap only).
	var binds := {
		A_FWD: [[KEY_W, "key"], [JOY_BUTTON_DPAD_UP, "joy"], [-1.0, "axis_y"]],
		A_BACK: [[KEY_S, "key"], [JOY_BUTTON_DPAD_DOWN, "joy"], [1.0, "axis_y"]],
		A_LEFT: [[KEY_A, "key"], [JOY_BUTTON_DPAD_LEFT, "joy"], [-1.0, "axis_x"]],
		A_RIGHT: [[KEY_D, "key"], [JOY_BUTTON_DPAD_RIGHT, "joy"], [1.0, "axis_x"]],
		A_RUN: [[KEY_SHIFT, "key"], [JOY_BUTTON_RIGHT_SHOULDER, "joy"]],
		A_USE: [[KEY_E, "key"], [JOY_BUTTON_A, "joy"]],
		A_FIRE: [[KEY_F, "key"], [JOY_BUTTON_X, "joy"]],
		A_ROT_L: [[KEY_Q, "key"], [JOY_BUTTON_LEFT_SHOULDER, "joy"]],
		A_ROT_R: [[KEY_R, "key"], [JOY_BUTTON_RIGHT_STICK, "joy"]],
		A_RESTART: [[KEY_R, "key"]],
	}
	for name in binds:
		if not InputMap.has_action(name):
			InputMap.add_action(name)
		if InputMap.action_get_events(name).size() > 0:
			continue
		for b in binds[name]:
			if b[1] == "key":
				var e := InputEventKey.new()
				e.physical_keycode = b[0]
				InputMap.action_add_event(name, e)
			elif b[1] == "joy":
				var e2 := InputEventJoypadButton.new()
				e2.button_index = b[0]
				InputMap.action_add_event(name, e2)
			elif b[1] == "axis_x":
				var e3 := InputEventJoypadMotion.new()
				e3.axis = JOY_AXIS_LEFT_X
				e3.axis_value = b[0]
				InputMap.action_add_event(name, e3)
			elif b[1] == "axis_y":
				var e4 := InputEventJoypadMotion.new()
				e4.axis = JOY_AXIS_LEFT_Y
				e4.axis_value = b[0]
				InputMap.action_add_event(name, e4)


func _build_env() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_density = 0.005
	_world_env = WorldEnvironment.new()
	_world_env.environment = env
	add_child(_world_env)
	_sun = DirectionalLight3D.new()
	_sun.shadow_enabled = true
	_sun.rotation = Vector3(DAY.sun_pitch, -0.61087, 0.0)
	add_child(_sun)
	_apply_light(0.0)


func _apply_light(t: float) -> void:
	# t: 0 = day preset, 1 = dusk preset
	var env := _world_env.environment
	env.ambient_light_color = DAY.amb_color.lerp(DUSK.amb_color, t)
	env.ambient_light_energy = lerpf(DAY.amb_energy, DUSK.amb_energy, t)
	env.background_color = DAY.bg.lerp(DUSK.bg, t)
	env.fog_light_color = DAY.fog_color.lerp(DUSK.fog_color, t)
	env.fog_light_energy = lerpf(DAY.fog_energy, DUSK.fog_energy, t)
	_sun.light_color = DAY.sun_color.lerp(DUSK.sun_color, t)
	_sun.light_energy = lerpf(DAY.sun_energy, DUSK.sun_energy, t)
	# sun elevation falls all afternoon, independent of the colour lerp
	var h := START_HOUR + _elapsed_gh
	var k := clampf((h - START_HOUR) / (18.0 - START_HOUR), 0.0, 1.0)
	_sun.rotation.x = lerpf(DAY.sun_pitch, DUSK.sun_pitch, k)


func _build_ground() -> void:
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(160, 160)
	g.mesh = pm
	g.material_override = SNOW_MAT
	add_child(g)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := WorldBoundaryShape3D.new()
	cs.shape = shape
	body.add_child(cs)
	add_child(body)


func _place(scn: PackedScene, pos: Vector3, rot_y: float, s: float = 1.0, parent: Node = null) -> Node3D:
	var n: Node3D = scn.instantiate()
	n.position = pos
	n.rotation.y = rot_y
	n.scale = Vector3(s, s, s)
	(parent if parent else self).add_child(n)
	_apply_flat(n)
	return n


func _apply_flat(n: Node) -> void:
	if n is MeshInstance3D:
		n.material_override = FLAT_MAT
	for c in n.get_children():
		_apply_flat(c)


func _solid(n: Node3D, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	cs.shape = shape
	cs.position.y = height * 0.5
	body.add_child(cs)
	n.add_child(body)


func _build_world() -> void:
	var shelter := _place(SHELTER, _shelter_pos, 2.6)
	_solid(shelter, 1.6, 2.0)
	var placed: Array[Vector3] = []
	var pines := 0
	var bares := 0
	var tries := 0
	while pines < 25 and tries < 6000:
		tries += 1
		var pos := _scatter(9.0, 38.0, placed, 3.5)
		if pos == Vector3.INF:
			continue
		var tp := _place(PINE, pos, rng.randf() * TAU, 0.8 + rng.randf() * 0.45)
		_solid(tp, 0.65, 5.0)
		placed.append(pos)
		pines += 1
	tries = 0
	while bares < 6 and tries < 6000:
		tries += 1
		var pos := _scatter(8.0, 34.0, placed, 4.5)
		if pos == Vector3.INF:
			continue
		var t := _place(BARE, pos, rng.randf() * TAU, 0.8 + rng.randf() * 0.4)
		t.set_meta("bark_left", 2)
		t.set_meta("chopped", false)
		_solid(t, 0.5, 4.0)
		_trees.append(t)
		placed.append(pos)
		bares += 1
		# stick pile cluster near each bare tree
		var p := _make_pile(pos + Vector3(rng.randf_range(-2.0, 2.0), 0, rng.randf_range(1.5, 2.5)))
		_piles.append(p)
	for i in 5:
		var pos := _scatter(10.0, 36.0, placed, 4.0)
		if pos == Vector3.INF:
			continue
		var r := _place(ROCK, pos, rng.randf() * TAU, 0.6 + rng.randf() * 0.6)
		_solid(r, 0.8, 0.8)
		placed.append(pos)
	# extra scattered stick piles
	for i in 4:
		var pos := _scatter(8.0, 35.0, placed, 3.0)
		if pos == Vector3.INF:
			continue
		_piles.append(_make_pile(pos))
		placed.append(pos)


func _scatter(rmin: float, rmax: float, placed: Array[Vector3], spacing: float) -> Vector3:
	for i in 60:
		var ang := rng.randf() * TAU
		var r := rmin + rng.randf() * (rmax - rmin)
		var pos := Vector3(cos(ang) * r, 0, sin(ang) * r)
		if pos.distance_to(_shelter_pos) < 6.0:
			continue
		var ok := true
		for q in placed:
			if pos.distance_to(q) < spacing:
				ok = false
				break
		if ok:
			return pos
	return Vector3.INF


func _make_pile(pos: Vector3) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	add_child(p)
	p.set_meta("charges", 3)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.23, 0.12)   # wood_brown-ish
	mat.roughness = 1.0
	for i in 3:
		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.035
		cyl.bottom_radius = 0.035
		cyl.height = 0.55
		cyl.radial_segments = 6
		mi.mesh = cyl
		mi.material_override = mat
		mi.rotation = Vector3(PI / 2.0, rng.randf() * TAU, 0)
		mi.position = Vector3(rng.randf_range(-0.15, 0.15), 0.05 + i * 0.06, rng.randf_range(-0.15, 0.15))
		p.add_child(mi)
	return p


func _build_player() -> void:
	_player = CharacterBody3D.new()
	_player.position = Vector3(1.5, 0, 3.0)
	add_child(_player)
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.7
	cs.shape = cap
	cs.position.y = 0.85
	_player.add_child(cs)
	_visual = _place(SURVIVOR, Vector3.ZERO, PI, 1.0, _player)


func _build_camera() -> void:
	_cam_pivot = Node3D.new()
	_cam_pivot.position = _player.position
	add_child(_cam_pivot)
	_cam = Camera3D.new()
	_cam.fov = 30.0
	_cam.far = 300.0
	_cam_pivot.add_child(_cam)
	_update_cam_transform()
	_cam.make_current()


func _update_cam_transform() -> void:
	_cam.position = Vector3(0, sin(CAM_PITCH) * _cam_dist, cos(CAM_PITCH) * _cam_dist)
	_cam.rotation.x = -CAM_PITCH


func _build_hud() -> void:
	_font = SystemFont.new()
	(_font as SystemFont).font_names = PackedStringArray(["PingFang SC", "Hiragino Sans GB", "Noto Sans CJK SC"])
	_hud = CanvasLayer.new()
	add_child(_hud)
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(14, 10)
	_hud.add_child(vbox)
	_lbl_temp = _mk_label(vbox, 18)
	_bar_bg = ColorRect.new()
	_bar_bg.custom_minimum_size = Vector2(180, 10)
	_bar_bg.color = Color(0.08, 0.1, 0.16, 0.8)
	vbox.add_child(_bar_bg)
	_bar = ColorRect.new()
	_bar.position = Vector2(1, 1)
	_bar.color = Color(0.94, 0.5, 0.1)
	_bar_bg.add_child(_bar)
	_lbl_clock = _mk_label(vbox, 18)
	_lbl_counts = _mk_label(vbox, 15)
	_lbl_prompt = _mk_label(_hud, 20)
	_lbl_prompt.anchor_left = 0.5
	_lbl_prompt.anchor_right = 0.5
	_lbl_prompt.anchor_top = 1.0
	_lbl_prompt.anchor_bottom = 1.0
	_lbl_prompt.offset_left = -300
	_lbl_prompt.offset_right = 300
	_lbl_prompt.offset_top = -70
	_lbl_prompt.offset_bottom = -40
	_lbl_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# hypothermia vignette (radial alpha texture, trunk_navy)
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			var d := Vector2(x - 63.5, y - 63.5).length() / 90.5
			var a: float = clampf((d - 0.55) / 0.45, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.117, 0.165, 0.267, a * a))
	_vignette = TextureRect.new()
	_vignette.texture = ImageTexture.create_from_image(img)
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate.a = 0.0
	_hud.add_child(_vignette)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(1, 1, 1, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_fade)
	_lbl_end = _mk_label(_hud, 34)
	_lbl_end.set_anchors_preset(Control.PRESET_CENTER)
	_lbl_end.anchor_left = 0.5
	_lbl_end.anchor_right = 0.5
	_lbl_end.anchor_top = 0.5
	_lbl_end.anchor_bottom = 0.5
	_lbl_end.offset_left = -400
	_lbl_end.offset_right = 400
	_lbl_end.offset_top = -80
	_lbl_end.offset_bottom = 80
	_lbl_end.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_end.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _mk_label(parent: Node, size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(l)
	return l


# ---------- input helpers (bot uses the same path) ----------
func _i_move() -> Vector2:
	if _autoplay or _autoplay_nofire:
		var goal := _bot_detour if _bot_detour_t > 0.0 else _bot_goal
		var d := goal - _player.position
		d.y = 0
		if d.length() > 0.4:
			return Vector2(d.x, d.z).normalized()
		return Vector2.ZERO
	return Input.get_vector(A_LEFT, A_RIGHT, A_FWD, A_BACK)


func _i_held() -> bool:
	if _autoplay or _autoplay_nofire:
		return _bot_hold or _bot_pulse > 0
	return Input.is_action_pressed(A_USE)


func _i_press() -> bool:
	if _autoplay or _autoplay_nofire:
		return _bot_press
	return Input.is_action_just_pressed(A_USE)


func _i_run() -> bool:
	if _autoplay or _autoplay_nofire:
		return false   # bot walks — 8x timescale + run speed tunnels through tree colliders
	return Input.is_action_pressed(A_RUN)


func _i_fire() -> bool:
	if _autoplay or _autoplay_nofire:
		return _bot_press_f
	return Input.is_action_just_pressed(A_FIRE)


# ---------- main loop ----------
func _process(delta: float) -> void:
	_frame += 1
	if _autoplay or _autoplay_nofire:
		_bot_tick(delta)
	if _dead or _won:
		_end_t += delta
		_fade.color.a = minf(_end_t / 3.0, 1.0)
		if (_autoplay or _autoplay_nofire) and _end_t > 3.5:
			get_tree().quit()
		return
	if _frame == 30 and _autoplay and not _shots.has("start.png"):
		_shot("start.png")
	_cam_step(delta)
	_player_step(delta)
	_player_action(delta)
	_temp_step(delta)
	_fire_step(delta)
	_hud_step()
	_hourly_log()
	if (_autoplay or _autoplay_nofire):
		_capture_check()
		if Time.get_ticks_msec() - _start_ms > 480000:
			print("TIMEOUT — quitting")
			get_tree().quit()


func _cam_step(delta: float) -> void:
	if Input.is_action_just_pressed(A_ROT_L):
		_cam_yaw_target += PI / 4.0
	if Input.is_action_just_pressed(A_ROT_R) and not (_dead or _won):
		_cam_yaw_target -= PI / 4.0
	_cam_yaw = lerp_angle(_cam_yaw, _cam_yaw_target, minf(delta * 8.0, 1.0))
	_cam_pivot.rotation.y = _cam_yaw
	_cam_pivot.position = _cam_pivot.position.lerp(_player.position, minf(delta * 6.0, 1.0))
	_update_cam_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cam_dist = clampf(_cam_dist - 1.5, 16.0, 30.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cam_dist = clampf(_cam_dist + 1.5, 16.0, 30.0)
	if (_dead or _won) and Input.is_action_just_pressed(A_RESTART):
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()


func _player_step(delta: float) -> void:
	var inp := _i_move()
	var speed := RUN_SPEED if (_i_run() and inp != Vector2.ZERO) else WALK_SPEED
	if _temp < HYPO_T:
		speed *= 0.7
	var dir3 := Vector3(inp.x, 0, inp.y)
	if dir3.length() > 1.0:
		dir3 = dir3.normalized()
	if not (_autoplay or _autoplay_nofire):
		dir3 = dir3.rotated(Vector3.UP, _cam_yaw)
	_moving = inp != Vector2.ZERO
	_running = _moving and speed > WALK_SPEED
	_player.velocity.x = dir3.x * speed
	_player.velocity.z = dir3.z * speed
	_player.velocity.y = -9.0
	_player.move_and_slide()
	if _moving:
		var face := atan2(dir3.x, dir3.z)
		_visual.rotation.y = lerp_angle(_visual.rotation.y, face - _player.rotation.y, minf(delta * 10.0, 1.0))
		_bob_phase += delta * speed * 3.0
		_foot_acc += speed * delta
		if _foot_acc >= 0.7:
			_foot_acc = 0.0
			_footprint()
	else:
		_bob_phase = lerp(_bob_phase, 0.0, delta * 6.0)
	_anim_step(delta)
	# world edge
	_player.position.x = clampf(_player.position.x, -39.0, 39.0)
	_player.position.z = clampf(_player.position.z, -39.0, 39.0)


func _footprint() -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(0.16, 0.3)
	mi.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.63, 0.8, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 1.0
	mi.material_override = mat
	mi.position = _player.position + Vector3(0, 0.012, 0)
	mi.rotation.y = _visual.rotation.y
	add_child(mi)
	mi.set_meta("t", 60.0)


func _anim_step(delta: float) -> void:
	_anim_t += delta
	var hold := _i_held() and _hold_target != null
	if _strike_t >= 0.0:
		# strike: quick small shakes
		_visual.rotation.z = sin(_anim_t * 40.0) * 0.08
		_visual.rotation.x = 0.0
		_visual.position.y = 0.0
	elif hold and _hold_kind == "chop":
		# chop: repeated forward tilt pulses
		_visual.rotation.x = maxf(sin(_anim_t * 6.0), 0.0) * 0.35
		_visual.position.y = 0.0
	elif hold:
		# pick/dig: dip down scaled by progress
		_visual.position.y = -0.3 * sin(clampf(_hold_t, 0.0, 1.0) * PI)
		_visual.rotation.x = 0.1
	elif _moving:
		_visual.position.y = absf(sin(_bob_phase)) * 0.06
		_visual.rotation.x = 0.09
		_visual.rotation.z = sin(_bob_phase * 0.5) * 0.05
	else:
		_visual.position.y = lerp(_visual.position.y, 0.0, delta * 8.0)
		_visual.rotation.x = lerp(_visual.rotation.x, 0.0, delta * 8.0)
		_visual.rotation.z = lerp(_visual.rotation.z, 0.0, delta * 8.0)
	# fade footprints
	for mi in get_children():
		if mi is MeshInstance3D and mi.has_meta("t"):
			var t: float = mi.get_meta("t") - delta
			mi.set_meta("t", t)
			if t <= 0.0:
				mi.queue_free()
			elif t < 8.0:
				(mi.material_override as StandardMaterial3D).albedo_color.a = t / 10.0


func _prompt_target() -> Node3D:
	var best: Node3D = null
	var bd := INTERACT_R
	for p in _piles:
		if is_instance_valid(p) and p.get_meta("charges", 0) > 0:
			var d := p.position.distance_to(_player.position)
			if d < bd:
				bd = d
				best = p
	for t in _trees:
		if is_instance_valid(t) and not t.get_meta("chopped"):
			var d2 := t.position.distance_to(_player.position)
			if d2 < bd:
				bd = d2
				best = t
	if _site != null:
		var d3 := _site.position.distance_to(_player.position)
		var useful: bool = _site_stage != 4 or sticks > 0 or logs > 0
		if useful and d3 < bd:
			bd = d3
			best = _site
	return best


func _player_action(delta: float) -> void:
	var target := _prompt_target()
	if target != _hold_target:
		_hold_t = 0.0
		_hold_target = target
		_hold_kind = ""
	if target == null:
		return
	var kind := ""
	var need := 0.0
	if _piles.has(target):
		kind = "pick"
		need = 0.6
	elif _trees.has(target):
		kind = "tree"
		need = 4.0
	elif target == _site:
		match _site_stage:
			0:
				kind = "clear"
				need = 2.0
			1, 5:
				kind = "lay"   # press
			2:
				kind = "strike" # press
			3, 4:
				kind = "fuel"   # tap=stick, hold>=1.5=log
	_hold_kind = kind
	match kind:
		"pick":
			if _i_held():
				_hold_t += delta
				if _hold_t >= need:
					_take_stick(target)
					_hold_t = 0.0
			else:
				_hold_t = 0.0
		"tree":
			if _i_held():
				var before := _hold_t
				_hold_t += delta
				_hold_kind = "chop"
				if before < 2.0 and _hold_t >= 2.0 and target.get_meta("bark_left") > 0 and tinder < TINDER_CAP:
					target.set_meta("bark_left", target.get_meta("bark_left") - 1)
					tinder += 1
					print("+ tinder  (", tinder, "/", TINDER_CAP, ")")
				if _hold_t >= need:
					_chop(target)
					_hold_t = 0.0
			else:
				_hold_t = 0.0
		"clear":
			if _i_held():
				_hold_t += delta
				if _hold_t >= need:
					_clear_site()
					_hold_t = 0.0
			else:
				_hold_t = 0.0
		"lay":
			if _i_press() and tinder >= 1 and sticks >= 3:
				tinder -= 1
				sticks -= 3
				_site_stage = 2
				_show_fire_base()
				print("fire: fuel laid — strike to ignite")
		"strike":
			if _i_press() and _strike_t < 0.0:
				_strike_t = 0.0
		"fuel":
			if _site_stage == 3:
				if _i_press() and sticks > 0:
					sticks -= 1
					_embers_sticks += 1
					print("embers + stick  (", _embers_sticks, "/2)")
			elif _site_stage == 4:
				if _i_held():
					_hold_t += delta
					if _hold_t >= 1.5:
						if logs > 0:
							logs -= 1
							_fuel = minf(_fuel + FUEL_LOG, FUEL_CAP)
							print("+ log  fuel=", int(_fuel))
						elif sticks > 0:
							sticks -= 1
							_fuel = minf(_fuel + FUEL_STICK, FUEL_CAP)
							print("+ stick  fuel=", int(_fuel))
						_hold_t = 0.0
				elif _hold_t > 0.0:
					# released before 1.5 s = tap -> add a stick
					if _hold_t < 1.5 and sticks > 0:
						sticks -= 1
						_fuel = minf(_fuel + FUEL_STICK, FUEL_CAP)
						print("+ stick  fuel=", int(_fuel))
					_hold_t = 0.0


func _take_stick(p: Node3D) -> void:
	if sticks >= STICK_CAP:
		print("sticks full")
		return
	sticks += 1
	var c: int = p.get_meta("charges") - 1
	p.set_meta("charges", c)
	if c < p.get_child_count():
		p.get_child(c).visible = false
	print("+ stick  (", sticks, "/", STICK_CAP, ")")
	if _autoplay:
		_shot("gathering.png")


func _chop(t: Node3D) -> void:
	t.set_meta("chopped", true)
	logs = mini(logs + 3, LOG_CAP)
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.28
	cyl.height = 0.4
	cyl.radial_segments = 8
	mi.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.23, 0.12)
	mat.roughness = 1.0
	mi.material_override = mat
	mi.position.y = 0.2
	for c in t.get_children():
		c.queue_free()
	t.add_child(mi)
	_solid(t, 0.3, 0.4)
	print("+ 3 logs  (", logs, "/", LOG_CAP, ") — tree chopped")
	if _autoplay:
		_shot("chopping.png")


func _start_site() -> void:
	if _site != null:
		return
	if _player.position.distance_to(_shelter_pos) < 3.0:
		print("too close to shelter to build a fire")
		return
	_site = Node3D.new()
	_site.position = _player.position
	add_child(_site)
	_site_stage = 0
	print("fire site placed — clear the snow (hold E 2s)")


func _clear_site() -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.9
	cyl.bottom_radius = 0.9
	cyl.height = 0.02
	cyl.radial_segments = 16
	mi.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.23, 0.29, 0.39)
	mat.roughness = 1.0
	mi.material_override = mat
	mi.position.y = 0.01
	_site.add_child(mi)
	_site_stage = 1
	print("snow cleared — lay tinder + sticks (E)")


func _show_fire_base() -> void:
	if _fire_visual == null:
		_fire_visual = _place(CAMPFIRE, Vector3(0, 0.02, 0), rng.randf() * TAU, 0.7, _site)


func _fire_step(delta: float) -> void:
	if _i_fire():
		_start_site()
	# strike resolution
	if _strike_t >= 0.0:
		_strike_t += delta
		if _strike_t >= 0.5:
			_strike_t = -1.0
			if _site_stage == 2:
				if strike_rng.randf() < STRIKE_CHANCE:
					_site_stage = 3
					_embers_left = EMBER_LIFE
					_embers_sticks = 0
					_ignite_visual(0.15)
					print("strike SUCCESS — embers! feed 2 sticks")
					_shot("ignition.png")
				else:
					print("strike … nothing")
	match _site_stage:
		3:
			_embers_left -= delta
			if _embers_sticks >= 2:
				_site_stage = 4
				_fuel = minf(30.0 + _embers_sticks * FUEL_STICK, FUEL_CAP)
				_ignite_visual(1.0)
				print("burning! fuel=", int(_fuel))
			elif _embers_left <= 0.0:
				_site_stage = 2
				_ignite_visual(0.0)
				print("embers died — strike again")
		4:
			_fuel -= delta
			var sf: float = clampf(0.3 + _fuel / 200.0, 0.3, 1.3)
			if _fire_visual:
				for c in _fire_visual.get_children():
					if c.has_meta("flame"):
						c.scale = Vector3(sf, sf, sf)
			if _fire_light:
				_fire_light.light_energy = 1.0 + 3.5 * minf(_fuel / 200.0, 1.0)
				_fire_light.omni_range = 5.0 + 3.0 * minf(_fuel / 200.0, 1.0)
			if _fuel <= 0.0:
				_fuel = 0.0
				_site_stage = 5
				_ignite_visual(0.0)
				print("fire out — relight needs tinder+sticks again")


func _ignite_visual(scale_f: float) -> void:
	if _fire_visual == null:
		return
	var has := false
	for c in _fire_visual.get_children():
		if c.has_meta("flame"):
			has = true
	if not has and scale_f > 0.0:
		var outer := _flame_cone(0.11, 0.36, Color(0.945, 0.274, 0.044))
		outer.position = Vector3(0, 0.32, 0)
		outer.set_meta("flame", true)
		var inner := _flame_cone(0.055, 0.22, Color(1.0, 0.605, 0.146))
		inner.position = Vector3(0.02, 0.33, 0.01)
		inner.set_meta("flame", true)
		_fire_visual.add_child(outer)
		_fire_visual.add_child(inner)
		_fire_light = OmniLight3D.new()
		_fire_light.position = Vector3(0, 0.55, 0)
		_fire_light.light_color = Color(1.0, 0.42, 0.16)
		_fire_light.light_energy = 1.0
		_fire_light.omni_range = 5.0
		_fire_light.omni_attenuation = 1.4
		_fire_light.shadow_enabled = true
		_fire_visual.add_child(_fire_light)
	for c in _fire_visual.get_children():
		if c.has_meta("flame"):
			c.visible = scale_f > 0.0
	if _fire_light:
		_fire_light.visible = scale_f > 0.0


func _flame_cone(radius: float, height: float, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.bottom_radius = radius
	cone.top_radius = 0.0
	cone.height = height
	cone.radial_segments = 6
	mi.mesh = cone
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mi.material_override = mat
	return mi


func _warm_radius() -> float:
	if _site_stage != 4 or _site == null:
		return 0.0
	return lerpf(2.0, 5.0, minf(_fuel / 200.0, 1.0))


func _temp_step(delta: float) -> void:
	var h := START_HOUR + _elapsed_gh
	_elapsed_gh += delta / GH_SECONDS
	var in_warmth := _warm_radius() > 0.0 and _player.position.distance_to(_site.position) <= _warm_radius()
	if in_warmth:
		_temp = minf(_temp + WARM_REGEN * delta / 60.0, 37.0)
	else:
		var rate := DRAIN_NIGHT if h >= 18.0 else DRAIN_DAY
		if _running:
			rate *= DRAIN_RUN_MULT
		_temp -= rate * delta / 60.0
	# lighting lerp: day -> dusk across 17:00 -> 18:00
	_apply_light(clampf((h - 17.0) / 1.0, 0.0, 1.0))
	# hypothermia
	if _temp < HYPO_T:
		var k: float = clampf((HYPO_T - _temp) / (HYPO_T - DEATH_T), 0.0, 1.0)
		_vignette.modulate.a = 0.25 + 0.5 * k
		_world_env.environment.adjustment_enabled = true
		_world_env.environment.adjustment_saturation = lerpf(1.0, 0.6, k)
	else:
		_vignette.modulate.a = lerpf(_vignette.modulate.a, 0.0, delta * 2.0)
		_world_env.environment.adjustment_saturation = 1.0
	if _temp <= DEATH_T:
		_die()
	elif _elapsed_gh >= (WIN_HOUR - START_HOUR):
		_win()


func _die() -> void:
	_dead = true
	var h := START_HOUR + _elapsed_gh
	var hh := int(h) % 24
	var mm := int(fmod(h, 1.0) * 60.0)
	_lbl_end.text = "冻死了\n存活到 %02d:%02d（%.1f 小时）\n\n按 R 重新开始" % [hh, mm, _elapsed_gh]
	print("DIED at game %02d:%02d  temp=%.1f  elapsed_gh=%.2f  real_s=%.1f  equiv_min=%.1f" % [hh, mm, _temp, _elapsed_gh, Time.get_ticks_msec() / 1000.0, _elapsed_gh * GH_SECONDS / 60.0])
	_shot("death.png")


func _win() -> void:
	_won = true
	_lbl_end.text = "撑过了第一夜\n\n按 R 重新开始"
	print("SURVIVED to 06:00  temp=%.1f" % _temp)


func _shot(name: String) -> void:
	if _shots.has(name):
		return
	_shots[name] = true
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(OUT_DIR + name)
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("capture: ", name, " -> ", path, " err=", err)


func _hourly_log() -> void:
	var hh := int(_elapsed_gh)
	if hh != _hour_log:
		_hour_log = hh
		var gh := int(START_HOUR + _elapsed_gh) % 24
		print("H%02d:00  temp=%.1f  fuel=%.0f  sticks=%d tinder=%d logs=%d  stage=%d  state=%s" % [gh, _temp, _fuel, sticks, tinder, logs, _site_stage, _bot_state])


func _hud_step() -> void:
	var h := START_HOUR + _elapsed_gh
	var hh := int(h) % 24
	var mm := int(fmod(h, 1.0) * 60.0)
	_lbl_clock.text = "%02d:%02d" % [hh, mm]
	_lbl_temp.text = "体温 %.1f°C" % _temp
	var k: float = clampf((_temp - DEATH_T) / (37.0 - DEATH_T), 0.0, 1.0)
	_bar.size = Vector2(178.0 * k, 8)
	_bar.color = Color(0.2, 0.5, 0.9).lerp(Color(0.95, 0.45, 0.08), k)
	_lbl_counts.text = "树枝 %d/%d　引火物 %d/%d　原木 %d/%d　燃料 %ds" % [sticks, STICK_CAP, tinder, TINDER_CAP, logs, LOG_CAP, int(_fuel)]
	_lbl_prompt.text = _prompt_text()


func _prompt_text() -> String:
	if _dead or _won:
		return ""
	var t := _prompt_target()
	if t == null:
		if _site == null and _player.position.distance_to(_shelter_pos) >= 3.0:
			return "F：放置篝火点"
		return ""
	if _piles.has(t):
		return "按住 E：捡树枝"
	if _trees.has(t):
		return "按住 E：采树皮(2s) / 砍树(4s)"
	if t == _site:
		match _site_stage:
			0: return "按住 E：清理积雪"
			1: return "按 E：铺引火物×1 + 树枝×3" if (tinder >= 1 and sticks >= 3) else "需要 引火物×1 + 树枝×3"
			2: return "按 E：打火（35%）"
			3: return "按 E：添树枝 ×%d 让火旺起来" % (2 - _embers_sticks)
			4: return "按 E：添树枝（+40s） / 按住 E：加原木（+150s）"
			5: return "按 E：重新铺燃料" if (tinder >= 1 and sticks >= 3) else "需要 引火物×1 + 树枝×3"
	return ""


# ---------- autoplay bot ----------
func _bot_tick(delta: float) -> void:
	_bot_press = false
	_bot_press_f = false
	_bot_hold = false
	_bot_pulse = maxi(_bot_pulse - 1, 0)
	if _autoplay_nofire:
		return
	# stuck watchdog: displacement-based — walking but not moving -> lateral detour
	_bot_detour_t = maxf(_bot_detour_t - delta, 0.0)
	if _i_move() != Vector2.ZERO:
		_bot_stuck_t += delta
		if _bot_stuck_t > 2.0:
			if _player.position.distance_to(_bot_last_pos) < 0.3:
				_bot_esc += 1
				var ang: float = [1.2, -1.2, 2.3, -2.3][_bot_esc % 4]
				_bot_detour_t = 2.5
				_bot_detour = _player.position + (_bot_goal - _player.position).rotated(Vector3.UP, ang)
				if _bot_esc >= 4:
					# fully wedged inside a collider — bot-only rescue nudge
					_player.position += (_bot_goal - _player.position).normalized() * 1.5
					print("bot unstuck-nudge (bot-only rescue)")
					_bot_esc = 0
			_bot_stuck_t = 0.0
			_bot_last_pos = _player.position
	else:
		_bot_stuck_t = 0.0
		_bot_esc = 0
	_dbg_f += 1
	if _dbg_f % 300 == 0:
		var t := _prompt_target()
		print("dbg  pos=%.1f,%.1f  goal=%.1f,%.1f  d=%.1f  hold=%.1f  tgt=%s  stage=%d" % [_player.position.x, _player.position.z, _bot_goal.x, _bot_goal.z, _player.position.distance_to(_bot_goal), _hold_t, t, _site_stage])
	match _bot_state:
		"GATHER_STICKS":
			if sticks >= 8 or (_bot_restock and sticks >= 4):
				var rs := _bot_restock
				_bot_restock = false
				_next_state("MAINTAIN" if rs else "GATHER_TINDER")
				return
			var p := _nearest_pile()
			if p == null:
				if _bot_restock:
					_bot_restock = false
					_next_state("CHOP" if _nearest_tree(false, false) != null else "HOVEL")
				else:
					_next_state("GATHER_TINDER")
				return
			if _goto(p.position, 1.8):
				_bot_hold = true
		"GATHER_TINDER":
			if tinder >= 1:
				_next_state("CHOP")
				return
			var tr := _nearest_tree(true, false)
			if tr == null:
				_next_state("CHOP")
				return
			if _goto(tr.position, 1.6):
				_bot_hold = true
		"CHOP":
			var tr2 := _nearest_tree(false, false)
			if tr2 == null or logs > 0:
				_next_state("BUILD")
				return
			if _goto(tr2.position, 1.6):
				_bot_hold = true   # one hold: tinder at 2s (if bark), chop at 4s
		"BUILD":
			if _site != null:
				# site already exists — route by its stage
				match _site_stage:
					0:
						if _goto(_site.position, 1.4):
							_bot_hold = true
					1:
						if _goto(_site.position, 1.4):
							_bot_press = true
					2:
						_next_state("IGNITE")
					3:
						_next_state("EMBER_FEED")
					4:
						_next_state("MAINTAIN")
					5:
						_next_state("RELAY")
				return
			var spot := _shelter_pos + Vector3(0, 0, 4.2)
			if _goto(spot, 0.8):
				_bot_press_f = true
		"IGNITE":
			if _site_stage == 3:
				_next_state("EMBER_FEED")
			elif _site_stage == 2 and _goto(_site.position, 1.5):
				_bot_press = true
		"EMBER_FEED":
			if _site_stage == 4:
				_next_state("MAINTAIN")
			elif _site_stage == 2:
				_next_state("IGNITE")
			elif _site_stage == 3 and _goto(_site.position, 1.5):
				if sticks > 0:
					_bot_press = true
				else:
					_next_state("GATHER_STICKS")
		"RELAY":
			if _site_stage == 5:
				if tinder >= 1 and sticks >= 3:
					if _goto(_site.position, 1.5):
						_bot_press = true
				elif sticks < 3 and _nearest_pile() == null:
					_next_state("HOVEL")
				elif tinder < 1 and _nearest_tree(true, false) == null:
					_next_state("HOVEL")
				else:
					_bot_restock = true
					_next_state("GATHER_STICKS" if sticks < 3 else "GATHER_TINDER")
			elif _site_stage == 2:
				_next_state("IGNITE")
			elif _site_stage == 4:
				_next_state("MAINTAIN")
		"HOVEL":
			# nothing left to burn anywhere — hunker down and take the odds
			var anchor := _site.position if _site != null else _shelter_pos
			_goto(anchor + Vector3(1.2, 0, 0.8), 0.9)
		"MAINTAIN":
			if _site_stage == 5:
				_next_state("RELAY")
			elif _site_stage == 3:
				_next_state("EMBER_FEED")
			elif _site_stage == 2:
				_next_state("IGNITE")
			elif _site_stage == 1:
				_next_state("BUILD")
			elif _site_stage == 4:
				if _fuel < 280.0:
					if logs > 0:
						if _goto(_site.position, 1.4):
							_bot_hold = true   # 1.5s hold -> +log
					elif sticks > 0:
						if _goto(_site.position, 1.4) and _bot_pulse == 0:
							_bot_pulse = 3   # brief hold, release -> +stick
					else:
						_bot_restock = true
						_next_state("GATHER_STICKS")
				else:
					_goto(_site.position + Vector3(0.9, 0, 0.6), 0.8)


func _next_state(s: String) -> void:
	_bot_state = s
	_bot_stuck_t = 0.0
	_bot_last_pos = _player.position
	print("bot -> ", s)


func _goto(pos: Vector3, tol: float) -> bool:
	_bot_goal = pos
	return _player.position.distance_to(pos) <= tol


func _nearest_pile() -> Node3D:
	var best: Node3D = null
	var bd := 999.0
	for p in _piles:
		if is_instance_valid(p) and p.get_meta("charges", 0) > 0:
			var d := p.position.distance_to(_player.position)
			if d < bd:
				bd = d
				best = p
	return best


func _nearest_tree(need_bark: bool, chopped_ok: bool) -> Node3D:
	var best: Node3D = null
	var bd := 999.0
	for t in _trees:
		if is_instance_valid(t) and (chopped_ok or not t.get_meta("chopped")) and (not need_bark or t.get_meta("bark_left") > 0):
			var d := t.position.distance_to(_player.position)
			if d < bd:
				bd = d
				best = t
	return best


func _capture_check() -> void:
	if not _autoplay:
		return
	var h := START_HOUR + _elapsed_gh
	if h >= 17.83 and not _shots.has("dusk_fire.png"):
		_shot("dusk_fire.png")
	if h >= 20.5 and not _shots.has("night_fire.png"):
		_shot("night_fire.png")
	if _won and _frame > 30:
		get_tree().quit()
	if _dead and _end_t > 3.5:
		get_tree().quit()
