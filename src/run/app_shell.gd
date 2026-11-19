extends Node

const RUN: PackedScene = preload("res://src/run/run.tscn")
var _run: RunCoordinator

func _ready() -> void:
	_mount_run()

func _mount_run() -> void:
	if is_instance_valid(_run):
		_run.input_router.set_context(InputRouter.Context.LOCKED)
		_run.simulation.cancel_action()
		remove_child(_run)
		_run.free()
	_run = RUN.instantiate() as RunCoordinator
	_run.restart_requested.connect(_request_restart)
	add_child(_run)

func _request_restart() -> void:
	if is_instance_valid(_run):
		_run.process_mode = Node.PROCESS_MODE_DISABLED
	_mount_run.call_deferred()
