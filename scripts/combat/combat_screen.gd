class_name CombatScreen
extends Control

signal back_requested
var session: CombatSession = CombatSession.new()
var manual_pause: bool = false
var focused: bool = true
var app_paused: bool = false
var _skip_frame: bool = false
var _last_log_second: int = -1
@onready var arena: CombatArena = $Safe/Column/Arena
@onready var title: Label = $Safe/Column/Header/Title
@onready var status: Label = $Safe/Column/Status
@onready var hull_bar: ProgressBar = $Safe/Column/Bars/Hull
@onready var shield_bar: ProgressBar = $Safe/Column/Bars/Shield
@onready var pause_button: Button = $Safe/Column/Header/Pause
@onready var ability_button: Button = $Safe/Column/Ability
@onready var overlay: PanelContainer = $Overlay
@onready var overlay_title: Label = $Overlay/Inset/Column/Title
@onready var details: Label = $Overlay/Inset/Column/Details
@onready var resume_button: Button = $Overlay/Inset/Column/Resume
@onready var restart_button: Button = $Overlay/Inset/Column/Restart
@onready var menu_button: Button = $Overlay/Inset/Column/Menu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("m2_combat")
	_style_controls()
	arena.session = session
	session.fired.connect(arena.show_shot)
	session.station_hit.connect(arena.show_hit)
	session.finished.connect(_finished)
	session.wave_started.connect(func(_number: int) -> void: _report("wave"))
	pause_button.pressed.connect(toggle_pause)
	resume_button.pressed.connect(toggle_pause)
	ability_button.pressed.connect(use_shield)
	restart_button.pressed.connect(restart)
	menu_button.pressed.connect(func() -> void: back_requested.emit())
	# The M1 probe owns SceneTree pause only while its page is open.
	get_tree().paused = false
	_refresh()
	_report("start")

func _process(delta: float) -> void:
	if _skip_frame:
		_skip_frame = false
	else:
		session.advance(delta)
	_refresh()
	if OS.is_debug_build() and int(session.elapsed) != _last_log_second:
		_last_log_second = int(session.elapsed)
		if _last_log_second % 5 == 0:
			_report("tick")

func toggle_pause() -> void:
	if session.is_finished():
		return
	manual_pause = not manual_pause
	_sync_pause()
	_report("manual_pause" if manual_pause else "manual_resume")

func use_shield() -> void:
	if session.activate_shield():
		_report("shield")
	_refresh()

func restart() -> void:
	session.restart()
	manual_pause = false
	arena.clear_pointer()
	arena.shot_flash = 0.0
	arena.hit_flash = 0.0
	_last_log_second = -1
	_sync_pause()
	_refresh()
	_report("restart")

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT: focused = false
		NOTIFICATION_APPLICATION_FOCUS_IN: focused = true
		NOTIFICATION_APPLICATION_PAUSED: app_paused = true
		NOTIFICATION_APPLICATION_RESUMED: app_paused = false
		_: return
	_sync_pause()
	_report("lifecycle")

func _sync_pause() -> void:
	var was_paused: bool = session.paused
	session.paused = manual_pause or not focused or app_paused
	if was_paused and not session.paused:
		_skip_frame = true
	arena.clear_pointer()
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("menu_back"):
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("shield_ability"):
		use_shield()
		get_viewport().set_input_as_handled()

func _finished(_victory: bool) -> void:
	arena.clear_pointer()
	_refresh()
	_report("results")

func _refresh() -> void:
	if not is_node_ready():
		return
	title.text = tr("COMBAT_WAVE") % [maxi(1, session.wave), 3]
	hull_bar.value = session.hull
	shield_bar.max_value = session.run.shield.capacity
	shield_bar.value = session.run.shield.current
	($Safe/Column/Health as Label).text = tr("COMBAT_HEALTH") % [session.hull, session.run.shield.current]
	status.text = tr("COMBAT_FOCUS" if session.focus_active else "COMBAT_AUTO")
	if session.phase == CombatSession.Phase.INTERMISSION:
		status.text = tr("COMBAT_NEXT_WAVE") % [session.wave + 1, ceili(session.phase_time)]
	ability_button.text = tr("COMBAT_ABILITY_ACTIVE") if session.ability_left > 0 else (tr("COMBAT_ABILITY_WAIT") % ceili(session.ability_wait) if session.ability_wait > 0 else tr("COMBAT_ABILITY"))
	ability_button.disabled = session.paused or session.is_finished() or session.ability_wait > 0
	overlay.visible = session.paused or session.is_finished()
	resume_button.visible = not session.is_finished()
	resume_button.disabled = not focused or app_paused
	if session.is_finished():
		overlay_title.text = tr("COMBAT_VICTORY" if session.phase == CombatSession.Phase.VICTORY else "COMBAT_DEFEAT")
		var cause: String = tr("COMBAT_CLEAN") if session.damage_taken == 0 else tr("COMBAT_CAUSE") % [tr(session.last_cause), tr(session.last_kind)]
		details.text = tr("COMBAT_RESULTS") % [session.wave, session.elapsed, session.kills, session.intercepted, session.breaches, session.hull, cause]
	else:
		overlay_title.text = tr("COMBAT_PAUSED")
		details.text = tr("COMBAT_PAUSE_BODY")

func _report(event: String) -> void:
	if OS.is_debug_build():
		print("M2_COMBAT ", JSON.stringify({"event": event, "seconds": session.elapsed,
			"wave": session.wave, "phase": session.phase, "hull": session.hull,
			"shield": session.run.shield.current, "actors": session.actors.size(),
			"paused": session.paused, "focus": session.focus_active,
			"instances": get_tree().get_nodes_in_group("m2_combat").size()}))

func _style_controls() -> void:
	var panel: StyleBoxFlat = StyleBoxFlat.new()
	panel.bg_color = Color("122432")
	panel.border_color = Color("466579")
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(12)
	overlay.add_theme_stylebox_override("panel", panel)
	for button: Button in [pause_button, ability_button, resume_button, restart_button, menu_button]:
		var normal: StyleBoxFlat = panel.duplicate() as StyleBoxFlat
		normal.bg_color = Color("1b3544")
		button.add_theme_stylebox_override("normal", normal)
		var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
		hover.border_color = Color("76dbca")
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("focus", hover)
		button.add_theme_stylebox_override("pressed", hover)
	for bar: ProgressBar in [hull_bar, shield_bar]:
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		fill.bg_color = Color("efa968") if bar == hull_bar else Color("76dbca")
		fill.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("fill", fill)
