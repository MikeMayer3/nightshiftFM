class_name CombatScreen
extends Control

signal back_requested
var broadcast_context: Dictionary = {}
var campaign_enabled: bool = false
var campaign_mission: int = 1
var campaign_modules: Array[StringName] = []
var patchboard_enabled: bool = false
var patchboard_panel: PatchboardPanel
var mixer_open: bool = false
var mixer_button: Button
var pause_mixer_button: Button
var arsenal_enabled: bool = false
var loadout: Dictionary = ArsenalContent.DEFAULT.duplicate()
var broadcast: RadioBroadcast = RadioBroadcast.new()
var broadcast_strip: BroadcastStrip
var coach: CombatCoach
var shield_button: Button
var settings_panel: RadioSettingsPanel
var settings_button: Button
var radio_audio: RadioAudio
var active_enabled: bool = false
var signal_enabled: bool = false
var signal_bar: RadioDial
var signal_label: Label
var m4_enabled: bool = false
var report_open: bool = false
var report_button: Button
var result_goals: VBoxContainer
var result_goals_ready: bool = false
var result_checkpoint_ready: bool = false
var rewards_before: Array[String] = []
var m3_enabled: bool = false
var resume_existing: bool = false
var store: MissionStore = MissionStore.new()
var profile: MissionProfile = MissionProfile.new()
var draft_panel: DraftPanel
var last_checkpoint: Dictionary = {}
var save_failed: bool = false
var recovery_required: bool = false
var session: CombatSession = CombatSession.new()
var finish_button: Button
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
var hull_caption: Label
var shield_caption: Label
var boost_duration_bar: ProgressBar
var boost_style: StyleBoxFlat
var idle_shield_style: StyleBox
var idle_button_style: StyleBox
var idle_button_text: Color
var boost_visible: bool = false
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
	hull_caption = _bar_caption(hull_bar)
	shield_caption = _bar_caption(shield_bar)
	_setup_boost_meter()
	$Safe/Column/Health.hide()
	($Safe as SafeMargin).base_margins = Vector4(12, 12, 12, 12)
	for path: String in ["Legend", "Hint", "AbilityHint"]: $Safe/Column.get_node(path).hide()
	if m3_enabled:
		var meter: VBoxContainer = VBoxContainer.new()
		meter.name = "SignalMeter"
		$Safe/Column.add_child(meter)
		$Safe/Column.move_child(meter, arena.get_index())
		signal_label = Label.new()
		signal_label.hide()
		meter.add_child(signal_label)
		signal_bar = RadioDial.new()
		meter.add_child(signal_bar)
		draft_panel = DraftPanel.new()
		add_child(draft_panel)
		draft_panel.selected.connect(_choose_upgrade)
		draft_panel.banished.connect(func(id: StringName) -> void: session.banish_card(id))
		draft_panel.rerolled.connect(func() -> void: session.reroll_draft())
		draft_panel.recruited.connect(func(id: StringName) -> void:
			if session.recruit(id, profile.unlocked): arena.feedback.upgrade(id))
		draft_panel.branch_swapped.connect(func(id: StringName) -> void:
			var card: UpgradeDefinition = session.draft.card(id)
			if session.swap_branch(id) and card != null: arena.feedback.upgrade(card.target_id))
		draft_panel.declined.connect(func() -> void: session.recruit(&"", profile.unlocked))
		draft_panel.back_requested.connect(func() -> void: back_requested.emit())
		session.checkpoint_changed.connect(_save_checkpoint)
		patchboard_panel = PatchboardPanel.new()
		add_child(patchboard_panel)
		patchboard_panel.back_requested.connect(func() -> void: back_requested.emit())
		patchboard_panel.mixer_closed.connect(close_mixer)
		_setup_m3()
	rewards_before = ProgressionGoals.earned_ids(profile)
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
		RadioUI.button(shield_button)
		idle_button_style = shield_button.get_theme_stylebox("disabled")
		idle_button_text = shield_button.get_theme_color("font_disabled_color")
		actions.add_child(shield_button)
		shield_button.pressed.connect(use_shield)
	if session.patchboard != null and session.patchboard.mixer != null:
		mixer_button = Button.new()
		mixer_button.text = tr("MIXER_BUTTON")
		mixer_button.custom_minimum_size = Vector2(180, 76)
		mixer_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mixer_button.add_theme_font_size_override("font_size", 26)
		RadioUI.button(mixer_button)
		shield_button.get_parent().add_child(mixer_button)
		mixer_button.pressed.connect(open_mixer)
	if RadioBalance.enabled(session):
		coach = CombatCoach.new()
		$Safe/Column.add_child(coach)
		$Safe/Column.move_child(coach, shield_button.get_parent().get_index())
	ability_button.visible = session.active_combat == null
	if session.active_combat == null: ability_button.pressed.connect(use_shield)
	pause_button.text = "Ⅱ"
	pause_button.tooltip_text = tr("COMBAT_PAUSE")
	pause_button.set_meta("radio_touch_minimum", 48)
	pause_button.custom_minimum_size = Vector2(48, 48)
	pause_button.add_theme_font_size_override("font_size", 20)
	title.add_theme_font_size_override("font_size", 28)
	($Safe/Column as VBoxContainer).add_theme_constant_override("separation", 6)
	for node: Node in [$Safe/Column/Health, $Safe/Column/Bars]:
		$Safe/Column.move_child(node, $Safe/Column.get_child_count() - 1)
	broadcast.attach(session, resume_existing)
	if RadioBroadcast.enabled(session):
		broadcast_strip = BroadcastStrip.new()
		broadcast_strip.state = broadcast
		$Safe/Column.add_child(broadcast_strip)
		$Safe/Column.move_child(broadcast_strip, arena.get_index())
	arena.broadcast = broadcast
	arena.session = session
	if profile.campaign.cosmetic != &"default": arena.station_color = DraftPanel.ACCENTS[profile.campaign.cosmetic]
	session.combat_event.connect(arena.show_event)
	session.fired.connect(arena.show_shot)
	session.chain_fired.connect(arena.show_chain)
	session.support_effect.connect(arena.show_support)
	session.station_hit.connect(arena.show_hit)
	session.finished.connect(_finished)
	session.wave_started.connect(func(_number: int) -> void: _report("wave"))
	session.wave_started.connect(arena.feedback.announce)
	pause_button.pressed.connect(toggle_pause)
	resume_button.pressed.connect(toggle_pause)
	restart_button.pressed.connect(restart)
	menu_button.pressed.connect(func() -> void: back_requested.emit())
	if session.signal_progress is BroadcastProgress:
		finish_button = Button.new()
		finish_button.text = tr("BROADCAST_FINISH")
		RadioUI.button(finish_button)
		menu_button.get_parent().add_child(finish_button)
		finish_button.pressed.connect(func() -> void:
			if session.finish_endless(): back_requested.emit())
	if mixer_button != null:
		var pause_mix: Button = Button.new()
		pause_mixer_button = pause_mix
		pause_mix.text = tr("MIXER_BUTTON")
		pause_mix.custom_minimum_size.y = 76
		pause_mix.add_theme_font_size_override("font_size", 26)
		RadioUI.button(pause_mix)
		menu_button.get_parent().add_child(pause_mix)
		pause_mix.pressed.connect(open_mixer)
	settings_button = Button.new()
	settings_button.text = tr("M10_SETTINGS")
	settings_button.custom_minimum_size.y = 76
	settings_button.add_theme_font_size_override("font_size", 26)
	for state: String in ["normal", "hover", "focus", "pressed"]:
		settings_button.add_theme_stylebox_override(state, menu_button.get_theme_stylebox(state))
	menu_button.get_parent().add_child(settings_button)
	menu_button.get_parent().move_child(settings_button, menu_button.get_index())
	settings_button.pressed.connect(_open_settings)
	RadioPreferences.current.changed.connect(_apply_presentation)
	_apply_presentation()
	RadioUI.button(resume_button, true)
	radio_audio = RadioAudio.new()
	radio_audio.session = session
	add_child(radio_audio)
	broadcast.cue_started.connect(radio_audio.broadcast_cue)
	session.fired.connect(radio_audio.shot)
	session.chain_fired.connect(radio_audio.chain)
	session.station_hit.connect(radio_audio.hit)
	session.wave_started.connect(radio_audio.wave_started)
	report_button = Button.new()
	report_button.text = tr("M4_REPORT")
	report_button.custom_minimum_size.y = 76
	report_button.add_theme_font_size_override("font_size", 26)
	RadioUI.button(report_button)
	restart_button.get_parent().add_child(report_button)
	restart_button.get_parent().move_child(report_button, restart_button.get_index())
	report_button.pressed.connect(func() -> void:
		report_open = true
		draft_panel.show_report(session, func() -> void: report_open = false; _refresh())
		_refresh())
	if campaign_enabled:
		# The result sheet can grow with earned/tracked rewards and large text.
		# Keep its existing controls and references; scroll vertically within it.
		var result_column: VBoxContainer = menu_button.get_parent() as VBoxContainer
		var inset: Node = result_column.get_parent()
		var layout: VBoxContainer = VBoxContainer.new()
		layout.add_theme_constant_override("separation", 12)
		inset.add_child(layout)
		var scroll: ScrollContainer = ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.name = "ResultScroll"
		scroll.follow_focus = true
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		layout.add_child(scroll)
		PageScroll.attach(overlay, scroll, true)
		result_column.reparent(scroll)
		result_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		result_goals = VBoxContainer.new()
		result_goals.add_theme_constant_override("separation", 12)
		result_column.add_child(result_goals)
		result_column.move_child(result_goals, details.get_index() + 1)
		report_button.reparent(layout)
		var actions: HBoxContainer = HBoxContainer.new()
		actions.add_theme_constant_override("separation", 12)
		layout.add_child(actions)
		for action: Button in [restart_button, menu_button]:
			action.reparent(actions)
			action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The M1 probe owns SceneTree pause only while its page is open.
	get_tree().paused = false
	_refresh()
	_report("start")

