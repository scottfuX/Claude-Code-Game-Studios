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

func _ready() -> void:
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
		start_run({&"profile": &"three_night" if "--three-day" in arguments else &"first_night"})
	else:
		return_to_title()

func start_run(config: Dictionary) -> bool:
	if _transition_pending:
		return false
	var profile: StringName = config.get(&"profile", &"first_night")
	if profile not in [&"first_night", &"three_night"] or config.get(&"restore") != null:
		_menu.show_error(&"MENU_START_ERROR")
		return false
	_chapter = profile == &"three_night"
	_mount_run(config.get(&"seed", randi()))
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
	_menu.show_menu(tr(&"MENU_TITLE"), "", [
		[&"continue", &"MENU_CONTINUE", false],
		[&"new_run", &"MENU_NEW_RUN"],
		[&"chapter", &"MENU_CHAPTER"],
		[&"quit", &"HUD_QUIT"]])
	_set_state(&"title")
	return true

func _checkpoint_before_leave() -> bool:
	return true

func _mount_run(seed_value: int) -> void:
	stop_run(&"restart")
	_menu.hide()
	_router.set_context(InputRouter.Context.LOCKED)
	_router.set_process_input(false)
	_run = RUN.instantiate() as RunCoordinator
	_run.tuning = CHAPTER if _chapter else null
	_run.seed_value = seed_value
	_run.restart_requested.connect(_request_restart)
	_run.switch_chapter_requested.connect(_switch_chapter)
	_run.title_requested.connect(_request_title)
	_run.quit_requested.connect(_request_quit)
	_run.phase_changed.connect(_set_state)
	add_child(_run)
	_transition_pending = false
	_set_state(&"run")

func _request_restart() -> void:
	if _transition_pending:
		return
	_transition_pending = true
	if is_instance_valid(_run):
		_run.process_mode = Node.PROCESS_MODE_DISABLED
	_restart_if_current.call_deferred(_generation)

func _restart_if_current(generation: int) -> void:
	if generation == _generation and _transition_pending:
		_mount_run(randi())

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
		&"new_run":
			start_run({&"profile": &"first_night"})
		&"chapter":
			start_run({&"profile": &"three_night"})
		&"quit":
			_menu.ask_confirmation(&"quit_confirmed", &"MENU_QUIT_CONFIRM")
		&"quit_confirmed":
			_request_quit()

func _set_state(value: StringName) -> void:
	state = value
	state_changed.emit(value)

func _quit_application() -> void:
	get_tree().quit()
