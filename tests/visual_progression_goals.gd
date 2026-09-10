extends SceneTree
const DIR: String = "res://docs/evidence/P6-goals/"
const CAMPAIGN = preload("res://tests/integration/test_campaign_screen.gd")
var t: TestContext = TestContext.new()
func _initialize() -> void: run.call_deferred()
func settle() -> void:
	await process_frame; await process_frame; await process_frame; await RenderingServer.frame_post_draw
func capture(name: String) -> void:
	await settle()
	root.get_texture().get_image().save_png(DIR + name + ".png")
func check_cards(node: Node) -> void:
	if node is ProgressionCard:
		var card: ProgressionCard = node
		t.check(card.get_global_rect().position.x >= 0 and card.get_global_rect().end.x <= root.get_visible_rect().size.x + 1, "reward card fits viewport width")
		t.check(card.title_label.get_line_count() == card.title_label.get_visible_line_count() and card.requirement_label.get_line_count() == card.requirement_label.get_visible_line_count(), "large reward title and requirement have no hidden lines")
	for child: Node in node.get_children(): check_cards(child)
func tap(button: Button) -> void:
	await settle()
	t.check(root.get_visible_rect().encloses(button.get_global_rect()), "sticky action is fully visible")
	var point: Vector2 = button.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		root.push_input(event, true); await process_frame
	await settle()
func run() -> void:
	for dimensions: Vector2i in [Vector2i(360,640), Vector2i(450,1000), Vector2i(1024,768)]:
		root.size = dimensions; root.content_scale_size = Vector2i(720,1280)
		RadioPreferences.current.values.large_text = true
		RadioPreferences.current.coach_seen.assign(RadioPreferences.COACH_IDS)
		var profile: MissionProfile = CAMPAIGN.new().profile_at(1)
		profile.achievements.track(&"first_broadcast")
		profile.achievements.track(&"endless_three")
		profile.achievements.track(&"arc_aerial_three_capstones")
		var path: String = "user://p6_native_%d.json" % Time.get_ticks_usec()
		t.check(MissionStore.new(path).save(profile, {}) == OK, "save isolated near-unlock fixture")
		var boot: BootScreen = preload("res://scenes/boot/boot.tscn").instantiate()
		boot.save_path = path; root.add_child(boot)
		boot.show_page(BootScreen.Page.CAMPAIGN)
		var panel: CampaignPanel = boot.campaign_panel
		await capture("route-%dx%d" % [dimensions.x, dimensions.y]); check_cards(panel)
		panel.show_rewards(); await settle(); check_cards(panel)
		await capture("hardware-%dx%d" % [dimensions.x, dimensions.y])
		panel.show_home(); panel.launch_button.pressed.emit(); boot.picker.launch_button.pressed.emit()
		var screen: CombatScreen = boot.combat
		screen.set_process(false); screen.arena.set_process(false)
		# Labeled result-layout fixture: actual finish/commit/save path, synthetic victory.
		screen.session.wave = 10
		screen.session.achievement_run.cleared_waves = 10
		screen.session._finish(true); screen._refresh()
		t.check(not screen.save_failed and MissionStore.valid(screen.store.load_save()), "result and rewards save together in production envelope")
		t.check(screen.result_goals.get_child_count() == 5, "result has one earned hardware card plus next and three tracked goals")
		await capture("results-%dx%d" % [dimensions.x, dimensions.y]); check_cards(screen.result_goals)
		var snapshot: Dictionary = screen.profile.to_data()
		for frame: int in 10: screen._refresh(); screen._save_checkpoint()
		t.check(screen.profile.to_data() == snapshot and screen.result_goals.get_child_count() == 5, "repeated results neither duplicate cards nor rewards")
		boot.show_page(BootScreen.Page.MENU); boot.continue_button.pressed.emit()
		screen = boot.combat; screen.set_process(false); screen.arena.set_process(false)
		screen._refresh(); await settle()
		t.check(not screen.save_failed and not screen.recovery_required and screen.session.is_finished(), "Continue reopens validated finished run")
		t.check(JSON.parse_string(JSON.stringify(screen.profile.to_data())) == JSON.parse_string(JSON.stringify(snapshot)) and screen.result_goals.get_child_count() == 4, "Continue preserves rewards without announcing already-earned hardware again")
		var scroll: ScrollContainer = screen.result_goals.get_parent().get_parent() as ScrollContainer
		t.check(screen.overlay.get_global_rect().end.y <= screen.size.y, "result sheet stays inside small phone")
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value); await capture("result-actions-%dx%d" % [dimensions.x, dimensions.y])
		await tap(screen.restart_button)
		t.check(not screen.session.is_finished() and not screen.result_goals.visible and screen.result_goals.get_child_count() == 0, "real pointer retry clears result cards and starts fresh run")
		t.check(screen.session.draft.track(&"main").rank() == 1, "reward presentation grants no inherited combat power")
		# Reward availability and next goal survive reopening the actual saved profile.
		boot.show_page(BootScreen.Page.CAMPAIGN)
		t.check(boot.campaign_panel.profile.campaign.cleared == 2 and ProgressionGoals.next(boot.campaign_panel.profile).target == 3, "route reload shows committed progression and next reward")
		boot.queue_free(); await process_frame
	FileAccess.open(DIR + "native.json", FileAccess.WRITE).store_string(JSON.stringify({"checks":t.checks,"failures":t.failures,"scope":"Desktop native renderer; isolated synthetic victory through real finish/save path; pointer retry, three window sizes, large text. Human comprehension NOT RUN."}, "\t"))
	print("RESULT: %d P6 native checks; %d failures" % [t.checks,t.failures])
	quit(0 if t.failures == 0 else 1)
