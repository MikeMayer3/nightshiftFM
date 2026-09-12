extends SceneTree
## Staged production UI, drone flight/fire and pointer-driven Mixer check.
func _initialize() -> void: run.call_deferred()

func run() -> void:
	var t: TestContext = TestContext.new()
	var folder: String = "res://docs/evidence/note-drones/"
	DirAccess.make_dir_recursive_absolute(folder)
	RadioPreferences.current.values.sound = false; RadioPreferences.current.values.music = false
	for dimensions: Vector2i in [Vector2i(320,568),Vector2i(450,1000),Vector2i(1024,768)]:
		root.size = dimensions; root.content_scale_size = Vector2i(720,1280)
		RadioPreferences.current.values.large_text = dimensions.x == 320
		var boot: BootScreen = load("res://scenes/boot/boot.tscn").instantiate()
		boot.save_path = "user://note_drone_visual_%d.json" % Time.get_ticks_usec(); root.add_child(boot)
		boot.show_page(BootScreen.Page.COMBAT)
		var screen: CombatScreen = boot.combat
		screen.set_process(false); screen.arena.set_process(false); screen.coach.set_process(false)
		var s: CombatSession = screen.session
		s.advance(.1); s.elapsed = 12; s.actors.clear()
		s.draft.catalog = ArsenalContent.tracks(ArsenalContent.DEFAULT)
		s.draft.equip(&"needle_swarm")
		var actor: CombatActor = s.spawn_enemy(CombatContent.CARRIER,320)
		actor.position.y = 400; actor.health = 1000; actor.max_health = 1000; actor.armor = 0
		s.arsenal._needles(s,actor,ArsenalStats.parameters(s.draft.track(&"needle_swarm")),s.arsenal._root(s,&"needle_swarm",actor.serial))
		for tick: int in 200:
			screen.arena._process(.01); s.arsenal._tick_needles(s,.01)
			if not screen.arena.drone_shots.is_empty(): break
		t.check(not screen.arena.drone_shots.is_empty() and actor.health < 1000, "orbiting notes visibly shoot and apply damage through production wiring")
		s.arsenal.hit(s,actor,{"damage":18.0,"crit":1.0},&"main",s.attack_serial)
		screen._refresh()
		await settle()
		t.check(screen.coach.current_hint == "mixer" and screen.coach.visible, "Mixer reminder appears during a run")
		t.check(screen.shield_bar.get_global_rect().end.y <= screen.size.y + 1, "reminder and controls fit the viewport")
		t.check(not screen.coach.get_global_rect().intersects(screen.arena.get_global_rect()), "reminder does not cover the battlefield")
		root.get_texture().get_image().save_png(folder + "%dx%d-firing.png" % [dimensions.x,dimensions.y])
		for pressed: bool in [true,false]:
			var event: InputEventMouseButton = InputEventMouseButton.new()
			event.position = screen.mixer_button.get_global_rect().get_center()
			event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed; root.push_input(event,true)
		await settle()
		t.check(screen.mixer_open and s.paused, "visible Mixer button opens and pauses combat")
		screen.close_mixer(); screen.arena._process(.18); s.arsenal._tick_needles(s,.18)
		screen._refresh(); await settle()
		root.get_texture().get_image().save_png(folder + "%dx%d-orbit.png" % [dimensions.x,dimensions.y])
		boot.queue_free(); await process_frame
	print("RESULT: %d note drone rendered checks; %d failures" % [t.checks,t.failures])
	quit(0 if t.failures == 0 else 1)

func settle() -> void:
	for frame: int in 6: await process_frame
	await RenderingServer.frame_post_draw
