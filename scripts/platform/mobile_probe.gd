class_name MobileProbe
extends Control

signal back_requested

var store: ProbeStore = ProbeStore.new()
var taps: int = 0
var pause_count: int = 0
var resume_count: int = 0
var paused_drift_count: int = 0
var _focused: bool = true
var _app_paused: bool = false
var _os_suspended: bool = false
var _manual_pause: bool = false
var _enabled: bool = false
var _pause_seconds: float = 0.0
var _status_key: String = "PROBE_READY"
var _last_second: int = -1

@onready var clock: ProbeClock = $Clock
@onready var safe_margin: SafeMargin = $SafeMargin
@onready var summary: Label = $SafeMargin/Column/Summary
@onready var status: Label = $SafeMargin/Column/Status
@onready var pause_button: Button = $SafeMargin/Column/Pause

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("m1_probe")
	safe_margin.safe_area_changed.connect(_refresh)
	($SafeMargin/Column/Tap as Button).pressed.connect(_tap)
	($SafeMargin/Column/Save as Button).pressed.connect(save_checkpoint)
	($SafeMargin/Column/Load as Button).pressed.connect(load_checkpoint)
	pause_button.pressed.connect(_toggle_pause)
	($SafeMargin/Column/Back as Button).pressed.connect(func() -> void: back_requested.emit())
	load_checkpoint()
	_sync_pause()
	_report("ready")

func set_enabled(enabled: bool) -> void:
	var was_enabled: bool = _enabled
	_enabled = enabled
	if was_enabled and not enabled:
		get_tree().paused = false
	visible = enabled
	_sync_pause()
	if enabled:
		($SafeMargin/Column/Tap as Button).grab_focus()

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_focused = false
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_focused = true
		NOTIFICATION_APPLICATION_PAUSED:
			_app_paused = true
		NOTIFICATION_APPLICATION_RESUMED:
			_app_paused = false
		_:
			return
	var suspended: bool = not _focused or _app_paused
	if not _enabled:
		_os_suspended = suspended
		return
	if suspended != _os_suspended:
		_os_suspended = suspended
		if suspended:
			pause_count += 1
			_pause_seconds = clock.active_seconds
			save_checkpoint()
		else:
			resume_count += 1
			if clock.active_seconds != _pause_seconds:
				paused_drift_count += 1
		_sync_pause()
		_report("os_pause" if suspended else "os_resume")
	else:
		_sync_pause()

func _sync_pause() -> void:
	if not is_node_ready():
		return
	clock.process_mode = Node.PROCESS_MODE_PAUSABLE if _enabled else Node.PROCESS_MODE_DISABLED
	if not _enabled:
		_refresh()
		return
	var should_pause: bool = _os_suspended or _manual_pause
	if get_tree().paused and not should_pause:
		clock.skip_next_frame = true
	get_tree().paused = should_pause
	_refresh()

func _process(_delta: float) -> void:
	if visible and int(clock.active_seconds) != _last_second:
		_last_second = int(clock.active_seconds)
		_refresh()

func _tap() -> void:
	if _os_suspended or _manual_pause:
		return
	taps += 1
	save_checkpoint()
	_report("tap")

func save_checkpoint() -> void:
	_status_key = "PROBE_SAVED" if store.save_checkpoint(taps, clock.active_seconds) == OK else "PROBE_SAVE_ERROR"
	_refresh()

func load_checkpoint() -> void:
	var data: Dictionary = store.load_checkpoint()
	if not data.is_empty():
		taps = int(data.taps)
		clock.active_seconds = float(data.active_seconds)
		_status_key = "PROBE_RECOVERED" if store.recovered_backup else "PROBE_LOADED"
	else:
		_status_key = "PROBE_LOAD_ERROR" if store.last_error != OK else "PROBE_READY"
	_refresh()

func _toggle_pause() -> void:
	_manual_pause = not _manual_pause
	_sync_pause()

func _refresh() -> void:
	if not is_node_ready():
		return
	summary.text = tr("PROBE_SUMMARY") % [taps, clock.active_seconds, pause_count, resume_count, paused_drift_count]
	status.text = tr(_status_key)
	pause_button.text = tr("PROBE_RESUME" if _manual_pause else "PROBE_PAUSE")
	($SafeMargin/Column/SafeInfo as Label).text = tr("PROBE_SAFE_INFO") % [str(safe_margin.canvas_safe_rect)]

func _report(event: String) -> void:
	print("M1_PROBE ", JSON.stringify({"event": event, "taps": taps,
		"active_seconds": clock.active_seconds, "pauses": pause_count,
		"resumes": resume_count, "paused_drift": paused_drift_count,
		"instances": get_tree().get_nodes_in_group("m1_probe").size()}))

func _exit_tree() -> void:
	if is_inside_tree():
		get_tree().paused = false
