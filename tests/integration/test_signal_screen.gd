extends RefCounted
const SCENE: PackedScene = preload("res://scenes/combat/combat.tscn")
func run(context: TestContext, tree: SceneTree) -> bool:
	var screen: CombatScreen = SCENE.instantiate() as CombatScreen
	screen.m3_enabled = true
	screen.signal_enabled = true
	screen.store = MissionStore.new("user://test_signal_screen.json")
	tree.root.add_child(screen)
	await tree.process_frame
	screen.set_process(false)
	screen.session.advance(6)
	screen._refresh()
	context.check(screen.signal_bar.get_parent().visible and screen.signal_bar.value > 0 and screen.signal_bar.value < screen.signal_bar.max_value, "HUD meter grows with kills")
	screen.session.advance(30)
	context.check(screen.session.phase == CombatSession.Phase.DRAFT and screen.draft_panel.heading.text == screen.tr("SIGNAL_READY"), "real screen shows kill-triggered choice")
	context.check(not screen.save_failed and screen.store.load_save().run.content == SignalContent.VERSION, "real store accepts signal decision snapshot")
	var offer: StringName = screen.session.draft.offers[0]
	screen.draft_panel.info_buttons[0].pressed.emit()
	context.check(screen.session.draft.normal_count == 0, "new weapon detail button does not purchase")
	screen.draft_panel.show_draft(screen.session)
	screen.draft_panel.cards[0].pressed.emit()
	context.check(screen.session.phase == CombatSession.Phase.COMBAT and screen.session.draft.normal_count == 1, "whole-card input purchases and resumes fight")
	context.check(screen.session.draft.track(screen.session.draft.card(offer).target_id).rank() == 1, "whole-card acquisition equips new weapon")
	var saved: Dictionary = screen.store.load_save()
	var restored: CombatSession = CombatSession.new()
	context.check(restored.restore_checkpoint(saved.run) and restored.signal_progress.choices == 1, "real disk save remembers accepted choice")
	screen.toggle_pause()
	context.check(screen.session.paused and screen.details.text == screen.tr("SIGNAL_PAUSE"), "pause explains new checkpoint contract")
	screen.toggle_pause()
	screen.queue_free()
	await tree.process_frame
	return true
