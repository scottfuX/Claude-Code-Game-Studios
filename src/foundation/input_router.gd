class_name InputRouter extends Node

signal action_pressed(action: StringName)

enum Context { GAMEPLAY, UI, LOCKED }
const ROUTED: Array[StringName] = [&"interact", &"secondary", &"cancel_action", &"backpack", &"pause_menu", &"camera_turn_left", &"camera_turn_right", &"camera_zoom_in", &"camera_zoom_out", &"wait", &"debug_overlay", &"help", &"sleep", &"drink_snow"]
const MOVEMENT: Array[StringName] = [&"move_left", &"move_right", &"move_forward", &"move_back", &"move_hurry"]
const UI_ACTIONS: Array[StringName] = [&"ui_accept", &"ui_cancel", &"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev"]
var context: Context = Context.GAMEPLAY
var terminal_input: bool = false
var _terminal_skip_enabled: bool = false
var chapter_actions_enabled: bool = false
var _blocked: Dictionary[StringName, bool] = {}
var _ui_sources: Dictionary[StringName, bool] = {}
var _pause_tokens: Dictionary[int, StringName] = {}
var _next_token: int = 1
var _debug_driving: bool = false
var _debug_move: Vector2 = Vector2.ZERO
var _debug_hurry: bool = false

## Supplies replay commands through the same context gate as physical bindings.
func drive_debug(movement: Vector2, action: StringName = &"", hurry: bool = false) -> void:
	if not OS.is_debug_build():
		return
	_debug_driving = true
	_debug_move = movement.limit_length(1.0) if movement.is_finite() else Vector2.ZERO
	_debug_hurry = hurry
	if action in ROUTED or action in UI_ACTIONS:
		_dispatch(action)

func enable_terminal_skip(enabled: bool) -> void:
	if enabled == _terminal_skip_enabled:
		return
	_terminal_skip_enabled = enabled
	for action: StringName in [&"interact", &"ui_accept"]:
		if Input.is_action_pressed(action):
			_blocked[action] = true

## Requests a UI context without stopping simulation or active work.
func request_ui_context(source: StringName, open: bool) -> void:
	if open:
		_ui_sources[source] = true
	else:
		_ui_sources.erase(source)
	_refresh_context()

## Acquires an independently owned simulation-pause token.
func request_pause(source: StringName) -> int:
	var token := _next_token
	_next_token += 1
	_pause_tokens[token] = source
	_refresh_context()
	return token

## Releases only the matching request; unknown tokens are harmless.
func release_pause(token: int) -> void:
	_pause_tokens.erase(token)
	_refresh_context()

## Returns the aggregate pause authority for the run adapter.
func is_paused() -> bool:
	return not _pause_tokens.is_empty()

## Resolves authored keyboard glyphs at the input boundary, not inside the HUD.
func glyph_for(action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	return ""

func _refresh_context() -> void:
	if context != Context.LOCKED:
		set_context(Context.UI if is_paused() or not _ui_sources.is_empty() else Context.GAMEPLAY)

## Applies an exclusive context and suppresses already-held bindings until release.
func set_context(value: Context) -> void:
	if context == value:
		return
	context = value
	for action: StringName in ROUTED + MOVEMENT + UI_ACTIONS:
		if Input.is_action_pressed(action):
			_blocked[action] = true

## Returns the only sampled gameplay movement and hurry state.
func sample_actions() -> Dictionary[StringName, Variant]:
	if context != Context.GAMEPLAY:
		return {&"move": Vector2.ZERO, &"hurry": false}
	if OS.is_debug_build() and _debug_driving:
		return {&"move": _debug_move, &"hurry": _debug_hurry}
	var move := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back", 0.2)
	if (move.x < 0 and _blocked.has(&"move_left")) or (move.x > 0 and _blocked.has(&"move_right")):
		move.x = 0
	if (move.y < 0 and _blocked.has(&"move_forward")) or (move.y > 0 and _blocked.has(&"move_back")):
		move.y = 0
	return {&"move": move, &"hurry": Input.is_action_pressed(&"move_hurry") and not _blocked.has(&"move_hurry")}

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		if context != Context.GAMEPLAY:
			get_viewport().set_input_as_handled()
		return
	for action: StringName in MOVEMENT:
		if event.is_action_released(action):
			_blocked.erase(action)
	var actions: Array[StringName] = ROUTED + UI_ACTIONS
	if context == Context.UI and (is_paused() or not _ui_sources.has(&"backpack")):
		actions = UI_ACTIONS + ROUTED
	for action: StringName in actions:
		if event.is_action_released(action):
			_blocked.erase(action)
		if not event.is_action_pressed(action, false, action in UI_ACTIONS):
			continue
		if _blocked.has(action):
			if context != Context.GAMEPLAY:
				get_viewport().set_input_as_handled()
			return
		if _dispatch(action):
			get_viewport().set_input_as_handled()
			return

func _dispatch(action: StringName) -> bool:
	if _blocked.has(action):
		return false
	if not chapter_actions_enabled and action in [&"sleep", &"drink_snow"]:
		return false
	var debug := (action == &"debug_overlay" and OS.is_debug_build()) or action == &"help"
	var skip := terminal_input and _terminal_skip_enabled and not is_paused() and action in [&"interact", &"ui_accept"]
	if context == Context.LOCKED and action != &"pause_menu" and not skip and (terminal_input or not debug):
		return false
	if action in UI_ACTIONS and context != Context.UI and not skip:
		return false
	var wake := action == &"cancel_action" and _ui_sources.has(&"sleep") and not is_paused()
	if context == Context.UI and action not in UI_ACTIONS and action not in [&"pause_menu", &"backpack"] and not debug and not wake:
		return false
	action_pressed.emit(action)
	return true
