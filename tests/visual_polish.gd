extends SceneTree
## Rendered title/effect review at real phone widths; production scenes and queries.
var checks: TestContext = TestContext.new()
func _initialize() -> void: run.call_deferred()
func capture(name: String) -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M10-polish/" + name + ".png")
func fit(node: Node) -> void:
	if node is Control and node.is_visible_in_tree():
		var r: Rect2 = node.get_global_rect()
		checks.check(r.position.x >= -1 and r.end.x <= root.get_visible_rect().size.x + 1, "horizontal fit: " + str(node.name))
	for child: Node in node.get_children(): fit(child)
func run() -> void:
	for dimensions: Vector2i in [Vector2i(360,640), Vector2i(450,950), Vector2i(1024,768)]:
		root.size = dimensions; root.content_scale_size = Vector2i(720,1280)
		var boot: BootScreen = load("res://scenes/boot/boot.tscn").instantiate()
		boot.save_path = "user://polish_visual.json"; root.add_child(boot)
		await process_frame
		await capture("splash-%dx%d" % [dimensions.x, dimensions.y])
		fit(boot)
		checks.check(boot.splash.visible and boot.menu.visible, "splash gives direct menu access")
		checks.check(not boot.menu.get_node("MobileChecks").visible, "diagnostics are absent from the player title screen")
		boot.continue_button.show()
		RadioPreferences.current.values.large_text = true
		RadioPreferences.current.apply_fonts(boot)
		await capture("splash-continue-large-%dx%d" % [dimensions.x, dimensions.y])
		fit(boot)
		for button: Node in boot.menu.get_children():
			if button is Button and button.visible:
				checks.check(button.get_global_rect().end.y <= root.get_visible_rect().size.y, "large-font title actions remain inside viewport")
		RadioPreferences.current.values.large_text = false
		boot.show_page(BootScreen.Page.SETTINGS)
		checks.check(not boot.splash.visible, "splash does not cover other pages")
		boot.show_page(BootScreen.Page.COMBAT)
		boot.combat.set_process(false)
		boot.combat.session.phase = CombatSession.Phase.VICTORY
		boot.combat._refresh()
		await capture("result-layout-%dx%d" % [dimensions.x, dimensions.y])
		checks.check(not boot.combat.pause_mixer_button.visible, "results hide the unavailable mixer action")
		checks.check(boot.combat.report_button.get_theme_stylebox("normal") is StyleBoxFlat, "results report button uses the radio style")
		boot.queue_free(); await process_frame
	root.size = Vector2i(900,900); root.content_scale_size = root.size
	var grid: GridContainer = GridContainer.new(); grid.columns = 3; grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(grid)
	for id: String in ["pulse", "sweep", "burst", "static_net", "bass_driver", "reverb_well"]:
		var column: VBoxContainer = VBoxContainer.new(); column.size_flags_horizontal = Control.SIZE_EXPAND_FILL; column.size_flags_vertical = Control.SIZE_EXPAND_FILL; grid.add_child(column)
		var label: Label = Label.new(); label.text = tr(ArsenalContent.DEFINITIONS[id].name_key); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; column.add_child(label)
		var arena: CombatArena = CombatArena.new(); arena.custom_minimum_size = Vector2(292,405); arena.size_flags_vertical = Control.SIZE_EXPAND_FILL; column.add_child(arena)
		var s: CombatSession = CombatSession.new(); s.start_campaign(42, &"run.1", {"main": id if id in ArsenalContent.MAINS else "pulse", "shield": "capacitor", "support": "arc_aerial" if id in ArsenalContent.MAINS else id}, {"mission":1,"cleared":12,"modules":[]})
		arena.session = s; arena.set_process(false); arena.waveform_time = 1.1; s.phase = CombatSession.Phase.COMBAT; s.wave = 1; s.actors.clear()
		var target: CombatActor = s.spawn_enemy(CombatContent.CARRIER,320); target.position.y = 345
		for x: float in [240, 400]: s.spawn_enemy(CombatContent.SWARMER,x).position.y = 320
		s.chain_fired.connect(arena.show_chain); s.support_effect.connect(arena.show_support)
		if id in ArsenalContent.MAINS:
			s.arsenal.fire_main(s, target)
			for chain: Dictionary in arena.chains: chain.left = .16
		else:
			var p: Dictionary = ArsenalStats.parameters(s.draft.track(StringName(id)))
			s.arsenal._deploy(s, target.position, StringName(id), p, 1)
			s.arsenal._tick_zones(s, .1)
			for pulse: Dictionary in arena.pulses: pulse.left = .33
	await capture("combat-effects")
	RadioPreferences.current.values.low_effects = true; RadioPreferences.current.values.reduced_flash = true
	grid.queue_redraw(); for child: Node in grid.get_children(): (child.get_child(1) as Control).queue_redraw()
	await capture("combat-effects-reduced")
	grid.queue_free(); await process_frame
	print("RESULT: %d polish rendered checks; %d failures" % [checks.checks, checks.failures])
	quit(0 if checks.failures == 0 else 1)
