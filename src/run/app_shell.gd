extends Node

signal state_changed(state: StringName)
signal quit_requested

const RUN: PackedScene = preload("res://src/run/run.tscn")
const MENU: PackedScene = preload("res://src/presentation/navigation_screen.tscn")
const CHAPTER: SliceTuning = preload("res://assets/data/three_day_survival.tres")
var _run: RunCoordinator
var _chapter: bool = false
var state: StringName = &"boot"
var _menu: NavigationScreen
var _router: InputRouter
var _transition_pending: bool = false
var _generation: int = 0
var save_store: SaveStore
var _checkpoint: Dictionary = {}
var _discard_profile: StringName = &"first_night"

func _ready() -> void:
	if save_store == null:
		save_store = SaveStore.new()
	_router = InputRouter.new()
	add_child(_router)
	_router.set_context(InputRouter.Context.UI)
	_router.action_pressed.connect(_on_title_action)
	_menu = MENU.instantiate() as NavigationScreen
	add_child(_menu)
	_menu.selected.connect(_on_title_selected)
	quit_requested.connect(_quit_application)
	boot(OS.get_cmdline_user_args())

func boot(arguments: PackedStringArray) -> void:
	if "--three-day" in arguments or "--demo" in arguments:
		if not start_run({&"profile": &"three_night" if "--three-day" in arguments else &"first_night"}):
			return_to_title()
			_menu.show_error(&"MENU_CHECKPOINT_UNAVAILABLE" if not save_store.can_write() else &"MENU_START_ERROR")
	else:
		return_to_title()

func start_run(config: Dictionary) -> bool:
	if _transition_pending:
		return false
	var profile: StringName = config.get(&"profile", &"first_night")
	var restore: Variant = config.get(&"restore")
	if profile not in [&"first_night", &"three_night"] or (restore != null and (not RunCheckpoint.validate(restore) or StringName(restore.profile) != profile)):
		_menu.show_error(&"MENU_START_ERROR")
		return false
	if restore == null:
		save_store.probe()
		if not save_store.can_write():
			_menu.show_error(&"MENU_CHECKPOINT_UNAVAILABLE")
			return false
	_chapter = profile == &"three_night"
	var seed_value: int = restore.seed.to_int() if restore != null else int(config.get(&"seed", randi()))
	if not _mount_run(seed_value, restore if restore != null else {}):
		return false
	if restore == null and not save_store.delete_checkpoint():
		stop_run(&"discard_failed")
		return_to_title()
		_menu.show_error(&"MENU_DELETE_FAILED")
		return false
	_checkpoint = {}
	return true

func stop_run(_reason: StringName = &"navigation") -> void:
	_generation += 1
	_transition_pending = false
	if is_instance_valid(_run):
		_run.shutdown()
		remove_child(_run)
		_run.free()
		_run = null

func return_to_title() -> bool:
	if not _checkpoint_before_leave():
		return false
	stop_run(&"title")
	_transition_pending = false
	_router.set_process_input(true)
	_router.set_context(InputRouter.Context.UI)
	_checkpoint = save_store.probe()
	_menu.show_menu(tr(&"MENU_TITLE"), "", [
		[&"continue", &"MENU_CONTINUE", not _checkpoint.is_empty()],
		[&"new_run", &"MENU_NEW_RUN"],
		[&"chapter", &"MENU_CHAPTER"],
		[&"quit", &"HUD_QUIT"]])
	if save_store.last_error != OK:
		_menu.show_error(&"MENU_CHECKPOINT_UNAVAILABLE")
	_set_state(&"title")
	return true

func _checkpoint_before_leave() -> bool:
	if not is_instance_valid(_run):
		return true
	if _run.simulation.terminal != &"":
		return _run.ensure_checkpoint_deleted()
	_run.simulation.cancel_action()
	if not _write_checkpoint(_run):
		_run.show_save_error()
		_transition_pending = false
		return false
	return true

func _write_checkpoint(run: RunCoordinator) -> bool:
	return run == _run and save_store.save(RunCheckpoint.capture(run))

func _mount_run(seed_value: int, restore: Dictionary = {}) -> bool:
	stop_run(&"restart")
	_menu.hide()
	_router.set_context(InputRouter.Context.LOCKED)
	_router.set_process_input(false)
	_run = RUN.instantiate() as RunCoordinator
	_run.tuning = CHAPTER if _chapter else null
	_run.seed_value = seed_value
	_run.restore_checkpoint = restore
	_run.checkpoint_writer = _write_checkpoint
	_run.checkpoint_deleter = save_store.delete_checkpoint
	_run.checkpoint_available = func() -> bool: return not save_store.probe().is_empty()
	_run.restart_requested.connect(_request_restart)
	_run.switch_chapter_requested.connect(_switch_chapter)
	_run.title_requested.connect(_request_title)
	_run.quit_requested.connect(_request_quit)
	_run.phase_changed.connect(_set_state)
	add_child(_run)
	if not _run.initialization_ok:
		stop_run(&"restore_failed")
		return_to_title()
		_menu.show_error(&"MENU_START_ERROR")
		return false
	_transition_pending = false
	_set_state(&"run")
	return true

func _request_restart() -> void:
	if is_instance_valid(_run) and _run.simulation.terminal != &"" and not _run.ensure_checkpoint_deleted():
		return
	if _transition_pending:
		return
	_transition_pending = true
	if is_instance_valid(_run):
		_run.process_mode = Node.PROCESS_MODE_DISABLED
	_restart_if_current.call_deferred(_generation)

func _restart_if_current(generation: int) -> void:
	if generation == _generation and _transition_pending:
		_transition_pending = false
		if not start_run({&"profile": &"three_night" if _chapter else &"first_night"}) and is_instance_valid(_run):
			_run.process_mode = Node.PROCESS_MODE_INHERIT
			_run.show_save_error()

func _switch_chapter() -> void:
	if _transition_pending:
		return
	_chapter = not _chapter
	_request_restart()

func _request_title() -> void:
	if _transition_pending:
		return
	_transition_pending = true
	_title_if_current.call_deferred(_generation)

func _title_if_current(generation: int) -> void:
	if generation == _generation and _transition_pending:
		return_to_title()

func _request_quit() -> void:
	if _checkpoint_before_leave():
		quit_requested.emit()

func _on_title_action(action: StringName) -> void:
	_menu.handle_action(action)

func _on_title_selected(action: StringName) -> void:
	match action:
		&"continue":
			var dto := save_store.probe()
			if dto.is_empty():
				return_to_title()
				_menu.show_error(&"MENU_CHECKPOINT_UNAVAILABLE")
			else:
				start_run({&"profile": StringName(dto.profile), &"restore": dto})
		&"new_run":
			_start_or_confirm(&"first_night")
		&"chapter":
			_start_or_confirm(&"three_night")
		&"discard_confirmed":
			start_run({&"profile": _discard_profile})
		&"quit":
			_menu.ask_confirmation(&"quit_confirmed", &"MENU_QUIT_CONFIRM")
		&"quit_confirmed":
			_request_quit()

func _start_or_confirm(profile: StringName) -> void:
	_checkpoint = save_store.probe()
	if not _checkpoint.is_empty():
		_discard_profile = profile
		_menu.ask_confirmation(&"discard_confirmed", &"MENU_DISCARD_CONFIRM")
	else:
		start_run({&"profile": profile})

func _set_state(value: StringName) -> void:
	state = value
	state_changed.emit(value)

func _quit_application() -> void:
	get_tree().quit()
