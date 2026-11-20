class_name SaveStore extends RefCounted

const SLOT: String = "run_checkpoint.json"
var directory: String
var last_error: Error = OK
var _quarantine_blocked: bool = false

func _init(path: String = "user://saves") -> void:
	directory = ProjectSettings.globalize_path(path)

func slot_path() -> String:
	return directory.path_join(SLOT)

func can_write() -> bool:
	return not _quarantine_blocked

func probe() -> Dictionary:
	last_error = OK
	_quarantine_blocked = false
	if not FileAccess.file_exists(slot_path()):
		return {}
	var file := FileAccess.open(slot_path(), FileAccess.READ)
	var dto: Variant = null
	if file != null:
		if file.get_length() <= 1048576:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK:
				dto = json.data
		file.close()
	if RunCheckpoint.validate(dto):
		return dto
	last_error = ERR_FILE_CORRUPT
	var corrupt := slot_path() + ".corrupt"
	var suffix := 0
	while FileAccess.file_exists(corrupt):
		suffix += 1
		corrupt = slot_path() + ".corrupt." + str(suffix)
	var error := _rename(slot_path(), corrupt)
	if error != OK:
		_quarantine_blocked = true
		last_error = error
	return {}

func save(dto: Dictionary) -> bool:
	if _quarantine_blocked or not RunCheckpoint.validate(dto):
		last_error = ERR_INVALID_DATA
		return false
	last_error = DirAccess.make_dir_recursive_absolute(directory)
	if last_error != OK:
		return false
	var temp := slot_path() + ".tmp"
	last_error = _write_temp(temp, JSON.stringify(dto, "", true, true))
	if last_error != OK:
		return false
	last_error = _rename(temp, slot_path())
	return last_error == OK

func delete_checkpoint() -> bool:
	if not FileAccess.file_exists(slot_path()):
		last_error = OK
		return true
	last_error = _remove(slot_path())
	return last_error == OK

func _write_temp(path: String, contents: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(contents)
	file.flush()
	var error := file.get_error()
	file.close()
	return error

func _rename(from: String, to: String) -> Error:
	return DirAccess.rename_absolute(from, to)

func _remove(path: String) -> Error:
	return DirAccess.remove_absolute(path)
