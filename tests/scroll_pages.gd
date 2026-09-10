extends RefCounted
## Production pages, real viewport events, deliberately isolated progress fixtures.
var tree: SceneTree
var t: TestContext
var input: RefCounted
var rows: Array[Dictionary] = []
var baseline: bool = false
func settle() -> void:
	for frame: int in 3: await tree.process_frame
func inspect_page(page: Control, label: String) -> void:
	RadioPreferences.current.apply_fonts(page)
	await settle()
	var scroll: ScrollContainer = page.find_children("*", "ScrollContainer", true, false)[0]
	var handlers: Array[Node] = page.get_children().filter(func(n: Node) -> bool: return n is PageScroll)
	if baseline:
		for handler: Node in handlers: handler.free()
	var max_scroll: float = scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page
	var initial_failures: int = t.failures
	var rect: Rect2 = page.get_global_rect()
	var tested: int = 0
	var positions: Array[Vector2] = [Vector2(.01,.5), Vector2(.99,.5), Vector2(.5,.01), Vector2(.5,.99), Vector2(.25,.3), Vector2(.75,.3), Vector2(.25,.55), Vector2(.75,.55), Vector2(.25,.8), Vector2(.75,.8)]
	if rect.size.y < tree.root.get_visible_rect().size.y - 10:
		positions.append((Vector2(20,160) - rect.position) / rect.size)
	for mode: String in ["mouse", "touch"]:
		# Both side gutters, top/bottom margins, headers, cards and action areas.
		for fraction: Vector2 in positions:
			if not baseline:
				for handler: Node in handlers: handler._cancel()
			scroll.scroll_vertical = 0; await settle()
			var point: Vector2 = rect.position + rect.size * fraction
			input.motion(point, Vector2.ZERO)
			var target: Control = tree.root.gui_get_hovered_control()
			var interactive_drag: bool = false
			var ancestor: Node = target
			while ancestor != null and ancestor != page:
				if ancestor is Slider or ancestor is ScrollBar: interactive_drag = true
				ancestor = ancestor.get_parent()
			if interactive_drag: continue
			if mode == "mouse": input.mouse(point, true); input.motion(point - Vector2(0, 140), Vector2(0, -140)); input.mouse(point - Vector2(0, 140), false)
			else: input.touch(point, true); input.drag(point - Vector2(0, 140)); input.touch(point - Vector2(0, 140), false)
			var expected: int = mini(130, floori(max_scroll))
			t.check(scroll.scroll_vertical >= expected, "%s %s drag at %s (%s) scrolls %d/%d" % [label, mode, fraction, target.get_class() if target != null else "empty", scroll.scroll_vertical, expected])
			tested += 1
			if not baseline:
				for handler: Node in handlers: handler._cancel()
	rows.append({"page":label,"viewport":str(tree.root.size),"positions":tested,"max_scroll":max_scroll,"failures":t.failures-initial_failures})
func run(context: TestContext, scene_tree: SceneTree) -> bool:
	t = context; tree = scene_tree; input = preload("res://tests/integration/test_page_scroll.gd").new(); input.tree = tree
	baseline = "--scroll-baseline" in OS.get_cmdline_user_args()
	RadioPreferences.current.values.large_text = true
	RadioPreferences.current.values.sound = false
	RadioPreferences.current.values.music = false
	for dimensions: Vector2i in [Vector2i(360,640), Vector2i(450,1000)]:
		tree.root.size = dimensions; tree.root.content_scale_size = Vector2i(720,1280)
		var profile: MissionProfile = preload("res://tests/integration/test_campaign_screen.gd").new().profile_at(12)
		var panel: CampaignPanel = CampaignPanel.new(); panel.profile = profile; tree.root.add_child(panel)
		for method: String in ["show_home","show_rewards","show_achievements","show_codex","show_records","show_modes","show_enemies","show_logs"]:
			panel.call(method); await inspect_page(panel, "campaign/" + method)
			if baseline:
				panel.queue_free(); await settle(); return true
		panel.queue_free(); await settle()
		var picker: ArsenalPicker = ArsenalPicker.new(); picker.campaign_profile = profile.campaign; tree.root.add_child(picker)
		picker.modules_body.show(); picker.details_body.show()
		await inspect_page(picker,"equipment/modules"); picker.queue_free(); await settle()
		var settings: RadioSettingsPanel = RadioSettingsPanel.new(); tree.root.add_child(settings)
		settings.find_child("ReplayHints",true,false).get_parent().show()
		await inspect_page(settings,"settings/help"); settings.queue_free(); await settle()
		var session: CombatSession = CombatSession.new()
		session.start_campaign(42,&"run.99",{"main":"pulse","shield":"capacitor","support":"needle_swarm"},{"mission":1,"cleared":12,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
		session.advance(.1); session.draft.track(&"needle_swarm").accept(&"m5.needle_swarm.t0",[])
		session.phase = CombatSession.Phase.DRAFT
		session.draft.offers.assign([&"m5.needle_swarm.b3",&"recruit.echo_deck",&"m5.pulse.t0"])
		var draft: DraftPanel = DraftPanel.new(); tree.root.add_child(draft); draft.show_draft(session)
		await inspect_page(draft,"draft/choices")
		draft.info_buttons[0].pressed.emit(); await inspect_page(draft,"draft/details")
		draft.show_report(session,func() -> void: pass); await inspect_page(draft,"draft/report")
		draft.show_recruit(session); await inspect_page(draft,"draft/recruit")
		draft.show_recovery("Save recovery details. ".repeat(50),func() -> void: pass,func() -> void: pass); await inspect_page(draft,"draft/recovery")
		draft.queue_free(); await settle()
		var patch: PatchboardPanel = PatchboardPanel.new(); tree.root.add_child(patch); patch.show_unavailable = true; patch.open(session,profile)
		await inspect_page(patch,"patchboard/connections")
		patch.open(session,profile,true); await inspect_page(patch,"mixer/faders")
		patch.connection_toggle.pressed.emit(); await inspect_page(patch,"mixer/connections")
		patch.queue_free(); await settle()
		var screen: CombatScreen = preload("res://scenes/combat/combat.tscn").instantiate()
		screen.campaign_enabled = true; screen.active_enabled = true; screen.arsenal_enabled = true; screen.m3_enabled = true
		screen.store = MissionStore.new("user://scroll_result_%d.json"%Time.get_ticks_usec()); tree.root.add_child(screen)
		screen.set_process(false); screen.arena.set_process(false)
		screen.profile.achievements.track(&"first_broadcast"); screen.profile.achievements.track(&"endless_three"); screen.profile.achievements.track(&"arc_aerial_three_capstones")
		screen.session.wave=10; screen.session.achievement_run.cleared_waves=10; screen.session._finish(true); screen._refresh()
		await inspect_page(screen.overlay,"results/rewards")
		screen.queue_free(); await settle()
	return true