func _process(delta: float) -> void:
	if _skip_frame:
		_skip_frame = false
	else:
		session.advance(delta)
	broadcast.update(session)
	_refresh()
	if OS.is_debug_build() and int(session.elapsed) != _last_log_second:
		_last_log_second = int(session.elapsed)
		if _last_log_second % 5 == 0:
			_report("tick")

func _choose_upgrade(id: StringName) -> void:
	var card: UpgradeDefinition = session.draft.card(id)
	var target: StringName = card.target_id if card != null else (&"shield" if id == DraftState.REFILL else &"repair")
	if session.choose_upgrade(id): arena.feedback.upgrade(target)

func open_mixer() -> void:
	if session.is_finished() or save_failed or recovery_required or settings_panel != null: return
	if session.patchboard == null or session.patchboard.mixer == null: return
	mixer_open = true
	_sync_pause()
	patchboard_panel.open(session, profile, true)
	_refresh()

func close_mixer() -> void:
	mixer_open = false
	patchboard_panel.live = false
	_sync_pause()
	# A pre-mixer checkpoint may still be waiting at the old connection screen.
	if session.is_wiring() and not session.paused: session.launch_wave()
	_refresh_decision()

func toggle_pause() -> void:
	if mixer_open:
		close_mixer()
		return
	if settings_panel != null: return
	if session.is_finished():
		return
	manual_pause = not manual_pause
	_sync_pause()
	_report("manual_pause" if manual_pause else "manual_resume")

