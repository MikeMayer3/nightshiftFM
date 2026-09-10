extends RefCounted
func run(t: TestContext, tree: SceneTree) -> bool:
	var s: CombatSession = CombatSession.new()
	s.start_campaign(42,&"run.1",ArsenalContent.DEFAULT,{"mission":1,"cleared":0,"modules":[]})
	s.advance(.1)
	var actor: CombatActor = s.spawn_enemy(CombatContent.CARRIER,320)
	actor.position.y = 400
	var count_before: int = RadioFeedback.living_enemies(s)
	var projectile: CombatActor = s.spawn_enemy(CombatContent.SWARMER,100)
	projectile.projectile = true
	var dead: CombatActor = s.spawn_enemy(CombatContent.SWARMER,120); dead.health = 0
	var resolved: CombatActor = s.spawn_enemy(CombatContent.SWARMER,140); resolved.resolved = true
	t.check(RadioFeedback.living_enemies(s) == count_before,"waveform counts living enemies, excluding projectiles and resolved/dead actors")
	var shapes: Array[Vector2] = []
	for count: int in [0,1,5,20,100,1000]: shapes.append(RadioFeedback.signal_shape(count))
	var ordered: bool = true
	for index: int in range(1,shapes.size()): ordered = ordered and shapes[index].x > shapes[index-1].x and shapes[index].y < shapes[index-1].y
	t.check(ordered,"more living enemies increase amplitude and shorten waveform period")
	var flat: bool = true
	for point: Vector2 in RadioFeedback.signal_points(0,1): flat = flat and point.y == 20
	t.check(flat,"empty battlefield produces a flat signal")
	var bounded: bool = true
	for point: Vector2 in RadioFeedback.signal_points(1000,1): bounded = bounded and point.y >= 5 and point.y <= 35
	t.check(bounded,"crowded waveform remains inside the incoming strip")
	var arena: CombatArena = CombatArena.new(); arena.session = s
	tree.root.add_child(arena); arena.set_process(false)
	s.combat_event.connect(arena.show_event)
	var original_position: Vector2 = actor.position
	s.damage_actor(actor,1,&"bass_driver")
	var saved: Dictionary = s.to_checkpoint()
	arena.feedback.announce(5); arena.feedback.upgrade(&"main")
	arena._process(.1)
	t.check(arena.feedback.recoil(actor,false).y < 0 and actor.position == original_position,"bass recoil moves only the sprite, not collision or path state")
	t.check(arena.feedback.recoil(actor,true) == Vector2.ZERO,"reduced effects eliminate enemy recoil")
	t.check(s.to_checkpoint() == saved,"all new feedback leaves simulation and checkpoint RNG unchanged")
	for phase: CombatSession.Phase in [CombatSession.Phase.COMBAT,CombatSession.Phase.DRAFT]:
		s.phase = phase; s.paused = phase == CombatSession.Phase.COMBAT
		var before: Array = [arena.feedback.reactions.duplicate(true),arena.feedback.upgrades.duplicate(true),arena.feedback.wave_left]
		arena._process(5)
		t.check(before == [arena.feedback.reactions,arena.feedback.upgrades,arena.feedback.wave_left],"pause and choice screens preserve new feedback clocks")
	s.phase = CombatSession.Phase.COMBAT; s.paused = false
	arena._process(3)
	t.check(arena.feedback.wave_left == 0 and arena.feedback.upgrades.is_empty() and arena.feedback.reactions.is_empty(),"announcements and upgrade celebrations expire without delaying waves")
	for serial: int in 300: arena.feedback.hit(CombatEvent.new(serial,1,&"main",CombatEvent.Kind.DAMAGE,serial,1))
	t.check(arena.feedback.reactions.size() == 128,"dense hit feedback has a fixed memory bound")
	arena.feedback.upgrade(&"not_equipped_or_valid")
	t.check(arena.feedback.upgrades.is_empty(),"unknown instrument feedback is ignored")
	actor.position.y = CombatSession.BREACH_Y - 106
	t.check(not RadioFeedback.approaching(actor),"distant actors do not raise breach warnings")
	actor.position.y += 2
	t.check(RadioFeedback.approaching(actor),"actors near the line raise a breach warning")
	actor.resolved = true
	t.check(not RadioFeedback.approaching(actor),"resolved actors cannot leave stale danger warnings")
	t.check([RadioScenery.lit_windows(1),RadioScenery.lit_windows(.5),RadioScenery.lit_windows(.2),RadioScenery.lit_windows(0)] == [3,2,1,0],"studio lights communicate healthy, damaged, critical and lost states")
	arena.queue_free(); await tree.process_frame
	var boot: BootScreen = load("res://scenes/boot/boot.tscn").instantiate()
	boot.save_path = "user://feedback_unit.json"; tree.root.add_child(boot)
	boot.show_page(BootScreen.Page.COMBAT)
	var screen: CombatScreen = boot.combat
	screen.set_process(false); screen.arena.set_process(false)
	screen.session.hull = 37; screen.session.run.shield.current = 0
	screen._refresh()
	t.check(screen.hull_caption.text == screen.tr("POLISH_HEALTH_BAR") % [37,screen.session.maximum_hull()] and screen.shield_caption.text == screen.tr("POLISH_SHIELD_BAR") % [0,screen.session.run.shield.capacity],"in-bar labels show independent live health and shield values")
	t.check(not screen.get_node("Safe/Column/Health").visible and screen.hull_caption.get_parent() == screen.hull_bar and screen.shield_caption.get_parent() == screen.shield_bar,"health text is inside the bars without a duplicate external line")
	screen.session.hull = screen.session.maximum_hull(); screen.session.run.shield.current = screen.session.run.shield.capacity
	for tick: int in 1000:
		if screen.session.is_deciding(): break
		screen.session.advance(.2)
	t.check(screen.session.is_deciding(),"production broadcast earns a real upgrade for feedback integration")
	screen._refresh()
	var id: StringName = screen.session.draft.offers[0]
	var target: StringName = screen.session.draft.card(id).target_id
	screen.draft_panel.cards[0].pressed.emit()
	t.check(screen.arena.feedback.upgrades.has(target),"a legal visible upgrade highlights its actual instrument")
	var feedback_before: Dictionary = screen.arena.feedback.upgrades.duplicate()
	screen._choose_upgrade(&"invalid.card")
	t.check(screen.arena.feedback.upgrades == feedback_before,"rejected choices cannot create a false celebration")
	screen.restart()
	t.check(screen.arena.feedback.upgrades.is_empty() and screen.arena.feedback.reactions.is_empty() and screen.arena.feedback.wave_left == 0,"restart clears all old run feedback")
	screen.session.advance(.1)
	t.check(screen.session.phase == CombatSession.Phase.COMBAT and screen.arena.feedback.wave == 1 and screen.arena.feedback.wave_left > 0,"wave notice starts with live combat and no countdown")
	boot.queue_free(); await tree.process_frame
	return true
