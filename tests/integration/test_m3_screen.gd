extends RefCounted
const SCENE: PackedScene = preload("res://scenes/combat/combat.tscn")
func run(context: TestContext, tree: SceneTree) -> bool:
	var path: String = "user://test_m3_ui.json"
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(path + suffix)
	var screen: CombatScreen = SCENE.instantiate() as CombatScreen
	screen.m3_enabled = true
	screen.store = MissionStore.new(path)
	tree.root.add_child(screen)
	await tree.process_frame
	context.check(not screen.save_failed and not screen.recovery_required and screen.session.draft != null, "M3 screen starts with durable rank-1 checkpoint")
	screen.session.advance(90)
	await tree.process_frame
	context.check(screen.session.phase == CombatSession.Phase.DRAFT and screen.draft_panel.visible and screen.draft_panel.cards.size() == 3, "wave completion shows three real selectable cards")
	context.check(screen.draft_panel.cards.all(func(button: Button) -> bool: return button.mouse_filter == Control.MOUSE_FILTER_PASS), "card actions propagate touch drags to the scroll container")
	context.check(screen.draft_panel.heading.text == "Choose an upgrade" and not "27" in screen.draft_panel.heading.text, "draft headline describes the choice without a mission-wide counter")
	var pending_offers: Array[StringName] = screen.session.draft.offers.duplicate()
	screen.draft_panel.info_buttons[0].pressed.emit()
	context.check(screen.session.draft.normal_count == 0 and screen.session.draft.offers == pending_offers, "opening optional details never purchases or changes an offer")
	screen.draft_panel.show_draft(screen.session)
	screen.draft_panel.banish_button.pressed.emit()
	context.check(screen.draft_panel.banish_mode and screen.session.draft.banishes == 1, "banish toolbar enters explicit mode without spending a token")
	screen.draft_panel.banish_button.pressed.emit()
	context.check(not screen.draft_panel.banish_mode and screen.session.draft.offers == pending_offers, "cancel banish returns to the same choices")
	await tree.process_frame
	await tree.process_frame
	var scroll: ScrollContainer = screen.draft_panel.column.get_parent() as ScrollContainer
	context.check(screen.draft_panel.cards[-1].get_global_rect().end.y <= scroll.get_global_rect().end.y, "all three compact cards fit in the initial viewport")
	context.check(screen.draft_panel.cards.all(func(card: Button) -> bool: return card.get_global_rect().end.x <= scroll.get_global_rect().end.x), "compact cards stay within horizontal viewport bounds")
	context.check(screen.draft_panel.cards.all(func(card: Button) -> bool: return (card.get_child(0) as Control).get_combined_minimum_size().y <= card.size.y), "card contents fit inside their touch targets without vertical text collapse")
	var snapshot: Dictionary = screen.store.load_save()
	var offers: Array[StringName] = screen.session.draft.offers.duplicate()
	screen.queue_free()
	await tree.process_frame
	screen = SCENE.instantiate() as CombatScreen
	screen.m3_enabled = true
	screen.resume_existing = true
	screen.store = MissionStore.new(path)
	tree.root.add_child(screen)
	await tree.process_frame
	context.check(screen.session.draft.offers == offers and screen.draft_panel.visible, "fresh screen Continue restores same offer IDs")
	screen.draft_panel.cards[0].pressed.emit()
	await tree.process_frame
	context.check(screen.session.draft.normal_count == 1 and not screen.save_failed and screen.store.load_save().run.draft.normal_count == 1, "card button accepts and durably saves exactly one choice")
	var elapsed: float = screen.session.elapsed
	screen._process(100)
	context.check(screen.session.elapsed == elapsed, "draft screen freezes all combat time")
	screen.toggle_pause()
	var count: int = screen.session.draft.normal_count
	screen.session.choose_upgrade(screen.session.draft.offers[0])
	context.check(screen.session.draft.normal_count == count and screen.overlay.visible, "paused draft cannot accept hidden choices")
	screen.toggle_pause()
	context.check(screen.draft_panel.visible and not screen.session.paused, "resume returns to existing draft")
	# Save failure must freeze and retry the same checkpoint, never a partial wave.
	screen.store.path = "user://missing_m3_directory/ui.json"
	screen.draft_panel.cards[0].pressed.emit()
	context.check(screen.save_failed and screen.session.paused and screen.draft_panel.visible, "write failure freezes at explicit recovery screen")
	screen.store.path = path
	screen._retry_save()
	context.check(not screen.save_failed and not screen.session.paused and screen.session.draft.normal_count == 2, "retry saves the accepted choice without applying it twice")
	# Complete the remaining decisions and verify the separately scheduled arsenal UI.
	screen.draft_panel.cards[0].pressed.emit()
	context.check(screen.session.phase == CombatSession.Phase.RECRUIT and screen.draft_panel.visible, "third normal pick opens separate recruitment window")
	screen.draft_panel.declined.emit()
	context.check(screen.session.draft.bonus and screen.session.draft.normal_count == 3, "decline opens support-only bonus without advancing normal count")
	screen.draft_panel.cards[0].pressed.emit()
	context.check(screen.session.phase == CombatSession.Phase.INTERMISSION and screen.session.draft.bonus_count == 1, "bonus pick permits next wave")
	screen.queue_free()
	await tree.process_frame
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("truncated")
	file.close()
	file = FileAccess.open(path + ".bak", FileAccess.WRITE)
	file.store_string("truncated")
	file.close()
	screen = SCENE.instantiate() as CombatScreen
	screen.m3_enabled = true
	screen.resume_existing = true
	screen.store = MissionStore.new(path)
	tree.root.add_child(screen)
	await tree.process_frame
	context.check(screen.recovery_required and screen.session.paused and screen.draft_panel.visible, "corrupt primary and backup show safe recovery UI")
	screen.queue_free()
	await tree.process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(path + suffix)
	return not snapshot.is_empty()
