extends RefCounted
const SCENE: PackedScene = preload("res://scenes/combat/combat.tscn")
func run(context: TestContext, tree: SceneTree) -> bool:
	var screen: CombatScreen = SCENE.instantiate() as CombatScreen
	screen.m3_enabled = true
	screen.m4_enabled = true
	screen.store = MissionStore.new("user://test_m4_screen.json")
	tree.root.add_child(screen)
	await tree.process_frame
	context.check(screen.session.supports != null and screen.profile.unlocked.has(&"static_net"), "new M4 screen enables real roster")
	screen.session.advance(90)
	context.check(screen.session.phase == CombatSession.Phase.DRAFT, "M4 first wave reaches compact draft")
	for i: int in 3: screen.session.choose_upgrade(screen.session.draft.offers[0])
	context.check(screen.session.phase == CombatSession.Phase.RECRUIT, "M4 recruitment opens after first three picks")
	var recruits: Array[Button] = []
	for node: Node in screen.draft_panel.column.get_children():
		if node is Button and node.icon != null: recruits.append(node)
	context.check(recruits.size() == 2, "only Bass and Net are offered as new supports")
	recruits[0].pressed.emit()
	context.check(screen.session.draft.track(&"bass_driver") != null and screen.session.draft.support_count() == 2, "actual recruitment button equips Bass once")
	var saved: Dictionary = screen.store.load_save().run
	var restored: CombatSession = CombatSession.new()
	context.check(restored.restore_checkpoint(saved) and restored.draft.track(&"bass_driver").rank() == 1, "recruited support survives actual disk save")
	# Dedicated M4 draft with rank-3 branch; all mutations use real selection paths.
	screen.session.start_m4(4, &"run.1")
	screen.session.advance(90)
	while screen.session.draft.track(&"arc_aerial").rank() < 2:
		for id: StringName in screen.session.draft.offers:
			if String(id).begins_with("arc_aerial."):
				screen.session.choose_upgrade(id)
				break
	var branch: StringName = &""
	for id: StringName in screen.session.draft.offers:
		if String(id).begins_with("arc_aerial."): branch = id
	var before_count: int = screen.session.draft.normal_count
	var before_tokens: int = screen.session.draft.rerolls
	var alternative: StringName = &"arc_aerial.tap" if branch == &"arc_aerial.storm" else &"arc_aerial.storm"
	context.check(screen.session.swap_branch(alternative) and screen.session.draft.normal_count == before_count and screen.session.draft.rerolls == before_tokens, "branch comparison changes offer without buying or spending reroll")
	var checkpoint: Dictionary = screen.store.load_save().run
	context.check(restored.restore_checkpoint(checkpoint) and alternative in restored.draft.offers, "compared branch persists on recovery")
	context.check(not screen.session.swap_branch(&"bass_driver.wide"), "cannot swap an unequipped support branch")
	screen.session.supports.report.add(&"static_net", &"slow_seconds", 2.5)
	screen.session.phase = CombatSession.Phase.DEFEAT
	screen.session.hull = 0
	screen._refresh()
	screen.report_button.pressed.emit()
	await tree.process_frame
	context.check(screen.report_open and screen.draft_panel.visible and not screen.overlay.visible, "results contribution report opens as its own scrollable page")
	(screen.draft_panel.column.get_child(screen.draft_panel.column.get_child_count() - 1) as Button).pressed.emit()
	context.check(not screen.report_open and screen.overlay.visible, "contribution report returns to results")
	screen.queue_free()
	await tree.process_frame
	return true
