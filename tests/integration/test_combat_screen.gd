extends RefCounted
const SCENE: PackedScene = preload("res://scenes/combat/combat.tscn")

func run(context: TestContext, tree: SceneTree) -> bool:
	var screen: CombatScreen = SCENE.instantiate() as CombatScreen
	tree.root.add_child(screen)
	await tree.process_frame
	await tree.process_frame
	context.check(tree.get_nodes_in_group("m2_combat").size() == 1, "single combat screen instance")
	screen.pause_button.pressed.emit()
	var seconds: float = screen.session.elapsed
	await tree.create_timer(0.08).timeout
	context.check(screen.session.elapsed == seconds and screen.overlay.visible, "real frame processing freezes under pause overlay")
	screen._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	screen._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	screen._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	context.check(screen.session.paused, "resume notification alone does not override lost focus")
	screen._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	context.check(screen.session.paused, "OS resume preserves manual pause")
	screen.resume_button.pressed.emit()
	await tree.create_timer(0.08).timeout
	context.check(screen.session.elapsed > seconds, "Resume button advances real simulation")
	for cycle: int in 20:
		screen._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		seconds = screen.session.elapsed
		screen._process(10.0)
		context.check(screen.session.elapsed == seconds, "combat focus pause freezes cycle %d" % cycle)
		screen._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		screen._process(10.0)
		context.check(screen.session.elapsed == seconds, "first resume frame skips background delta cycle %d" % cycle)
	var pointer: InputEventMouseButton = InputEventMouseButton.new()
	pointer.button_index = MOUSE_BUTTON_LEFT
	pointer.pressed = true
	pointer.position = screen.arena.arena_offset() + Vector2(100,200) * screen.arena.arena_scale()
	screen.arena._gui_input(pointer)
	context.check(screen.session.focus_active and screen.session.focus_point.is_equal_approx(Vector2(100,200)), "pointer maps visible arena to fixed combat coordinates")
	pointer.pressed = false
	screen.arena._input(pointer)
	context.check(not screen.session.focus_active, "pointer release outside arena clears focus")
	screen.ability_button.pressed.emit()
	context.check(screen.session.ability_left > 0 and screen.ability_button.disabled, "shield button activates with cooldown UI")
	for attempt: int in 10:
		screen.restart_button.pressed.emit()
		screen.session.advance(180.0)
		context.check(screen.session.phase == CombatSession.Phase.VICTORY and screen.overlay.visible and not screen.resume_button.visible, "UI results and restart complete run %d" % (attempt + 1))
		context.check(screen.session.finished.get_connections().size() == 1 and tree.get_nodes_in_group("m2_combat").size() == 1, "no duplicate scene or results subscription run %d" % (attempt + 1))
	screen.restart()
	screen.session.hit_station(999, &"M2_DIVER_NAME")
	context.check(screen.overlay_title.text == screen.tr("COMBAT_DEFEAT") and "Diver" in screen.details.text, "defeat UI explains source of fatal damage")
	screen.queue_free()
	await tree.process_frame
	context.check(tree.get_nodes_in_group("m2_combat").is_empty(), "leaving combat frees its entire screen")
	return true
