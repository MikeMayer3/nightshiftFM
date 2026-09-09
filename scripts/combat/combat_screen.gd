class_name CombatScreen
extends Control

signal back_requested
var campaign_enabled: bool = false
var campaign_mission: int = 1
var campaign_modules: Array[StringName] = []
var patchboard_enabled: bool = false
var patchboard_panel: PatchboardPanel
var arsenal_enabled: bool = false
var loadout: Dictionary = ArsenalContent.DEFAULT.duplicate()
var shield_button: Button
var active_enabled: bool = false
var signal_enabled: bool = false
var signal_bar: ProgressBar
var signal_label: Label
var m4_enabled: bool = false
var report_open: bool = false
var report_button: Button
var m3_enabled: bool = false
var resume_existing: bool = false
var store: MissionStore = MissionStore.new()
var profile: MissionProfile = MissionProfile.new()
var draft_panel: DraftPanel
var last_checkpoint: Dictionary = {}
var save_failed: bool = false
var recovery_required: bool = false
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
	($Safe as SafeMargin).base_margins = Vector4(12, 12, 12, 12)
	for path: String in ["Legend", "Hint", "AbilityHint"]: $Safe/Column.get_node(path).hide()
	if m3_enabled:
		var meter: VBoxContainer = VBoxContainer.new()
		meter.name = "SignalMeter"
		$Safe/Column.add_child(meter)
		$Safe/Column.move_child(meter, arena.get_index())
		signal_label = Label.new()
		signal_label.add_theme_font_size_override("font_size", 24)
		meter.add_child(signal_label)
		signal_bar = ProgressBar.new()
		signal_bar.custom_minimum_size.y = 16
		signal_bar.show_percentage = false
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		fill.bg_color = Color("bba5f4")
		fill.set_corner_radius_all(4)
		signal_bar.add_theme_stylebox_override("fill", fill)
		meter.add_child(signal_bar)
		draft_panel = DraftPanel.new()
		add_child(draft_panel)
		draft_panel.selected.connect(func(id: StringName) -> void: session.choose_upgrade(id))
		draft_panel.banished.connect(func(id: StringName) -> void: session.banish_card(id))
		draft_panel.rerolled.connect(func() -> void: session.reroll_draft())
		draft_panel.recruited.connect(func(id: StringName) -> void: session.recruit(id, profile.unlocked))
		draft_panel.branch_swapped.connect(func(id: StringName) -> void: session.swap_branch(id))
		draft_panel.declined.connect(func() -> void: session.recruit(&"", profile.unlocked))
		draft_panel.back_requested.connect(func() -> void: back_requested.emit())
		session.checkpoint_changed.connect(_save_checkpoint)
		patchboard_panel = PatchboardPanel.new()
		add_child(patchboard_panel)
		patchboard_panel.back_requested.connect(func() -> void: back_requested.emit())
		_setup_m3()
	if arsenal_enabled or session.arsenal != null:
		var actions: HBoxContainer = HBoxContainer.new()
		var footer: Node = ability_button.get_parent()
		var place: int = ability_button.get_index()
		footer.add_child(actions)
		footer.move_child(actions, place)
		ability_button.reparent(actions)
		ability_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shield_button = Button.new()
		shield_button.custom_minimum_size = Vector2(180, 76)
		shield_button.add_theme_font_size_override("font_size", 26)
		actions.add_child(shield_button)
		shield_button.pressed.connect(func() -> void: session.activate_shield())
	arena.session = session
	if profile.campaign.cosmetic != &"default": arena.station_color = DraftPanel.ACCENTS[profile.campaign.cosmetic]
	session.fired.connect(arena.show_shot)
	session.chain_fired.connect(arena.show_chain)
	session.support_effect.connect(arena.show_support)
	session.station_hit.connect(arena.show_hit)
	session.finished.connect(_finished)
	session.wave_started.connect(func(_number: int) -> void: _report("wave"))
	pause_button.pressed.connect(toggle_pause)
	resume_button.pressed.connect(toggle_pause)
	ability_button.gui_input.connect(func(event: InputEvent) -> void: arena.button_input(event, ability_button))
	ability_button.pressed.connect(func() -> void:
		if not arena.button_click_handled(): use_shield())
	restart_button.pressed.connect(restart)
	menu_button.pressed.connect(func() -> void: back_requested.emit())
	report_button = Button.new()
	report_button.text = tr("M4_REPORT")
	report_button.custom_minimum_size.y = 76
	report_button.add_theme_font_size_override("font_size", 26)
	restart_button.get_parent().add_child(report_button)
	restart_button.get_parent().move_child(report_button, restart_button.get_index())
	report_button.pressed.connect(func() -> void:
		report_open = true
		draft_panel.show_report(session, func() -> void: report_open = false; _refresh()))
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
	if session.active_combat != null:
		var target: CombatActor = session.target()
		if target != null: session.active_combat.burst(session, session.focus_point if session.focus_active else target.position)
		_refresh()
		return
	if session.activate_shield():
		_report("shield")
	_refresh()