func _open_settings() -> void:
	if settings_panel != null: return
	manual_pause = true
	_sync_pause()
	arena.clear_pointer()
	settings_panel = RadioSettingsPanel.new()
	add_child(settings_panel)
	settings_panel.back_requested.connect(func() -> void:
		remove_child(settings_panel)
		settings_panel.queue_free()
		settings_panel = null
		# Returning to the pause menu never resumes a run unexpectedly.
		_refresh())

func _apply_presentation() -> void:
	if shield_button != null:
		var actions: Node = shield_button.get_parent()
		if RadioBalance.enabled(session):
			actions.move_child(shield_button, 0 if RadioPreferences.current.enabled("left_handed") else actions.get_child_count() - 1)
		else:
			actions.move_child(ability_button, 0 if RadioPreferences.current.enabled("left_handed") else 1)
	arena.queue_redraw()

func use_shield() -> void:
	if session.activate_shield():
		if coach != null:
			RadioPreferences.current.remember_coach("shield")
			coach.current_hint = ""
		_report("shield")
	_refresh()

func restart() -> void:
	rewards_before = ProgressionGoals.earned_ids(profile)
	result_goals_ready = false
	result_checkpoint_ready = false
	if result_goals != null:
		for child: Node in result_goals.get_children():
			result_goals.remove_child(child)
			child.queue_free()
	report_open = false
	mixer_open = false
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
	arena.fragments.clear()
	arena.feedback.reset()
	broadcast.attach(session)
	if radio_audio != null: radio_audio.broadcast_player.stop()
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
	session.paused = mixer_open or manual_pause or not focused or app_paused or save_failed or recovery_required
	if was_paused and not session.paused:
		_skip_frame = true
	arena.clear_pointer()
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if settings_panel != null: return
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
	if broadcast_strip != null: broadcast_strip.refresh(session)
	if coach != null: coach.refresh(session)
	if not is_node_ready():
		return
	title.text = tr("BROADCAST_ENDLESS_WAVE") % maxi(1, session.wave) if session.signal_progress is BroadcastProgress else tr("ACTIVE_WAVE" if session.active_combat != null else "COMBAT_WAVE") % [maxi(1, session.wave), session.total_waves()]
	hull_bar.max_value = session.maximum_hull()
	hull_bar.value = session.hull
	shield_bar.max_value = session.run.shield.capacity
	shield_bar.value = session.run.shield.current
	hull_caption.text = tr("POLISH_HEALTH_BAR") % [session.hull, session.maximum_hull()]
	shield_caption.text = tr("POLISH_SHIELD_BAR") % [session.run.shield.current, session.run.shield.capacity]
	_refresh_boost_meter()
	status.visible = session.phase == CombatSession.Phase.INTERMISSION
	status.text = tr("COMBAT_FOCUS" if session.focus_active else "COMBAT_AUTO")
	if session.phase == CombatSession.Phase.INTERMISSION:
		status.text = tr("COMBAT_WAVE") % [session.wave + 1, session.total_waves()] if RadioBalance.enabled(session) else tr("COMBAT_NEXT_WAVE") % [session.wave + 1, ceili(session.phase_time)]
	ability_button.text = tr("COMBAT_ABILITY_ACTIVE") if session.ability_left > 0 else (tr("COMBAT_ABILITY_WAIT") % ceili(session.ability_wait) if session.ability_wait > 0 else tr("COMBAT_ABILITY"))
	ability_button.disabled = session.paused or session.is_finished() or session.is_deciding() or session.ability_wait > 0
	if session.active_combat != null:
		ability_button.text = tr("ACTIVE_WAIT") % ceili(session.active_combat.cooldown) if session.active_combat.cooldown > 0 else tr("ACTIVE_BURST")
		ability_button.disabled = session.paused or session.phase != CombatSession.Phase.COMBAT or session.active_combat.cooldown > 0
	if shield_button != null:
		shield_button.visible = session.arsenal != null
		shield_button.text = tr("M5_SHIELD_WAIT") % ceili(session.ability_wait) if session.ability_wait > 0 else tr("M5_SHIELD_READY")
		if session.draft is ArsenalDraft and session.draft.loadout.shield == "capacitor":
			shield_button.text = tr("POLISH_BOOST_WAIT") % ceili(session.ability_wait) if session.ability_wait > 0 else tr("POLISH_BOOST_READY")
			if boost_visible: shield_button.text = tr("POLISH_BOOST_ACTIVE") % ceili(RadioShieldVisual.seconds_left(session))
		shield_button.disabled = session.paused or session.is_finished() or session.is_deciding() or session.ability_wait > 0
	if m3_enabled and session.draft != null:
		($Safe/Column/AbilityHint as Label).text = tr("M3_ABILITY_HINT") % [session.shield_stat(&"duration", 2.5), session.shield_stat(&"cooldown", 12)]
		($Safe/Column/Hint as Label).text = tr("M3_RANKS") % [session.run.main_weapon.rank, session.run.shield.rank, session.run.supports[0].rank if not session.run.supports.is_empty() else 0]
		if session.supports != null:
			($Safe/Column/Hint as Label).text = tr("M4_RANKS") % session.run.supports.size()
			($Safe/Column/Legend as Label).text = tr("M4_LEGEND")
			if session.phase == CombatSession.Phase.COMBAT and session.wave == 10: status.text = tr("M4_FINALE")
		if signal_bar != null:
			signal_bar.get_parent().visible = session.signal_progress != null
			if session.signal_progress != null:
				signal_bar.set_cycle(session.random.seed_value, session.signal_progress.choices)
				signal_bar.max_value = session.signal_progress.threshold()
				signal_bar.value = session.signal_progress.progress()
				signal_bar.running = not session.paused and not session.is_finished() and not session.is_deciding() and not session.is_wiring()
				signal_bar.queue_redraw()
				signal_label.text = tr("SIGNAL_METER") % [session.signal_progress.progress(), session.signal_progress.threshold()]
				if session.signal_progress.ready(): signal_label.text = tr("SIGNAL_FULL")
		draft_panel.visible = report_open or (session.is_deciding() and not session.paused)
	if patchboard_panel != null:
		patchboard_panel.visible = (mixer_open or (session.is_wiring() and not session.paused)) and not report_open and not save_failed and not recovery_required
	if mixer_button != null:
		mixer_button.disabled = session.is_finished() or mixer_open or save_failed or recovery_required
	if recovery_required or save_failed:
		draft_panel.show()
		return
	overlay.visible = not mixer_open and not report_open and (session.paused or session.is_finished())
	if settings_button != null: settings_button.visible = not session.is_finished()
	if report_button != null: report_button.visible = session.supports != null and session.is_finished()
	if pause_mixer_button != null: pause_mixer_button.visible = not session.is_finished()
	if finish_button != null:
		finish_button.visible = not session.is_finished()
		finish_button.disabled = session.achievement_run.cleared_waves == 0
	resume_button.visible = not session.is_finished()
	resume_button.disabled = not focused or app_paused
	if result_goals != null:
		result_goals.visible = session.is_finished()
		if session.is_finished() and not result_goals_ready: _show_result_goals()
	if session.is_finished():
		overlay_title.text = tr("COMBAT_VICTORY" if session.phase == CombatSession.Phase.VICTORY else "COMBAT_DEFEAT")
		var cause: String = tr("COMBAT_CLEAN") if session.damage_taken == 0 else tr("COMBAT_CAUSE") % [tr(session.last_cause), tr(session.last_kind)]
		details.text = tr("M3_RESULTS" if m3_enabled else "COMBAT_RESULTS") % [session.wave, session.elapsed, session.kills, session.intercepted, session.breaches, session.hull, session.maximum_hull(), cause]
		if BroadcastRules.expanded(session):
			details.text = tr(PostRunAnalysis.loss_key(session)) + "\n\n" + tr("P2_RESULT_STATS") % [session.wave, session.kills, session.breaches] + "\n" + tr("POLISH_HEALTH_BAR") % [session.hull, session.maximum_hull()]
			restart_button.text = tr("P2_RETRY")
	else:
		overlay_title.text = tr("COMBAT_PAUSED")
		details.text = tr("SIGNAL_PAUSE" if session.signal_progress != null else ("M3_PAUSE_BODY" if m3_enabled else "COMBAT_PAUSE_BODY"))

		if session.active_combat != null: details.text = tr("M10_RADIO_CONTROLS")
		for id: StringName in profile.achievements.tracked:
			details.text += "\n" + tr(AchievementCatalog.ALL[id].name_key) + "  " + str(profile.achievements.count(id)) + "/" + str(AchievementCatalog.ALL[id].threshold)

