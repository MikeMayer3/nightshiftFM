class_name MissionStore
extends RefCounted
## Profile and run share one atomic envelope: completion and its reward cannot split.
var path: String
var error: Error = OK
var recovered: bool = false

func _init(save_path: String = "user://m3_mission.json") -> void:
	path = save_path

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 3 or data.get("schema") != 1: return false
	var profile: MissionProfile = MissionProfile.new()
	if not profile.restore(data.get("profile")): return false
	if data.get("run") == null: return true
	var session: CombatSession = CombatSession.new()
	if not session.restore_checkpoint(data.get("run")): return false
	var number: int = int(String(session.run_id).trim_prefix("run."))
	return number > 0 and number < profile.next_run and (session.phase != CombatSession.Phase.VICTORY or session.run_id in profile.rewarded_runs)

func load_save() -> Dictionary:
	error = OK
	recovered = false
	var data: Dictionary = _read(path)
	if not data.is_empty(): return data
	for suffix: String in [".tmp", ".bak"]:
		data = _read(path + suffix)
		if not data.is_empty():
			recovered = true
			return data
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak") or FileAccess.file_exists(path + ".tmp"):
		error = ERR_FILE_CORRUPT
	return {}

func save(profile: MissionProfile, checkpoint: Dictionary) -> Error:
	var data: Dictionary = {"schema": 1, "profile": profile.to_data(), "run": checkpoint if not checkpoint.is_empty() else null}
	if not valid(data):
		error = ERR_INVALID_DATA
		return error
	var file: FileAccess = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		error = FileAccess.get_open_error()
		return error
	# Full precision keeps active combat timers stable across kill-meter checkpoints.
	file.store_string(JSON.stringify(data, "", true, true))
	file.flush()
	error = file.get_error()
	file.close()
	if error != OK: return error
	if _read(path + ".tmp").is_empty():
		error = ERR_FILE_CORRUPT
		return error
	if not _read(path).is_empty():
		error = DirAccess.rename_absolute(path, path + ".bak")
		if error != OK: return error
	error = DirAccess.rename_absolute(path + ".tmp", path)
	return error

func _read(source: String) -> Dictionary:
	if not FileAccess.file_exists(source): return {}
	var file: FileAccess = FileAccess.open(source, FileAccess.READ)
	if file == null or file.get_length() > 16000000: return {}
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK or not valid(json.data): return {}
	return json.data
