class_name ProbeStore
extends RefCounted
## Small M1 checkpoint only. Not the game's future run/profile save system.

var path: String
var last_error: Error = OK
var recovered_backup: bool = false

func _init(save_path: String = "user://m1_probe.json") -> void:
	path = save_path

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 3:
		return false
	if data.get("schema") != 1:
		return false
	for key: String in ["taps", "active_seconds"]:
		var value: Variant = data.get(key)
		if not (value is int or value is float) or not is_finite(float(value)):
			return false
		if float(value) < 0.0 or float(value) > 1000000000.0:
			return false
	return float(data.taps) == floor(float(data.taps))

func load_checkpoint() -> Dictionary:
	recovered_backup = false
	last_error = OK
	var data: Dictionary = _read(path)
	if not data.is_empty():
		return data
	data = _read(path + ".bak")
	if not data.is_empty():
		recovered_backup = true
	elif FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		last_error = ERR_FILE_CORRUPT
	return data

func save_checkpoint(taps: int, active_seconds: float) -> Error:
	var data: Dictionary = {"schema": 1, "taps": taps, "active_seconds": active_seconds}
	if not valid(data):
		last_error = ERR_INVALID_DATA
		return last_error
	var temporary: FileAccess = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if temporary == null:
		last_error = FileAccess.get_open_error()
		return last_error
	temporary.store_string(JSON.stringify(data))
	temporary.flush()
	last_error = temporary.get_error()
	temporary.close()
	if last_error != OK:
		return last_error
	# Only rotate a validated primary; never replace a good backup with corruption.
	if not _read(path).is_empty():
		last_error = DirAccess.rename_absolute(path, path + ".bak")
		if last_error != OK:
			return last_error
	last_error = DirAccess.rename_absolute(path + ".tmp", path)
	return last_error

func _read(source: String) -> Dictionary:
	if not FileAccess.file_exists(source):
		return {}
	var file: FileAccess = FileAccess.open(source, FileAccess.READ)
	if file == null or file.get_length() > 1024:
		return {}
	var parser: JSON = JSON.new()
	if parser.parse(file.get_as_text()) != OK or not valid(parser.data):
		return {}
	return parser.data