func restart() -> void:
	report_open = false
	if m3_enabled:
		_start_m3()
	else:
		session.restart()
	manual_pause = false
	arena.clear_pointer()
	arena.shot_flash = 0.0
	arena.hit_flash = 0.0
	arena.chains.clear()
	arena.pulses.clear()
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
	session.paused = manual_pause or not focused or app_paused or save_failed or recovery_required
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
	title.text = tr("ACTIVE_WAVE" if session.active_combat != null else "COMBAT_WAVE") % [maxi(1, session.wave), session.total_waves()]
	hull_bar.max_value = session.maximum_hull()
	hull_bar.value = session.hull
	shield_bar.max_value = session.run.shield.capacity
	shield_bar.value = session.run.shield.current
	($Safe/Column/Health as Label).text = tr("COMBAT_HEALTH") % [session.hull, session.maximum_hull(), session.run.shield.current, session.run.shield.capacity]
	status.visible = session.phase == CombatSession.Phase.INTERMISSION
	status.text = tr("COMBAT_FOCUS" if session.focus_active else "COMBAT_AUTO")
	if session.phase == CombatSession.Phase.INTERMISSION:
		status.text = tr("COMBAT_NEXT_WAVE") % [session.wave + 1, ceili(session.phase_time)]
	ability_button.text = tr("COMBAT_ABILITY_ACTIVE") if session.ability_left > 0 else (tr("COMBAT_ABILITY_WAIT") % ceili(session.ability_wait) if session.ability_wait > 0 else tr("COMBAT_ABILITY"))
	ability_button.disabled = session.paused or session.is_finished() or session.is_deciding() or session.ability_wait > 0
	if session.active_combat != null:
		ability_button.text = tr("ACTIVE_WAIT") % ceili(session.active_combat.cooldown) if session.active_combat.cooldown > 0 else tr("ACTIVE_BURST")
		ability_button.disabled = session.paused or session.phase != CombatSession.Phase.COMBAT or session.active_combat.cooldown > 0
	if shield_button != null:
		shield_button.visible = session.arsenal != null
		shield_button.text = tr("M5_SHIELD_WAIT") % ceili(session.ability_wait) if session.ability_wait > 0 else tr("M5_SHIELD_READY")
		shield_button.disabled = session.paused or session.is_finished() or session.is_deciding() or session.ability_wait > 0
	if m3_enabled and session.draft != null:
		($Safe/Column/Health as Label).text = tr("M3_HEALTH") % [session.hull, session.maximum_hull(), session.run.shield.current, session.run.shield.capacity]
		($Safe/Column/AbilityHint as Label).text = tr("M3_ABILITY_HINT") % [session.shield_stat(&"duration", 2.5), session.shield_stat(&"cooldown", 12)]
		($Safe/Column/Hint as Label).text = tr("M3_RANKS") % [session.run.main_weapon.rank, session.run.shield.rank, session.run.supports[0].rank]
		if session.supports != null:
			($Safe/Column/Hint as Label).text = tr("M4_RANKS") % session.run.supports.size()
			($Safe/Column/Legend as Label).text = tr("M4_LEGEND")
			if session.phase == CombatSession.Phase.COMBAT and session.wave == 10: status.text = tr("M4_FINALE")
		if signal_bar != null:
			signal_bar.get_parent().visible = session.signal_progress != null
			if session.signal_progress != null:
				signal_bar.max_value = session.signal_progress.threshold()
				signal_bar.value = session.signal_progress.progress()
				signal_label.text = tr("SIGNAL_METER") % [session.signal_progress.progress(), session.signal_progress.threshold()]
				if session.signal_progress.ready(): signal_label.text = tr("SIGNAL_FULL")
		draft_panel.visible = report_open or (session.is_deciding() and not session.paused)
	if patchboard_panel != null:
		patchboard_panel.visible = session.is_wiring() and not session.paused and not report_open
	if recovery_required or save_failed:
		draft_panel.show()
		return
	overlay.visible = not report_open and (session.paused or session.is_finished())
	if report_button != null: report_button.visible = session.supports != null and session.is_finished()
	resume_button.visible = not session.is_finished()
	resume_button.disabled = not focused or app_paused
	if session.is_finished():
		overlay_title.text = tr("COMBAT_VICTORY" if session.phase == CombatSession.Phase.VICTORY else "COMBAT_DEFEAT")
		var cause: String = tr("COMBAT_CLEAN") if session.damage_taken == 0 else tr("COMBAT_CAUSE") % [tr(session.last_cause), tr(session.last_kind)]
		details.text = tr("M3_RESULTS" if m3_enabled else "COMBAT_RESULTS") % [session.wave, session.elapsed, session.kills, session.intercepted, session.breaches, session.hull, session.maximum_hull(), cause]
	else:
		overlay_title.text = tr("COMBAT_PAUSED")
		details.text = tr("SIGNAL_PAUSE" if session.signal_progress != null else ("M3_PAUSE_BODY" if m3_enabled else "COMBAT_PAUSE_BODY"))

		if session.active_combat != null: details.text = tr("ACTIVE_PAUSE")

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

