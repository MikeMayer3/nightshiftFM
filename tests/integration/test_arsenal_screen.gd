extends RefCounted
func run(t: TestContext, tree: SceneTree) -> bool:
	var path: String = "user://arsenal_screen_test.json"
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(path + suffix)
	var store: MissionStore = MissionStore.new(path)
	var old: CombatSession = CombatSession.new()
	old.start_active(42, &"run.1")
	var profile: MissionProfile = MissionProfile.new()
	profile.enable_m4()
	profile.next_run = 2
	t.check(store.save(profile, old.to_checkpoint()) == OK, "legacy fixture saved")
	var screen: CombatScreen = (load("res://scenes/combat/combat.tscn") as PackedScene).instantiate() as CombatScreen
	screen.m3_enabled = true
	screen.active_enabled = true
	screen.arsenal_enabled = true
	screen.resume_existing = true
	screen.store = store
	tree.root.add_child(screen)
	await tree.process_frame
	t.check(screen.session.arsenal == null and not screen.shield_button.visible, "legacy Continue retains original controls and combat")
	screen.restart()
	t.check(screen.session.arsenal != null and screen.shield_button.visible and not screen.save_failed, "restarting legacy mission exposes the M5 shield control")
	screen.session.start_arsenal(43, &"run.2", {"main": "sweep", "shield": "relay", "support": "reverb_well"})
	screen._save_checkpoint()
	screen.queue_free()
	await tree.process_frame
	var resumed: CombatScreen = (load("res://scenes/combat/combat.tscn") as PackedScene).instantiate() as CombatScreen
	resumed.m3_enabled = true
	resumed.arsenal_enabled = true
	resumed.resume_existing = true
	resumed.store = store
	tree.root.add_child(resumed)
	await tree.process_frame
	t.check(resumed.loadout == {"main": "sweep", "shield": "relay", "support": "reverb_well"}, "Continue restores the selected arsenal")
	resumed.restart()
	t.check((resumed.session.draft as ArsenalDraft).loadout == resumed.loadout and resumed.session.run.main_weapon.rank == 1, "Restart keeps the selected chassis and resets rank")
	resumed.session.draft.begin()
	resumed.draft_panel.show_draft(resumed.session)
	var correct_caption: bool = false
	for node: Node in resumed.draft_panel.find_children("*", "Label", true, false):
		if (node as Label).text == TranslationServer.translate(ArsenalContent.DEFINITIONS["sweep"].name_key): correct_caption = true
	t.check(correct_caption, "draft caption names the selected main chassis")
	resumed.queue_free()
	await tree.process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(path + suffix)
	return true
