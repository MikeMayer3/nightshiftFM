extends SceneTree
const BOOT: PackedScene = preload("res://scenes/boot/boot.tscn")
const FIXTURE: Script = preload("res://tests/unit/test_achievements.gd")
var checks: TestContext = TestContext.new()
var boot: BootScreen
func _initialize() -> void: _run.call_deferred()
func click(button: BaseButton) -> void:
	var ancestor: Node = button.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(button)
		ancestor = ancestor.get_parent()
	await process_frame
	await process_frame
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
func button_text(text: String) -> Button:
	for node: Node in boot.campaign_panel.find_children("*", "Button", true, false):
		if node.text == text: return node
	return null
func goal(id: StringName) -> Button:
	for node: Node in boot.campaign_panel.find_children("*", "Button", true, false):
		if node.get_meta("achievement_id", &"") == id: return node
	return null
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M9/" + name + ".png")
func _run() -> void:
	var path: String = "user://m9_visual_fixture.json"
	for size: Vector2i in [Vector2i(360, 640), Vector2i(450, 800), Vector2i(450, 950)]:
		root.size = size
		MissionStore.new(path).save(MissionProfile.new(), {})
		boot = BOOT.instantiate() as BootScreen
		boot.save_path = path
		root.add_child(boot)
		await process_frame
		await click(boot.menu.get_node("Start"))
		await click(button_text(TranslationServer.translate("M9_ACHIEVEMENTS")))
		await capture("achievements-%dx%d" % [size.x, size.y])
		var panel: CampaignPanel = boot.campaign_panel
		var scroll: ScrollContainer = panel.column.get_parent()
		checks.check(panel.column.size.x <= scroll.size.x + 1, "achievement catalog has no horizontal overflow at %s" % size)
		checks.check(goal(&"endless_60") == null and goal(&"first_broadcast") != null, "pending achievement has no action; available achievement can be tracked")
		for id: StringName in [&"first_broadcast", &"arc_aerial_first_capstone", &"arc_aerial_three_capstones"]:
			await click(goal(id))
			checks.check(panel.profile.achievements.tracked.has(id), "viewport click tracks " + String(id))
		checks.check(goal(&"echo_deck_first_capstone").disabled, "fourth track action visibly disabled")
		var saved: MissionProfile = MissionProfile.new()
		checks.check(saved.restore(MissionStore.new(path).load_save().profile) and saved.achievements.tracked.size() == 3, "three tracked goals persisted from actual UI clicks")
		await click(goal(&"first_broadcast"))
		checks.check(panel.profile.achievements.tracked.size() == 2 and not goal(&"echo_deck_first_capstone").disabled, "untracking frees a goal slot")
		# Labeled fixture supplies an earned title solely to exercise its UI.
		panel.profile.achievements = FIXTURE.new().fixture(&"first_broadcast", true)
		panel.show_achievements()
		await process_frame
		await click(goal(&"first_broadcast"))
		checks.check(panel.profile.achievements.title == &"first_broadcast", "earned fixture title selected through viewport input")
		await capture("title-fixture-%dx%d" % [size.x, size.y])
		checks.check(saved.restore(MissionStore.new(path).load_save().profile) and saved.achievements.title == &"first_broadcast", "cosmetic title persists in atomic profile")
		await click(panel.launch_button)
		await click(boot.picker.launch_button)
		boot.combat.set_process(false)
		checks.check(boot.combat.session.hull == 100 and boot.combat.session.run.shield.capacity == 65 and boot.combat.session.draft.track(&"main").rank() == 1, "cosmetic title cannot alter starting combat power")
		boot.combat.session.phase = CombatSession.Phase.DEFEAT
		boot.combat.session.hull = 0
		boot.combat._refresh()
		await click(boot.combat.report_button)
		await capture("report-fixture-%dx%d" % [size.x, size.y])
		checks.check(boot.combat.draft_panel.visible, "post-run report opens through viewport input")
		boot.queue_free()
		await process_frame
	print("RESULT: %d visual checks; %d failures" % [checks.checks, checks.failures])
	quit(0 if checks.failures == 0 else 1)
