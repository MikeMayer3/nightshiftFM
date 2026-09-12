extends SceneTree
## Synthetic hits through production combat/UI wiring; no player save or progression.
func _initialize() -> void: run.call_deferred()

func run() -> void:
	var checks: TestContext = TestContext.new()
	var folder: String = "res://docs/evidence/damage-numbers/"
	DirAccess.make_dir_recursive_absolute(folder)
	RadioPreferences.current.values.sound = false; RadioPreferences.current.values.music = false
	for dimensions: Vector2i in [Vector2i(320,568),Vector2i(450,1000),Vector2i(1024,768)]:
		root.size = dimensions; root.content_scale_size = Vector2i(720,1280)
		var boot: BootScreen = load("res://scenes/boot/boot.tscn").instantiate()
		boot.save_path = "user://damage_number_visual.json"; root.add_child(boot)
		boot.show_page(BootScreen.Page.COMBAT)
		var screen: CombatScreen = boot.combat
		screen.set_process(false); screen.arena.set_process(false)
		var s: CombatSession = screen.session
		s.advance(.1); s.actors.clear()
		for i: int in 12:
			var actor: CombatActor = s.spawn_enemy(CombatContent.CARRIER, 28 + (i % 4) * 195)
			actor.position.y = 295 + (i / 4) * 100
			actor.health = 500; actor.max_health = 500; actor.armor = 0
			s.arsenal.hit(s, actor, {"damage":24.0 + i * 3,"crit":1.0 if i%3==1 else 0.0}, &"main", i+1)
		var saved: Dictionary = s.to_checkpoint()
		for mode: String in ["pop","float","reduced-large"]:
			if mode == "float": screen.arena._process(.35)
			RadioPreferences.current.values.low_effects = mode == "reduced-large"
			RadioPreferences.current.values.reduced_flash = mode == "reduced-large"
			RadioPreferences.current.values.large_text = mode == "reduced-large"
			screen._refresh(); screen.arena.queue_redraw()
			for frame: int in 5: await process_frame
			await RenderingServer.frame_post_draw
			checks.check(s.to_checkpoint() == saved, "rendered number animation preserves gameplay and RNG")
			checks.check(screen.arena.feedback.damage_numbers.entries.size() == 12, "real damage events reach the production arena")
			root.get_texture().get_image().save_png(folder + "%dx%d-%s.png" % [dimensions.x,dimensions.y,mode])
		RadioPreferences.current.values.low_effects = false
		RadioPreferences.current.values.reduced_flash = false
		RadioPreferences.current.values.large_text = false
		boot.queue_free(); await process_frame
	print("RESULT: %d rendered damage-number checks; %d failures" % [checks.checks,checks.failures])
	quit(0 if checks.failures == 0 else 1)
