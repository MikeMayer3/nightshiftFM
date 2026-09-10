class_name RadioPreferences
extends Node
## Presentation only. No gameplay RNG, checkpoint or combat values are stored here.
signal changed
static var current: RadioPreferences
const DEFAULTS: Dictionary = {"reduced_flash": false, "low_effects": false,
	"left_handed": false, "large_text": false, "haptics": false,
	"sound": true, "music": true, "show_signal": true}
const COACH_IDS: Array[String] = ["shield", "boost", "mixer"]
var coach_seen: Array[String] = []
var values: Dictionary = DEFAULTS.duplicate()
var path: String = "user://presentation_v1.json"
var save_error: Error = OK
var _font_pending: bool = false

func _enter_tree() -> void:
	current = self

func _exit_tree() -> void:
	if current == self: current = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Script-driven QA starts from defaults and never reads or writes owner settings.
	if "--script" in OS.get_cmdline_args() or "-s" in OS.get_cmdline_args():
		path = "user://m10_script_preferences.json"
	else:
		load_preferences()
	get_tree().node_added.connect(func(_node: Node) -> void: queue_fonts())
	changed.connect(queue_fonts)
	queue_fonts()

func enabled(key: String) -> bool:
	return bool(values.get(key, false))

func set_option(key: String, value: bool) -> void:
	if not DEFAULTS.has(key): return
	values[key] = value
	save_error = save_preferences()
	changed.emit()

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.size() not in [2, 3] or data.get("schema") != 1: return false
	if data.size() == 3:
		if not data.get("coaching") is Array or data.coaching.size() > COACH_IDS.size(): return false
		var seen: Array[String] = []
		for id: Variant in data.coaching:
			if not id is String or id not in COACH_IDS or id in seen: return false
			seen.append(id)
	var options: Variant = data.get("options")
	if not options is Dictionary or options.size() != DEFAULTS.size(): return false
	for key: String in DEFAULTS:
		if not options.get(key) is bool: return false
	return true

func read_preferences(file_path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null or file.get_length() > 4096: return {}
	var parser: JSON = JSON.new()
	if parser.parse(file.get_as_text()) != OK: return {}
	return parser.data if valid(parser.data) else {}

func load_preferences() -> void:
	var data: Dictionary = read_preferences(path)
	if data.is_empty(): data = read_preferences(path + ".bak")
	values = data.options.duplicate() if not data.is_empty() else DEFAULTS.duplicate()
	coach_seen.assign(data.get("coaching", []))

func save_preferences() -> Error:
	var file: FileAccess = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"schema": 1, "options": values, "coaching": coach_seen}))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK: return error
	if not read_preferences(path).is_empty():
		error = DirAccess.rename_absolute(path, path + ".bak")
		if error != OK: return error
	return DirAccess.rename_absolute(path + ".tmp", path)

func queue_fonts() -> void:
	if _font_pending: return
	_font_pending = true
	_apply_fonts.call_deferred()

func _apply_fonts() -> void:
	_font_pending = false
	if not is_inside_tree(): return
	apply_fonts(get_tree().root)

func apply_fonts(node: Node) -> void:
	if node is Label or node is Button or node is CheckButton or node is OptionButton:
		var control: Control = node as Control
		if not control.has_meta("radio_base_font"):
			control.set_meta("radio_base_font", control.get_theme_font_size("font_size"))
		var target: int = roundi(float(control.get_meta("radio_base_font")) * (1.15 if enabled("large_text") else 1.0))
		if control.get_theme_font_size("font_size") != target:
			control.add_theme_font_size_override("font_size", target)
		if control is BaseButton:
			control.custom_minimum_size.y = maxf(float(control.get_meta("radio_touch_minimum", 88)), control.custom_minimum_size.y)
	for child: Node in node.get_children(): apply_fonts(child)

func remember_coach(id: String) -> void:
	if id not in COACH_IDS or id in coach_seen: return
	coach_seen.append(id)
	save_error = save_preferences()

func replay_coaching() -> void:
	coach_seen.clear()
	save_error = save_preferences()
	changed.emit()
