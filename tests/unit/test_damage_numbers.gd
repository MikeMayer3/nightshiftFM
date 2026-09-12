extends RefCounted

func run(t: TestContext, tree: SceneTree) -> bool:
	var session: CombatSession = CombatSession.new()
	session.start_campaign(42, &"run.1", ArsenalContent.DEFAULT, {"mission":1,"cleared":0,"modules":[]})
	session.advance(.1)
	var actor: CombatActor = session.spawn_enemy(CombatContent.CARRIER, 320)
	actor.position.y = 400; actor.health = 1000; actor.max_health = 1000; actor.armor = 100
	var arena: CombatArena = CombatArena.new(); arena.session = session
	tree.root.add_child(arena); arena.set_process(false)
	session.combat_event.connect(arena.show_event)
	var numbers: DamageNumbers = arena.feedback.damage_numbers
	session.arsenal.hit(session, actor, {"damage":20.0,"crit":0.0}, &"main", 1)
	t.check(numbers.entries.size() == 1 and is_equal_approx(numbers.entries[0].amount, 10) and not numbers.entries[0].critical, "normal popup shows actual post-armor damage")
	session.arsenal.hit(session, actor, {"damage":20.0,"crit":1.0}, &"main", 2)
	t.check(numbers.entries.size() == 2 and numbers.entries[1].critical and is_equal_approx(numbers.entries[1].amount, 17.5), "real critical roll reaches its own popup with the applied multiplier")
	session.damage_actor(actor, 4)
	t.check(numbers.entries.size() == 2 and is_equal_approx(numbers.entries[0].amount, 12), "rapid regular hits combine without contaminating the critical total")
	var checkpoint: Dictionary = session.to_checkpoint()
	arena._process(.2)
	t.check(session.to_checkpoint() == checkpoint, "number animation leaves combat state and RNG untouched")
	var before: Array[Dictionary] = numbers.entries.duplicate(true)
	session.paused = true; arena._process(2)
	t.check(numbers.entries == before, "pause freezes damage-number lifetime")
	session.paused = false; session.phase = CombatSession.Phase.DRAFT; arena._process(2)
	t.check(numbers.entries == before, "earned upgrade choice freezes damage-number lifetime")
	session.phase = CombatSession.Phase.COMBAT
	numbers.clear(); actor.health = 3
	session.damage_actor(actor, 999)
	t.check(actor.resolved and numbers.entries.size() == 1 and numbers.entries[0].amount == 3, "killing hit shows remaining health rather than overkill")
	actor.position = Vector2.ZERO; session.actors.erase(actor)
	t.check(numbers.entries[0].position == Vector2(320,400), "killing popup survives actor removal at the impact location")
	numbers.advance(2)
	t.check(numbers.entries.is_empty(), "all number entries expire")
	var other: CombatActor = session.spawn_enemy(CombatContent.CARRIER,320); other.position.y = 400
	other.projectile = true; session.damage_actor(other,1)
	t.check(numbers.entries.is_empty(), "projectile interception does not masquerade as enemy damage")
	other.projectile = false
	other.position.y = -50; session.damage_actor(other, 10, &"main", 0, 0, true)
	t.check(numbers.entries.is_empty(), "protected incoming enemies cannot produce false hit or critical numbers")
	other.position.y = 400
	numbers.hit(CombatEvent.new(0,0,&"main",CombatEvent.Kind.DAMAGE,other.serial,0),other)
	session.damage_actor(other,0)
	t.check(numbers.entries.is_empty(), "zero damage produces no popup")
	for i: int in 100:
		numbers.hit(CombatEvent.new(i,i,&"main",CombatEvent.Kind.DAMAGE,i,2),other)
	t.check(numbers.entries.size() == DamageNumbers.LIMIT, "dense fights keep a fixed presentation memory bound")
	arena.feedback.reset()
	t.check(numbers.entries.is_empty(), "run restart clears damage numbers through existing feedback reset")
	t.check(DamageNumbers.number(.02) == "0.1" and DamageNumbers.number(17.5) == "18", "fractional hits remain visible and normal values round cleanly")
	arena.queue_free(); await tree.process_frame
	return true
