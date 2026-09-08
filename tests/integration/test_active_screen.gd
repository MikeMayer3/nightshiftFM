extends RefCounted
const SCENE: PackedScene = preload("res://scenes/combat/combat.tscn")
func run(context: TestContext, tree: SceneTree) -> bool:
	var screen: CombatScreen = SCENE.instantiate() as CombatScreen
	screen.m3_enabled = true
	screen.active_enabled = true
	screen.store = MissionStore.new("user://active_screen_test.json")
	tree.root.add_child(screen)
	await tree.process_frame
	await tree.process_frame
	screen.set_process(false)
	context.check(screen.session.active_combat != null, "active screen starts revised mission")
	context.check(screen.arena.equipped_supports() == [&"arc_aerial"], "battlefield shows only the equipped starting support")
	for name: String in ["Legend", "Hint", "AbilityHint"]:
		context.check(not (screen.get_node("Safe/Column/" + name) as Control).visible, "removed bottom text: " + name)
	screen.session.advance(2.4)
	screen._refresh()
	await tree.process_frame
	context.check(screen.arena.size.y > screen.size.y * 0.7 and screen.arena.arena_offset() == Vector2.ZERO, "battlefield fills over 70 percent of the screen without inner letterboxing")
	var world: Vector2 = screen.session.actors[2].position
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = world * screen.arena.arena_stretch()
	screen.arena._gui_input(event)
	context.check(screen.session.focus_active and screen.session.focus_point.is_equal_approx(world), "expanded field maps aiming to unchanged simulation coordinates")
	event.pressed = false
	event.position = screen.arena.get_global_transform_with_canvas() * (world * screen.arena.arena_stretch())
	screen.arena._input(event)
	screen._refresh()
	context.check(screen.session.active_combat.uses == 1 and screen.session.kills == 5 and not screen.session.focus_active, "aim-and-release fires one burst at the displayed formation")
	context.check(screen.ability_button.disabled and screen.ability_button.text.contains("5"), "burst button displays real recharge time")
	screen.session.advance(6)
	event.pressed = true
	event.position = world * screen.arena.arena_stretch()
	screen.arena._gui_input(event)
	event.pressed = false
	event.position = Vector2(-20,-20)
	screen.arena._input(event)
	context.check(screen.session.active_combat.uses == 1 and not screen.session.focus_active, "release outside battlefield cancels instead of firing")
	screen.ability_button.pressed.emit()
	screen.session.advance(CombatSession.STEP)
	context.check(screen.session.active_combat.uses == 2, "accessible Burst button fires at current automatic target")
	var saved: Dictionary = screen.store.load_save()
	var restored: CombatSession = CombatSession.new()
	context.check(saved.run.content == ActiveCombat.VERSION and restored.restore_checkpoint(saved.run), "real atomic store validates active mission checkpoint")
	screen.toggle_pause()
	context.check(screen.details.text == screen.tr("ACTIVE_PAUSE"), "instructions are available in pause instead of beneath the battlefield")
	screen.session.draft.equip(&"bass_driver")
	screen.session.draft.equip(&"static_net")
	context.check(screen.arena.equipped_supports().size() == 3, "recruited Bass and Net add their own mini turrets")
	var original: PackedVector2Array = PackedVector2Array([CombatSession.TRANSMITTER, Vector2(320, 150)])
	screen.arena.show_chain(original, true)
	context.check(screen.arena.chains.back().points[0] == CombatArena.SUPPORT_POSITIONS[&"arc_aerial"] and original[0] == CombatSession.TRANSMITTER, "Arc fires visually from its support turret without changing attack data")
	var old_session: CombatSession = CombatSession.new()
	old_session.start_m3(42, &"run.1")
	screen.arena.session = old_session
	screen.arena.show_chain(original, true)
	context.check(screen.arena.equipped_supports().is_empty() and screen.arena.chains.back().points[0] == CombatSession.TRANSMITTER, "legacy M3 keeps its transmitter origin without an invisible support turret")
	screen.queue_free()
	await tree.process_frame
	return true