func _show_result_goals() -> void:
	# Reward commits happen at checkpoints. Build once after that commit, never
	# award from rendering or show uncommitted rewards as earned.
	if not result_checkpoint_ready: return
	result_goals_ready = true
	for row: Dictionary in ProgressionGoals.newly_earned(profile, rewards_before, loadout):
		ProgressionCard.add_to(result_goals, row, tr("P6_NEW"))
	var goal: Dictionary = ProgressionGoals.next(profile)
	if not goal.is_empty(): ProgressionCard.add_to(result_goals, goal, tr("P6_NEXT"))
	for id: StringName in profile.achievements.tracked:
		ProgressionCard.add_to(result_goals, ProgressionGoals.achievement(profile.achievements, id, session.achievement_run.eligible), tr("P6_TRACKED"))

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
		bar.custom_minimum_size.y = 76
		var background: StyleBoxFlat = StyleBoxFlat.new()
		background.bg_color = Color("152837")
		background.border_color = Color("48616e")
		background.set_border_width_all(2)
		background.set_corner_radius_all(8)
		bar.add_theme_stylebox_override("background", background)
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		fill.bg_color = Color("9b623d") if bar == hull_bar else Color("286f69")
		fill.set_corner_radius_all(8)
		bar.add_theme_stylebox_override("fill", fill)

