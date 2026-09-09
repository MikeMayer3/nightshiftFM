extends SceneTree
## Native rendered UI interactions plus explicitly staged encounter art coverage.
const BOOT: PackedScene = preload("res://scenes/boot/boot.tscn")
var checks: TestContext = TestContext.new()
func _initialize() -> void: run.call_deferred()
func click(button: BaseButton) -> void:
	var ancestor: Node = button.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(button)
		ancestor = ancestor.get_parent()
	await process_frame; await process_frame
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT; event.position = button.get_global_rect().get_center(); event.pressed = pressed
		root.push_input(event, true)
		await process_frame
func capture(name: String) -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M8-M10/" + name + ".png")
func matching(parent: Node, key: String, value: Variant) -> Button:
	for child: Node in parent.find_children("*", "Button", true, false):
		if child.has_meta(key) and child.get_meta(key) == value: return child
	return null
func widths(parent: Node) -> bool:
	if parent is Control and parent.is_visible_in_tree():
		var rect: Rect2 = parent.get_global_rect()
		if rect.position.x < -1 or rect.end.x > root.get_visible_rect().size.x + 1: return false
	for child: Node in parent.get_children():
		if not widths(child): return false
	return true
func run() -> void:
	root.content_scale_size = Vector2i(720, 1280)
	for dimensions: Vector2i in [Vector2i(360,640), Vector2i(450,950), Vector2i(1024,768)]:
		root.size = dimensions
		RadioPreferences.current.values = RadioPreferences.DEFAULTS.duplicate()
		RadioPreferences.current.values.large_text = true
		var profile: MissionProfile = load("res://tests/integration/test_campaign_screen.gd").new().profile_at(12)
		var path: String = "user://broadcast_visual.json"
		MissionStore.new(path).save(profile, {})
		var boot: BootScreen = BOOT.instantiate(); boot.save_path = path; root.add_child(boot)
		await process_frame
		await click(boot.menu.get_node("Start"))
		boot.campaign_panel.show_modes(); await process_frame
		await click(matching(boot.campaign_panel, "broadcast_mode", "contract"))
		await click(matching(boot.campaign_panel, "broadcast_contract", "bare_antenna"))
		checks.check(boot.campaign_panel.rules.contract == "bare_antenna", "native click selects restricted contract")
		await capture("modes-%s" % dimensions)
		checks.check(widths(boot.campaign_panel), "mode controls fit %s" % dimensions)
		boot.campaign_panel.show_home(); await process_frame
		await click(boot.campaign_panel.launch_button)
		checks.check(boot.picker.broadcast_context.contract == "bare_antenna", "contract reaches equipment")
		checks.check(widths(boot.picker), "restricted setup fits %s" % dimensions)
		await click(boot.picker.launch_button)
		var screen: CombatScreen = boot.combat
		checks.check(screen.session.draft.support_count() == 0, "bare antenna starts without support")
		await capture("patchboard-%s" % dimensions)
		checks.check(widths(screen.patchboard_panel), "compact patchboard fits %s" % dimensions)
		await click(screen.patchboard_panel.launch_button)
		await click(screen.pause_button)
		checks.check(screen.session.paused, "native pause works on restricted loadout")
		await click(screen.resume_button)
		checks.check(not screen.session.paused, "native resume works on restricted loadout")
		# Staged art gallery: same production renderer, no fabricated playthrough claim.
		screen.session.checkpoint_changed.disconnect(screen._save_checkpoint)
		screen.session.actors.clear(); screen.set_process(false)
		screen.session.phase = CombatSession.Phase.COMBAT
		screen.session.campaign.mission = 12
		for index: int in BroadcastContent.ENEMIES.size():
			var actor: CombatActor = screen.session.spawn_enemy(BroadcastContent.ENEMIES[index], 130 + (index % 3) * 190)
			actor.position.y = 105 + (index / 3) * 170
			actor.ability_time = actor.ability_interval - .5
			actor.age = 7
			checks.check(RadioArt.enemy(actor, 2) == RadioArt.ROLES[actor.role], "expanded role has its own silhouette")
		await capture("device-tells-%s" % dimensions)
		checks.check(widths(screen), "encounter screen fits %s" % dimensions)
		boot.show_page(BootScreen.Page.CAMPAIGN)
		await process_frame
		boot.campaign_panel.show_modes(); await process_frame
		await click(matching(boot.campaign_panel, "broadcast_mode", "endless"))
		boot.campaign_panel.show_home(); await process_frame
		await click(boot.campaign_panel.launch_button)
		await click(boot.picker.launch_button)
		screen = boot.combat
		checks.check(screen.session.signal_progress is BroadcastProgress and screen.finish_button.disabled, "Endless starts with banking disabled until a cleared wave")
		await click(screen.patchboard_panel.launch_button)
		for step: int in 1000:
			if screen.session.achievement_run.cleared_waves >= 1: break
			if screen.session.is_deciding(): screen.session.choose_upgrade(screen.session.draft.offers[0])
			else: screen.session.advance(.5)
		await process_frame
		await click(screen.pause_button)
		checks.check(not screen.finish_button.disabled, "cleared wave enables Endless banking")
		await capture("endless-bank-%s" % dimensions)
		await click(screen.finish_button)
		checks.check(MissionStore.new(path).load_save().profile.broadcast.best_scores.get("endless:best:0", 0) == 1000, "native bank control commits one finished wave")
		boot.queue_free(); await process_frame
	print("RESULT: %d broadcast visual checks; %d failures" % [checks.checks, checks.failures])
	quit(0 if checks.failures == 0 else 1)
