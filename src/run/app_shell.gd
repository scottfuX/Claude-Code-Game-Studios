extends Node

const RUN: PackedScene = preload("res://src/run/run.tscn")
const CHAPTER: SliceTuning = preload("res://assets/data/three_day_survival.tres")
var _run: RunCoordinator
var _chapter: bool = false

func _ready() -> void:
	_chapter = "--three-day" in OS.get_cmdline_user_args()
	_mount_run()

func _mount_run() -> void:
	if is_instance_valid(_run):
		_run.input_router.set_context(InputRouter.Context.LOCKED)
		_run.simulation.cancel_action()
		remove_child(_run)
		_run.free()
	_run = RUN.instantiate() as RunCoordinator
	_run.tuning = CHAPTER if _chapter else null
	_run.restart_requested.connect(_request_restart)
	_run.switch_chapter_requested.connect(_switch_chapter)
	add_child(_run)

func _request_restart() -> void:
	if is_instance_valid(_run):
		_run.process_mode = Node.PROCESS_MODE_DISABLED
	_mount_run.call_deferred()

func _switch_chapter() -> void:
	_chapter = not _chapter
	_request_restart()