func _bar_caption(bar: ProgressBar) -> Label:
	var label: Label = Label.new()
	label.name = "Caption"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 23)
	label.add_theme_color_override("font_color", Color("fff1da"))
	label.add_theme_color_override("font_outline_color", Color("14232c"))
	label.add_theme_constant_override("outline_size", 3)
	bar.add_child(label)
	return label

func _setup_boost_meter() -> void:
	idle_shield_style = shield_bar.get_theme_stylebox("background")
	boost_style = RadioUI.surface("29213c","c4aff5")
	boost_style.set_border_width_all(2)
	boost_duration_bar = ProgressBar.new()
	boost_duration_bar.name = "BoostDuration"
	boost_duration_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boost_duration_bar.show_percentage = false
	boost_duration_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	boost_duration_bar.offset_top = -6
	boost_duration_bar.offset_left = 3; boost_duration_bar.offset_right = -3; boost_duration_bar.offset_bottom = -2
	var fill: StyleBoxFlat = StyleBoxFlat.new(); fill.bg_color = Color("c4aff5")
	boost_duration_bar.add_theme_stylebox_override("fill",fill)
	var background: StyleBoxFlat = StyleBoxFlat.new(); background.bg_color = Color("44345b")
	boost_duration_bar.add_theme_stylebox_override("background",background)
	shield_bar.add_child(boost_duration_bar)
	boost_duration_bar.hide()

