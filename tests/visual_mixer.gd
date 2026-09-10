extends SceneTree
var t: TestContext = TestContext.new()
func _initialize() -> void: run.call_deferred()
func frames() -> void:
	await process_frame
	await process_frame
func capture(name: String) -> void:
	await frames()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M10-mixer/" + name + ".png")
func click_at(point: Vector2, pressed: bool) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	root.push_input(event, true)
func click(button: Button) -> void:
	var point: Vector2 = button.get_global_rect().get_center()
	click_at(point, true)
	click_at(point, false)
	await frames()
func run() -> void:
	root.content_scale_size = Vector2i(720, 1280)
	for dimensions: Vector2i in [Vector2i(360, 640), Vector2i(450, 950)]:
		root.size = dimensions
		for cleared: int in [0, 4, 12]:
			var path: String = "user://mixer_visual_%d.json" % cleared
			MissionStore.new(path).save(load("res://tests/integration/test_campaign_screen.gd").new().profile_at(cleared), {})
			var boot: BootScreen = load("res://scenes/boot/boot.tscn").instantiate()
			boot.save_path = path
			root.add_child(boot)
			await frames()
			boot.show_page(BootScreen.Page.CAMPAIGN)
			boot.campaign_panel.launch_button.pressed.emit()
			boot.picker.launch_button.pressed.emit()
			var screen: CombatScreen = boot.combat
			screen.set_process(false)
			screen.session.auto_fire = false
			screen.session.advance(2.5)
			screen._refresh()
			await frames()
			await click(screen.mixer_button)
			var panel: PatchboardPanel = screen.patchboard_panel
			var desk: MixerDesk = panel.desk
			t.check(screen.mixer_open and screen.session.paused and panel.visible and not screen.overlay.visible, "actual Mixer button pauses and opens desk")
			t.check(not panel.connections.visible and desk.visible, "faders lead; connections collapsed")
			t.check(panel.get_global_rect().end.x <= screen.size.x and panel.get_global_rect().end.y < screen.size.y, "panel fits viewport with battlefield visible")
			for fader: MixerFader in desk.faders:
				t.check(panel.scroll.get_global_rect().encloses(fader.get_global_rect()), "fader fits visible panel without horizontal overflow")
			t.check(panel.scroll.get_global_rect().encloses(desk.unlocks.get_global_rect()), "difficulty point hint is visible without scrolling")
			# A real pointer click on the upper notch drives the native slider.
			var fader: MixerFader = desk.faders[0]
			var top: Vector2 = fader.global_position + Vector2(fader.size.x / 2, 19)
			click_at(top, true); click_at(top, false)
			await frames()
			t.check(screen.session.patchboard.mixer.levels[0] == (3 if cleared == 0 else 4), "slider obeys hard point budget through input")
			await click(desk.minus_buttons[0])
			await click(desk.plus_buttons[1])
			var chosen: Array[int] = screen.session.patchboard.mixer.levels.duplicate()
			t.check(chosen[1] == 1 and chosen[0] >= 2 and not screen.save_failed, "touch-size buttons redistribute and persist points")
			var saved: Dictionary = MissionStore.new(path).load_save().run
			var disk_levels: Array[int] = []
			disk_levels.assign(saved.patchboard.mixer.levels)
			t.check(disk_levels == chosen, "actual disk save contains chosen mix")
			var elapsed: float = screen.session.elapsed
			screen.session.advance(10)
			t.check(screen.session.elapsed == elapsed, "combat stays frozen while mixing")
			await capture("mixer-%dx%d-%d-points" % [dimensions.x, dimensions.y, MixerState.budget(cleared)])
			await click(panel.connection_toggle)
			t.check(panel.connections.visible and not desk.visible, "connection view replaces faders without enlarging desk")
			panel.recipe_buttons[&"feedback_loop"].pressed.emit()
			t.check(screen.session.patchboard.slots[0] == &"feedback_loop" and not screen.save_failed, "optional weapon connections work during a frozen round")
			await click(panel.connection_toggle)
			t.check(desk.visible and screen.session.patchboard.mixer.levels == chosen, "return from connections preserves mix")
			await click(panel.launch_button)
			t.check(not screen.mixer_open and not screen.session.paused and not panel.visible, "Return to broadcast resumes same round")
			screen.session.advance(.1)
			t.check(screen.session.elapsed > elapsed, "simulation continues after closing mixer")
			await click(screen.mixer_button)
			t.check(screen.session.patchboard.mixer.levels == chosen, "reopening preserves allocation")
			screen.focused = false
			screen.close_mixer()
			t.check(screen.session.paused, "closing while backgrounded cannot resume combat")
			screen.focused = true
			screen._sync_pause()
			screen.toggle_pause()
			await frames()
			await capture("pause-%dx%d" % [dimensions.x, dimensions.y])
			var pause_mixer: Button
			for node: Node in screen.menu_button.get_parent().get_children():
				if node is Button and node.visible:
					t.check(Rect2(Vector2.ZERO, screen.size).encloses(node.get_global_rect()), "pause action fits phone viewport")
					if node.text == tr("MIXER_BUTTON"): pause_mixer = node
			await click(pause_mixer)
			t.check(screen.mixer_open, "desk accessible from pause menu")
			screen.close_mixer()
			t.check(screen.session.paused and screen.overlay.visible, "closing preserves explicit manual pause")
			screen.toggle_pause()
			# Return from the mixer to an existing upgrade decision, unchanged.
			screen.session.signal_progress.earned = screen.session.signal_progress.threshold()
			screen.session._open_signal_choice()
			var offers: Array[StringName] = screen.session.draft.offers.duplicate()
			screen.open_mixer()
			screen.close_mixer()
			t.check(screen.draft_panel.visible and screen.session.draft.offers == offers, "mixer preserves pending upgrade decision")
			boot.queue_free()
			await frames()
	print("RESULT: %d mixer visual/input checks; %d failures" % [t.checks, t.failures])
	quit(0 if t.failures == 0 else 1)