func _setup_m3() -> void:
	var data: Dictionary = store.load_save()
	if store.error != OK:
		recovery_required = true
		session.paused = true
		draft_panel.show_recovery(tr("M3_CORRUPT"), _retry_load, _fresh_save)
		return
	if not data.is_empty(): profile.restore(data.profile)
	if resume_existing and not data.is_empty() and data.run != null:
		session.restore_checkpoint(data.run)
		if session.draft is ArsenalDraft: loadout = (session.draft as ArsenalDraft).loadout.duplicate()
		if session.campaign != null:
			campaign_mission = session.campaign.mission
			campaign_modules = session.campaign.modules.duplicate()
		else: campaign_enabled = false
		last_checkpoint = data.run.duplicate(true)
		_refresh_decision()
	else:
		_start_m3()

func _start_m3() -> void:
	draft_panel.banish_mode = false
	var identity: StringName = StringName("run.%d" % profile.next_run)
	profile.next_run += 1
	if campaign_enabled:
		profile.enable_m4()
		session.start_campaign(int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec(), identity, loadout, {"mission": campaign_mission, "cleared": profile.campaign.cleared, "modules": Array(campaign_modules)})
	elif patchboard_enabled:
		profile.enable_m4()
		session.start_patchboard(int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec(), identity, loadout)
	elif arsenal_enabled:
		profile.enable_m4()
		session.start_arsenal(int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec(), identity, loadout)
	elif active_enabled:
		profile.enable_m4()
		session.start_active(int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec(), identity)
	elif signal_enabled:
		profile.enable_m4()
		session.start_signal(int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec(), identity)
	elif m4_enabled:
		profile.enable_m4()
		session.start_m4(int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec(), identity)
	else:
		session.start_m3(int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec(), identity)
	save_failed = false
	recovery_required = false
	_save_checkpoint()

func _save_checkpoint() -> void:
	if session.draft == null: return
	if session.phase == CombatSession.Phase.VICTORY: profile.commit_reward(session.run_id, session)
	if session.patchboard != null:
		for id: StringName in session.patchboard.discovered():
			if id not in profile.discovered: profile.discovered.append(id)
	last_checkpoint = session.to_checkpoint()
	_retry_save()

func _retry_save() -> void:
	save_failed = store.save(profile, last_checkpoint) != OK
	if save_failed:
		session.paused = true
		draft_panel.show_recovery(tr("M3_SAVE_ERROR"), _retry_save, _fresh_save)
	else:
		_sync_pause()
		_refresh_decision()

func _refresh_decision() -> void:
	if patchboard_panel != null and session.is_wiring(): patchboard_panel.open(session, profile)
	if session.phase == CombatSession.Phase.DRAFT:
		draft_panel.show_draft(session)
	elif session.phase == CombatSession.Phase.RECRUIT:
		draft_panel.show_recruit(session)
	else:
		draft_panel.hide()
	_refresh()

func _retry_load() -> void:
	recovery_required = false
	_setup_m3()

func _fresh_save() -> void:
	# This button is an explicit player choice on a recovery screen.
	if recovery_required: profile = MissionProfile.new()
	_start_m3()
