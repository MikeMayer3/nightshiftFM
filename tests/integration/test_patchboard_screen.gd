extends RefCounted
func run(t: TestContext, tree: SceneTree) -> bool:
	var path: String = "user://m6_screen_test.json"
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(path + suffix)
	var screen: CombatScreen = create_screen(path)
	tree.root.add_child(screen)
	await tree.process_frame
	await tree.process_frame
	screen.set_process(false)
	t.check(screen.session.is_wiring() and screen.patchboard_panel.visible and not screen.save_failed, "new M6 screen opens durable patchboard tutorial")
	t.check(screen.patchboard_panel.recipe_buttons.size() == 8, "tutorial reveals all eight recipe previews")
	var button: Button = screen.patchboard_panel.recipe_buttons[&"feedback_loop"]
	t.check(not button.disabled, "starting Arc can connect shield-break recipe")
	button.pressed.emit()
	t.check(screen.session.patchboard.slots[0] == &"feedback_loop" and not screen.save_failed, "connecting via UI persists slot immediately")
	screen.toggle_pause()
	t.check(not screen.patchboard_panel.visible and screen.overlay.visible, "pause overlay owns input during wiring")
	screen.toggle_pause()
	t.check(screen.patchboard_panel.visible, "resume returns to unchanged wiring")
	var saved: Dictionary = screen.store.load_save()
	t.check(saved.run.patchboard.slots[0] == "feedback_loop", "actual disk envelope contains selected recipe")
	screen.queue_free()
	await tree.process_frame
	screen = create_screen(path)
	screen.resume_existing = true
	tree.root.add_child(screen)
	await tree.process_frame
	screen.set_process(false)
	t.check(screen.session.is_wiring() and screen.session.patchboard.slots[0] == &"feedback_loop", "Continue restores interactive wiring and selected connection")
	screen.patchboard_panel.launch_button.pressed.emit()
	screen.session.advance(2.2)
	screen._refresh()
	t.check(screen.session.phase == CombatSession.Phase.COMBAT and not screen.patchboard_panel.visible, "Go live starts next wave and removes wiring input")
	# An actual break records discovery, commits at next checkpoint, and survives a fresh run.
	screen.session.run.shield.current = 1
	screen.session.hit_station(2, &"M2_SWARMER_NAME")
	screen._save_checkpoint()
	t.check(&"feedback_loop" in screen.profile.discovered and not screen.save_failed, "actual shield break persists discovered recipe")
	screen.restart()
	t.check(screen.session.patchboard.slots == [&"", &""] and &"feedback_loop" in screen.profile.discovered, "Restart clears connections and preserves discovery")
	# Corrupt primary uses the last valid backup, including the M6 runtime.
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string('{"schema":')
	file.close()
	var recovered: Dictionary = screen.store.load_save()
	t.check(not recovered.is_empty() and screen.store.recovered, "truncated M6 save recovers validated backup")
	screen.queue_free()
	await tree.process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(path + suffix)
	return true

func create_screen(path: String) -> CombatScreen:
	var screen: CombatScreen = (load("res://scenes/combat/combat.tscn") as PackedScene).instantiate() as CombatScreen
	screen.m3_enabled = true
	screen.arsenal_enabled = true
	screen.patchboard_enabled = true
	screen.store = MissionStore.new(path)
	return screen
