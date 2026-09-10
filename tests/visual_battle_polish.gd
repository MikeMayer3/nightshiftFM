extends SceneTree
## Staged dense fights test presentation only; production UI and combat event wiring.
var checks: TestContext = TestContext.new()
func _initialize() -> void: run.call_deferred()
func capture(name: String) -> void:
	for screen: Node in get_nodes_in_group("m2_combat"): screen.arena.queue_redraw()
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M10-battle-polish/"+name+".png")
func run() -> void:
	for dimensions: Vector2i in [Vector2i(360,640),Vector2i(450,950),Vector2i(1024,768)]:
		root.size = dimensions; root.content_scale_size = Vector2i(720,1280)
		var boot: BootScreen = load("res://scenes/boot/boot.tscn").instantiate()
		boot.save_path = "user://battle_visual.json"; root.add_child(boot)
		boot.loadout.support = "static_net"; boot.show_page(BootScreen.Page.COMBAT)
		var screen: CombatScreen = boot.combat
		screen.set_process(false); screen.arena.set_process(false)
		var s: CombatSession = screen.session
		s.advance(.1)
		s.actors.clear(); s.wave = 5
		s.draft.catalog = ArsenalContent.tracks(ArsenalContent.DEFAULT)
		s.draft.equip(&"bass_driver"); s.draft.equip(&"arc_aerial"); s.draft.equip(&"needle_swarm"); s.draft.equip(&"reverb_well")
		checks.check(screen.arena.equipped_supports().size() == 5,"dense review includes every occupied support slot")
		screen.arena.feedback.announce(5)
		for index: int in 18:
			var actor: CombatActor = s.spawn_enemy(CombatContent.CARRIER if index % 7 == 0 else CombatContent.SWARMER,80+(index%6)*96)
			actor.position.y = 190+(index/6)*145
			if index%3 == 0: actor.status.apply_slow(.5,false)
			if index%4 == 0: s.damage_actor(actor,1,&"bass_driver")
		var net: Dictionary = ArsenalStats.parameters(s.draft.track(&"static_net"))
		s.arsenal._deploy(s,Vector2(280,350),&"static_net",net,1)
		s.arsenal._deploy(s,Vector2(430,470),&"bass_driver",ArsenalStats.parameters(s.draft.track(&"bass_driver")),2)
		screen.arena.feedback.upgrade(&"static_net")
		screen.arena._process(.1); screen._refresh()
		var snap: Dictionary = s.to_checkpoint()
		await capture("healthy-%dx%d" % [dimensions.x,dimensions.y])
		checks.check(s.to_checkpoint() == snap,"rendering scenery, waves and reactions preserves gameplay")
		checks.check(s.phase == CombatSession.Phase.COMBAT and screen.arena.feedback.wave_left > 0,"announcement leaves dense combat live")
		s.hull = 22; s.run.shield.current = 0; screen.arena.hit_flash = .15
		for index: int in 4: s.actors[index].position.y = 584+index*10
		screen.arena.feedback.wave_left = 0
		screen._refresh(); await capture("critical-%dx%d" % [dimensions.x,dimensions.y])
		checks.check(s.actors.any(RadioFeedback.approaching),"danger review contains genuine near-breach positions")
		RadioPreferences.current.values.low_effects = true; RadioPreferences.current.values.reduced_flash = true
		screen.arena.queue_redraw(); await capture("reduced-%dx%d" % [dimensions.x,dimensions.y])
		s.paused = true
		var before: Dictionary = screen.arena.feedback.upgrades.duplicate()
		screen.arena._process(2)
		checks.check(screen.arena.feedback.upgrades == before,"pause retains the upgrade highlight")
		RadioPreferences.current.values.low_effects = false; RadioPreferences.current.values.reduced_flash = false
		boot.queue_free(); await process_frame
	print("RESULT: %d battlefield rendered checks; %d failures" % [checks.checks,checks.failures])
	quit(0 if checks.failures == 0 else 1)
