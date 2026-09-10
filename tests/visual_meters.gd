extends SceneTree
## Phone-sized meter and population-waveform layout inspection, using staged actors.
var checks: TestContext = TestContext.new()
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for dimensions: Vector2i in [Vector2i(360,640),Vector2i(450,950),Vector2i(1024,768)]:
		root.size = dimensions; root.content_scale_size = Vector2i(720,1280)
		var boot: BootScreen = load("res://scenes/boot/boot.tscn").instantiate()
		boot.save_path = "user://meter_visual.json"; root.add_child(boot)
		boot.show_page(BootScreen.Page.COMBAT)
		var screen: CombatScreen = boot.combat
		screen.set_process(false); screen.arena.set_process(false)
		var s: CombatSession = screen.session
		s.advance(.1)
		RadioPreferences.current.values.large_text = true
		RadioPreferences.current.apply_fonts(screen)
		for count: int in [0,4,24]:
			s.actors.clear()
			for index: int in count:
				var actor: CombatActor = s.spawn_enemy(CombatContent.SWARMER,70+(index%6)*100)
				actor.position.y = 170+(index/6)*90
			s.hull = 100 if count == 0 else 37 if count == 4 else 0
			s.run.shield.current = 65 if count == 0 else 23 if count == 4 else 0
			screen._refresh(); screen.arena.queue_redraw()
			await process_frame; await process_frame; await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/evidence/M10-meters/" + "enemies-%d-%dx%d.png" % [count,dimensions.x,dimensions.y])
			checks.check(RadioFeedback.living_enemies(s) == count,"rendered waveform uses the staged live population")
			for bar: ProgressBar in [screen.hull_bar,screen.shield_bar]:
				var label: Label = bar.get_node("Caption")
				checks.check(bar.get_global_rect().encloses(label.get_global_rect()),"label stays inside its bar")
				checks.check(label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x < bar.size.x-8,"large-text meter caption fits without clipping")
				checks.check(bar.get_global_rect().end.y <= root.get_visible_rect().size.y and bar.size.y >= 60,"taller bar stays inside the viewport")
		RadioPreferences.current.values.large_text = false
		boot.queue_free(); await process_frame
	print("RESULT: %d meter rendered checks; %d failures" % [checks.checks,checks.failures])
	quit(0 if checks.failures == 0 else 1)
