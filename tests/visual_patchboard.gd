extends SceneTree
const SCREEN: Script = preload("res://tests/integration/test_patchboard_screen.gd")
var screen: CombatScreen
var checks: TestContext = TestContext.new()
func _initialize() -> void: _run.call_deferred()
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M6/" + name + ".png")
func click(button: Button) -> void:
	var point: Vector2 = button.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
func _run() -> void:
	screen = SCREEN.new().create_screen("user://m6_visual_test.json")
	root.add_child(screen)
	screen.set_process(false)
	await capture("patchboard-tutorial")
	checks.check(screen.session.is_wiring() and not screen.save_failed, "visual fixture starts at live saved wiring screen")
	for size: Vector2i in [Vector2i(360,640), Vector2i(450,950), Vector2i(450,800)]:
		root.size = size
		await capture("patchboard-%dx%d" % [size.x, size.y])
		var panel: PatchboardPanel = screen.patchboard_panel
		checks.check(panel.catalog.size.x <= panel.scroll.size.x + 1, "catalog has no horizontal overflow at %s" % size)
		checks.check(panel.launch_button.get_global_rect().end.y <= screen.size.y and panel.launch_button.size.y >= 76, "Go live remains visible with usable target at %s" % size)
	# Scroll to an actual enabled recipe and send viewport mouse events, not pressed.emit.
	screen.patchboard_panel.scroll.ensure_control_visible(screen.patchboard_panel.recipe_buttons[&"feedback_loop"])
	await process_frame
	await process_frame
	await capture("patchboard-requirements")
	await click(screen.patchboard_panel.recipe_buttons[&"feedback_loop"])
	checks.check(screen.session.patchboard.slots[0] == &"feedback_loop", "actual viewport click connects Feedback Loop")
	await capture("patchboard-connected")
	await click(screen.patchboard_panel.launch_button)
	screen.session.advance(2.3)
	screen._refresh()
	checks.check(screen.session.phase == CombatSession.Phase.COMBAT and not screen.patchboard_panel.visible, "actual Go live click enters combat")
	await capture("patchboard-combat")
	print("RESULT: %d visual checks; %d failures" % [checks.checks, checks.failures])
	quit(0 if checks.failures == 0 else 1)
