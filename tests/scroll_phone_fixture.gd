extends Node
## Only exported by tools/build_scroll_qa.py into a separate Android package.
var page: Control
var holder: Node
var scroll: ScrollContainer
var command: String = ""
var elapsed: float = 0.0
var picked: String = ""
var resolved: bool = false
func _ready() -> void:
	RadioPreferences.current.values.large_text = true
	RadioPreferences.current.values.sound = false
	RadioPreferences.current.values.music = false
	open_page("0")
func open_page(value: String) -> void:
	command = value
	picked = ""; resolved = false
	RadioPreferences.current.values.large_text = not value.contains(":normal")
	if is_instance_valid(holder):
		remove_child(holder); holder.queue_free()
	holder = Node.new(); add_child(holder)
	var index: int = int(value.split(":")[0])
	var profile: MissionProfile = MissionProfile.new()
	var session: CombatSession = CombatSession.new()
	session.start_campaign(42,&"run.99",{"main":"pulse","shield":"capacitor","support":"needle_swarm"},{"mission":1,"cleared":12,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
	session.advance(.1); session.draft.track(&"needle_swarm").accept(&"m5.needle_swarm.t0",[])
	session.phase = CombatSession.Phase.DRAFT
	session.paused = true
	session.draft.offers.assign([&"m5.needle_swarm.b3",&"recruit.echo_deck",&"m5.pulse.t0"])
	if index == 19:
		var real: CombatSession = CombatSession.new()
		real.start_campaign(42,&"run.1",ArsenalContent.DEFAULT,{"mission":1,"cleared":0,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
		for step: int in 800:
			if real.is_deciding() or real.is_finished(): break
			real.advance(.1)
		var draft: DraftPanel = DraftPanel.new(); holder.add_child(draft); draft.show_draft(real); page = draft
		draft.selected.connect(func(id: StringName) -> void:
			picked = String(id)
			resolved = real.choose_upgrade(id))
	elif index < 8:
		var panel: CampaignPanel = CampaignPanel.new(); panel.profile = profile; holder.add_child(panel)
		panel.call(["show_home","show_rewards","show_achievements","show_codex","show_records","show_modes","show_enemies","show_logs"][index]); page = panel
	elif index == 8:
		var picker: ArsenalPicker = ArsenalPicker.new(); picker.campaign_profile = CampaignProfile.new(); picker.campaign_profile.cleared = 12; holder.add_child(picker)
		picker.modules_body.show(); picker.details_body.show(); page = picker
	elif index == 9:
		var settings: RadioSettingsPanel = RadioSettingsPanel.new(); holder.add_child(settings)
		settings.find_child("ReplayHints",true,false).get_parent().show(); page = settings
	elif index < 15:
		var draft: DraftPanel = DraftPanel.new(); holder.add_child(draft); page = draft
		if index in [10,11]:
			draft.show_draft(session)
			if index == 11: draft.info_buttons[0].pressed.emit()
		elif index == 12: draft.show_report(session,func() -> void: pass)
		elif index == 13: draft.show_recruit(session)
		else: draft.show_recovery("Save recovery details. ".repeat(50),func() -> void: pass,func() -> void: pass)
	elif index < 18:
		var patch: PatchboardPanel = PatchboardPanel.new(); holder.add_child(patch); patch.show_unavailable = true; patch.open(session,profile,index != 15); page = patch
		if index == 17: patch.connection_toggle.pressed.emit()
	else:
		var screen: CombatScreen = preload("res://scenes/combat/combat.tscn").instantiate()
		screen.campaign_enabled = true; screen.active_enabled = true; screen.arsenal_enabled = true; screen.m3_enabled = true
		screen.store = MissionStore.new("user://scroll_result_%d.json"%Time.get_ticks_usec()); holder.add_child(screen)
		screen.set_process(false); screen.arena.set_process(false)
		screen.profile.achievements.track(&"first_broadcast"); screen.profile.achievements.track(&"endless_three"); screen.profile.achievements.track(&"arc_aerial_three_capstones")
		screen.session.wave=10; screen.session.achievement_run.cleared_waves=10; screen.session._finish(true); screen._refresh(); page = screen.overlay
	RadioPreferences.current.apply_fonts(page)
	scroll = page.find_children("*","ScrollContainer",true,false)[0]
	if OS.has_feature("scroll_baseline"):
		for node: Node in page.get_children():
			if node is PageScroll: node.queue_free()
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < .1: return
	elapsed = 0
	if FileAccess.file_exists("user://scroll_command.txt"):
		var value: String = FileAccess.get_file_as_string("user://scroll_command.txt").strip_edges()
		if value != command: open_page(value)
	if not is_instance_valid(page): return
	var rect: Rect2 = page.get_global_rect()
	var transform: Transform2D = get_viewport().get_screen_transform()
	var points: Dictionary = {}
	for key: String in ["margin", "text", "card"]:
		var ratio: Vector2 = {"margin":Vector2(.02,.5),"text":Vector2(.5,.08),"card":Vector2(.25,.55)}[key]
		var start: Vector2 = rect.position + rect.size * ratio
		var a: Vector2 = transform * start
		var b: Vector2 = transform * (start - Vector2(0,140))
		points[key] = [[a.x,a.y],[b.x,b.y]]
	var outside: Vector2 = transform * Vector2(20,160)
	var outside_end: Vector2 = transform * Vector2(20,20)
	points.outside = [[outside.x,outside.y],[outside_end.x,outside_end.y]]
	var data: Dictionary = {"command":command,"scroll":scroll.scroll_vertical,"max":scroll.get_v_scroll_bar().max_value-scroll.get_v_scroll_bar().page,"points":points}
	if page is DraftPanel:
		data.picked = picked; data.resolved = resolved
		data.card_heights = []; data.all_cards_visible = true; data.card_taps = []
		for card: Button in page.cards:
			data.card_heights.append(card.size.y)
			data.all_cards_visible = data.all_cards_visible and scroll.get_global_rect().encloses(card.get_global_rect())
			var point: Vector2 = transform * card.get_global_rect().get_center()
			data.card_taps.append([point.x,point.y])
		for child: Node in page.column.get_children():
			if child is Button and child.text == tr("M3_BACK_DRAFT"):
				var point: Vector2 = transform * child.get_global_rect().get_center()
				data.back = [point.x,point.y]
		data.detail_open = page.cards.is_empty()
		if not page.info_buttons.is_empty():
			var point: Vector2 = transform * page.info_buttons[0].get_global_rect().get_center()
			data.tap = [point.x,point.y]
	if page is RadioSettingsPanel:
		data.toggled = page.toggles.reduced_flash.button_pressed
		var point: Vector2 = transform * page.toggles.reduced_flash.get_global_rect().get_center()
		data.tap = [point.x,point.y]
	if page is ArsenalPicker:
		data.popup = page.selectors[0].get_popup().visible
		var point: Vector2 = transform * page.selectors[0].get_global_rect().get_center()
		data.tap = [point.x,point.y]
	if page is PatchboardPanel and page.desk.visible:
		data.level = page.session.patchboard.mixer.levels[0]
		var point: Vector2 = transform * page.desk.faders[0].get_global_rect().get_center()
		var end: Vector2 = transform * (page.desk.faders[0].get_global_rect().position + Vector2(40,20))
		data.fader = [[point.x,point.y],[end.x,end.y]]
	FileAccess.open("user://scroll_telemetry.json",FileAccess.WRITE).store_string(JSON.stringify(data))
