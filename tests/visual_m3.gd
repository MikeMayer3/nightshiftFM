extends SceneTree
## Desktop rendered evidence with isolated save. --interactive leaves the draft open.
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var evidence: String = "res://docs/evidence/M3.2/" if "--revision-m3-2" in OS.get_cmdline_user_args() else "res://docs/evidence/M3/"
	var scene: PackedScene = load("res://scenes/combat/combat.tscn") as PackedScene
	var screen: CombatScreen = scene.instantiate() as CombatScreen
	screen.m3_enabled = true
	screen.store = MissionStore.new("user://m3_visual_fixture.json")
	root.add_child(screen)
	await process_frame
	screen.session.advance(90)
	screen._refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence + "desktop-draft.png")
	if "--interactive" in OS.get_cmdline_user_args(): return
	screen.draft_panel.info_buttons[0].pressed.emit()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence + "desktop-details.png")
	screen.draft_panel.show_draft(screen.session)
	await process_frame
	var scroll: ScrollContainer = screen.draft_panel.column.get_parent() as ScrollContainer
	scroll.scroll_vertical = 600
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence + "desktop-draft-scrolled.png")
	root.size = Vector2i(360, 640)
	scroll.scroll_vertical = 0
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence + "desktop-small-draft.png")
	for index: int in 3: screen.session.choose_upgrade(screen.session.draft.offers[0])
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence + "desktop-recruit.png")
	screen.session.recruit(&"", screen.profile.unlocked)
	screen.session.choose_upgrade(screen.session.draft.offers[0])
	screen.session.advance(7)
	screen.session.paused = true
	screen.set_process(false)
	screen.draft_panel.hide()
	screen.overlay.hide()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence + "desktop-combat.png")
	print("PASS: M3 desktop draft, scroll, 360x640 draft, recruitment, combat rendered")
	quit()