func _refresh_boost_meter() -> void:
	var amount: float = RadioShieldVisual.reserve(session)
	var active: bool = amount > 0
	if active != boost_visible:
		shield_bar.add_theme_stylebox_override("background",boost_style if active else idle_shield_style)
	if shield_button != null and bool(shield_button.get_meta("boost_style",false)) != active:
		shield_button.add_theme_stylebox_override("disabled",boost_style if active else idle_button_style)
		shield_button.add_theme_color_override("font_disabled_color",Color("eee4ff") if active else idle_button_text)
		shield_button.set_meta("boost_style",active)
	boost_visible = active
	boost_duration_bar.visible = active
	if active:
		shield_caption.text += "\n" + tr("POLISH_BOOST_AMOUNT") % ceili(amount)
		boost_duration_bar.max_value = maxf(RadioShieldVisual.seconds_left(session),session.shield_stat(&"duration",3))
		boost_duration_bar.value = RadioShieldVisual.seconds_left(session)

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
		if session.achievement_run != null and not AchievementRun.production_build(): session.achievement_run.eligible = false
		if session.draft is ArsenalDraft: loadout = (session.draft as ArsenalDraft).loadout.duplicate()
		if session.campaign != null:
			campaign_mission = session.campaign.mission
			campaign_modules = session.campaign.modules.duplicate()
			broadcast_context = {"mode": session.campaign.mode, "difficulty": session.campaign.difficulty, "contract": session.campaign.contract} if session.campaign.expanded else {}
		else: campaign_enabled = false
		last_checkpoint = data.run.duplicate(true)
		result_checkpoint_ready = session.is_finished()
		_refresh_decision()
	else:
		_start_m3()

func _start_m3() -> void:
	draft_panel.banish_mode = false
	var identity: StringName = StringName("run.%d" % profile.next_run)
	profile.next_run += 1
	if campaign_enabled:
		profile.enable_m4()
		var context: Dictionary = {"mission": campaign_mission, "cleared": profile.campaign.cleared, "modules": Array(campaign_modules)}
		context.merge(broadcast_context)
		session.start_campaign(int(Time.get_unix_time_from_system()) ^ Time.get_ticks_usec(), identity, loadout, context)
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
	profile.broadcast.record(session)
	profile.achievements.record_waves(session)
	if session.phase == CombatSession.Phase.VICTORY or session.signal_progress is BroadcastProgress and session.phase == CombatSession.Phase.DEFEAT: profile.commit_reward(session.run_id, session)
	if session.patchboard != null:
		for id: StringName in session.patchboard.discovered():
			if id not in profile.discovered: profile.discovered.append(id)
	last_checkpoint = session.to_checkpoint()
	_retry_save()
	result_checkpoint_ready = session.is_finished()

func _retry_save() -> void:
	save_failed = store.save(profile, last_checkpoint) != OK
	if save_failed:
		session.paused = true
		draft_panel.show_recovery(tr("M3_SAVE_ERROR"), _retry_save, _fresh_save)
	else:
		_sync_pause()
		_refresh_decision()

func _refresh_decision() -> void:
	if patchboard_panel != null and session.is_wiring() and not mixer_open:
		if session.patchboard.mixer != null: open_mixer()
		else: patchboard_panel.open(session, profile)
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
